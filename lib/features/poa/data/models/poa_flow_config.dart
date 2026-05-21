import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';

/// Defines a single step in the POA sidebar.
class PoaStepDef {
  final int stepNumber;
  final String title;
  final IconData icon;

  const PoaStepDef({
    required this.stepNumber,
    required this.title,
    required this.icon,
  });
}

/// Strategy class that defines how the POA flow behaves per Australian state.
///
/// All states share Step 1 (basic details) and use a single `/poa/step2` route
/// that delegates to a state-specific screen via [PoaStep2Factory].
class PoaFlowConfig {
  final String stateKey;
  final int totalSteps;
  final List<PoaStepDef> steps;

  /// Whether the basic details screen (Step 1) should show matters + attorneys.
  /// True for NSW (they are part of Step 1), false for QLD (they move to Step 2).
  final bool showMattersOnBasicDetails;

  const PoaFlowConfig._({
    required this.stateKey,
    required this.totalSteps,
    required this.steps,
    required this.showMattersOnBasicDetails,
  });

  /// Returns the appropriate config based on the user's state string.
  /// Defaults to NSW for null/unknown states.
  factory PoaFlowConfig.forState(String? state) {
    print('[PoaFlowConfig.forState] Input state: "$state"');
    final normalized = state?.toLowerCase();
    print('[PoaFlowConfig.forState] Normalized: "$normalized"');
    switch (normalized) {
      case 'queensland':
        print('[PoaFlowConfig.forState] Returning QLD config');
        return PoaFlowConfig._queensland();
      case 'victoria':
        print('[PoaFlowConfig.forState] Returning Victoria config');
        return PoaFlowConfig._victoria();
      case 'south_australia':
        print('[PoaFlowConfig.forState] Returning SA 2-step config');
        return PoaFlowConfig._southAustralia();
      case 'northern_territory':
        print('[PoaFlowConfig.forState] Returning NT 3-step config');
        return PoaFlowConfig._northernTerritory();
      case 'tasmania':
        print('[PoaFlowConfig.forState] Returning TAS 2-step config');
        return PoaFlowConfig._tasmania();
      case 'act':
        print('[PoaFlowConfig.forState] Returning ACT 5-step config');
        return PoaFlowConfig._act();
      case 'western_australia':
        print('[PoaFlowConfig.forState] Returning WA 2-step config');
        return PoaFlowConfig._westernAustralia();
      default:
        print('[PoaFlowConfig.forState] Returning NSW config (default)');
        return PoaFlowConfig._nsw();
    }
  }

  bool get isQueensland => stateKey == 'queensland';

  /// Returns the route path for the next screen after [currentStep].
  String nextRoute(int currentStep) {
    if (stateKey == 'queensland') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaQldFinal;
        default:
          return AppRouter.poaQldFinal;
      }
    }
    if (stateKey == 'new_south_wales') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaReviewNsw;
        default:
          return AppRouter.poaReviewNsw;
      }
    }
    if (stateKey == 'western_australia') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaStep3Wa;
        case 3:
          return AppRouter.poaStep4Wa;
        case 4:
          return AppRouter.poaStep5Wa;
        case 5:
          return AppRouter.poaStep6Wa;
        default:
          return AppRouter.poaStep6Wa;
      }
    }
    if (stateKey == 'act') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaStep3Act;
        case 3:
          return AppRouter.poaStep4Act;
        case 4:
          return AppRouter.poaStep5Act;
        default:
          return AppRouter.poaStep5Act;
      }
    }
    if (stateKey == 'victoria') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaNotification;
        default:
          return AppRouter.poaNotification;
      }
    }
    if (stateKey == 'northern_territory') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaStep3Nt;
        case 3:
          return AppRouter.poaStep4Nt;
        case 4:
          return AppRouter.poaStep5Nt;
        default:
          return AppRouter.poaStep5Nt;
      }
    }
    if (stateKey == 'south_australia') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaStep3Sa;
        case 3:
          return AppRouter.poaStep4Sa;
        case 4:
          return AppRouter.poaStep5Sa;
        default:
          return AppRouter.poaStep5Sa;
      }
    }
    if (stateKey == 'tasmania') {
      switch (currentStep) {
        case 1:
          return AppRouter.poaStep2;
        case 2:
          return AppRouter.poaStep3Tas;
        case 3:
          return AppRouter.poaStep4Tas;
        case 4:
          return AppRouter.poaStep5Tas;
        default:
          return AppRouter.poaStep5Tas;
      }
    }
    // Fallback — should not be reached
    return AppRouter.poaStep2;
  }

  // ── NSW config (default) ────────────────────────────────────────────────

  factory PoaFlowConfig._nsw() {
    return const PoaFlowConfig._(
      stateKey: 'new_south_wales',
      totalSteps: 3,
      showMattersOnBasicDetails: true,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Details, Matters, Attorneys & Guardians',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Commencement, Views & Terms',
          icon: Icons.play_circle_outline,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Review & Download',
          icon: Icons.download_outlined,
        ),
      ],
    );
  }

  // ── Default 4-step config (VIC, SA, WA, TAS, NT, ACT) ────────────────

  factory PoaFlowConfig._defaultFourStep(String stateKey) {
    return PoaFlowConfig._(
      stateKey: stateKey,
      totalSteps: 4,
      showMattersOnBasicDetails: true,
      steps: const [
        PoaStepDef(
          stepNumber: 1,
          title: 'Details, Matters, Attorneys & Guardians',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Commencement, Views & Terms',
          icon: Icons.play_circle_outline,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Notification',
          icon: Icons.notifications_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Assistance & Signing',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── Northern Territory config (5 steps) ─────────────────────────────────

  factory PoaFlowConfig._northernTerritory() {
    return const PoaFlowConfig._(
      stateKey: 'northern_territory',
      totalSteps: 5,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Eligibility',
          icon: Icons.verified_user_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Donor Details',
          icon: Icons.person_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Decision Makers',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 5,
          title: 'Land Dealings',
          icon: Icons.landscape_outlined,
        ),
      ],
    );
  }

  // ── Queensland config ───────────────────────────────────────────────────

  factory PoaFlowConfig._queensland() {
    return const PoaFlowConfig._(
      stateKey: 'queensland',
      totalSteps: 3,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Matters, Attorneys & Preferences',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Notification & Signing',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── Victoria config ─────────────────────────────────────────────────────

  factory PoaFlowConfig._victoria() {
    return const PoaFlowConfig._(
      stateKey: 'victoria',
      totalSteps: 3,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Matters, Attorneys, Terms & More',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Notification',
          icon: Icons.notifications_outlined,
        ),
      ],
    );
  }

  // ── Western Australia config (6 steps) ──────────────────────────────────

  factory PoaFlowConfig._westernAustralia() {
    return const PoaFlowConfig._(
      stateKey: 'western_australia',
      totalSteps: 6,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Document Details',
          icon: Icons.description_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Attorney Appointment',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Substitute Attorney',
          icon: Icons.person_add_outlined,
        ),
        PoaStepDef(
          stepNumber: 5,
          title: 'Conditions',
          icon: Icons.rule_outlined,
        ),
        PoaStepDef(
          stepNumber: 6,
          title: 'Commencement',
          icon: Icons.play_circle_outline,
        ),
      ],
    );
  }

  // ── Tasmania config (5 steps) ────────────────────────────────────────────

  factory PoaFlowConfig._tasmania() {
    return const PoaFlowConfig._(
      stateKey: 'tasmania',
      totalSteps: 5,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Eligibility',
          icon: Icons.verified_user_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Donor Details',
          icon: Icons.person_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Attorneys',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 5,
          title: 'Conditions',
          icon: Icons.rule_outlined,
        ),
      ],
    );
  }

  // ── South Australia config (5 steps) ─────────────────────────────────────

  factory PoaFlowConfig._southAustralia() {
    return const PoaFlowConfig._(
      stateKey: 'south_australia',
      totalSteps: 5,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Donor Details',
          icon: Icons.person_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Donee Appointment',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Commencement',
          icon: Icons.play_circle_outline,
        ),
        PoaStepDef(
          stepNumber: 5,
          title: 'Conditions',
          icon: Icons.rule_outlined,
        ),
      ],
    );
  }

  // ── ACT config (5 steps) ──────────────────────────────────────────────

  factory PoaFlowConfig._act() {
    return const PoaFlowConfig._(
      stateKey: 'act',
      totalSteps: 5,
      showMattersOnBasicDetails: false,
      steps: [
        PoaStepDef(
          stepNumber: 1,
          title: 'Basic Details',
          icon: Icons.person_outline,
        ),
        PoaStepDef(
          stepNumber: 2,
          title: 'Eligibility & Principal',
          icon: Icons.verified_user_outlined,
        ),
        PoaStepDef(
          stepNumber: 3,
          title: 'Attorneys, Delegation & Matters',
          icon: Icons.gavel_outlined,
        ),
        PoaStepDef(
          stepNumber: 4,
          title: 'Directions, Commencement & Prior EPA',
          icon: Icons.description_outlined,
        ),
        PoaStepDef(
          stepNumber: 5,
          title: 'Signing',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }
}
