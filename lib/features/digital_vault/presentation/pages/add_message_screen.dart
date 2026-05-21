import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/mock_data_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/select_recipient_bottom_sheet.dart';
import '../../data/models/vault_models.dart';
import '../cubit/vault_cubit.dart';
import '../cubit/vault_state.dart';
import '../widgets/vault_warning_banner.dart';

class AddMessageScreen extends StatefulWidget {
  final VaultItem? existingItem;

  const AddMessageScreen({super.key, this.existingItem});

  @override
  State<AddMessageScreen> createState() => _AddMessageScreenState();
}

class _AddMessageScreenState extends State<AddMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final List<WillPerson> _selectedRecipients = [];
  final List<PlatformFile> _pendingFiles = [];
  final List<VaultFile> _existingFiles = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingItem != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final data = widget.existingItem!.messageData;
      _titleController.text = data.title;
      _bodyController.text = data.message;

      // Restore existing files
      _existingFiles.addAll(widget.existingItem!.files);

      // Restore recipients from existing message data
      for (final r in data.recipients) {
        final parts = r.fullName.split(' ');
        _selectedRecipients.add(WillPerson(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          firstName: parts.first,
          lastName: parts.length > 1 ? parts.sublist(1).join(' ') : '',
          email: r.email,
          mobile: r.phone,
        ));
      }
    } else if (DebugDataService.isEnabled) {
      final mock = DebugDataService.debugVaultMessageData;
      _titleController.text = mock['title'] ?? '';
      _bodyController.text = mock['message'] ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  void _handleUploadMedia() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx',
        'mp4', 'mov', 'avi', 'mkv', 'wmv',
      ],
      allowMultiple: true,
    );
    if (result != null) {
      setState(() {
        for (final file in result.files) {
          if (file.size > 200 * 1024 * 1024) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${file.name} exceeds 200MB limit'),
                backgroundColor: AppColors.errorRed,
              ),
            );
            continue;
          }
          if (!_pendingFiles.any((f) => f.name == file.name)) {
            _pendingFiles.add(file);
          }
        }
      });
    }
  }

  List<RecipientInfo> _getWillPeopleAsRecipients() {
    final cubitState = context.read<VaultCubit>().state;
    List<WillPerson> willPeople = [];
    if (cubitState is VaultLoaded) willPeople = cubitState.willPeople;
    if (cubitState is VaultOperationSuccess) {
      willPeople = cubitState.willPeople;
    }

    return willPeople
        .where((p) =>
            !_selectedRecipients.any((r) => r.id == p.id))
        .map((p) => RecipientInfo(
              id: p.id,
              firstName: p.firstName,
              middleName: p.middleName,
              lastName: p.lastName,
              email: p.email,
              mobile: p.mobile,
              displayType: p.role,
            ))
        .toList();
  }

  Future<void> _showSelectFromWillPeople() async {
    final recipients = _getWillPeopleAsRecipients();

    if (recipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No people found from your will')),
      );
      return;
    }

    final selected = await showModalBottomSheet<RecipientInfo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectRecipientBottomSheet(
        recipients: recipients,
        title: 'Select previously added',
        subtitle: 'Select from people added to your will',
        emptyMessage:
            'No previously added persons found.\nTap "+ Add recipients" to add one.',
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedRecipients.add(WillPerson(
          id: selected.id,
          firstName: selected.firstName,
          middleName: selected.middleName,
          lastName: selected.lastName,
          email: selected.email,
          mobile: selected.mobile,
          role: selected.displayType,
        ));
      });
    }
  }

  Future<void> _addRecipientManually() async {
    final recipient = await context.push<WillPerson?>(
      AppRouter.vaultAddMessageRecipient,
    );
    if (recipient != null && mounted) {
      setState(() {
        _selectedRecipients.add(recipient);
      });
    }
  }

  void _removeRecipient(int index) {
    setState(() {
      _selectedRecipients.removeAt(index);
    });
  }

  void _removePendingFile(int index) {
    setState(() {
      _pendingFiles.removeAt(index);
    });
  }

  void _removeExistingFile(int index) async {
    final file = _existingFiles[index];
    final deleted = await context.read<VaultCubit>().deleteVaultFile(file.id);
    if (deleted && mounted) {
      setState(() {
        _existingFiles.removeAt(index);
      });
    }
  }

  void _onSave() {
    if (_isSaving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add at least one recipient'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    setState(() => _isSaving = true);

    final recipients = _selectedRecipients.map((r) => MessageRecipient(
      fullName: r.fullName,
      email: r.email,
      phone: r.mobile,
    )).toList();

    final messageData = MessageData(
      title: _titleController.text.trim(),
      message: _bodyController.text.trim(),
      recipients: recipients,
    );

    final payload = VaultItemCreate(
      assetId: widget.existingItem?.id,
      type: VaultAssetType.message,
      data: messageData.toMap(),
    );

    // Collect file paths from pending files
    final filePaths = _pendingFiles
        .where((f) => f.path != null)
        .map((f) => f.path!)
        .toList();
    final fileNames = _pendingFiles
        .where((f) => f.path != null)
        .map((f) => f.name)
        .toList();

    if (filePaths.isNotEmpty) {
      context.read<VaultCubit>().createMessageItem(
        payload,
        filePaths: filePaths,
        fileNames: fileNames,
      );
    } else {
      context.read<VaultCubit>().createItem(payload);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Message' : 'Add Message',
          style: AppTextStyles.sectionTitle,
        ),
        backgroundColor: AppColors.backgroundWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<VaultCubit, VaultState>(
        listener: (context, state) {
          if (state is VaultOperationSuccess) {
            context.read<VaultCubit>().acknowledgeSuccess();
            context.pop(true);
          } else if (state is VaultError) {
            setState(() => _isSaving = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.errorRed,
              ),
            );
          } else if (state is VaultOperationLoading) {
            setState(() => _isSaving = true);
          }
        },
        builder: (context, state) {
          return SafeArea(
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
                          const VaultWarningBanner(
                            message:
                                'Do not include testamentary instructions or sensitive information such as passwords in your personal messages. These messages are intended for personal sentiment only.',
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _titleController,
                            label: 'Title',
                            isRequired: true,
                          ),
                          const SizedBox(height: 16),
                          AppTextArea(
                            controller: _bodyController,
                            label: 'Message',
                            isRequired: true,
                            maxLines: 8,
                          ),
                          const SizedBox(height: 24),
                          Container(
                              height: 1, color: AppColors.borderGray),
                          const SizedBox(height: 24),

                          // Attachments section
                          Text('Additional documents',
                              style: AppTextStyles.questionTitle),
                          const SizedBox(height: 12),
                          AppSecondaryButton(
                            text: 'Upload media',
                            icon: Icons.upload_outlined,
                            onPressed: _handleUploadMedia,
                          ),
                          if (_existingFiles.isNotEmpty || _pendingFiles.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            // Existing uploaded files
                            ..._existingFiles.asMap().entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.borderGray),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.value.filename,
                                        style: AppTextStyles.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _removeExistingFile(entry.key),
                                      child: const Icon(Icons.close,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            // Newly picked files
                            ..._pendingFiles.asMap().entries.map((entry) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                margin: const EdgeInsets.only(bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.backgroundLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: AppColors.borderGray),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.insert_drive_file,
                                        size: 18,
                                        color: AppColors.textSecondary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.value.name,
                                        style: AppTextStyles.bodySmall,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () =>
                                          _removePendingFile(entry.key),
                                      child: const Icon(Icons.close,
                                          size: 18,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          const SizedBox(height: 24),

                          // Recipients section
                          _buildRecipientsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
                AppBottomActionBar(
                  child: Row(
                    children: [
                      Expanded(
                        child: AppCancelButton(
                          text: 'Cancel',
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppPrimaryButton(
                          text: _isSaving ? 'Saving...' : 'Save',
                          onPressed: _isSaving ? null : _onSave,
                          isLoading: _isSaving,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecipientsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundLightGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select recipients', style: AppTextStyles.questionTitle),
          const SizedBox(height: 12),

          // Select previously added button
          InkWell(
            onTap: _showSelectFromWillPeople,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderGray),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select previously added',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          // Recipient cards
          if (_selectedRecipients.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._selectedRecipients.asMap().entries.map((entry) {
              final r = entry.value;
              final initials =
                  '${r.firstName.isNotEmpty ? r.firstName[0] : ''}${r.lastName.isNotEmpty ? r.lastName[0] : ''}'
                      .toUpperCase();
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.backgroundLightGreen,
                        child: Text(
                          initials,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryGreen,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.fullName,
                                style: AppTextStyles.itemLabel),
                            if (r.role != null)
                              Text(r.role!,
                                  style: AppTextStyles.cardSecondary),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _removeRecipient(entry.key),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.delete_outline,
                              size: 20, color: AppColors.errorRed),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Add at least one recipient for this message.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ],

          const SizedBox(height: 12),
          AppPrimaryButton(
            text: '+ Add recipients',
            onPressed: _addRecipientManually,
          ),
        ],
      ),
    );
  }
}
