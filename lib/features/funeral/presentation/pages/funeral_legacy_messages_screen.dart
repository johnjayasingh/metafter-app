import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/funeral_flow_data.dart';
import '../../data/services/funeral_service.dart';

class FuneralLegacyMessagesScreen extends StatefulWidget {
  final FuneralFlowData flowData;
  
  const FuneralLegacyMessagesScreen({super.key, required this.flowData});

  @override
  State<FuneralLegacyMessagesScreen> createState() => _FuneralLegacyMessagesScreenState();
}

class _FuneralLegacyMessagesScreenState extends State<FuneralLegacyMessagesScreen> {
  final FuneralService _funeralService = FuneralService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  late FuneralFlowData _flowData;
  bool _isSaving = false;
  bool _isUploading = false;
  
  // Video file state
  PlatformFile? _selectedVideoFile;
  String? _existingVideoUrl; // URL from previously saved data

  static const int _maxVideoSizeBytes = 200 * 1024 * 1024; // 200MB
  static const List<String> _allowedVideoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv'];

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;
    _messageController.text = _flowData.legacyMessage ?? '';
    _existingVideoUrl = _flowData.legacyMessageVideoUrl;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleUploadMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _allowedVideoExtensions,
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;

    if (file.size > _maxVideoSizeBytes) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} exceeds 200MB limit'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    if (file.path == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not access the selected file'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
      return;
    }

    setState(() {
      _selectedVideoFile = file;
    });

    await _uploadVideo(file);
  }

  Future<void> _uploadVideo(PlatformFile file) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final videoFile = File(file.path!);
      final response = await _funeralService.uploadLegacyVideo(videoFile);

      if (mounted) {
        if (response.isSuccess) {
          setState(() {
            _existingVideoUrl = null; // New upload replaces existing
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video uploaded successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          setState(() {
            _selectedVideoFile = null;
            _isUploading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: AppColors.errorRed,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedVideoFile = null;
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _removeVideo() {
    setState(() {
      _selectedVideoFile = null;
      _existingVideoUrl = null;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get _hasVideo => _selectedVideoFile != null || _existingVideoUrl != null;

  void _exitAndRefresh() {
    // Pop all funeral flow screens to trigger refresh
    int popCount = 3; // preferences + service details + legacy messages
    for (int i = 0; i < popCount && context.canPop(); i++) {
      context.pop();
    }
  }

  Future<void> _saveFuneralDetailsAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update flow data with legacy message
      _flowData = _flowData.copyWith(
        legacyMessage: _messageController.text.isNotEmpty 
            ? _messageController.text 
            : null,
      );

      // Save funeral details to API
      final response = await _funeralService.createOrUpdateFuneral(
        _flowData.toFuneralModel(),
      );

      setState(() {
        _isSaving = false;
      });

      if (response.isSuccess && mounted) {
        // Navigate to recipients screen
        context.push(
          AppRouter.funeralRecipients,
          extra: _flowData,
        );
      } else if (mounted) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save funeral details: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: 4,
        title: 'Legacy messages',
        showBackButton: true,
        showStepNumber: true,
        exitTitle: 'Exit funeral preferences?',
        exitDescription: 'You can save your progress as a draft and continue later, or discard these preferences.',
        exitDiscardButtonText: 'Discard Preferences',
        onExitNavigate: _exitAndRefresh,
        onBack: () {
          context.pop();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Create personal legacy messages',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Leave a message that will be shared with your loved ones after death — personal goodbyes, memories, or special instructions',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 32),

                      // Upload media button
                      GestureDetector(
                        onTap: (_isUploading || _hasVideo) ? null : _handleUploadMedia,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isUploading) ...[
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Uploading media...',
                                  style: AppTextStyles.buttonSmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ] else ...[
                                Icon(
                                  Icons.upload_outlined,
                                  color: _hasVideo 
                                      ? AppColors.borderGray 
                                      : AppColors.textSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Upload media',
                                  style: AppTextStyles.buttonSmall.copyWith(
                                    color: _hasVideo 
                                        ? AppColors.borderGray 
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Accepted formats: MP4, MOV, AVI, MKV, WMV. Max size: 200MB.',
                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                      ),
                      const SizedBox(height: 16),

                      // Uploaded video display
                      if (_hasVideo) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.borderGray),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.videocam_outlined,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVideoFile?.name ?? 'Legacy video attached',
                                      style: AppTextStyles.itemLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (_selectedVideoFile != null) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        _formatFileSize(_selectedVideoFile!.size),
                                        style: AppTextStyles.subtitle.copyWith(fontSize: 12),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                                onPressed: _removeVideo,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Message textarea
                      AppTextArea(
                        controller: _messageController,
                        label: 'Message',
                        isRequired: true,
                        maxLines: 8,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.backgroundWhite,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: AppSecondaryButton(
                        text: 'Previous',
                        onPressed: () {
                          context.pop();
                        },
                        fullWidth: false,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AppPrimaryButton(
                        text: _isSaving ? 'Saving...' : 'Next step',
                        onPressed: (_isSaving || _isUploading) ? null : _saveFuneralDetailsAndContinue,
                        fullWidth: false,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
