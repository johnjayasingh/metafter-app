import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../../core/routes/app_router.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/funeral_flow_data.dart';
import '../../data/models/funeral_models.dart';
import '../../data/services/funeral_service.dart';

class FuneralServiceDetailsScreen extends StatefulWidget {
  final FuneralFlowData flowData;
  
  const FuneralServiceDetailsScreen({super.key, required this.flowData});

  @override
  State<FuneralServiceDetailsScreen> createState() => _FuneralServiceDetailsScreenState();
}

class _FuneralServiceDetailsScreenState extends State<FuneralServiceDetailsScreen> {
  final FuneralService _funeralService = FuneralService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _serviceLocationController = TextEditingController();
  final TextEditingController _dateTimeController = TextEditingController();
  final TextEditingController _specialInstructionsController = TextEditingController();
  late FuneralFlowData _flowData;
  DateTime? _selectedDateTime;
  bool _isSaving = false;
  
  // Music dropdown state
  List<MusicOption> _musicOptions = [];
  int? _selectedMusicId;
  bool _isLoadingMusic = true;

  @override
  void initState() {
    super.initState();
    _flowData = widget.flowData;
    
    // Populate fields from flow data
    _serviceLocationController.text = _flowData.serviceLocation ?? '';
    _specialInstructionsController.text = _flowData.specialInstruction ?? '';
    _selectedDateTime = _flowData.dateTimePreference;
    _selectedMusicId = _flowData.musicId;
    if (_selectedDateTime != null) {
      _dateTimeController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!);
    }
    
    _loadMusicOptions();
  }

  Future<void> _loadMusicOptions() async {
    try {
      final response = await _funeralService.getMusicOptions();
      if (response.isSuccess && response.data != null) {
        setState(() {
          _musicOptions = response.data!;
          _isLoadingMusic = false;
        });
      } else {
        setState(() {
          _isLoadingMusic = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMusic = false;
      });
    }
  }

  @override
  void dispose() {
    _serviceLocationController.dispose();
    _dateTimeController.dispose();
    _specialInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDateTime ?? DateTime.now()),
      );
      
      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _dateTimeController.text = DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDateTime!);
        });
      }
    }
  }

  Future<void> _saveAndContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Update flow data
      _flowData = _flowData.copyWith(
        serviceLocation: _serviceLocationController.text.isNotEmpty 
            ? _serviceLocationController.text 
            : null,
        dateTimePreference: _selectedDateTime,
        musicId: _selectedMusicId,
        specialInstruction: _specialInstructionsController.text.isNotEmpty
            ? _specialInstructionsController.text
            : null,
      );

      // Save to API
      await _funeralService.createOrUpdateFuneral(_flowData.toFuneralModel());

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        // Navigate to next screen
        context.push(
          AppRouter.funeralLegacyMessages,
          extra: _flowData,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _exitAndRefresh() {
    // Pop all funeral flow screens to trigger refresh
    int popCount = 2; // preferences + service details
    for (int i = 0; i < popCount && context.canPop(); i++) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundWhite,
      appBar: WillCreationAppBar(
        currentStep: 2,
        totalSteps: 4,
        title: 'Service details',
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
                        'Service details',
                        style: AppTextStyles.pageTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Provide details about your preferred funeral service arrangements.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 32),

                      // Service Location
                      AppTextField(
                        controller: _serviceLocationController,
                        label: 'Service Location',
                        isRequired: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a service location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date/Time Preferences
                      AppTextField(
                        controller: _dateTimeController,
                        label: 'Date/Time Preferences (Optional)',
                        readOnly: true,
                        onTap: _selectDateTime,
                        suffixIcon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 20),

                      // Music choice dropdown
                      _isLoadingMusic
                          ? const Center(child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ))
                          : AppDropdown<int>(
                              value: _selectedMusicId,
                              label: 'Music choice (Optional)',
                              items: _musicOptions.map((m) => m.id).toList(),
                              displayName: (id) {
                                final option = _musicOptions.firstWhere((m) => m.id == id);
                                return option.name;
                              },
                              onChanged: (value) {
                                setState(() {
                                  _selectedMusicId = value;
                                });
                              },
                            ),
                      const SizedBox(height: 32),

                      // Special Instructions section
                      Text(
                        'Special Instructions',
                        style: AppTextStyles.sectionTitle,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Preferred funeral director, religious or cultural rites, attire for attendees.',
                        style: AppTextStyles.subtitle,
                      ),
                      const SizedBox(height: 16),

                      // Special instructions textarea
                      AppTextArea(
                        controller: _specialInstructionsController,
                        label: 'Write instruction',
                        maxLines: 5,
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
                        onPressed: _isSaving ? null : _saveAndContinue,
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
