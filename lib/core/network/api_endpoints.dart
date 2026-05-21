import '../config/environment_config.dart';

class ApiEndpoints {
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  // Auth endpoints
  static const String signupBasic = '/user/signup/basic';
  static const String otpValidate = '/user/otp/validate';
  static const String loginBasic = '/user/login/basic';
  static const String mfaSetup = '/user/mfa/setup';  // First-time MFA setup
  static const String mfaValidate = '/user/mfa/validate';  // MFA challenge on login
  static const String logout = '/user/logout';
  static const String refreshToken = '/user/refresh-token';
  
  // User endpoints
  static const String userProfile = '/user/me';
  static const String updateProfile = '/user/me';
  static const String notifications = '/user/notifications';
  // Meeting endpoints
  static const String userMeetingCreate = '/user/meeting/create';
  static const String userMeetingJoin = '/user/meeting/join';
  static const String userMeetingStartRecording = '/user/meeting/start-recording';
  static const String userMeetingStopRecording = '/user/meeting/stop-recording';
  static const String userMeetingStop = '/user/meeting/stop';

  // Will endpoints
  static const String willInitial = '/will/initial';
  static String willInitialById(String willId) => '/will/initial/$willId';
  static const String willAsset = '/will/asset';
  static const String willAssetsCatalog = '/will/assets';  // Asset type catalog
  static const String willAssetInstitutions = '/will/asset-institutions';  // Institutions for asset type
  static const String willGift = '/will/gift';
  static const String willAllocation = '/will/beneficiary/allocation';
  static const String allWills = '/will/all';
  static const String medicalProof = '/will/medical-proof';
  
  // Family endpoints
  static const String familyInitial = '/will/family/initial';
  static String familyInitialById(String willId) => '/will/family/initial/$willId';
  
  // Partner endpoints (for current spouse, de facto, and former partners)
  static const String partner = '/will/family/partner';
  static String deletePartner(String willId, String partnerId) => 
      '/will/family/former-partner/$willId/$partnerId';
  
  // Legacy alias
  static const String formerPartner = partner;
  
  // Dependent Person endpoints
  static const String dependentPerson = '/will/family/dependent/person';
  
  // Pet endpoints
  static const String pet = '/will/family/dependent/pet';
  
  // Beneficiary Person endpoints
  static const String beneficiaryPerson = '/will/family/beneficiary/person';
  
  // Charity endpoints
  static const String charity = '/will/charity';
  
  // Beneficiary Charity endpoints
  static const String beneficiaryCharity = '/will/family/beneficiary/charity';
  
  // Gift Beneficiary endpoints
  static const String giftBeneficiary = '/will/gift/beneficiary';
  
  // Witness endpoints
  static const String witness = '/will/witness';
  
  // Executor endpoints
  static const String executorAllocate = '/will/executor/allocate';
  static const String executorDeallocate = '/will/executor/deallocate';
  static const String executor = '/will/executor';
  
  // Execution Rule endpoints
  static const String executionRule = '/will/execution/rule';
  
  // Document generation endpoints
  static String documentGenerate(String willId) => '/will/document/generate?will_id=$willId';
  static String willCompleteDetail(String willId) => '/will/complete-detail?will_id=$willId';
  
  // Comments endpoints
  static String documentComments(String willId) => '/will/document/comments?will_id=$willId';
  static const String documentComment = '/will/document/comment';
  
  // Business endpoints
  static const String lawFirms = '/business/law-firm';
  static String lawFirmMembers(String lawFirmId) => '/business/member?law_firm_id=$lawFirmId';
  
  // Professional Lawyer endpoints
  static const String professionalLawyer = '/will/professional-lawyer';
  static String lawyers(String willId) => '/will/lawyers?will_id=$willId';
  
  // Personal Lawyer endpoints
  static const String personalLawyer = '/will/personal-lawyer';
  
  // Will sign endpoint (returns signing URL)
  static String willSign(String willId) => '/will/sign?will_id=$willId';

  // Signed document upload endpoint
  static String uploadSignedDocument(String willId) => '/will/document/signed/upload?will_id=$willId';
  
  // Will Persons endpoint
  static const String willPersons = '/will/persons';
  
  // Generic Will Person delete endpoint
  // Used for deleting any will person (witness, beneficiary, dependent, guardian, etc.)
  static String deleteWillPerson(String willId, String personRoleId) => 
      '/will/$willId/$personRoleId/';

  // Professional Executor endpoints
  static const String professionalExecutor = '/will/professional-executor';

  // Will location update endpoint
  static const String updateWillLocation = '/will/location/update';
  
  // Digital Vault endpoints (unified API)
  static const String vaultAssets = '/vault/assets';
  static String vaultAsset(String assetId) => '/vault/assets/$assetId';
  static const String vaultPreferences = '/vault/preferences';
  static const String vaultFilesUpload = '/vault/files/upload';
  static String vaultFileDownload(String fileId) => '/vault/files/$fileId/download';
  static String vaultFile(String fileId) => '/vault/files/$fileId';
  static String vaultAssetFiles(String assetId) => '/vault/assets/$assetId/files';

  // Will data endpoints (for vault selection)
  static const String userWillAssets = '/user/will-assets';

  // Funeral endpoints
  static const String funeral = '/user/funeral';
  static const String funeralAttendees = '/user/funeral/attendees';
  static const String funeralLegacyVideo = '/user/funeral/legacy-video';
  static const String funeralMusic = '/user/funeral/music';
  static const String funeralScienceDonationInstitutions =
      '/user/funeral/science-donation-institutions';
  
  // Power of Attorney endpoints
  static const String powerOfAttorney = '/user/power-of-attorney';
  static const String attorneyForPoa = '/user/attorney-for-poa';
  static const String attorneysForPoa = '/user/attorneys-for-poa';
  static const String willPeople = '/user/will-people';
  static const String poaNotification = '/user/poa-notification';
  static String deleteAttorneyForPoa(int attorneyPoaId) =>
      '/user/attorney-for-poa/$attorneyPoaId';

  // Advance Health Directive endpoints
  static const String ahd = '/user/ahd';

  // Probate endpoint
  static const String probate = '/will/probate';

  // Executor Checklist endpoints
  static const String executorChecklist = '/will/executor-checklist';

  // Will notification endpoints
  static const String willNotification = '/will/user/notification';
  
  // Will users endpoint (for notification recipients)
  static String willUsers(String willId, List<String> roles) {
    final rolesParam = roles.join(',');
    return '/will/users?will_id=$willId&roles=$rolesParam';
  }
}
