import 'package:digitalwill/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/services/subscription_service.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../widgets/subscription_card.dart';
import '../widgets/subscription_models.dart';
import 'checkout_webview_page.dart';

class SubscriptionSelectionPage extends StatefulWidget {
  final String userName;
  final String? willId;

  const SubscriptionSelectionPage({
    super.key,
    this.userName = 'James',
    this.willId,
  });

  @override
  State<SubscriptionSelectionPage> createState() =>
      _SubscriptionSelectionPageState();
}

class _SubscriptionSelectionPageState extends State<SubscriptionSelectionPage> {
  final PageController _pageController = PageController(
    viewportFraction: 0.72,
    initialPage: 1,
  );
  final _subscriptionService = SubscriptionService();
  final _secureStorage = SecureStorageService();

  int _currentPage = 1;
  bool _isProcessing = false;
  bool _isVerifying = true;
  String? _willId;
  List<SubscriptionPlan> _subscriptionPlans = [];

  @override
  void initState() {
    super.initState();
    _loadSubscriptionPlans();
    _loadWillId();
    _verifyPaymentStatus();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (page != _currentPage) {
        setState(() {
          _currentPage = page;
        });
      }
    });
  }

  Future<void> _loadSubscriptionPlans() async {
    _subscriptionPlans = await getSubscriptionPlans();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _verifyPaymentStatus() async {
    // Mock verification - simulate checking payment status
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() {
        _isVerifying = false;
      });
    }
  }

  Future<void> _loadWillId() async {
    // First try to use the passed willId
    if (widget.willId != null) {
      setState(() {
        _willId = widget.willId;
      });
      print('✅ Will ID received from navigation: $_willId');
      return;
    }
    
    // Fallback to secure storage
    _willId = await _secureStorage.getWillId();
    if (_willId != null) {
      print('✅ Will ID loaded from secure storage: $_willId');
      setState(() {});
    } else {
      print('⚠️ No will ID found in secure storage or navigation');
    }
  }

  Future<void> _handleSubscriptionSelect(SubscriptionPlan plan) async {
    if (_isProcessing) return;

    // Check if we have a will ID
    if (_willId == null) {
      _showErrorDialog('Unable to proceed', 'No will ID found. Please try creating your will again.');
      return;
    }

    // Handle free plan (Basic)
    if (plan.priceId == null) {
      print('✅ Free plan selected, navigating to legal review');
      context.push(
        AppRouter.legalReview,
        extra: {
          'userName': widget.userName,
          'willId': _willId,
          'regenerate': true,
        },
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _subscriptionService.createCheckout(
        willId: _willId!,
        priceId: plan.priceId!,
      );

      if (!mounted) return;

      if (result != null) {
        print('✅ Checkout created successfully: $result');
        
        // Extract checkout URL from response
        String? checkoutUrl;
        if (result['data'] != null && result['data']['url'] != null) {
          checkoutUrl = result['data']['url'] as String;
          print('💳 Checkout URL: $checkoutUrl');
        } else if (result['checkout_url'] != null) {
          checkoutUrl = result['checkout_url'] as String;
          print('💳 Checkout URL: $checkoutUrl');
        } else if (result['url'] != null) {
          checkoutUrl = result['url'] as String;
          print('💳 Checkout URL: $checkoutUrl');
        }
        
        if (result['session_id'] != null) {
          print('💳 Session ID: ${result['session_id']}');
        }
        
        // If we have a checkout URL, show it to the user
        if (checkoutUrl != null) {
          _showCheckoutUrlDialog(checkoutUrl);
        } else {
          // No checkout URL, navigate directly (free plan fallback)
          context.push(
            AppRouter.legalReview,
            extra: {
              'userName': widget.userName,
              'documentId': 'WILL-MDVO2Y98',
              'regenerate': true,
            },
          );
        }
      } else {
        _showErrorDialog('Payment Error', 'Unable to create checkout session. Please try again.');
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Error handling subscription: $e');
      _showErrorDialog('Error', 'An unexpected error occurred. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: AppTextStyles.cardTitle),
        content: Text(message, style: AppTextStyles.bodyMedium),
        actions: [
          AppTextButton(
            text: 'OK',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showCheckoutUrlDialog(String checkoutUrl) {
    // Directly navigate to webview instead of showing dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutWebViewPage(
          checkoutUrl: checkoutUrl,
          onPaymentComplete: () async {
            print('💳 Payment completed, processing navigation...');
            
            // Ensure we have a will ID
            String? willId = _willId;
            if (willId == null || willId.isEmpty) {
              print('⚠️ Will ID not in memory, fetching from secure storage...');
              willId = await _secureStorage.getWillId();
            }
            
            print('📋 Will ID for legal review: $willId');
            
            // Pop the webview first
            Navigator.of(context).pop();
            
            // Then navigate to legal review after successful payment
            if (mounted) {
              if (willId != null && willId.isNotEmpty) {
                print('✅ Navigating to legal review with will ID: $willId');
                context.push(
                  AppRouter.legalReview,
                  extra: {
                    'userName': widget.userName,
                    'willId': willId,
                    'regenerate': true,
                  },
                );
              } else {
                print('❌ Cannot navigate to legal review: No will ID available');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Unable to proceed. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: _isVerifying ? null : PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: AppColors.backgroundWhite,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 80,
          titleSpacing: 0,
          flexibleSpace: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Progress indicator on the left - clickable
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Close button - custom behavior
                  GestureDetector(
                    onTap: () {
                      // Navigate back to review page directly
                      context.go(AppRouter.review);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.backgroundWhite,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.borderGray,
                          width: 1,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.close,
                          color: AppColors.primaryDarkGreen,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isVerifying
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryDarkGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Verifying payment status...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : Column(
        children: [
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
            // Title section
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Hello ${widget.userName},\n',
                        style: AppTextStyles.pageTitle.copyWith(
                          fontSize: 20,
                          height: 1.2,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      TextSpan(
                        text: 'Choose the support that\'s right for you',
                        style: AppTextStyles.pageTitle.copyWith(
                          fontSize: 20,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Whether you just want to create and store your Will, or you\'d like a lawyer to guide you along the way — you\'re in the right place.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _subscriptionPlans.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primaryDarkGreen,
                      ),
                    ),
                  )
                : PageView.builder(
              controller: _pageController,
              itemCount: _subscriptionPlans.length,
              itemBuilder: (context, index) {
                final plan = _subscriptionPlans[index];
                final isActive = index == _currentPage;

                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.95,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 0.7,
                    duration: const Duration(milliseconds: 300),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Center(
                      child: SizedBox(
                        width: AppDimensions.responsiveSize(context, 260),
                        child: SubscriptionCard(
                          plan: plan,
                          isActive: isActive,
                          onSelect: () {
                            if (!_isProcessing) {
                              _handleSubscriptionSelect(plan);
                            }
                          },
                        ),
                      ),
                    ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Page indicators
          if (_subscriptionPlans.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _subscriptionPlans.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: index == _currentPage ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: index == _currentPage
                          ? AppColors.primaryDarkGreen
                          : AppColors.primaryDarkGreen.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
