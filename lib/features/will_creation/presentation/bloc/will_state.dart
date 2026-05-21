import 'package:equatable/equatable.dart';
import '../../data/models/will_models.dart';
import '../../data/models/family_models.dart';
import '../../data/models/gift_models.dart';
import '../../data/models/will_detail_models.dart';

abstract class WillState extends Equatable {
  const WillState();

  @override
  List<Object?> get props => [];
}

class WillInitial extends WillState {
  const WillInitial();
}

class WillLoading extends WillState {
  const WillLoading();
}

class WillSuccess extends WillState {
  final String message;
  final dynamic data;

  const WillSuccess({required this.message, this.data});

  @override
  List<Object?> get props => [message, data];
}

class WillError extends WillState {
  final String message;

  const WillError(this.message);

  @override
  List<Object?> get props => [message];
}

// ==================== SPECIFIC STATES ====================

class InitialWillLoaded extends WillState {
  final InitialWillData willData;

  const InitialWillLoaded(this.willData);

  @override
  List<Object?> get props => [willData];
}

class MedicalProofUploaded extends WillState {
  final String fileName;

  const MedicalProofUploaded(this.fileName);

  @override
  List<Object?> get props => [fileName];
}

class FamilyInitialLoaded extends WillState {
  final FamilyInitialData familyData;

  const FamilyInitialLoaded(this.familyData);

  @override
  List<Object?> get props => [familyData];
}

class PartnersLoaded extends WillState {
  final List<PartnerData> partners;

  const PartnersLoaded(this.partners);

  @override
  List<Object?> get props => [partners];
}

// Legacy alias for backward compatibility
typedef FormerPartnersLoaded = PartnersLoaded;

class DependentPersonsLoaded extends WillState {
  final List<DependentPersonData> dependents;

  const DependentPersonsLoaded(this.dependents);

  @override
  List<Object?> get props => [dependents];
}

class PetsLoaded extends WillState {
  final List<PetData> pets;

  const PetsLoaded(this.pets);

  @override
  List<Object?> get props => [pets];
}

class BeneficiaryPersonsLoaded extends WillState {
  final List<BeneficiaryPersonData> beneficiaries;

  const BeneficiaryPersonsLoaded(this.beneficiaries);

  @override
  List<Object?> get props => [beneficiaries];
}

class WillPersonsLoaded extends WillState {
  final List<WillPersonData> persons;

  const WillPersonsLoaded(this.persons);

  @override
  List<Object?> get props => [persons];
}

class AllWillsLoaded extends WillState {
  final List<WillSummary> wills;

  const AllWillsLoaded(this.wills);

  @override
  List<Object?> get props => [wills];
}

class InvitedWillsLoaded extends WillState {
  final List<WillSummary> wills;

  const InvitedWillsLoaded(this.wills);

  @override
  List<Object?> get props => [wills];
}

class CharitiesLoaded extends WillState {
  final List<CharityData> charities;

  const CharitiesLoaded(this.charities);

  @override
  List<Object?> get props => [charities];
}

class BeneficiaryCharitiesLoaded extends WillState {
  final List<BeneficiaryCharityData> charities;

  const BeneficiaryCharitiesLoaded(this.charities);

  @override
  List<Object?> get props => [charities];
}

class AssetsLoaded extends WillState {
  final List<WillAsset> assets;

  const AssetsLoaded(this.assets);

  @override
  List<Object?> get props => [assets];
}

/// Asset type catalog loaded from /will/assets
class AssetTypeCatalogLoaded extends WillState {
  final List<AssetTypeItem> assetTypes;

  const AssetTypeCatalogLoaded(this.assetTypes);

  @override
  List<Object?> get props => [assetTypes];
}

/// Institutions for an asset type loaded from /will/asset-institutions
class AssetInstitutionsLoaded extends WillState {
  final List<InstitutionItem> institutions;

  const AssetInstitutionsLoaded(this.institutions);

  @override
  List<Object?> get props => [institutions];
}

class GiftCreated extends WillState {
  final GiftData gift;

  const GiftCreated(this.gift);

  @override
  List<Object?> get props => [gift];
}

class GiftsLoaded extends WillState {
  final List<GiftData> gifts;

  const GiftsLoaded(this.gifts);

  @override
  List<Object?> get props => [gifts];
}

class GiftBeneficiariesLoaded extends WillState {
  final List<GiftBeneficiaryData> beneficiaries;

  const GiftBeneficiariesLoaded(this.beneficiaries);

  @override
  List<Object?> get props => [beneficiaries];
}

// ==================== WITNESS STATES ====================

class WitnessesLoaded extends WillState {
  final List<WitnessData> witnesses;

  const WitnessesLoaded(this.witnesses);

  @override
  List<Object?> get props => [witnesses];
}

class WitnessAdded extends WillState {
  final WitnessData witness;

  const WitnessAdded(this.witness);

  @override
  List<Object?> get props => [witness];
}

class WitnessUpdated extends WillState {
  final WitnessData witness;

  const WitnessUpdated(this.witness);

  @override
  List<Object?> get props => [witness];
}

class WitnessDeleted extends WillState {
  const WitnessDeleted();

  @override
  List<Object?> get props => [];
}

// ==================== EXECUTOR STATES ====================

class BeneficiaryAllocationLoaded extends WillState {
  final BeneficiaryAllocationResponse allocation;

  const BeneficiaryAllocationLoaded(this.allocation);

  @override
  List<Object?> get props => [allocation];
}

class ExecutorsLoaded extends WillState {
  final List<ExecutorData> executors;

  const ExecutorsLoaded(this.executors);

  @override
  List<Object?> get props => [executors];
}

class ExecutorAllocated extends WillState {
  final ExecutorData executor;

  const ExecutorAllocated(this.executor);

  @override
  List<Object?> get props => [executor];
}

class ExecutorDeallocated extends WillState {
  const ExecutorDeallocated();

  @override
  List<Object?> get props => [];
}

class ProfessionalExecutorAdded extends WillState {
  const ProfessionalExecutorAdded();

  @override
  List<Object?> get props => [];
}

// ==================== EXECUTION RULES STATES ====================

class ExecutionRulesAdded extends WillState {
  const ExecutionRulesAdded();

  @override
  List<Object?> get props => [];
}

// ==================== WILL COMPLETE DETAIL STATES ====================

class WillCompleteDetailLoaded extends WillState {
  final WillCompleteDetail detail;

  const WillCompleteDetailLoaded(this.detail);

  @override
  List<Object?> get props => [detail];
}

// ==================== COMMENTS STATES ====================

class CommentsLoaded extends WillState {
  final List<WillComment> comments;

  const CommentsLoaded(this.comments);

  @override
  List<Object?> get props => [comments];
}

class CommentAdded extends WillState {
  final int commentId;

  const CommentAdded(this.commentId);

  @override
  List<Object?> get props => [commentId];
}
