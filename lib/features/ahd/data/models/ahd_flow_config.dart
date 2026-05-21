import 'package:flutter/material.dart';
import '../../../../core/routes/app_router.dart';

/// Defines a single step in the AHD sidebar.
class AhdStepDef {
  final int stepNumber;
  final String title;
  final IconData icon;

  const AhdStepDef({
    required this.stepNumber,
    required this.title,
    required this.icon,
  });
}

/// Strategy class that defines how the AHD flow behaves per Australian state.
///
/// All states share Step 1 (personal details). Step 2+ varies by state.
class AhdFlowConfig {
  final String stateKey;
  final int totalSteps;
  final List<AhdStepDef> steps;

  const AhdFlowConfig._({
    required this.stateKey,
    required this.totalSteps,
    required this.steps,
  });

  /// Returns the appropriate config based on the user's state string.
  /// Defaults to a generic 2-step flow for unknown states.
  factory AhdFlowConfig.forState(String? state) {
    final normalized = state?.toLowerCase();
    switch (normalized) {
      case 'victoria':
        return AhdFlowConfig._victoria();
      case 'new_south_wales':
        return AhdFlowConfig._nsw();
      case 'western_australia':
        return AhdFlowConfig._wa();
      case 'south_australia':
        return AhdFlowConfig._sa();
      case 'northern_territory':
        return AhdFlowConfig._nt();
      case 'tasmania':
        return AhdFlowConfig._tas();
      case 'act':
        return AhdFlowConfig._act();
      case 'queensland':
        return AhdFlowConfig._qld();
      default:
        return AhdFlowConfig._default(normalized ?? 'default');
    }
  }

  /// Returns the route path for the next screen after [currentStep].
  String nextRoute(int currentStep) {
    if (stateKey == 'victoria') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2;
        case 2:
          return AppRouter.ahdStep3Vic;
        case 3:
          return AppRouter.ahdStep4Vic;
        case 4:
          return AppRouter.ahdStep5Vic;
        case 5:
          return AppRouter.ahdStep6Vic;
        default:
          return AppRouter.ahdStep6Vic;
      }
    }
    if (stateKey == 'new_south_wales') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2;
        case 2:
          return AppRouter.ahdStep6Nsw; // Person responsible (now step 3)
        case 3:
          return AppRouter.ahdStep3Nsw; // Values (now step 4)
        case 4:
          return AppRouter.ahdStep4Nsw; // Medical care (now step 5)
        case 5:
          return AppRouter.ahdStep5Nsw; // Organ/tissue (now step 6)
        case 6:
          return AppRouter.ahdStep7Nsw;
        default:
          return AppRouter.ahdStep7Nsw;
      }
    }
    if (stateKey == 'western_australia') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2Wa;
        case 2:
          return AppRouter.ahdStep3Wa;
        case 3:
          return AppRouter.ahdStep4Wa;
        case 4:
          return AppRouter.ahdStep5Wa;
        case 5:
          return AppRouter.ahdStep6Wa;
        case 6:
          return AppRouter.ahdStep7Wa;
        default:
          return AppRouter.ahdStep7Wa;
      }
    }
    if (stateKey == 'south_australia') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2Sa;
        case 2:
          return AppRouter.ahdStep3Sa;
        case 3:
          return AppRouter.ahdStep4Sa;
        case 4:
          return AppRouter.ahdStep5Sa;
        case 5:
          return AppRouter.ahdStep6Sa;
        case 6:
          return AppRouter.ahdStep7Sa;
        case 7:
          return AppRouter.ahdStep8Sa;
        case 8:
          return AppRouter.ahdStep9Sa;
        case 9:
          return AppRouter.ahdStep10Sa;
        default:
          return AppRouter.ahdStep10Sa;
      }
    }
    if (stateKey == 'northern_territory') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2;
        case 2:
          return AppRouter.ahdStep3Nt;
        case 3:
          return AppRouter.ahdStep4Nt;
        case 4:
          return AppRouter.ahdStep5Nt;
        case 5:
          return AppRouter.ahdStep6Nt;
        default:
          return AppRouter.ahdStep6Nt;
      }
    }
    if (stateKey == 'tasmania') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2;
        case 2:
          return AppRouter.ahdStep3Tas;
        case 3:
          return AppRouter.ahdStep4Tas;
        case 4:
          return AppRouter.ahdStep5Tas;
        case 5:
          return AppRouter.ahdStep8Tas;   // Interpreter (now step 6)
        case 6:
          return AppRouter.ahdStep9Tas;   // Expiry (now step 7)
        case 7:
          return AppRouter.ahdStep10Tas;  // Revoking (now step 8)
        case 8:
          return AppRouter.ahdStep7Tas;   // Witnessing (now step 9)
        case 9:
          return AppRouter.ahdStep11Tas;  // Organ Donation (still final, step 10)
        default:
          return AppRouter.ahdStep11Tas;
      }
    }
    if (stateKey == 'act') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2;
        case 2:
          return AppRouter.ahdStep3Act;
        case 3:
          return AppRouter.ahdStep4Act;
        default:
          return AppRouter.ahdStep4Act;
      }
    }
    if (stateKey == 'queensland') {
      switch (currentStep) {
        case 1:
          return AppRouter.ahdStep2Qld;
        case 2:
          return AppRouter.ahdStep3Qld;
        case 3:
          return AppRouter.ahdStep4Qld;
        case 4:
          return AppRouter.ahdStep5Qld;
        case 5:
          return AppRouter.ahdStep6Qld;
        case 6:
          return AppRouter.ahdStep7Qld;
        case 7:
          return AppRouter.ahdStep8Qld;
        case 8:
          return AppRouter.ahdStep9Qld;
        default:
          return AppRouter.ahdStep9Qld;
      }
    }
    // Default 2-step: step 1 → step 2 (finish)
    return AppRouter.ahdStep2;
  }

  // ── Victoria config (6 steps per Figma) ────────────────────────────────

  factory AhdFlowConfig._victoria() {
    return const AhdFlowConfig._(
      stateKey: 'victoria',
      totalSteps: 6,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Health conditions and concerns',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Values directive',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Instructional directive',
          icon: Icons.assignment_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Witnessing',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Signature of interpreter',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── NSW config (7 steps per Figma) ─────────────────────────────────────

  factory AhdFlowConfig._nsw() {
    return const AhdFlowConfig._(
      stateKey: 'new_south_wales',
      totalSteps: 7,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Enduring guardian',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Person responsible',
          icon: Icons.person_add_outlined,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Personal values about dying',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Directions about medical care',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Organ and tissue donation',
          icon: Icons.volunteer_activism_outlined,
        ),
        AhdStepDef(
          stepNumber: 7,
          title: 'Authorisation',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── WA config (7 steps per Figma) ──────────────────────────────────────

  factory AhdFlowConfig._wa() {
    return const AhdFlowConfig._(
      stateKey: 'western_australia',
      totalSteps: 7,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Health Conditions & Concerns',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Values, Wishes & Preferences',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Treatment Decisions',
          icon: Icons.assignment_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Medical Research',
          icon: Icons.science_outlined,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'People Who Helped',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 7,
          title: 'Review & Submit',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── SA config (10 steps per Figma) ─────────────────────────────────────

  factory AhdFlowConfig._sa() {
    return const AhdFlowConfig._(
      stateKey: 'south_australia',
      totalSteps: 10,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Substitute Decision-Makers',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Decision-Maker Acceptance',
          icon: Icons.check_circle_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Conditions of Appointments',
          icon: Icons.description_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Values and Wishes',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Refusal/s of Health Care',
          icon: Icons.do_not_disturb_outlined,
        ),
        AhdStepDef(
          stepNumber: 7,
          title: 'Organ & Tissue Donation',
          icon: Icons.volunteer_activism_outlined,
        ),
        AhdStepDef(
          stepNumber: 8,
          title: 'Expiry Date',
          icon: Icons.calendar_today_outlined,
        ),
        AhdStepDef(
          stepNumber: 9,
          title: 'Witnessing',
          icon: Icons.edit_outlined,
        ),
        AhdStepDef(
          stepNumber: 10,
          title: 'Interpreter Statement',
          icon: Icons.translate_outlined,
        ),
      ],
    );
  }

  // ── NT config (7 steps per Figma) ──────────────────────────────────────

  factory AhdFlowConfig._nt() {
    return const AhdFlowConfig._(
      stateKey: 'northern_territory',
      totalSteps: 6,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Advance care statement',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Other information',
          icon: Icons.info_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Advanced consent decisions',
          icon: Icons.assignment_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Appointed decision maker',
          icon: Icons.person_add_outlined,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Decision maker preferences',
          icon: Icons.how_to_vote_outlined,
        ),
      ],
    );
  }

  // ── TAS config (11 steps per Figma) ────────────────────────────────────

  factory AhdFlowConfig._tas() {
    return const AhdFlowConfig._(
      stateKey: 'tasmania',
      totalSteps: 10,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Health Conditions',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Views, Wishes & Preferences',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Medical Treatment Refuse',
          icon: Icons.do_not_disturb_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Your Signature',
          icon: Icons.draw_outlined,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Interpreter/Translator',
          icon: Icons.translate_outlined,
        ),
        AhdStepDef(
          stepNumber: 7,
          title: 'Expiry Date of ACD',
          icon: Icons.calendar_today_outlined,
        ),
        AhdStepDef(
          stepNumber: 8,
          title: 'Revoking Your ACD',
          icon: Icons.cancel_outlined,
        ),
        AhdStepDef(
          stepNumber: 9,
          title: 'Witnessing',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 10,
          title: 'Organ & Tissue Donation',
          icon: Icons.volunteer_activism_outlined,
        ),
      ],
    );
  }

  // ── ACT config (4 steps per Figma) ─────────────────────────────────────

  factory AhdFlowConfig._act() {
    return const AhdFlowConfig._(
      stateKey: 'act',
      totalSteps: 4,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Advance Consent Direction',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Directed person',
          icon: Icons.person_add_outlined,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Witnesses',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── QLD config (9 steps per Figma) ─────────────────────────────────────

  factory AhdFlowConfig._qld() {
    return const AhdFlowConfig._(
      stateKey: 'queensland',
      totalSteps: 9,
      steps: [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Health Conditions',
          icon: Icons.medical_services_outlined,
        ),
        AhdStepDef(
          stepNumber: 3,
          title: 'Values, Wishes & Preferences',
          icon: Icons.favorite_outline,
        ),
        AhdStepDef(
          stepNumber: 4,
          title: 'Directions about Life Sustaining',
          icon: Icons.assignment_outlined,
        ),
        AhdStepDef(
          stepNumber: 5,
          title: 'Life Sustaining Treatment',
          icon: Icons.local_hospital_outlined,
        ),
        AhdStepDef(
          stepNumber: 6,
          title: 'Other Healthcare & Blood',
          icon: Icons.bloodtype_outlined,
        ),
        AhdStepDef(
          stepNumber: 7,
          title: 'Doctor Certificate',
          icon: Icons.badge_outlined,
        ),
        AhdStepDef(
          stepNumber: 8,
          title: 'Appointing Attorneys',
          icon: Icons.people_outline,
        ),
        AhdStepDef(
          stepNumber: 9,
          title: 'Declaration & Signatures',
          icon: Icons.edit_outlined,
        ),
      ],
    );
  }

  // ── Default config (2 steps) ───────────────────────────────────────────

  factory AhdFlowConfig._default(String stateKey) {
    return AhdFlowConfig._(
      stateKey: stateKey,
      totalSteps: 2,
      steps: const [
        AhdStepDef(
          stepNumber: 1,
          title: 'Personal Details',
          icon: Icons.person_outline,
        ),
        AhdStepDef(
          stepNumber: 2,
          title: 'Health Conditions, Directions & Declaration',
          icon: Icons.medical_services_outlined,
        ),
      ],
    );
  }
}
