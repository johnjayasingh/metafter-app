import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/routes/app_router.dart';
import '../../../../core/widgets/form/form_widgets.dart';
import '../../../will_creation/presentation/widgets/will_creation_app_bar.dart';
import '../../data/models/ahd_models.dart';
import '../../data/models/ahd_flow_config.dart';
import '../widgets/ahd_steps_sidebar.dart';
import '../widgets/ahd_bottom_bar.dart';

/// AHD WA Step 3 — Your values, wishes and preferences
///
/// API fields:
///   - life_and_health_priorities.living_well_choices
///   - death_and_wishes.what_worries_most
///   - life_and_health_priorities.is_nearing_death
///   - life_and_health_priorities.nearing_death_location_details
///   - life_and_health_priorities.comfort_care_preferences
///   - life_and_health_priorities.comfort_pain_details
///   - life_and_health_priorities.comfort_surroundings_details

const _livingWellOptions = [
  {'key': 'FAMILY_FRIENDS', 'label': 'Spending time with family and friends'},
  {'key': 'LIVING_INDEPENDENTLY', 'label': 'Living independently'},
  {
    'key': 'VISIT_HOMETOWN',
    'label':
        'Being able to visit my home town, country of origin, or spending time on country'
  },
  {
    'key': 'SELF_CARE',
    'label':
        'Being able to care for myself (e.g. showering, going to the toilet, feeding myself)'
  },
  {
    'key': 'KEEPING_ACTIVE',
    'label':
        'Keeping active (e.g. playing sport, walking, swimming, gardening)'
  },
  {
    'key': 'RECREATIONAL_ACTIVITIES',
    'label':
        'Enjoying recreational activities, hobbies and interests (e.g. music, travel, volunteering)'
  },
  {
    'key': 'RELIGIOUS_CULTURAL',
    'label':
        'Practising religious, cultural, spiritual and/or community activities'
  },
  {
    'key': 'CULTURAL_VALUES',
    'label':
        'Living according to my cultural and religious values (e.g. eating halal, kosher foods only)'
  },
  {'key': 'WORKING', 'label': 'Working in a paid or unpaid job'},
];

const _comfortOptions = [
  {
    'key': 'NO_PAIN',
    'label':
        'I do not want to be in pain, I want my symptoms managed, and I want to be as comfortable as possible'
  },
  {
    'key': 'LOVED_ONES',
    'label': 'I want to have my loved ones and/or pets around me'
  },
  {
    'key': 'CULTURAL_TRADITIONS',
    'label':
        'It is important to me that cultural or religious traditions are followed'
  },
  {
    'key': 'PASTORAL_CARE',
    'label': 'I want to have access to pastoral/spiritual care'
  },
  {
    'key': 'SURROUNDINGS',
    'label':
        'My surroundings are important to me (e.g. quiet, music, photographs)'
  },
];

class AhdStep3WaScreen extends StatefulWidget {
  final AhdFlowData flowData;

  const AhdStep3WaScreen({super.key, required this.flowData});

  @override
  State<AhdStep3WaScreen> createState() => _AhdStep3WaScreenState();
}

class _AhdStep3WaScreenState extends State<AhdStep3WaScreen> {
  late final List<String> _livingWellChoices;
  late final TextEditingController _worriesController;
  late final List<String> _nearingDeathLocations;
  late final TextEditingController _nearingDeathDetailsController;
  late final List<String> _comfortChoices;
  late final TextEditingController _comfortPainDetailsController;
  late final TextEditingController _comfortSurroundingsDetailsController;

  @override
  void initState() {
    super.initState();
    final d = widget.flowData;
    _livingWellChoices = List.from(d.waLivingWellChoices);
    _worriesController = TextEditingController(text: d.waWorries ?? '');
    _nearingDeathLocations = List.from(d.waNearingDeathLocations);
    _nearingDeathDetailsController =
        TextEditingController(text: d.waNearingDeathLocationDetails ?? '');
    _comfortChoices = List.from(d.waComfortChoices);
    _comfortPainDetailsController =
        TextEditingController(text: d.waComfortPainDetails ?? '');
    _comfortSurroundingsDetailsController =
        TextEditingController(text: d.waComfortSurroundingsDetails ?? '');
  }

  @override
  void dispose() {
    _worriesController.dispose();
    _nearingDeathDetailsController.dispose();
    _comfortPainDetailsController.dispose();
    _comfortSurroundingsDetailsController.dispose();
    super.dispose();
  }

  AhdFlowData? _returnedFromNext;

  AhdFlowData _collectData() {
    return (_returnedFromNext ?? widget.flowData).copyWith(
      waLivingWellChoices: List<String>.from(_livingWellChoices),
      waWorries: _worriesController.text.trim(),
      waNearingDeathLocations: List<String>.from(_nearingDeathLocations),
      waNearingDeathLocationDetails:
          _nearingDeathDetailsController.text.trim(),
      waComfortChoices: List<String>.from(_comfortChoices),
      waComfortPainDetails: _comfortPainDetailsController.text.trim(),
      waComfortSurroundingsDetails:
          _comfortSurroundingsDetailsController.text.trim(),
    );
  }

  Future<void> _handleNext() async {
    final updated = _collectData();
    final config = AhdFlowConfig.forState(widget.flowData.state);
    final result = await context.push<AhdFlowData>(
        config.nextRoute(3), extra: updated);
    if (result != null) _returnedFromNext = result;
  }

  void _toggleLivingWell(String key) {
    setState(() {
      if (_livingWellChoices.contains(key)) {
        _livingWellChoices.remove(key);
      } else {
        _livingWellChoices.add(key);
      }
    });
  }

  void _toggleNearingDeath(String key) {
    setState(() {
      if (_nearingDeathLocations.contains(key)) {
        _nearingDeathLocations.remove(key);
      } else {
        _nearingDeathLocations.add(key);
      }
    });
  }

  void _toggleComfort(String key) {
    setState(() {
      if (_comfortChoices.contains(key)) {
        _comfortChoices.remove(key);
      } else {
        _comfortChoices.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = AhdFlowConfig.forState(widget.flowData.state);
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: AhdStepsSidebar(
          currentStep: 3, userState: widget.flowData.state),
      appBar: WillCreationAppBar(
        currentStep: 3,
        totalSteps: config.totalSteps,
        title: 'Your values, wishes and preferences',
        enableDrawer: true,
        exitTitle: 'Exit advance health directive?',
        exitDescription:
            'Your progress will be lost. You can start a new advance health directive at any time.',
        exitDiscardButtonText: 'Exit AHD',
        hideSaveDraftOnExit: true,
        onExitNavigate: () => context.go(AppRouter.home, extra: 5),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your values, wishes and preferences',
                        style: AppTextStyles.pageTitle),
                    const SizedBox(height: 24),

                    // ── Living well ──
                    Text(
                      'What does living well mean to you?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),
                    ..._livingWellOptions.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _CheckboxOption(
                            label: opt['label']!,
                            isSelected:
                                _livingWellChoices.contains(opt['key']),
                            onTap: () => _toggleLivingWell(opt['key']!),
                          ),
                        )),
                    const SizedBox(height: 24),

                    // ── Worries ──
                    Text(
                      'What worries you most about the future?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 12),
                    AppTextArea(
                      controller: _worriesController,
                      label: 'Your worries',
                      maxLines: 6,
                      minLines: 4,
                    ),
                    const SizedBox(height: 24),

                    // ── Nearing death location ──
                    Text(
                      'Please indicate where you would like to be when you are nearing death. Tick the option that applies to you. You can provide more detail about the option you choose in the space below.',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),
                    _CheckboxOption(
                      label:
                          'I want to be at home \u2013 where I am living at the time',
                      isSelected: _nearingDeathLocations.contains('AT_HOME'),
                      onTap: () => _toggleNearingDeath('AT_HOME'),
                    ),
                    const SizedBox(height: 8),
                    _CheckboxOption(
                      label:
                          'I do not want to be at home \u2013 provide more details below',
                      isSelected:
                          _nearingDeathLocations.contains('NOT_AT_HOME'),
                      onTap: () => _toggleNearingDeath('NOT_AT_HOME'),
                    ),
                    const SizedBox(height: 8),
                    _CheckboxOption(
                      label:
                          'I do not have a preference \u2013 I would like to be wherever',
                      isSelected:
                          _nearingDeathLocations.contains('NO_PREFERENCE'),
                      onTap: () => _toggleNearingDeath('NO_PREFERENCE'),
                    ),
                    const SizedBox(height: 8),
                    _CheckboxOption(
                      label:
                          'I can receive the best care for my needs at the time',
                      isSelected: _nearingDeathLocations.contains('BEST_CARE'),
                      onTap: () => _toggleNearingDeath('BEST_CARE'),
                    ),
                    const SizedBox(height: 8),
                    _CheckboxOption(
                      label: 'Other',
                      isSelected: _nearingDeathLocations.contains('OTHER'),
                      onTap: () => _toggleNearingDeath('OTHER'),
                    ),

                    if (_nearingDeathLocations.contains('NOT_AT_HOME') ||
                        _nearingDeathLocations.contains('OTHER')) ...[
                      const SizedBox(height: 12),
                      AppTextArea(
                        controller: _nearingDeathDetailsController,
                        label: 'Please provide more details',
                        maxLines: 4,
                        minLines: 2,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── Comfort care ──
                    Text(
                      'What is important to you for your comfort and care?',
                      style: AppTextStyles.questionTitle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select all that apply',
                      style: AppTextStyles.subtitle,
                    ),
                    const SizedBox(height: 12),
                    ..._comfortOptions.map((opt) {
                      final key = opt['key']!;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CheckboxOption(
                              label: opt['label']!,
                              isSelected: _comfortChoices.contains(key),
                              onTap: () => _toggleComfort(key),
                            ),
                            if (key == 'NO_PAIN' &&
                                _comfortChoices.contains('NO_PAIN')) ...[
                              const SizedBox(height: 8),
                              AppTextArea(
                                controller: _comfortPainDetailsController,
                                label: 'Pain management details',
                                maxLines: 4,
                                minLines: 2,
                              ),
                            ],
                            if (key == 'SURROUNDINGS' &&
                                _comfortChoices
                                    .contains('SURROUNDINGS')) ...[
                              const SizedBox(height: 8),
                              AppTextArea(
                                controller:
                                    _comfortSurroundingsDetailsController,
                                label: 'Surroundings details',
                                maxLines: 4,
                                minLines: 2,
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            AhdBottomBar(
              onPrevious: () => context.pop(_collectData()),
              onNext: _handleNext,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckboxOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CheckboxOption({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.borderGray),
          color: isSelected
              ? AppColors.backgroundLightGreen
              : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              color: isSelected
                  ? AppColors.primaryGreen
                  : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
