import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';

class CheckoutWebViewPage extends StatefulWidget {
  final String checkoutUrl;
  final VoidCallback onPaymentComplete;

  const CheckoutWebViewPage({
    super.key,
    required this.checkoutUrl,
    required this.onPaymentComplete,
  });

  @override
  State<CheckoutWebViewPage> createState() => _CheckoutWebViewPageState();
}

class _CheckoutWebViewPageState extends State<CheckoutWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _paymentCompleted = false; // Flag to prevent multiple callbacks

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            print('🌐 Page started loading: $url');
            setState(() {
              _isLoading = true;
            });
            
            // Check if URL has changed away from Stripe
            _checkUrlChange(url);
          },
          onPageFinished: (String url) {
            print('✅ Page finished loading: $url');
            setState(() {
              _isLoading = false;
            });
          },
          onNavigationRequest: (NavigationRequest request) {
            print('🔄 Navigation request: ${request.url}');
            
            // Check if URL has changed away from Stripe
            _checkUrlChange(request.url);
            
            return NavigationDecision.navigate;
          },
          onWebResourceError: (WebResourceError error) {
            print('❌ Web resource error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  void _checkUrlChange(String url) {
    // Prevent multiple callbacks
    if (_paymentCompleted) {
      print('⚠️ Payment already processed, ignoring URL change: $url');
      return;
    }
    
    // Check if URL is still part of the Stripe payment flow (case-insensitive)
    final lowerUrl = url.toLowerCase();
    final isStripeRelated = lowerUrl.contains('stripe') || 
                           lowerUrl.contains('hcaptcha') ||
                           lowerUrl.contains('stripecdn');
    
    if (!isStripeRelated) {
      print('✅ Payment completed - URL changed away from Stripe: $url');
      
      // Mark as completed to prevent duplicate calls
      _paymentCompleted = true;
      
      // Trigger callback (which will handle navigation)
      widget.onPaymentComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.textPrimary),
          onPressed: () {
            _showCancelDialog();
          },
        ),
        title: Text(
          'Complete Payment',
          style: AppTextStyles.stepTitle,
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Payment?', style: AppTextStyles.cardTitle),
        content: Text(
          'Are you sure you want to cancel the payment process?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          AppTextButton(
            text: 'Continue Payment',
            onPressed: () => Navigator.of(context).pop(),
          ),
          AppTextButton(
            text: 'Cancel',
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.pop(); // Close webview
            },
            color: AppColors.error,
          ),
        ],
      ),
    );
  }
}
