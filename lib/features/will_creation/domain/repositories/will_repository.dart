import '../../data/models/will_models.dart';
import '../../data/models/family_models.dart';
import '../../data/models/gift_models.dart';
import '../../data/models/will_detail_models.dart';

abstract class WillRepository {
  // ==================== WILL INITIAL ====================
  
  /// Create initial will details
  Future<WillResponse<InitialWillData>> createInitialWill(InitialWillRequest request);
  
  /// Get initial will details
  Future<WillResponse<InitialWillData>> getInitialWill(String willId);
  
  /// Upload medical proof document
  Future<WillResponse<MedicalProofUploadData>> uploadMedicalProof({
    required String willId,
    required String filePath,
    required String fileName,
  });
  
  // ==================== FAMILY INITIAL ====================
  
  /// Create/update family initial details
  Future<WillResponse<FamilyInitialData>> createFamilyInitial(FamilyInitialRequest request);
  
  /// Get family initial details by will ID
  Future<WillResponse<FamilyInitialData>> getFamilyInitial(String willId);
  
  // ==================== PARTNER (CURRENT/DEFACTO/FORMER) ====================
  
  /// Add or update partner (spouse, de facto, or former)
  Future<WillResponse<PartnerData>> addPartner(PartnerRequest request);
  
  /// Get all partners for a will
  Future<WillResponse<List<PartnerData>>> getPartners(String willId);
  
  /// Delete partner
  Future<WillResponse<void>> deletePartner({
    required String willId,
    required String partnerId,
  });
  
  // Legacy aliases for backward compatibility
  Future<WillResponse<PartnerData>> addFormerPartner(PartnerRequest request) => addPartner(request);
  Future<WillResponse<List<PartnerData>>> getFormerPartners(String willId) => getPartners(willId);
  Future<WillResponse<void>> deleteFormerPartner({
    required String willId,
    required String partnerId,
  }) => deletePartner(willId: willId, partnerId: partnerId);
  
  // ==================== DEPENDENT PERSON ====================
  
  /// Add dependent person
  Future<WillResponse<DependentPersonData>> addDependentPerson(DependentPersonRequest request);
  
  /// Get all dependent persons for a will
  Future<WillResponse<List<DependentPersonData>>> getDependentPersons(String willId);
  
  /// Delete dependent person
  Future<WillResponse<void>> deleteDependentPerson({
    required String willId,
    required String dependentId,
    String? guardianId,
  });
  
  // ==================== PET ====================
  
  /// Add pet
  Future<WillResponse<PetData>> addPet(PetRequest request);
  
  /// Get all pets for a will
  Future<WillResponse<List<PetData>>> getPets(String willId);
  
  /// Delete pet
  Future<WillResponse<void>> deletePet({
    required String willId,
    required String petId,
    required String caretakerId,
  });
  
  // ==================== BENEFICIARY PERSON ====================
  
  /// Add beneficiary person
  Future<WillResponse<BeneficiaryPersonData>> addBeneficiaryPerson(BeneficiaryPersonRequest request);
  
  /// Get all beneficiary persons for a will
  Future<WillResponse<List<BeneficiaryPersonData>>> getBeneficiaryPersons(String willId);
  
  /// Delete beneficiary person
  Future<WillResponse<void>> deleteBeneficiaryPerson({
    required String willId,
    required String beneficiaryId,
  });
  
  // ==================== CHARITY ====================
  
  /// Create charity
  Future<WillResponse<CharityData>> createCharity(CharityRequest request);
  
  /// Get all charities
  Future<WillResponse<List<CharityData>>> getAllCharities();
  
  // ==================== BENEFICIARY CHARITY ====================
  
  /// Add beneficiary charity
  Future<WillResponse<BeneficiaryCharityData>> addBeneficiaryCharity(BeneficiaryCharityRequest request);
  
  /// Get all beneficiary charities for a will
  Future<WillResponse<List<BeneficiaryCharityData>>> getBeneficiaryCharities(String willId);
  
  /// Delete beneficiary charity
  Future<WillResponse<void>> deleteBeneficiaryCharity({
    required String willId,
    required String beneficiaryCharityId,
  });
  
  // ==================== WILL ASSET ====================
  
  /// Add will asset
  Future<WillResponse<WillAsset>> addWillAsset(WillAssetRequest request);
  
  /// Get all assets for a will
  Future<WillResponse<List<WillAsset>>> getWillAssets(String willId);
  
  /// Delete will asset
  Future<WillResponse<void>> deleteAsset({
    required String willId,
    required String assetId,
  });
  
  /// Get asset type catalog (Property, Finance, etc.)
  Future<WillResponse<List<AssetTypeItem>>> getAssetTypeCatalog();
  
  /// Get institutions for an asset type
  Future<WillResponse<List<InstitutionItem>>> getAssetInstitutions(String assetTypeId);
  
  // ==================== GIFT ====================
  
  /// Create/update gift
  Future<WillResponse<GiftData>> createGift(GiftRequest request);
  
  /// Get all gifts for a will
  Future<WillResponse<List<GiftData>>> getGifts(String willId);
  
  // ==================== GIFT BENEFICIARY ====================
  
  /// Add gift beneficiary
  Future<WillResponse<dynamic>> addGiftBeneficiary(GiftBeneficiaryRequest request);
  
  /// Get all gift beneficiaries for a will
  Future<WillResponse<List<GiftBeneficiaryData>>> getGiftBeneficiaries(String willId);
  
  /// Delete gift beneficiary
  Future<WillResponse<void>> deleteGiftBeneficiary({
    required String willId,
    required String beneficiaryId,
  });
  
  // ==================== WILL ALLOCATION ====================
  
  /// Set beneficiary and charity allocations
  Future<WillResponse<void>> setBeneficiaryAllocation(BeneficiaryAllocationRequest request);
  
  /// Get beneficiary and charity allocations for a will
  Future<WillResponse<BeneficiaryAllocationResponse>> getBeneficiaryAllocation(String willId);
  
  // ==================== WITNESS ====================
  
  /// Add/update witness
  Future<WillResponse<WitnessData>> addWitness(WitnessRequest request);
  
  /// Get all witnesses for a will
  Future<WillResponse<List<WitnessData>>> getWitnesses(String willId);
  
  /// Delete a witness from a will
  Future<WillResponse<void>> deleteWitness({
    required String willId,
    required String witnessId,
  });
  
  // ==================== EXECUTOR ====================
  
  /// Allocate executor to will
  Future<WillResponse<ExecutorData>> allocateExecutor(ExecutorRequest request);
  
  /// Get all executors for a will
  Future<WillResponse<List<ExecutorData>>> getExecutors(String willId);
  
  /// Deallocate (remove) executor from will
  Future<WillResponse<void>> deallocateExecutor({
    required String willId,
    required String executorId,
  });
  
  /// Add professional executor to will
  Future<WillResponse<void>> addProfessionalExecutor({
    required String userId,
    required String willId,
    bool isPrimary = true,
  });
  
  // ==================== EXECUTION RULES ====================
  
  /// Add execution rules for will
  Future<WillResponse<void>> addExecutionRules(ExecutionRuleRequest request);
  
  // ==================== ALL WILLS ====================
  
  /// Get all wills for the current user
  /// [isInvited] - if true, returns wills where user is invited as witness/executor/lawyer
  Future<WillResponse<List<WillSummary>>> getAllWills({bool isInvited = false});
  
  // ==================== WILL COMPLETE DETAIL ====================
  
  /// Get complete will details including witness, lawyer, and documents
  Future<WillResponse<WillCompleteDetail>> getWillCompleteDetail(String willId);
  
  // ==================== COMMENTS ====================
  
  /// Get all comments for a will
  Future<WillResponse<List<WillComment>>> getWillComments(String willId);
  
  /// Add a comment to a will
  Future<WillResponse<AddCommentResponse>> addWillComment(AddCommentRequest request);
  
  // ==================== WILL PERSONS ====================

  /// Get all persons associated with a will
  Future<WillResponse<List<WillPersonData>>> getWillPersons(String willId);
  
  /// Generic delete method for any will person (witness, beneficiary, dependent, guardian, etc.)
  /// Uses the endpoint: DELETE /will/{will_id}/{will_person_role_id}/
  Future<WillResponse<void>> deleteWillPerson({
    required String willId,
    required String personRoleId,
  });

  // ==================== WILL LOCATION ====================
  
  /// Update will document location/address
  Future<WillResponse<void>> updateWillLocation({
    required String willId,
    required String location,
  });
  
  // ==================== NOTIFICATION RECIPIENTS ====================
  
  /// Get will users by roles (for notification recipients)
  Future<WillResponse<List<WillUserData>>> getWillUsersByRoles(
    String willId,
    List<String> roles,
  );
  
  /// Send notification to selected recipients about will status
  Future<WillResponse<String>> sendNotificationRecipients(
    String willId,
    List<int> userIds,
  );
}
