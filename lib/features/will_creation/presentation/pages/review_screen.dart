import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/constants/debug_config.dart';
import '../../data/services/will_document_service.dart';
import '../bloc/will_bloc.dart';
import '../bloc/will_state.dart';
import '../widgets/will_creation_app_bar.dart';
import '../widgets/will_steps_sidebar.dart';
import '../widgets/pdf_preview_widget.dart';

class ReviewScreen extends StatefulWidget {
  const ReviewScreen({super.key});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  String? _willId;
  final _secureStorage = SecureStorageService();
  final _willDocumentService = WillDocumentService();
  
  Uint8List? _pdfData;
  bool _isLoadingDocument = true;
  String? _documentError;

  @override
  void initState() {
    super.initState();
    _loadWillData();
  }

  Future<void> _loadWillData() async {
    _willId = await _secureStorage.getWillId();
    if (_willId != null && mounted) {
      // Fetch document preview
      await _fetchDocumentPreview();
    }
  }

  Future<void> _fetchDocumentPreview() async {
    if (_willId == null) return;
    
    try {
      // Always generate/regenerate the document to reflect the latest will data
      print('📄 Generating/regenerating document for will_id: $_willId');
      final generateResponse = await _willDocumentService.generateWillDocument(_willId!);
      
      if (generateResponse != null && generateResponse.isSuccess && generateResponse.data != null) {
        print('✅ Document generated successfully, fetching preview...');
        // Wait a moment for the server to process
        await Future.delayed(const Duration(seconds: 2));
      } else {
        print('⚠️ Document generation returned no data, will try fetching existing preview...');
      }
      
      if (!mounted) return;
      
      print('🔄 Fetching document preview for will_id: $_willId');
      final data = await _willDocumentService.fetchWillDocumentPreview(_willId!);
      if (mounted) {
        setState(() {
          _pdfData = data;
          _isLoadingDocument = false;
          if (data == null) {
            _documentError = 'Failed to load document preview. Please check your authentication.';
            print('❌ PDF data is null');
          } else {
            print('✅ PDF data loaded successfully');
            // Validate PDF header
            if (data.length > 4) {
              final header = String.fromCharCodes(data.sublist(0, 4));
              print('📄 PDF Header: $header (should be %PDF)');
              if (!header.startsWith('%PDF')) {
                print('⚠️ WARNING: Data does not appear to be a valid PDF!');
                print('📊 First 100 bytes: ${String.fromCharCodes(data.sublist(0, data.length > 100 ? 100 : data.length))}');
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDocument = false;
          _documentError = 'Error loading document: $e';
          print('❌ Exception in _fetchDocumentPreview: $e');
        });
      }
    }
  }

  void _finalizeWill() {
    if (_willId != null) {
      // TODO: Implement API call to finalize will
      // context.read<WillBloc>().add(FinalizeWillEvent(_willId!));
      
      if (DebugConfig.skipPayment) {
        // Skip payment and go directly to legal review
        print('🔧 DEBUG: Skipping payment flow, going to legal review');
        context.push(
          AppRouter.legalReview,
          extra: {
            'userName': 'James',
            'willId': _willId,
            'regenerate': true,
          },
        );
      } else {
        // Navigate to subscription selection screen
        context.push(
          AppRouter.subscriptionSelection,
          extra: {
            'userName': 'James', // You can replace this with actual user name from state
            'willId': _willId,
            'regenerate': true,
          },
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      drawer: WillStepsSidebar(currentStep: 11),
      appBar: WillCreationAppBar(
        title: 'Review',
        currentStep: 11,
        totalSteps: 11,
        showBackButton: true,
        showStepNumber: true,
        onBack: () {
          context.go(AppRouter.witness);
        },
      ),
      body: BlocBuilder<WillBloc, WillState>(
        builder: (context, state) {
          if (state is WillLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Review',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      
                      // Subtitle
                      Text(
                        'You\'re almost done. This is your chance to double-check everything – your executor, beneficiaries, assets, and wishes – before we generate your final will.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 24),

                      // Edit info box
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundYellow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'You can still make edits now. Once finalised, changes will require a formal revision.',
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Will document preview
                      _buildDocumentPreview(),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom buttons
              AppBottomActionBar(
                padding: const EdgeInsets.all(16),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppSecondaryButton(
                          text: 'Previous',
                          onPressed: () => context.go(AppRouter.witness),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: 'Next step',
                          onPressed: _finalizeWill,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentPreview() {
    return PdfPreviewWidget(
      isLoading: _isLoadingDocument,
      errorMessage: _documentError,
      pdfData: _pdfData,
      onRetry: () {
        setState(() {
          _isLoadingDocument = true;
          _documentError = null;
        });
        _fetchDocumentPreview();
      },
      height: 500,
    );
  }
}
