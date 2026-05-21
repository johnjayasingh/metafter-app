import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart';
import '../../main.dart' as main_file;
import '../../features/splash/presentation/pages/splash_screen.dart';
import '../../features/onboarding/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/sign_in_screen.dart';
import '../../features/auth/presentation/pages/sign_up_screen.dart';
import '../../features/auth/presentation/pages/otp_verification_screen.dart';
import '../../features/auth/presentation/pages/mfa_setup_screen.dart';
import '../../features/auth/presentation/pages/mfa_challenge_screen.dart';
import '../../features/auth/data/models/auth_models.dart';
import '../../features/home/presentation/pages/home_screen.dart';
import '../../features/home/presentation/pages/will_timeline_screen.dart';
import '../../features/home/presentation/pages/will_comments_screen.dart';
import '../../features/will_creation/presentation/pages/basic_details_screen.dart';
import '../../features/will_creation/presentation/pages/relationship_status_screen.dart';
import '../../features/will_creation/presentation/pages/family_details_screen.dart';
import '../../features/will_creation/presentation/pages/add_former_partner_screen.dart';
import '../../features/will_creation/presentation/pages/add_dependent_screen.dart';
import '../../features/will_creation/presentation/pages/beneficiaries_screen.dart';
import '../../features/will_creation/presentation/pages/add_beneficiary_screen.dart';
import '../../features/will_creation/presentation/pages/charity_selection_screen.dart';
import '../../features/will_creation/presentation/pages/list_assets_screen.dart';
import '../../features/will_creation/presentation/pages/add_asset_screen.dart';
import '../../features/will_creation/presentation/pages/gifts_question_screen.dart';
import '../../features/will_creation/presentation/pages/list_gift_beneficiaries_screen.dart';
import '../../features/will_creation/presentation/pages/select_gift_recipient_screen.dart';
import '../../features/will_creation/presentation/pages/add_gift_recipient_screen.dart';
import '../../features/will_creation/presentation/pages/asset_allocation_screen.dart';
import '../../features/will_creation/presentation/pages/add_backup_beneficiary_screen.dart';
import '../../features/will_creation/presentation/pages/executors_screen.dart';
import '../../features/will_creation/presentation/pages/add_personal_executor_screen.dart';
import '../../features/will_creation/presentation/pages/add_willcloud_executor_screen.dart';
import '../../features/will_creation/presentation/pages/witness_screen.dart';
import '../../features/will_creation/presentation/pages/add_witness_screen.dart';
import '../../features/will_creation/presentation/pages/review_screen.dart';
import '../../features/will_creation/data/models/family_models.dart';
import '../../features/will_creation/data/models/will_models.dart';
import '../../features/will_creation/data/models/business_models.dart';
import '../../features/subscription/presentation/pages/subscription_selection_page.dart';
import '../../features/will_creation/presentation/pages/legal_review_screen.dart';
import '../../features/will_creation/presentation/pages/assign_lawyer_screen.dart';
import '../../features/will_creation/presentation/pages/add_willcloud_lawyer_screen.dart';
import '../../features/will_creation/presentation/pages/add_personal_lawyer_screen.dart';
import '../../features/will_creation/presentation/pages/notification_recipient_screen.dart';
import '../../features/funeral/presentation/pages/funeral_preferences_screen.dart';
import '../../features/funeral/presentation/pages/funeral_service_details_screen.dart';
import '../../features/funeral/presentation/pages/funeral_legacy_messages_screen.dart';
import '../../features/funeral/presentation/pages/funeral_recipients_screen.dart';
import '../../features/funeral/presentation/pages/funeral_add_direction_person_screen.dart';
import '../../features/funeral/data/models/funeral_flow_data.dart';
import '../../features/digital_vault/presentation/pages/closure_instructions_screen.dart';
import '../../features/digital_vault/presentation/pages/add_message_screen.dart';
import '../../features/digital_vault/presentation/pages/add_message_recipient_screen.dart';
import '../../features/digital_vault/presentation/pages/add_physical_asset_screen.dart';
import '../../features/digital_vault/presentation/pages/add_liability_screen.dart';
import '../../features/digital_vault/presentation/pages/add_contact_screen.dart';
import '../../features/digital_vault/data/models/vault_models.dart' hide WillAsset;
import '../../features/profile/presentation/pages/edit_profile_screen.dart';
import '../../features/profile/data/models/profile_models.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/poa/data/models/poa_models.dart';
import '../../features/poa/presentation/screens/poa_basic_details_screen.dart';
import '../../features/poa/presentation/screens/poa_matters_screen.dart';
import '../../features/poa/presentation/screens/poa_attorneys_screen.dart';
import '../../features/poa/presentation/screens/poa_successive_attorneys_screen.dart';
import '../../features/poa/presentation/screens/poa_commencement_screen.dart';
import '../../features/poa/presentation/screens/poa_views_wishes_screen.dart';
import '../../features/poa/presentation/screens/poa_terms_instructions_screen.dart';
import '../../features/poa/presentation/screens/poa_notification_screen.dart';
import '../../features/poa/presentation/screens/poa_assistance_signing_screen.dart';
import '../../features/poa/presentation/screens/poa_add_attorney_screen.dart';
import '../../features/poa/presentation/screens/poa_enduring_guardian_screen.dart';
import '../../features/poa/presentation/screens/poa_substitute_enduring_guardian_screen.dart';
import '../../features/poa/presentation/screens/poa_qld_merged_screen.dart';
import '../../features/poa/presentation/screens/poa_qld_final_screen.dart';
import '../../features/poa/presentation/screens/poa_step2_factory.dart';
import '../../features/poa/presentation/screens/poa_step3_act_screen.dart';
import '../../features/poa/presentation/screens/poa_step4_act_screen.dart';
import '../../features/poa/presentation/screens/poa_step5_act_screen.dart';
import '../../features/poa/presentation/screens/poa_step3_tas_screen.dart';
import '../../features/poa/presentation/screens/poa_step4_tas_screen.dart';
import '../../features/poa/presentation/screens/poa_step5_tas_screen.dart';
import '../../features/poa/presentation/screens/poa_step3_sa_screen.dart';
import '../../features/poa/presentation/screens/poa_step4_sa_screen.dart';
import '../../features/poa/presentation/screens/poa_step5_sa_screen.dart';
import '../../features/poa/presentation/screens/poa_step3_nt_screen.dart';
import '../../features/poa/presentation/screens/poa_step4_nt_screen.dart';
import '../../features/poa/presentation/screens/poa_step5_nt_screen.dart';
import '../../features/poa/presentation/screens/poa_step3_wa_screen.dart';
import '../../features/poa/presentation/screens/poa_step4_wa_screen.dart';
import '../../features/poa/presentation/screens/poa_step5_wa_screen.dart';
import '../../features/poa/presentation/screens/poa_step6_wa_screen.dart';
import '../../features/poa/presentation/screens/poa_review_nsw_screen.dart';
import '../../features/ahd/data/models/ahd_models.dart';
import '../../features/ahd/presentation/pages/ahd_personal_details_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_vic_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_vic_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_vic_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_vic_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_vic_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_nsw_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step8_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step9_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step10_sa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_nt_screen.dart';
import '../../features/ahd/presentation/pages/ahd_add_attorney_screen.dart';
import '../../features/ahd/presentation/pages/ahd_add_substitute_dm_screen.dart';
import '../../features/ahd/presentation/pages/ahd_add_nt_decision_maker_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step8_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step9_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step10_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step11_tas_screen.dart';
import '../../features/ahd/presentation/pages/ahd_add_tas_witness_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_act_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_act_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_act_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_wa_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step2_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step3_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step4_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step5_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step6_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step7_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step8_qld_screen.dart';
import '../../features/ahd/presentation/pages/ahd_step9_qld_screen.dart';
import '../../features/probate/presentation/pages/probate_request_screen.dart';
import '../../features/home/presentation/pages/executor_checklist_screen.dart';
import '../../features/will_creation/presentation/pages/will_sign_webview_page.dart';
import 'coming_soon_screen.dart';

class AppRouter {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String signIn = '/sign-in';
  static const String signUp = '/sign-up';
  static const String otpVerification = '/otp-verification';
  static const String mfaSetup = '/mfa-setup';
  static const String mfaChallenge = '/mfa-challenge';
  static const String home = '/home';
  static const String willOnboarding = '/will-onboarding';
  static const String basicDetails = '/will-creation/basic-details';
  static const String relationshipStatus = '/relationship-status';
  static const String familyDetails = '/will-creation/family-details';
  static const String addFormerPartner = '/will-creation/add-former-partner';
  static const String addDependent = '/will-creation/add-dependent';
  static const String beneficiaries = '/will-creation/beneficiaries';
  static const String addBeneficiary = '/will-creation/add-beneficiary';
  static const String charitySelection = '/will-creation/charities';
  static const String listAssets = '/will-creation/assets';
  static const String addAsset = '/will-creation/add-asset';
  static const String giftsQuestion = '/will-creation/gifts-question';
  static const String giftBeneficiaries = '/will-creation/gift-beneficiaries';
  static const String selectGiftRecipient = '/will-creation/select-gift-recipient';
  static const String addGiftRecipient = '/will-creation/add-gift-recipient';
  static const String assetAllocation = '/will-creation/asset-allocation';
  static const String addBackupBeneficiary = '/will-creation/add-backup-beneficiary';
  static const String executors = '/will-creation/executors';
  static const String addPersonalExecutor = '/will-creation/add-personal-executor';
  static const String addWillcloudExecutor = '/will-creation/add-willcloud-executor';
  static const String witness = '/will-creation/witness';
  static const String addWitness = '/will-creation/add-witness';
  static const String review = '/will-creation/review';
  static const String subscriptionSelection = '/subscription-selection';
  static const String legalReview = '/legal-review';
  static const String assignLawyer = '/will-creation/assign-lawyer';
  static const String addWillcloudLawyer = '/will-creation/add-willcloud-lawyer';
  static const String addPersonalLawyer = '/will-creation/add-personal-lawyer';
  static const String notificationRecipient = '/will-creation/notification-recipient';
  static const String willTimeline = '/will-timeline';
  static const String willComments = '/will-comments';
  
  // Funeral routes
  static const String funeralPreferences = '/funeral/preferences';
  static const String funeralServiceDetails = '/funeral/service-details';
  static const String funeralLegacyMessages = '/funeral/legacy-messages';
  static const String funeralRecipients = '/funeral/recipients';
  static const String funeralAddDirectionPerson = '/funeral/add-direction-person';
  
  // Digital Vault routes
  static const String digitalVaultInstructions = '/digital-vault/instructions';
  static const String vaultAddMessage = '/digital-vault/add-message';
  static const String vaultAddMessageRecipient = '/digital-vault/add-message-recipient';
  static const String vaultAddPhysicalAsset = '/digital-vault/add-physical-asset';
  static const String vaultAddLiability = '/digital-vault/add-liability';
  static const String vaultAddContact = '/digital-vault/add-contact';
  
  // POA routes
  static const String poaBasicDetails = '/poa/basic-details';
  static const String poaMatters = '/poa/matters';
  static const String poaAttorneys = '/poa/attorneys';
  static const String poaSuccessiveAttorneys = '/poa/successive-attorneys';
  static const String poaCommencement = '/poa/commencement';
  static const String poaStep2 = '/poa/step2';
  static const String poaViewsWishes = '/poa/views-wishes';
  static const String poaTermsInstructions = '/poa/terms-instructions';
  static const String poaNotification = '/poa/notification';
  static const String poaAssistanceSigning = '/poa/assistance-signing';
  static const String poaAddAttorney = '/poa/add-attorney';
  static const String poaEnduringGuardian = '/poa/enduring-guardian';
  static const String poaSubstituteEnduringGuardian = '/poa/substitute-enduring-guardian';
  static const String poaQldMerged = '/poa/qld-merged';
  static const String poaQldFinal = '/poa/qld-final';
  static const String poaReviewNsw = '/poa/review-nsw';
  static const String poaStep3Act = '/poa/step3-act';
  static const String poaStep4Act = '/poa/step4-act';
  static const String poaStep5Act = '/poa/step5-act';
  static const String poaStep3Tas = '/poa/step3-tas';
  static const String poaStep4Tas = '/poa/step4-tas';
  static const String poaStep5Tas = '/poa/step5-tas';
  static const String poaStep3Sa = '/poa/step3-sa';
  static const String poaStep4Sa = '/poa/step4-sa';
  static const String poaStep5Sa = '/poa/step5-sa';
  static const String poaStep3Nt = '/poa/step3-nt';
  static const String poaStep4Nt = '/poa/step4-nt';
  static const String poaStep5Nt = '/poa/step5-nt';
  static const String poaStep3Wa = '/poa/step3-wa';
  static const String poaStep4Wa = '/poa/step4-wa';
  static const String poaStep5Wa = '/poa/step5-wa';
  static const String poaStep6Wa = '/poa/step6-wa';

  // AHD (Advance Health Directive) routes
  static const String ahdPersonalDetails = '/ahd/personal-details';
  static const String ahdStep2 = '/ahd/step2';
  static const String ahdStep3Vic = '/ahd/step3-vic';
  static const String ahdStep4Vic = '/ahd/step4-vic';
  static const String ahdStep5Vic = '/ahd/step5-vic';
  static const String ahdStep6Vic = '/ahd/step6-vic';
  static const String ahdStep3Nsw = '/ahd/step3-nsw';
  static const String ahdStep4Nsw = '/ahd/step4-nsw';
  static const String ahdStep5Nsw = '/ahd/step5-nsw';
  static const String ahdStep6Nsw = '/ahd/step6-nsw';
  static const String ahdStep7Nsw = '/ahd/step7-nsw';
  static const String ahdStep2Wa = '/ahd/step2-wa';
  static const String ahdStep3Wa = '/ahd/step3-wa';
  static const String ahdStep4Wa = '/ahd/step4-wa';
  static const String ahdStep5Wa = '/ahd/step5-wa';
  static const String ahdStep6Wa = '/ahd/step6-wa';
  static const String ahdStep7Wa = '/ahd/step7-wa';
  static const String ahdStep2Sa = '/ahd/step2-sa';
  static const String ahdStep3Sa = '/ahd/step3-sa';
  static const String ahdStep4Sa = '/ahd/step4-sa';
  static const String ahdStep5Sa = '/ahd/step5-sa';
  static const String ahdStep6Sa = '/ahd/step6-sa';
  static const String ahdStep7Sa = '/ahd/step7-sa';
  static const String ahdStep8Sa = '/ahd/step8-sa';
  static const String ahdStep9Sa = '/ahd/step9-sa';
  static const String ahdStep10Sa = '/ahd/step10-sa';
  static const String ahdAddAttorney = '/ahd/add-attorney';
  static const String ahdAddSubstituteDm = '/ahd/add-substitute-dm';
  static const String ahdAddNtDecisionMaker = '/ahd/add-nt-decision-maker';
  static const String ahdAddNtPrimaryDecisionMaker = '/ahd/add-nt-primary-decision-maker';
  static const String ahdStep3Tas = '/ahd/step3-tas';
  static const String ahdStep4Tas = '/ahd/step4-tas';
  static const String ahdStep5Tas = '/ahd/step5-tas';
  static const String ahdStep6Tas = '/ahd/step6-tas';
  static const String ahdStep7Tas = '/ahd/step7-tas';
  static const String ahdStep8Tas = '/ahd/step8-tas';
  static const String ahdStep9Tas = '/ahd/step9-tas';
  static const String ahdStep10Tas = '/ahd/step10-tas';
  static const String ahdStep11Tas = '/ahd/step11-tas';
  static const String ahdAddTasWitness = '/ahd/add-tas-witness';
  static const String ahdStep3Nt = '/ahd/step3-nt';
  static const String ahdStep4Nt = '/ahd/step4-nt';
  static const String ahdStep5Nt = '/ahd/step5-nt';
  static const String ahdStep6Nt = '/ahd/step6-nt';
  static const String ahdStep7Nt = '/ahd/step7-nt';
  static const String ahdStep3Act = '/ahd/step3-act';
  static const String ahdStep4Act = '/ahd/step4-act';
  static const String ahdStep2Qld = '/ahd/step2-qld';
  static const String ahdStep3Qld = '/ahd/step3-qld';
  static const String ahdStep4Qld = '/ahd/step4-qld';
  static const String ahdStep5Qld = '/ahd/step5-qld';
  static const String ahdStep6Qld = '/ahd/step6-qld';
  static const String ahdStep7Qld = '/ahd/step7-qld';
  static const String ahdStep8Qld = '/ahd/step8-qld';
  static const String ahdStep9Qld = '/ahd/step9-qld';

  // Will sign route
  static const String willSign = '/will-sign';

  // Executor Checklist route
  static const String executorChecklist = '/executor-checklist';

  // Probate routes
  static const String probateRequest = '/probate/request';

  // Profile routes
  static const String editProfile = '/profile/edit';
  static const String notifications = '/notifications';
  
  // Route observer for detecting when screens become visible again
  static final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();
  
  static final GoRouter router = GoRouter(
    navigatorKey: main_file.navigatorKey,
    initialLocation: splash,
    debugLogDiagnostics: true,
    observers: [NavigationLogger(), routeObserver],
    errorBuilder: (context, state) {
      // Extract feature name from path for better UX
      final path = state.uri.path;
      String? featureName;
      if (path.contains('allocation')) {
        featureName = 'Allocation';
      } else if (path.contains('assets')) {
        featureName = 'Assets';
      } else if (path.contains('executor')) {
        featureName = 'Executor';
      } else if (path.contains('review')) {
        featureName = 'Review';
      }
      return ComingSoonScreen(featureName: featureName);
    },
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: signIn,
        builder: (context, state) => const SignInScreen(),
      ),
      GoRoute(
        path: signUp,
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: otpVerification,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return OtpVerificationScreen(
            sessionId: extra['sessionId'] as String,
            email: extra['email'] as String,
          );
        },
      ),
      GoRoute(
        path: mfaSetup,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MfaSetupScreen(
            session: extra['session'] as String,
            qrData: extra['qrData'] as String,
          );
        },
      ),
      GoRoute(
        path: mfaChallenge,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return MfaChallengeScreen(
            session: extra['session'] as String,
            challengeType: extra['challengeType'] as ChallengeType,
          );
        },
      ),
      GoRoute(
        path: home,
        builder: (context, state) => HomeScreen(
          initialIndex: state.extra as int? ?? 0,
        ),
      ),
      GoRoute(
        path: willOnboarding,
        builder: (context, state) => const BasicDetailsScreen(),
      ),
      GoRoute(
        path: basicDetails,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return BasicDetailsScreen(previousData: extra);
        },
      ),
      GoRoute(
        path: relationshipStatus,
        builder: (context, state) => const RelationshipStatusScreen(),
      ),
      GoRoute(
        path: familyDetails,
        builder: (context, state) => const FamilyDetailsScreen(),
      ),
      GoRoute(
        path: addFormerPartner,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is FormerPartnerData) {
            return AddFormerPartnerScreen(existingData: extra);
          }
          if (extra is Map<String, dynamic>) {
            return AddFormerPartnerScreen(
              partnerType: extra['partnerType'] as String?,
            );
          }
          return const AddFormerPartnerScreen();
        },
      ),
      GoRoute(
        path: addDependent,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is DependentPersonData) {
            return AddDependentScreen(existingDependent: extra);
          } else if (extra is PetData) {
            return AddDependentScreen(existingPet: extra);
          }
          return const AddDependentScreen();
        },
      ),
      GoRoute(
        path: beneficiaries,
        builder: (context, state) => const BeneficiariesScreen(),
      ),
      GoRoute(
        path: addBeneficiary,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is BeneficiaryPersonData) {
            return AddBeneficiaryScreen(existingData: extra);
          }
          return const AddBeneficiaryScreen();
        },
      ),
      GoRoute(
        path: charitySelection,
        builder: (context, state) => const CharitySelectionScreen(),
      ),
      GoRoute(
        path: listAssets,
        builder: (context, state) => const ListAssetsScreen(),
      ),
      GoRoute(
        path: addAsset,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is WillAsset) {
            return AddAssetScreen(existingAsset: extra);
          }
          return const AddAssetScreen();
        },
      ),
      GoRoute(
        path: giftsQuestion,
        builder: (context, state) => const GiftsQuestionScreen(),
      ),
      GoRoute(
        path: giftBeneficiaries,
        builder: (context, state) => const ListGiftBeneficiariesScreen(),
      ),
      GoRoute(
        path: selectGiftRecipient,
        builder: (context, state) => const SelectGiftRecipientScreen(),
      ),
      GoRoute(
        path: addGiftRecipient,
        builder: (context, state) {
          final extra = state.extra;
          return AddGiftRecipientScreen(existingData: extra);
        },
      ),
      GoRoute(
        path: assetAllocation,
        builder: (context, state) => const AssetAllocationScreen(),
      ),
      GoRoute(
        path: addBackupBeneficiary,
        builder: (context, state) {
          final args = state.extra as BackupBeneficiaryArgs;
          return AddBackupBeneficiaryScreen(args: args);
        },
      ),
      GoRoute(
        path: executors,
        builder: (context, state) => const ExecutorsScreen(),
      ),
      GoRoute(
        path: addPersonalExecutor,
        builder: (context, state) {
          final executorId = state.uri.queryParameters['executorId'];
          final isPrimary = state.uri.queryParameters['isPrimary'] != 'false';
          print('🔍 Router: executorId = $executorId, isPrimary = $isPrimary');
          return AddPersonalExecutorScreen(
            executorId: executorId,
            isPrimary: isPrimary,
          );
        },
      ),
      GoRoute(
        path: addWillcloudExecutor,
        builder: (context, state) {
          // extra can be a Map with 'isPrimary', or null (defaults to true)
          final extra = state.extra;
          final isPrimary = extra is Map ? (extra['isPrimary'] as bool? ?? true) : true;
          return AddWillcloudExecutorScreen(isPrimary: isPrimary);
        },
      ),
      GoRoute(
        path: witness,
        builder: (context, state) => const WitnessScreen(),
      ),
      GoRoute(
        path: addWitness,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is WitnessData) {
            return AddWitnessScreen(existingWitness: extra);
          }
          return const AddWitnessScreen();
        },
      ),
      GoRoute(
        path: review,
        builder: (context, state) => const ReviewScreen(),
      ),
      GoRoute(
        path: subscriptionSelection,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userName = extra?['userName'] as String? ?? 'James';
          final willId = extra?['willId'] as String?;
          return SubscriptionSelectionPage(
            userName: userName,
            willId: willId,
          );
        },
      ),
      GoRoute(
        path: legalReview,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final userName = extra?['userName'] as String? ?? 'Mary Wilson';
          final willId = extra?['willId'] as String? ?? '';
          final regenerate = extra?['regenerate'] as bool? ?? false;
          return LegalReviewScreen(
            userName: userName,
            willId: willId,
            regenerate: regenerate,
          );
        },
      ),
      GoRoute(
        path: assignLawyer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final willId = extra?['willId'] as String? ?? '';
          return AssignLawyerScreen(willId: willId);
        },
      ),
      GoRoute(
        path: addWillcloudLawyer,
        builder: (context, state) => const AddWillcloudLawyerScreen(),
      ),
      GoRoute(
        path: addPersonalLawyer,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final willId = extra?['willId'] as String? ?? '';
          final existingLawyer = extra?['existingLawyer'] as AssignedLawyer?;
          return AddPersonalLawyerScreen(
            willId: willId,
            existingLawyer: existingLawyer,
          );
        },
      ),
      GoRoute(
        path: notificationRecipient,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final willId = extra?['willId'] as String? ?? '';
          return NotificationRecipientScreen(willId: willId);
        },
      ),
      GoRoute(
        path: willTimeline,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WillTimelineScreen(
            willId: extra['willId'] as String,
            fullName: extra['fullName'] as String,
            status: extra['status'] as String,
            invitedRole: extra['invitedRole'] as String?,
          );
        },
      ),
      GoRoute(
        path: willComments,
        builder: (context, state) {
          final willId = state.extra as String;
          return WillCommentsScreen(willId: willId);
        },
      ),
      // Funeral routes
      GoRoute(
        path: funeralPreferences,
        builder: (context, state) {
          final flowData = state.extra as FuneralFlowData?;
          return FuneralPreferencesScreen(existingData: flowData);
        },
      ),
      GoRoute(
        path: funeralServiceDetails,
        builder: (context, state) {
          final flowData = state.extra as FuneralFlowData;
          return FuneralServiceDetailsScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: funeralLegacyMessages,
        builder: (context, state) {
          final flowData = state.extra as FuneralFlowData;
          return FuneralLegacyMessagesScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: funeralRecipients,
        builder: (context, state) {
          final flowData = state.extra as FuneralFlowData?;
          return FuneralRecipientsScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: funeralAddDirectionPerson,
        builder: (context, state) {
          return const FuneralAddDirectionPersonScreen();
        },
      ),
      // Digital Vault routes
      GoRoute(
        path: digitalVaultInstructions,
        builder: (context, state) => const ClosureInstructionsScreen(),
      ),
      GoRoute(
        path: vaultAddMessage,
        builder: (context, state) {
          final existing = state.extra as VaultItem?;
          return AddMessageScreen(existingItem: existing);
        },
      ),
      GoRoute(
        path: vaultAddMessageRecipient,
        builder: (context, state) {
          return const AddMessageRecipientScreen();
        },
      ),
      GoRoute(
        path: vaultAddPhysicalAsset,
        builder: (context, state) {
          final existing = state.extra as VaultItem?;
          return AddPhysicalAssetScreen(existingItem: existing);
        },
      ),
      GoRoute(
        path: vaultAddLiability,
        builder: (context, state) {
          final existing = state.extra as VaultItem?;
          return AddLiabilityScreen(existingItem: existing);
        },
      ),
      GoRoute(
        path: vaultAddContact,
        builder: (context, state) {
          final existing = state.extra as VaultItem?;
          return AddContactScreen(existingItem: existing);
        },
      ),
      // Profile routes
      GoRoute(
        path: editProfile,
        builder: (context, state) {
          final userProfile = state.extra as UserProfile;
          return EditProfileScreen(userProfile: userProfile);
        },
      ),
      GoRoute(
        path: notifications,
        builder: (context, state) => const NotificationsScreen(),
      ),
      // POA routes
      GoRoute(
        path: poaBasicDetails,
        builder: (context, state) {
          final flowData = (state.extra as PoaFlowData?) ?? const PoaFlowData();
          return PoaBasicDetailsScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaMatters,
        builder: (context, state) {
          final flowData = (state.extra as PoaFlowData?) ?? const PoaFlowData();
          return PoaMattersScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaAttorneys,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaAttorneysScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaSuccessiveAttorneys,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaSuccessiveAttorneysScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaEnduringGuardian,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaEnduringGuardianScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaSubstituteEnduringGuardian,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaSubstituteEnduringGuardianScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep2,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep2Factory.forState(flowData);
        },
      ),
      GoRoute(
        path: poaStep3Act,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep3Act(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep4Act,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep4Act(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep5Act,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep5Act(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep3Tas,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep3Tas(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep4Tas,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep4Tas(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep5Tas,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep5Tas(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep3Sa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep3Sa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep4Sa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep4Sa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep5Sa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep5Sa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep3Nt,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep3Nt(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep4Nt,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep4Nt(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep5Nt,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep5Nt(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep3Wa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep3Wa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep4Wa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep4Wa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep5Wa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep5Wa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaStep6Wa,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaStep6Wa(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaCommencement,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaCommencementScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaViewsWishes,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaViewsWishesScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaTermsInstructions,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaTermsInstructionsScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaNotification,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaNotificationScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaReviewNsw,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaReviewNswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaAssistanceSigning,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaAssistanceSigningScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaQldMerged,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaQldMergedScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaQldFinal,
        builder: (context, state) {
          final flowData = state.extra as PoaFlowData;
          return PoaQldFinalScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: poaAddAttorney,
        builder: (context, state) {
          final existing = state.extra as PoaPersonData?;
          return PoaAddAttorneyScreen(existing: existing);
        },
      ),
      // AHD routes
      GoRoute(
        path: ahdPersonalDetails,
        builder: (context, state) {
          final flowData = (state.extra as AhdFlowData?) ?? const AhdFlowData();
          return AhdPersonalDetailsScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep2,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          // Route to state-specific Step 2
          if (flowData.state?.toLowerCase() == 'victoria') {
            return AhdStep2VicScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'new_south_wales') {
            return AhdStep2NswScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'western_australia') {
            return AhdStep2WaScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'south_australia') {
            return AhdStep2SaScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'northern_territory') {
            return AhdStep2NtScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'tasmania') {
            return AhdStep2TasScreen(flowData: flowData);
          }
          if (flowData.state?.toLowerCase() == 'act') {
            return AhdStep2ActScreen(flowData: flowData);
          }
          return AhdStep2Screen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Vic,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3VicScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Vic,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4VicScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Vic,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5VicScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Vic,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6VicScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Nsw,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3NswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Nsw,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4NswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Nsw,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5NswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Nsw,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6NswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Nsw,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7NswScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep2Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep2WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Wa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7WaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep2Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep2SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep8Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep8SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep9Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep9SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep10Sa,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep10SaScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Nt,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3NtScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Nt,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4NtScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Nt,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5NtScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Nt,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6NtScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Nt,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7NtScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Act,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3ActScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Act,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4ActScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep8Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep8TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep9Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep9TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep10Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep10TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep11Tas,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep11TasScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdAddTasWitness,
        builder: (context, state) {
          final existing = state.extra as AhdAttorneyData?;
          return AhdAddTasWitnessScreen(existing: existing);
        },
      ),
      GoRoute(
        path: ahdStep2Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep2QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep3Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep3QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep4Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep4QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep5Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep5QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep6Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep6QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep7Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep7QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep8Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep8QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdStep9Qld,
        builder: (context, state) {
          final flowData = state.extra as AhdFlowData;
          return AhdStep9QldScreen(flowData: flowData);
        },
      ),
      GoRoute(
        path: ahdAddSubstituteDm,
        builder: (context, state) {
          final existing = state.extra as AhdAttorneyData?;
          return AhdAddSubstituteDmScreen(existing: existing);
        },
      ),
      GoRoute(
        path: ahdAddNtDecisionMaker,
        builder: (context, state) {
          final existing = state.extra as AhdAttorneyData?;
          return AhdAddNtDecisionMakerScreen(existing: existing);
        },
      ),
      GoRoute(
        path: ahdAddNtPrimaryDecisionMaker,
        builder: (context, state) {
          final existing = state.extra as AhdAttorneyData?;
          return AhdAddNtDecisionMakerScreen(
              existing: existing, isPrimary: true);
        },
      ),
      GoRoute(
        path: ahdAddAttorney,
        builder: (context, state) {
          final existing = state.extra as AhdAttorneyData?;
          return AhdAddAttorneyScreen(existing: existing);
        },
      ),
      GoRoute(
        path: willSign,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return WillSignWebViewPage(
            signUrl: extra['signUrl'] as String,
            onSigningComplete: extra['onSigningComplete'] as VoidCallback,
            onClosed: extra['onClosed'] as VoidCallback?,
          );
        },
      ),
      GoRoute(
        path: executorChecklist,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>;
          return ExecutorChecklistScreen(
            willId: extra['willId'] as String,
            executorName: extra['executorName'] as String? ?? 'Executor',
            testatorName: extra['testatorName'] as String? ?? '',
          );
        },
      ),
      GoRoute(
        path: probateRequest,
        builder: (context, state) => const ProbateRequestScreen(),
      ),
    ],
  );
}

/// Navigation logger to track route changes
class NavigationLogger extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      print('🔀 NAVIGATION[PUSH] => FROM: ${previousRoute?.settings.name ?? 'null'} TO: ${route.settings.name}');
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      print('🔙 NAVIGATION[POP] => FROM: ${route.settings.name} TO: ${previousRoute?.settings.name ?? 'null'}');
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (kDebugMode) {
      print('❌ NAVIGATION[REMOVE] => ROUTE: ${route.settings.name}');
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (kDebugMode) {
      print('🔄 NAVIGATION[REPLACE] => OLD: ${oldRoute?.settings.name ?? 'null'} NEW: ${newRoute?.settings.name}');
    }
  }
}
