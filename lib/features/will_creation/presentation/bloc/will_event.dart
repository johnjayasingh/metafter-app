import 'package:equatable/equatable.dart';
import '../../data/models/will_models.dart';
import '../../data/models/family_models.dart';
import '../../data/models/gift_models.dart';
import '../../data/models/will_detail_models.dart';

abstract class WillEvent extends Equatable {
  const WillEvent();

  @override
  List<Object?> get props => [];
}

// ==================== RESET STATE EVENT ====================

/// Event to reset the WillBloc state to initial
/// Use this when navigating to a page to clear any stale loading states
class ResetWillStateEvent extends WillEvent {
  const ResetWillStateEvent();
}

// ==================== INITIAL WILL EVENTS ====================

class CreateInitialWillEvent extends WillEvent {
  final InitialWillRequest request;

  const CreateInitialWillEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetInitialWillEvent extends WillEvent {
  final String willId;

  const GetInitialWillEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class UploadMedicalProofEvent extends WillEvent {
  final String willId;
  final String filePath;
  final String fileName;

  const UploadMedicalProofEvent({
    required this.willId,
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [willId, filePath, fileName];
}

// ==================== FAMILY INITIAL EVENTS ====================

class CreateFamilyInitialEvent extends WillEvent {
  final FamilyInitialRequest request;

  const CreateFamilyInitialEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetFamilyInitialEvent extends WillEvent {
  final String willId;

  const GetFamilyInitialEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

// ==================== PARTNER EVENTS (CURRENT/DEFACTO/FORMER) ====================

class AddPartnerEvent extends WillEvent {
  final PartnerRequest request;

  const AddPartnerEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetPartnersEvent extends WillEvent {
  final String willId;

  const GetPartnersEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeletePartnerEvent extends WillEvent {
  final String willId;
  final String partnerId;

  const DeletePartnerEvent({
    required this.willId,
    required this.partnerId,
  });

  @override
  List<Object?> get props => [willId, partnerId];
}

// Legacy aliases for backward compatibility
typedef AddFormerPartnerEvent = AddPartnerEvent;
typedef GetFormerPartnersEvent = GetPartnersEvent;
typedef DeleteFormerPartnerEvent = DeletePartnerEvent;

// ==================== DEPENDENT PERSON EVENTS ====================

class AddDependentPersonEvent extends WillEvent {
  final DependentPersonRequest request;

  const AddDependentPersonEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetDependentPersonsEvent extends WillEvent {
  final String willId;

  const GetDependentPersonsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeleteDependentPersonEvent extends WillEvent {
  final String willId;
  final String dependentId;
  final String? guardianId;

  const DeleteDependentPersonEvent({
    required this.willId,
    required this.dependentId,
    this.guardianId,
  });

  @override
  List<Object?> get props => [willId, dependentId, guardianId];
}

// ==================== PET EVENTS ====================

class AddPetEvent extends WillEvent {
  final PetRequest request;

  const AddPetEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetPetsEvent extends WillEvent {
  final String willId;

  const GetPetsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeletePetEvent extends WillEvent {
  final String willId;
  final String petId;
  final String caretakerId;

  const DeletePetEvent({
    required this.willId,
    required this.petId,
    required this.caretakerId,
  });

  @override
  List<Object?> get props => [willId, petId, caretakerId];
}

// ==================== BENEFICIARY PERSON EVENTS ====================

class AddBeneficiaryPersonEvent extends WillEvent {
  final BeneficiaryPersonRequest request;

  const AddBeneficiaryPersonEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetBeneficiaryPersonsEvent extends WillEvent {
  final String willId;

  const GetBeneficiaryPersonsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeleteBeneficiaryPersonEvent extends WillEvent {
  final String willId;
  final String beneficiaryId;

  const DeleteBeneficiaryPersonEvent({
    required this.willId,
    required this.beneficiaryId,
  });

  @override
  List<Object?> get props => [willId, beneficiaryId];
}

// ==================== WILL PERSONS EVENTS ====================

class GetWillPersonsEvent extends WillEvent {
  final String willId;

  const GetWillPersonsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

// ==================== ALL WILLS EVENTS ====================

class GetAllWillsEvent extends WillEvent {
  final bool isInvited;
  const GetAllWillsEvent({this.isInvited = false});
  
  @override
  List<Object?> get props => [isInvited];
}

/// Silent refresh event that doesn't show loading state
/// Use this when returning to the home screen to refresh the list in background
class RefreshWillsEvent extends WillEvent {
  final bool isInvited;
  const RefreshWillsEvent({this.isInvited = false});
  
  @override
  List<Object?> get props => [isInvited];
}

/// Get invited wills where user is witness/executor/lawyer
class GetInvitedWillsEvent extends WillEvent {
  const GetInvitedWillsEvent();
}

/// Silent refresh for invited wills
class RefreshInvitedWillsEvent extends WillEvent {
  const RefreshInvitedWillsEvent();
}

// ==================== CHARITY EVENTS ====================

class GetCharitiesEvent extends WillEvent {
  const GetCharitiesEvent();
}

class AddBeneficiaryCharityEvent extends WillEvent {
  final BeneficiaryCharityRequest request;

  const AddBeneficiaryCharityEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetBeneficiaryCharitiesEvent extends WillEvent {
  final String willId;

  const GetBeneficiaryCharitiesEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeleteBeneficiaryCharityEvent extends WillEvent {
  final String willId;
  final String charityId;

  const DeleteBeneficiaryCharityEvent({
    required this.willId,
    required this.charityId,
  });

  @override
  List<Object?> get props => [willId, charityId];
}

// ==================== ASSET EVENTS ====================

class AddAssetEvent extends WillEvent {
  final WillAssetRequest request;

  const AddAssetEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetAssetsEvent extends WillEvent {
  final String willId;

  const GetAssetsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeleteAssetEvent extends WillEvent {
  final String willId;
  final String assetId;

  const DeleteAssetEvent({
    required this.willId,
    required this.assetId,
  });

  @override
  List<Object?> get props => [willId, assetId];
}

/// Fetch asset type catalog from /will/assets
class GetAssetTypeCatalogEvent extends WillEvent {
  const GetAssetTypeCatalogEvent();

  @override
  List<Object?> get props => [];
}

/// Fetch institutions for an asset type from /will/asset-institutions
class GetAssetInstitutionsEvent extends WillEvent {
  final String assetTypeId;

  const GetAssetInstitutionsEvent(this.assetTypeId);

  @override
  List<Object?> get props => [assetTypeId];
}

// ==================== GIFT EVENTS ====================

class CreateGiftEvent extends WillEvent {
  final GiftRequest request;

  const CreateGiftEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetGiftsEvent extends WillEvent {
  final String willId;

  const GetGiftsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

// ==================== GIFT BENEFICIARY EVENTS ====================

class AddGiftBeneficiaryEvent extends WillEvent {
  final GiftBeneficiaryRequest request;

  const AddGiftBeneficiaryEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetGiftBeneficiariesEvent extends WillEvent {
  final String willId;

  const GetGiftBeneficiariesEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class DeleteGiftBeneficiaryEvent extends WillEvent {
  final String willId;
  final String beneficiaryId;

  const DeleteGiftBeneficiaryEvent({
    required this.willId,
    required this.beneficiaryId,
  });

  @override
  List<Object?> get props => [willId, beneficiaryId];
}

// ==================== WITNESS EVENTS ====================

class GetWitnessesEvent extends WillEvent {
  final String willId;

  const GetWitnessesEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class AddWitnessEvent extends WillEvent {
  final String willId;
  final WitnessData witness;

  const AddWitnessEvent(this.willId, this.witness);

  @override
  List<Object?> get props => [willId, witness];
}

class UpdateWitnessEvent extends WillEvent {
  final String willId;
  final WitnessData witness;

  const UpdateWitnessEvent(this.willId, this.witness);

  @override
  List<Object?> get props => [willId, witness];
}

class DeleteWitnessEvent extends WillEvent {
  final String willId;
  final String witnessId;

  const DeleteWitnessEvent(this.willId, this.witnessId);

  @override
  List<Object?> get props => [willId, witnessId];
}

// ==================== ALLOCATION EVENTS ====================

class SetBeneficiaryAllocationEvent extends WillEvent {
  final BeneficiaryAllocationRequest request;

  const SetBeneficiaryAllocationEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class GetBeneficiaryAllocationEvent extends WillEvent {
  final String willId;

  const GetBeneficiaryAllocationEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

// ==================== EXECUTOR EVENTS ====================

class GetExecutorsEvent extends WillEvent {
  final String willId;

  const GetExecutorsEvent(this.willId);

  @override
  List<Object?> get props => [willId];
}

class AllocateExecutorEvent extends WillEvent {
  final ExecutorRequest request;

  const AllocateExecutorEvent(this.request);

  @override
  List<Object?> get props => [request];
}

class DeallocateExecutorEvent extends WillEvent {
  final String willId;
  final String executorId;

  const DeallocateExecutorEvent({
    required this.willId,
    required this.executorId,
  });

  @override
  List<Object?> get props => [willId, executorId];
}

// ==================== EXECUTION RULES EVENTS ====================

class AddExecutionRulesEvent extends WillEvent {
  final ExecutionRuleRequest request;

  const AddExecutionRulesEvent(this.request);

  @override
  List<Object?> get props => [request];
}

// ==================== PROFESSIONAL EXECUTOR EVENTS ====================

class AddProfessionalExecutorEvent extends WillEvent {
  final String userId;
  final String willId;
  final bool isPrimary;

  const AddProfessionalExecutorEvent({
    required this.userId,
    required this.willId,
    this.isPrimary = true,
  });

  @override
  List<Object?> get props => [userId, willId, isPrimary];
}

// ==================== WILL COMPLETE DETAIL EVENTS ====================

class GetWillCompleteDetailEvent extends WillEvent {
  final String willId;

  const GetWillCompleteDetailEvent({required this.willId});

  @override
  List<Object?> get props => [willId];
}

// ==================== COMMENTS EVENTS ====================

class GetWillCommentsEvent extends WillEvent {
  final String willId;

  const GetWillCommentsEvent({required this.willId});

  @override
  List<Object?> get props => [willId];
}

class AddWillCommentEvent extends WillEvent {
  final String willId;
  final String comment;

  const AddWillCommentEvent({
    required this.willId,
    required this.comment,
  });

  @override
  List<Object?> get props => [willId, comment];
}
