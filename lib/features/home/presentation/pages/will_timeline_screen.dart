import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../../core/network/api_exceptions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/video_meeting_util.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/utils/status_utils.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../core/services/pdf_download_service.dart';
import '../../../../core/widgets/pdf_save_bottom_sheet.dart';
import '../../../will_creation/presentation/bloc/will_bloc.dart';
import '../../../will_creation/presentation/bloc/will_event.dart';
import '../../../will_creation/presentation/bloc/will_state.dart';
import '../../../will_creation/data/models/will_detail_models.dart';
import '../../../will_creation/data/services/will_document_service.dart';
import '../../../will_creation/presentation/widgets/pdf_preview_widget.dart';

class WillTimelineScreen extends StatefulWidget {
  final String willId;
  final String fullName;
  final String status;
  final String? invitedRole;

  const WillTimelineScreen({
    super.key,
    required this.willId,
    required this.fullName,
    required this.status,
    this.invitedRole,
  });

  bool get isExecutor => invitedRole?.toLowerCase() == 'executor';
  bool get isWitness => invitedRole?.toLowerCase() == 'witness';
  bool get isLawyer => invitedRole?.toLowerCase() == 'lawyer';
  bool get isInvited => invitedRole != null && invitedRole!.isNotEmpty;

  @override
  State<WillTimelineScreen> createState() => _WillTimelineScreenState();
}

class _WillTimelineScreenState extends State<WillTimelineScreen> {
  final _willDocumentService = WillDocumentService();
  final _secureStorage = SecureStorageService();
  final _pdfDownloadService = PdfDownloadService();
  bool _isExpanded = false;
  String? _currentUserId;
  WillCompleteDetail? _loadedDetail; // Cache the loaded detail
  int _pdfRefreshKey = 0; // Incremented after each upload to force SfPdfViewer re-render
  Uint8List? _pdfBytes; // PDF fetched manually to bypass SfPdfViewer's disk cache

  // ── Inline meeting panel ──────────────────────────────────────────────────
  bool _isMeetingActive = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
    _loadWillDetails();
  }

  @override
  void dispose() {
    // Ensure the root overlay panel is removed if the screen is disposed
    // while a meeting is still active (e.g. back button pressed).
    if (_isMeetingActive) {
      MeetingOverlay.hide();
    }
    super.dispose();
  }

  void _loadWillDetails() {
    // Clear PDF bytes so preview shows loading spinner while re-fetching
    if (mounted) setState(() => _pdfBytes = null);
    // Load complete will details
    context.read<WillBloc>().add(
      GetWillCompleteDetailEvent(willId: widget.willId),
    );
    // Load comments separately after a longer delay to avoid state conflicts
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        context.read<WillBloc>().add(
          GetWillCommentsEvent(willId: widget.willId),
        );
      }
    });
  }

  /// Downloads PDF bytes via Dio with cache-busting headers, completely
  /// bypassing SfPdfViewer's internal disk cache.
  Future<void> _fetchPdfBytes(String url) async {
    try {
      final dio = Dio();
      final response = await dio.get<List<int>>(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {
            'Cache-Control': 'no-cache, no-store, must-revalidate',
            'Pragma': 'no-cache',
          },
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (response.statusCode == 200 && response.data != null && mounted) {
        setState(() {
          _pdfBytes = Uint8List.fromList(response.data!);
        });
      }
    } catch (e) {
      debugPrint('⚠️ Failed to fetch PDF bytes: $e');
    }
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await _secureStorage.getUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  /// Fetches executors from the separate /will/executor API when the
  /// complete-detail response did not include them.
  Future<void> _fetchExecutorsSeparately() async {
    try {
      final bloc = context.read<WillBloc>();
      final response = await bloc.repository.getExecutors(widget.willId);
      if (response.isSuccess && response.data != null && response.data!.isNotEmpty && mounted) {
        final executorNames = response.data!.map((e) => PersonName(
          firstName: e.executor.firstName,
          middleName: e.executor.middleName,
          lastName: e.executor.lastName,
        )).toList();
        setState(() {
          _loadedDetail = WillCompleteDetail(
            willInfo: _loadedDetail!.willInfo,
            createdBy: _loadedDetail!.createdBy,
            witness: _loadedDetail!.witness,
            executors: executorNames,
            lawyer: _loadedDetail!.lawyer,
            willOriginal: _loadedDetail!.willOriginal,
            willWatermarked: _loadedDetail!.willWatermarked,
            willCoverImage: _loadedDetail!.willCoverImage,
          );
        });
      }
    } catch (e) {
      print('⚠️ Failed to fetch executors separately: $e');
    }
  }

  Future<void> _signWill() async {
    try {
      // Show loading using an overlay-style dialog and capture its navigator
      final dialogNavigator = Navigator.of(context, rootNavigator: true);
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          useRootNavigator: true,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Call GET /will/sign to get the signing URL
      final signUrl = await _willDocumentService.getWillSignUrl(widget.willId);

      // Hide loading dialog via root navigator
      if (!mounted) return;

      if (signUrl == null || signUrl.isEmpty) {
        dialogNavigator.pop();
        SnackBarUtils.showError(context, 'Failed to get signing URL. Please try again.');
        return;
      }


      final meetingRes = await _willDocumentService.createMeeting(widget.willId);
      print(" GOT MEETING RES: $meetingRes");
      if (!mounted) return;
      if (meetingRes == null) {
        dialogNavigator.pop();
        SnackBarUtils.showError(context, 'Failed to start meeting');
        return;

      }
      print("🔥 APP ID BEFORE PASS: ${meetingRes.appId}");
      // 🔥 Show meeting panel immediately via root overlay so it appears above
      // ALL routes including the DocuSign webview pushed next.
      if (mounted) {
        setState(() => _isMeetingActive = true);
        MeetingOverlay.show(
          context,
          VideoMeetingScreen(
            appId: meetingRes.appId,
            token: meetingRes.token,
            channel: meetingRes.channelName,
            uid: meetingRes.uid,
            onStartRecording: () async {
              await _willDocumentService.startMeetingRecording(meetingRes.meetingId);
            },
            onStopRecording: () async {
              await _willDocumentService.stopMeetingRecording(meetingRes.meetingId);
            },
            onLeaveMeeting: () async {
              MeetingOverlay.hide();
              if (mounted) {
                setState(() {
                  _isMeetingActive = false;
                });
              }
              try {
                await _willDocumentService.stopMeeting(meetingRes.meetingId);
              } catch (e) {
                print('⚠️ Failed to stop meeting on server: $e');
              }
            },
          ),
        );
      }
      dialogNavigator.pop();

      // Small delay so the meeting video widget renders before the webview
      // is pushed on top of the navigation stack.
      await Future.delayed(const Duration(milliseconds: 400));

      // Open the signing URL in webview
      if (mounted) {
        context.push(AppRouter.willSign, extra: {
          'signUrl': signUrl,
          'onSigningComplete': () {
            // Close the webview
            if (context.canPop()) {
              context.pop();
            }
            // Reload will details to reflect status change
            _loadWillDetails();
            SnackBarUtils.showSuccess(context, 'Will signed successfully');
          },
          // Stop recording 5 seconds after the webview is closed (any reason).
          'onClosed': () {
            if (!MeetingOverlay.recordingActive) return; // nothing to stop
            Future.delayed(const Duration(seconds: 5), () async {
              // Double-check in case recording was already stopped manually.
              if (!MeetingOverlay.recordingActive) return;
              try {
                await _willDocumentService.stopMeetingRecording(meetingRes.meetingId);
                MeetingOverlay.recordingActive = false;
                debugPrint('✅ Recording stopped 5 s after webview closed');
              } catch (e) {
                debugPrint('⚠️ Failed to stop recording after webview closed: $e');
              }
            });
          },
        });
      }
    } catch (e) {
      print('❌ Error initiating will signing: $e');
      // Hide loading if visible
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      if (mounted) {
        final message = e is ApiException
            ? e.message
            : 'An error occurred. Please try again.';
        SnackBarUtils.showError(context, message);
      }
    }
  }

  Future<void> _uploadSignedDocument() async {
    try {
      // Pick a file (PDF or image)
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        print('📁 No file selected');
        return;
      }

      final file = result.files.first;
      if (file.path == null) {
        if (mounted) {
          SnackBarUtils.showError(context, 'Unable to access selected file');
        }
        return;
      }

      print('📁 Selected file: ${file.name}');
      print('📁 File path: ${file.path}');
      print('📁 File size: ${file.size} bytes');

      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );
      }

      // Upload the file
      final response = await _willDocumentService.uploadSignedDocument(
        widget.willId,
        file.path!,
      );

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (response != null) {
        if (mounted) {
          SnackBarUtils.showSuccess(
            context,
            'Signed document uploaded successfully',
          );
          // Reset cached detail and bump refresh key so SfPdfViewer
          // is fully recreated and re-fetches the new S3 object.
          setState(() {
            _loadedDetail = null;
            _pdfRefreshKey++;
          });
          // Reload will details to reflect any status changes
          _loadWillDetails();
        }
      } else {
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Failed to upload signed document. Please try again.',
          );
        }
      }
    } catch (e) {
      print('❌ Error picking/uploading file: $e');
      // Hide loading indicator if visible
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'An error occurred. Please try again.',
        );
      }
    }
  }

  void _showUploadSignedDocumentBottomSheet(BuildContext parentContext) {
    String? selectedFilePath;
    String? selectedFileName;
    String addressText = '';
    final addressController = TextEditingController();
    
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 12, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Upload Signed Document',
                            style: AppTextStyles.sectionTitle.copyWith(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 24),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Description
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Add the address where the physical will is stored',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // File Picker
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
                            allowMultiple: false,
                          );
                          
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            setModalState(() {
                              selectedFilePath = file.path;
                              selectedFileName = file.name;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundMintLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.description_outlined,
                                color: AppColors.textSecondary,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedFileName ?? 'Tap to select file',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontSize: 14,
                                    color: selectedFileName != null 
                                        ? AppColors.textPrimary 
                                        : AppColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (selectedFileName == null)
                                Icon(
                                  Icons.add,
                                  color: AppColors.textSecondary,
                                  size: 20,
                                ),
                              if (selectedFileName != null)
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.success,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Address Field (Required)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: addressController,
                        onChanged: (value) {
                          setModalState(() {
                            addressText = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Address *',
                          hintStyle: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderGray),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.borderGray),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.primaryGreen),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppPrimaryButton(
                              text: 'Confirm & upload',
                              isDisabled: !(selectedFilePath != null && addressText.trim().isNotEmpty),
                              onPressed: () async {
                                final filePath = selectedFilePath!;
                                final address = addressController.text.trim();
                                Navigator.pop(context);
                                await _performUploadWill(filePath, address);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppSecondaryButton(
                              text: 'Cancel',
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        );
      },
    );
  }

  Future<void> _performUploadWill(String filePath, String address) async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Upload the file
      final uploadResponse = await _willDocumentService.uploadSignedDocument(
        widget.willId,
        filePath,
      );

      if (uploadResponse == null) {
        // Hide loading indicator
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        if (mounted) {
          SnackBarUtils.showError(
            context,
            'Failed to upload signed document. Please try again.',
          );
        }
        return;
      }

      // If address is provided, update the will location
      if (address.isNotEmpty) {
        final locationUpdated = await _willDocumentService.updateWillLocation(
          widget.willId,
          address,
        );
        if (!locationUpdated) {
          print('⚠️ Location update failed, but file was uploaded successfully');
        }
      }

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Signed document uploaded successfully',
        );
        // Reset cached detail and bump refresh key so SfPdfViewer
        // is fully recreated and re-fetches the new S3 object.
        setState(() {
          _loadedDetail = null;
          _pdfRefreshKey++;
        });
        // Reload will details to reflect any status changes
        _loadWillDetails();
      }
    } catch (e) {
      print('❌ Error uploading will: $e');
      // Hide loading indicator if visible
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'An error occurred. Please try again.',
        );
      }
    }
  }

  Future<void> _downloadPDF() async {
    if (_loadedDetail?.willWatermarked == null) {
      if (mounted) {
        SnackBarUtils.showError(context, 'No PDF available to download');
      }
      return;
    }

    // Show bottom sheet to get filename
    final defaultFileName = 'Will_${widget.willId.substring(0, 6).toUpperCase()}';
    final fileName = await PdfSaveBottomSheet.showSaveDialog(
      context: context,
      defaultName: defaultFileName,
    );
    
    if (fileName == null) return; // User cancelled

    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Download the file
      final filePath = await _pdfDownloadService.downloadPdf(
        url: _loadedDetail!.willWatermarked!,
        fileName: fileName,
      );

      // Hide loading indicator
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (filePath != null && mounted) {
        // Show success with options
        PdfSaveBottomSheet.showSuccessDialog(
          context: context,
          filePath: filePath,
        );
      }
    } catch (e) {
      // Hide loading indicator if visible
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      if (mounted) {
        SnackBarUtils.showError(
          context,
          e.toString().contains('permission')
              ? 'Storage permission is required to download PDF'
              : 'Failed to download PDF. Please try again.',
        );
      }
    }
  }

  void _showOptionsMenu(BuildContext context) {
    final parentContext = context; // Capture parent context

    // Shrink the meeting panel so it doesn't obscure the bottom sheet.
    if (_isMeetingActive) MeetingOverlay.collapse();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              _buildOption(
                bottomSheetContext,
                icon: Icons.chat_bubble_outline,
                title: 'Comments',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  parentContext.push(AppRouter.willComments, extra: widget.willId);
                },
              ),
              _buildDividerOption(),
              _buildOption(
                bottomSheetContext,
                icon: Icons.share_outlined,
                title: 'Share will',
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  // TODO: Implement share
                },
              ),
              _buildDividerOption(),
              _buildOption(
                bottomSheetContext,
                icon: Icons.download_outlined,
                title: 'Download PDF',
                onTap: () async {
                  Navigator.pop(bottomSheetContext);
                  await _downloadPDF();
                },
              ),
              // Sign will & upload signed document - available after lawyer review is completed
              if (widget.status == 'REVIEW_COMPLETED') ...[
                _buildDividerOption(),
                _buildOption(
                  bottomSheetContext,
                  icon: Icons.draw_outlined,
                  title: 'Sign Will',
                  onTap: () async {
                    Navigator.of(bottomSheetContext).pop();
                    await Future.delayed(const Duration(milliseconds: 350));
                    if (mounted) {
                      _signWill();
                    }
                  },
                ),
                _buildDividerOption(),
                _buildOption(
                  bottomSheetContext,
                  icon: Icons.upload_file_outlined,
                  title: 'Upload Signed Document',
                  onTap: () async {
                    // Close the options menu first
                    Navigator.of(bottomSheetContext).pop();
                    // Wait for the bottom sheet to close
                    await Future.delayed(const Duration(milliseconds: 350));
                    // Show upload signed document bottom sheet using the parent context
                    if (mounted) {
                      _showUploadSignedDocumentBottomSheet(parentContext);
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ).then((_) {
      // Restore the meeting panel once the bottom sheet is gone.
      if (_isMeetingActive) MeetingOverlay.expand();
    });
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final optionColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: optionColor),
            const SizedBox(width: 16),
            Text(
              title,
              style: AppTextStyles.itemLabel.copyWith(
                color: optionColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExecutorBottomBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                'You can start will execution',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppPrimaryButton(
              text: 'Execute will',
              fullWidth: false,
              onPressed: _showExecutorChecklistBottomSheet,
            ),
          ],
        ),
      ),
    );
  }

  void _showExecutorChecklistBottomSheet() {
    final testatorName =
        _loadedDetail?.createdBy.fullName ?? widget.fullName;
    final executorName =
        (_loadedDetail?.executors.isNotEmpty ?? false)
            ? _loadedDetail!.executors.first.fullName
            : 'Executor';

    context.push(AppRouter.executorChecklist, extra: {
      'willId': widget.willId,
      'executorName': executorName,
      'testatorName': testatorName,
    });
  }

  Widget _buildDividerOption() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Divider(height: 1, thickness: 1, color: AppColors.borderGray),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final meetingPanelHeight = _isMeetingActive
        ? screenHeight * 0.25
        : 0.0;

    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
            backgroundColor: AppColors.backgroundWhite,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRouter.home);
                }
              },
            ),
            title: Text(
              widget.willId,
              style: AppTextStyles.questionTitle,
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: false,
          ),
          // Add bottom padding equal to the meeting panel so content isn't hidden
          body: Padding(
            padding: EdgeInsets.only(bottom: meetingPanelHeight + safeBottom),
            child: BlocConsumer<WillBloc, WillState>(
              listener: (context, state) {
                if (state is WillCompleteDetailLoaded) {
                  setState(() {
                    _loadedDetail = state.detail;
                    _pdfBytes = null;
                  });
                  if (state.detail.willWatermarked != null) {
                    _fetchPdfBytes(state.detail.willWatermarked!);
                  }
                  if (state.detail.executors.isEmpty) {
                    _fetchExecutorsSeparately();
                  }
                }
              },
              buildWhen: (previous, current) {
                if (_loadedDetail != null) {
                  return current is WillError;
                }
                return current is WillLoading ||
                    current is WillCompleteDetailLoaded ||
                    current is WillError;
              },
              builder: (context, state) {
                if (_loadedDetail != null) {
                  return _buildContent(_loadedDetail!);
                }
                if (state is WillLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading will details...',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textGray,
                          ),
                        ),
                        const SizedBox(height: 24),
                        AppTextButton(
                          text: 'Cancel',
                          onPressed: () => context.pop(),
                        ),
                      ],
                    ),
                  );
                }
                if (state is WillError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: AppColors.errorRed2),
                          const SizedBox(height: 16),
                          Text('Error loading will details',
                              style: AppTextStyles.questionTitle, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          Text(state.message,
                              style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppSecondaryButton(
                                  text: 'Go Back',
                                  onPressed: () => context.pop(),
                                  fullWidth: false),
                              const SizedBox(width: 12),
                              AppPrimaryButton(
                                  text: 'Retry',
                                  onPressed: _loadWillDetails,
                                  fullWidth: false),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state is WillCompleteDetailLoaded) {
                  return _buildContent(state.detail);
                }
                return const Center(child: CircularProgressIndicator());
              },
            ),
          ),
          // Bottom bar — executor checklist or comments button
          bottomNavigationBar: widget.isExecutor
              ? _buildExecutorBottomBar()
              : BlocBuilder<WillBloc, WillState>(
                  buildWhen: (previous, current) => current is CommentsLoaded,
                  builder: (context, state) {
                    int commentCount = 0;
                    if (state is CommentsLoaded && _currentUserId != null) {
                      commentCount = state.comments
                          .where((c) => c.userId != _currentUserId)
                          .length;
                    }
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (commentCount > 0) ...[
                              Flexible(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.errorRed2,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '$commentCount',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    SizedBox(
                                      width: 120,
                                      child: Text(
                                        'New comments \nfrom lawyer',
                                        style: AppTextStyles.bodyMedium.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const Spacer(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            AppPrimaryButton(
                              text: 'View comments',
                              icon: Icons.chat_bubble_outline,
                              fullWidth: false,
                              onPressed: () {
                                context.push(
                                  AppRouter.willComments,
                                  extra: widget.willId,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildContent(WillCompleteDetail detail) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title with more icon
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Will of ${detail.createdBy.fullName.isNotEmpty ? detail.createdBy.fullName : widget.fullName}',
                    style: AppTextStyles.pageTitle.copyWith(fontSize: 28),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 24),
                  color: AppColors.textPrimary,
                  onPressed: () {
                    _showOptionsMenu(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status section (always visible)
            _buildInfoRow(
              'Status',
              StatusUtils.formatStatus(detail.willInfo.status),
              hasIndicator: true,
              rawStatus: detail.willInfo.status,
            ),
            _buildDivider(),

            // Testator section (always visible)
            _buildInfoRow(
              widget.isInvited ? 'Testator' : 'Testator (you)',
              detail.createdBy.fullName.isNotEmpty ? detail.createdBy.fullName : widget.fullName,
            ),
            _buildDivider(),

            // Lawyer section (always visible)
            if (detail.lawyer != null) ...[
              _buildInfoRow(widget.isLawyer ? 'Lawyer (you)' : 'Lawyer', detail.lawyer!.fullName),
              _buildDivider(),
            ],

            // Executors section - show only first when collapsed
            if (detail.executors.isNotEmpty) ...[
              if (!_isExpanded) ...[
                // Show only first executor when collapsed
                _buildInfoRow(
                  widget.isExecutor && detail.executors.length == 1
                      ? 'Executor (you)'
                      : detail.executors.length == 1
                          ? 'Executor'
                          : 'Executor 1',
                  detail.executors[0].fullName,
                ),
                _buildDivider(),
              ] else ...[
                // Show all executors when expanded
                ...detail.executors.asMap().entries.map((entry) {
                  final executorNumber = entry.key + 1;
                  final executor = entry.value;
                  final baseLabel = detail.executors.length == 1
                      ? 'Executor'
                      : 'Executor $executorNumber';
                  final label = widget.isExecutor && detail.executors.length == 1
                      ? 'Executor (you)'
                      : baseLabel;
                  return Column(
                    children: [
                      _buildInfoRow(label, executor.fullName),
                      _buildDivider(),
                    ],
                  );
                }),
              ],
            ],

            // Legacy single executor support (for backward compatibility)
            if (detail.executors.isEmpty && detail.executor != null) ...[
              _buildInfoRow('Executor', detail.executor!.fullName),
              _buildDivider(),
            ],

            // Expanded content - additional details
            if (_isExpanded) ...[
              const SizedBox(height: 8),

              // Witnesses (shown when expanded with sequential numbering)
              if (detail.witness.isNotEmpty)
                ...detail.witness.asMap().entries.map((entry) {
                  final witnessNumber = entry.key + 1;
                  final witness = entry.value;
                  final witnessLabel = widget.isWitness && detail.witness.length == 1
                      ? 'Witness (you)'
                      : 'Witness $witnessNumber';
                  return Column(
                    children: [
                      _buildInfoRow(witnessLabel, witness.fullName),
                      _buildDivider(),
                    ],
                  );
                }),

              const SizedBox(height: 8),

              // Collapse button (at the bottom of expanded content)
              Center(
                child: AppTextButton(
                  text: 'Collapse',
                  onPressed: _toggleExpand,
                  icon: Icons.keyboard_arrow_up,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            // Expand button (shown when collapsed)
            if (!_isExpanded) ...[
              const SizedBox(height: 8),
              Center(
                child: AppTextButton(
                  text: 'Expand',
                  onPressed: _toggleExpand,
                  icon: Icons.keyboard_arrow_down,
                  color: AppColors.textPrimary,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // PDF Preview (always visible, separate from expand)
            _buildDocumentPreview(),
            const SizedBox(height: 80), // Space for button
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool hasIndicator = false,
    String? rawStatus,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textGray),
          ),
          Row(
            children: [
              if (hasIndicator) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rawStatus != null
                        ? StatusUtils.getStatusColor(rawStatus)
                        : AppColors.infoBlue,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Row(
                children: [
                  if (label.contains('Testator') ||
                      label.contains('Witness') ||
                      label.contains('Lawyer') ||
                      label.contains('Executor'))
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        color: AppColors.borderGray,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          value.isNotEmpty ? value[0].toUpperCase() : '',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  Text(value, style: AppTextStyles.itemLabel),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 1, color: AppColors.borderGray);
  }

  Widget _buildDocumentPreview() {
    // Show loading until we have both the detail URL and the downloaded bytes.
    // Bytes are fetched via Dio with no-cache headers to bypass SfPdfViewer's
    // internal disk cache — the only reliable way to show the latest S3 file.
    if (_loadedDetail?.willWatermarked == null || _pdfBytes == null) {
      return PdfPreviewWidget(isLoading: true, height: 500);
    }

    // Pass raw bytes to SfPdfViewer.memory — completely bypasses network cache.
    return PdfPreviewWidget(
      key: ValueKey('pdf_$_pdfRefreshKey'),
      isLoading: false,
      pdfData: _pdfBytes,
      height: 500,
    );
  }

  Widget _buildDocumentDetail(String text) {
    return Text(
      text,
      style: AppTextStyles.inputLabelFloating.copyWith(
        fontSize: 12,
        color: AppColors.textGray4,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    return '${localDate.day} ${_getMonthName(localDate.month)} ${localDate.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }
}
