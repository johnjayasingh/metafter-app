import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_exceptions.dart';
import '../../data/models/family_models.dart';
import '../../data/models/will_models.dart';
import '../../data/models/will_detail_models.dart';
import '../../domain/repositories/will_repository.dart';
import 'will_event.dart';
import 'will_state.dart';

class WillBloc extends Bloc<WillEvent, WillState> {
  final WillRepository repository;
  
  // Cached wills list to persist across navigation
  List<WillSummary> _cachedWills = [];
  List<WillSummary> get cachedWills => _cachedWills;

  WillBloc({required this.repository}) : super(const WillInitial()) {
    // ==================== RESET STATE HANDLER ====================
    on<ResetWillStateEvent>(_onResetWillState);
    
    // ==================== INITIAL WILL HANDLERS ====================
    on<CreateInitialWillEvent>(_onCreateInitialWill);
    on<GetInitialWillEvent>(_onGetInitialWill);
    on<UploadMedicalProofEvent>(_onUploadMedicalProof);

    // ==================== FAMILY INITIAL HANDLERS ====================
    on<CreateFamilyInitialEvent>(_onCreateFamilyInitial);
    on<GetFamilyInitialEvent>(_onGetFamilyInitial);

    // ==================== PARTNER HANDLERS (CURRENT/DEFACTO/FORMER) ====================
    on<AddPartnerEvent>(_onAddPartner);
    on<GetPartnersEvent>(_onGetPartners);
    on<DeletePartnerEvent>(_onDeletePartner);

    // ==================== DEPENDENT PERSON HANDLERS ====================
    on<AddDependentPersonEvent>(_onAddDependentPerson);
    on<GetDependentPersonsEvent>(_onGetDependentPersons);
    on<DeleteDependentPersonEvent>(_onDeleteDependentPerson);

    // ==================== PET HANDLERS ====================
    on<AddPetEvent>(_onAddPet);
    on<GetPetsEvent>(_onGetPets);
    on<DeletePetEvent>(_onDeletePet);

    // ==================== BENEFICIARY PERSON HANDLERS ====================
    on<AddBeneficiaryPersonEvent>(_onAddBeneficiaryPerson);
    on<GetBeneficiaryPersonsEvent>(_onGetBeneficiaryPersons);
    on<DeleteBeneficiaryPersonEvent>(_onDeleteBeneficiaryPerson);

    // ==================== WILL PERSONS HANDLERS ====================
    on<GetWillPersonsEvent>(_onGetWillPersons);

    // ==================== CHARITY HANDLERS ====================
    on<GetCharitiesEvent>(_onGetCharities);
    on<AddBeneficiaryCharityEvent>(_onAddBeneficiaryCharity);
    on<GetBeneficiaryCharitiesEvent>(_onGetBeneficiaryCharities);
    on<DeleteBeneficiaryCharityEvent>(_onDeleteBeneficiaryCharity);

    // ==================== ASSET HANDLERS ====================
    on<AddAssetEvent>(_onAddAsset);
    on<GetAssetsEvent>(_onGetAssets);
    on<DeleteAssetEvent>(_onDeleteAsset);
    on<GetAssetTypeCatalogEvent>(_onGetAssetTypeCatalog);
    on<GetAssetInstitutionsEvent>(_onGetAssetInstitutions);

    // ==================== GIFT HANDLERS ====================
    on<CreateGiftEvent>(_onCreateGift);
    on<GetGiftsEvent>(_onGetGifts);
    on<AddGiftBeneficiaryEvent>(_onAddGiftBeneficiary);
    on<GetGiftBeneficiariesEvent>(_onGetGiftBeneficiaries);
    on<DeleteGiftBeneficiaryEvent>(_onDeleteGiftBeneficiary);

    // ==================== WITNESS HANDLERS ====================
    on<GetWitnessesEvent>(_onGetWitnesses);
    on<AddWitnessEvent>(_onAddWitness);
    on<UpdateWitnessEvent>(_onUpdateWitness);
    on<DeleteWitnessEvent>(_onDeleteWitness);

    // ==================== ALLOCATION HANDLERS ====================
    on<SetBeneficiaryAllocationEvent>(_onSetBeneficiaryAllocation);
    on<GetBeneficiaryAllocationEvent>(_onGetBeneficiaryAllocation);

    // ==================== EXECUTOR HANDLERS ====================
    on<GetExecutorsEvent>(_onGetExecutors);
    on<AllocateExecutorEvent>(_onAllocateExecutor);
    on<DeallocateExecutorEvent>(_onDeallocateExecutor);

    // ==================== EXECUTION RULES HANDLERS ====================
    on<AddExecutionRulesEvent>(_onAddExecutionRules);

    // ==================== PROFESSIONAL EXECUTOR HANDLERS ====================
    on<AddProfessionalExecutorEvent>(_onAddProfessionalExecutor);

    // ==================== ALL WILLS HANDLERS ====================
    on<GetAllWillsEvent>(_onGetAllWills);
    on<RefreshWillsEvent>(_onRefreshWills);
    on<GetInvitedWillsEvent>(_onGetInvitedWills);
    on<RefreshInvitedWillsEvent>(_onRefreshInvitedWills);

    // ==================== WILL COMPLETE DETAIL HANDLERS ====================
    on<GetWillCompleteDetailEvent>(_onGetWillCompleteDetail);

    // ==================== COMMENTS HANDLERS ====================
    on<GetWillCommentsEvent>(_onGetWillComments);
    on<AddWillCommentEvent>(_onAddWillComment);
  }

  // ==================== RESET STATE ====================

  void _onResetWillState(
    ResetWillStateEvent event,
    Emitter<WillState> emit,
  ) {
    emit(const WillInitial());
  }

  // ==================== INITIAL WILL ====================

  Future<void> _onCreateInitialWill(
    CreateInitialWillEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.createInitialWill(event.request);
      emit(WillSuccess(message: response.message ?? 'Success', data: response.data));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetInitialWill(
    GetInitialWillEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getInitialWill(event.willId);
      emit(InitialWillLoaded(response.data!));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onUploadMedicalProof(
    UploadMedicalProofEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.uploadMedicalProof(
        willId: event.willId,
        filePath: event.filePath,
        fileName: event.fileName,
      );
      if (response.isSuccess) {
        emit(MedicalProofUploaded(response.data!.file));
      } else {
        emit(WillError(response.message ?? 'Failed to upload medical proof'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== FAMILY INITIAL ====================

  Future<void> _onCreateFamilyInitial(
    CreateFamilyInitialEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.createFamilyInitial(event.request);
      emit(WillSuccess(message: response.message ?? 'Success', data: response.data));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetFamilyInitial(
    GetFamilyInitialEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getFamilyInitial(event.willId);
      emit(FamilyInitialLoaded(response.data!));
    } catch (e) {
      // If family initial data doesn't exist yet (404), emit default empty data
      // instead of showing an error - this is expected for new wills
      debugPrint('Family initial fetch failed: $e');
      emit(FamilyInitialLoaded(const FamilyInitialData(
        canIncludeFormerPartner: false,
      )));
    }
  }

  // ==================== PARTNER (CURRENT/DEFACTO/FORMER) ====================

  Future<void> _onAddPartner(
    AddPartnerEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addPartner(event.request);
      if (response.isSuccess) {
        final partnerType = event.request.partner.partnerType;
        final typeLabel = PartnerType.getDisplayName(partnerType);
        emit(WillSuccess(message: '$typeLabel added successfully'));
        // After successfully adding, fetch the updated list
        final listResponse = await repository.getPartners(event.request.willId);
        emit(PartnersLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add partner'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetPartners(
    GetPartnersEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getPartners(event.willId);
      emit(PartnersLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeletePartner(
    DeletePartnerEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deletePartner(
        willId: event.willId,
        partnerId: event.partnerId,
      );
      emit(const WillSuccess(message: 'Partner deleted successfully'));
      // After successfully deleting, fetch the updated list
      final listResponse = await repository.getPartners(event.willId);
      emit(PartnersLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== DEPENDENT PERSON ====================

  Future<void> _onAddDependentPerson(
    AddDependentPersonEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addDependentPerson(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Dependent added successfully'));
        // After successfully adding a dependent, fetch the updated list
        final listResponse = await repository.getDependentPersons(event.request.willId);
        emit(DependentPersonsLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add dependent'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetDependentPersons(
    GetDependentPersonsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getDependentPersons(event.willId);
      emit(DependentPersonsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteDependentPerson(
    DeleteDependentPersonEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deleteDependentPerson(
        willId: event.willId,
        dependentId: event.dependentId,
        guardianId: event.guardianId,
      );
      emit(const WillSuccess(message: 'Dependent deleted successfully'));
      // After successfully deleting, fetch the updated list
      final listResponse = await repository.getDependentPersons(event.willId);
      emit(DependentPersonsLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== PET ====================

  Future<void> _onAddPet(
    AddPetEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addPet(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Pet added successfully'));
        // After successfully adding a pet, fetch the updated list
        final listResponse = await repository.getPets(event.request.willId);
        emit(PetsLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add pet'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetPets(
    GetPetsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getPets(event.willId);
      emit(PetsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeletePet(
    DeletePetEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deletePet(
        willId: event.willId,
        petId: event.petId,
        caretakerId: event.caretakerId,
      );
      emit(const WillSuccess(message: 'Pet deleted successfully'));
      // After successfully deleting, fetch the updated list
      final listResponse = await repository.getPets(event.willId);
      emit(PetsLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== BENEFICIARY PERSON ====================

  Future<void> _onAddBeneficiaryPerson(
    AddBeneficiaryPersonEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addBeneficiaryPerson(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Beneficiary added successfully'));
        // After successfully adding a beneficiary, fetch the updated list
        final listResponse = await repository.getBeneficiaryPersons(event.request.willId);
        emit(BeneficiaryPersonsLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add beneficiary'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetBeneficiaryPersons(
    GetBeneficiaryPersonsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getBeneficiaryPersons(event.willId);
      emit(BeneficiaryPersonsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteBeneficiaryPerson(
    DeleteBeneficiaryPersonEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deleteBeneficiaryPerson(
        willId: event.willId,
        beneficiaryId: event.beneficiaryId,
      );
      emit(const WillSuccess(message: 'Beneficiary deleted successfully'));
      // After successfully deleting, fetch the updated list
      final listResponse = await repository.getBeneficiaryPersons(event.willId);
      emit(BeneficiaryPersonsLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== WILL PERSONS ====================

  Future<void> _onGetWillPersons(
    GetWillPersonsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getWillPersons(event.willId);
      emit(WillPersonsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== ALL WILLS ====================

  Future<void> _onGetAllWills(
    GetAllWillsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getAllWills(isInvited: event.isInvited);
      _cachedWills = response.data ?? [];
      emit(AllWillsLoaded(_cachedWills));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onRefreshWills(
    RefreshWillsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      // Don't show loading state to avoid UI flicker
      final response = await repository.getAllWills(isInvited: event.isInvited);
      _cachedWills = response.data ?? [];
      emit(AllWillsLoaded(_cachedWills));
    } catch (e) {
      // Silently fail on refresh, keep showing cached data
      debugPrint('Failed to refresh wills: $e');
      if (_cachedWills.isNotEmpty) {
        emit(AllWillsLoaded(_cachedWills));
      }
    }
  }

  // Cached invited wills for silent refresh
  List<WillSummary> _cachedInvitedWills = [];

  Future<void> _onGetInvitedWills(
    GetInvitedWillsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getAllWills(isInvited: true);
      _cachedInvitedWills = response.data ?? [];
      emit(InvitedWillsLoaded(_cachedInvitedWills));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onRefreshInvitedWills(
    RefreshInvitedWillsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      // Don't show loading state to avoid UI flicker
      final response = await repository.getAllWills(isInvited: true);
      _cachedInvitedWills = response.data ?? [];
      emit(InvitedWillsLoaded(_cachedInvitedWills));
    } catch (e) {
      // Silently fail on refresh, keep showing cached data
      debugPrint('Failed to refresh invited wills: $e');
      if (_cachedInvitedWills.isNotEmpty) {
        emit(InvitedWillsLoaded(_cachedInvitedWills));
      }
    }
  }

  // ==================== CHARITIES ====================

  Future<void> _onGetCharities(
    GetCharitiesEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getAllCharities();
      emit(CharitiesLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onAddBeneficiaryCharity(
    AddBeneficiaryCharityEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addBeneficiaryCharity(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Charity added successfully'));
        final listResponse = await repository.getBeneficiaryCharities(event.request.willId);
        emit(BeneficiaryCharitiesLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add charity'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetBeneficiaryCharities(
    GetBeneficiaryCharitiesEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getBeneficiaryCharities(event.willId);
      emit(BeneficiaryCharitiesLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteBeneficiaryCharity(
    DeleteBeneficiaryCharityEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deleteBeneficiaryCharity(
        willId: event.willId,
        beneficiaryCharityId: event.charityId,
      );
      emit(const WillSuccess(message: 'Charity deleted successfully'));
      final listResponse = await repository.getBeneficiaryCharities(event.willId);
      emit(BeneficiaryCharitiesLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== ASSETS ====================

  Future<void> _onAddAsset(
    AddAssetEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addWillAsset(event.request);
      if (response.status == 'success') {
        // Asset created successfully, reload the list
        final listResponse = await repository.getWillAssets(event.request.willId);
        if (listResponse.isSuccess) {
          emit(AssetsLoaded(listResponse.data ?? []));
        } else {
          // List fetch failed, but asset was created
          emit(const WillSuccess(message: 'Asset added successfully'));
        }
      } else {
        emit(WillError(response.message ?? 'Failed to add asset'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetAssets(
    GetAssetsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getWillAssets(event.willId);
      emit(AssetsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteAsset(
    DeleteAssetEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.deleteAsset(
        willId: event.willId,
        assetId: event.assetId,
      );
      
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Asset deleted successfully'));
        // Reload the asset list
        final listResponse = await repository.getWillAssets(event.willId);
        emit(AssetsLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to delete asset'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetAssetTypeCatalog(
    GetAssetTypeCatalogEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(WillLoading());
      final response = await repository.getAssetTypeCatalog();
      emit(AssetTypeCatalogLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetAssetInstitutions(
    GetAssetInstitutionsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(WillLoading());
      final response = await repository.getAssetInstitutions(event.assetTypeId);
      emit(AssetInstitutionsLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== GIFT HANDLERS ====================

  Future<void> _onCreateGift(
    CreateGiftEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.createGift(event.request);
      
      // Handle empty or null data from API
      if (response.data != null) {
        emit(GiftCreated(response.data!));
      } else {
        // If data is null/empty but status is success, emit success state
        emit(WillSuccess(message: response.message ?? 'Gift created successfully'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetGifts(
    GetGiftsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      print('🎁 BLOC: _onGetGifts called with willId: ${event.willId}');
      emit(const WillLoading());
      final response = await repository.getGifts(event.willId);
      print('🎁 BLOC: Repository returned ${response.data?.length ?? 0} gifts');
      if (response.data != null) {
        for (var gift in response.data!) {
          print('🎁 BLOC: Gift ${gift.id} - type: ${gift.giftType}, receiver: ${gift.giftReceiver?.firstName} ${gift.giftReceiver?.lastName}');
        }
      }
      emit(GiftsLoaded(response.data ?? []));
      print('🎁 BLOC: Emitted GiftsLoaded state');
    } catch (e) {
      print('🎁 BLOC: Error in _onGetGifts: $e');
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onAddGiftBeneficiary(
    AddGiftBeneficiaryEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addGiftBeneficiary(event.request);
      emit(WillSuccess(message: 'Gift recipient added successfully', data: response.data));
      // Reload the list so the gifts screen refreshes
      final listResponse = await repository.getGiftBeneficiaries(event.request.willId);
      emit(GiftBeneficiariesLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetGiftBeneficiaries(
    GetGiftBeneficiariesEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getGiftBeneficiaries(event.willId);
      emit(GiftBeneficiariesLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteGiftBeneficiary(
    DeleteGiftBeneficiaryEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deleteGiftBeneficiary(
        willId: event.willId,
        beneficiaryId: event.beneficiaryId,
      );
      emit(const WillSuccess(message: 'Gift recipient deleted successfully'));
      // Reload the list
      final listResponse = await repository.getGiftBeneficiaries(event.willId);
      emit(GiftBeneficiariesLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== WITNESS HANDLERS ====================

  Future<void> _onGetWitnesses(
    GetWitnessesEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getWitnesses(event.willId);
      emit(WitnessesLoaded(response.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onAddWitness(
    AddWitnessEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final request = WitnessRequest(
        willId: event.willId,
        witness: event.witness,
      );
      final response = await repository.addWitness(request);
      if (response.isSuccess) {
        emit(WitnessAdded(event.witness));
        // Reload the list
        final listResponse = await repository.getWitnesses(event.willId);
        emit(WitnessesLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to add witness'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onUpdateWitness(
    UpdateWitnessEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final request = WitnessRequest(
        willId: event.willId,
        witness: event.witness,
      );
      final response = await repository.addWitness(request);
      if (response.isSuccess) {
        emit(WitnessUpdated(event.witness));
        // Reload the list
        final listResponse = await repository.getWitnesses(event.willId);
        emit(WitnessesLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to update witness'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeleteWitness(
    DeleteWitnessEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deleteWitness(
        willId: event.willId,
        witnessId: event.witnessId,
      );
      emit(const WitnessDeleted());
      // Reload the list
      final listResponse = await repository.getWitnesses(event.willId);
      emit(WitnessesLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== ALLOCATION HANDLERS ====================

  Future<void> _onSetBeneficiaryAllocation(
    SetBeneficiaryAllocationEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.setBeneficiaryAllocation(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Allocation saved successfully'));
      } else {
        emit(WillError(response.message ?? 'Failed to save allocation'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onGetBeneficiaryAllocation(
    GetBeneficiaryAllocationEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getBeneficiaryAllocation(event.willId);
      if (response.isSuccess && response.data != null) {
        emit(BeneficiaryAllocationLoaded(response.data!));
      } else {
        // No allocation data yet — emit empty response
        emit(BeneficiaryAllocationLoaded(BeneficiaryAllocationResponse(
          willId: event.willId,
          allocation: [],
          isDivideEqually: false,
        )));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== EXECUTOR HANDLERS ====================

  Future<void> _onGetExecutors(
    GetExecutorsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      print('🎯 BLoC: GetExecutorsEvent received, will_id: ${event.willId}');
      emit(const WillLoading());
      print('🎯 BLoC: WillLoading emitted, calling repository...');
      final response = await repository.getExecutors(event.willId);
      print('🎯 BLoC: Repository returned, response.data: ${response.data}');
      print('🎯 BLoC: response.data?.length: ${response.data?.length}');
      print('🎯 BLoC: About to emit ExecutorsLoaded with ${response.data?.length ?? 0} executors');
      emit(ExecutorsLoaded(response.data ?? []));
      print('🎯 BLoC: ExecutorsLoaded emitted successfully');
    } catch (e) {
      print('🎯 BLoC: ERROR - $e');
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onAllocateExecutor(
    AllocateExecutorEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.allocateExecutor(event.request);
      if (response.isSuccess && response.data != null) {
        emit(ExecutorAllocated(response.data!));
        // Reload the list
        final listResponse = await repository.getExecutors(event.request.willId);
        emit(ExecutorsLoaded(listResponse.data ?? []));
      } else {
        emit(WillError(response.message ?? 'Failed to allocate executor'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onDeallocateExecutor(
    DeallocateExecutorEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      await repository.deallocateExecutor(
        willId: event.willId,
        executorId: event.executorId,
      );
      emit(const WillSuccess(message: 'Executor removed successfully'));
      // Reload the list
      final listResponse = await repository.getExecutors(event.willId);
      emit(ExecutorsLoaded(listResponse.data ?? []));
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== EXECUTION RULES HANDLERS ====================

  Future<void> _onAddExecutionRules(
    AddExecutionRulesEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addExecutionRules(event.request);
      if (response.isSuccess) {
        emit(const WillSuccess(message: 'Execution rules added successfully'));
      } else {
        emit(WillError(response.message ?? 'Failed to add execution rules'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== PROFESSIONAL EXECUTOR HANDLERS ====================

  Future<void> _onAddProfessionalExecutor(
    AddProfessionalExecutorEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.addProfessionalExecutor(
        userId: event.userId,
        willId: event.willId,
        isPrimary: event.isPrimary,
      );
      if (response.isSuccess) {
        emit(const ProfessionalExecutorAdded());
      } else {
        emit(WillError(response.message ?? 'Failed to add professional executor'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== WILL COMPLETE DETAIL HANDLERS ====================

  Future<void> _onGetWillCompleteDetail(
    GetWillCompleteDetailEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getWillCompleteDetail(event.willId);
      if (response.isSuccess && response.data != null) {
        emit(WillCompleteDetailLoaded(response.data!));
      } else {
        emit(WillError(response.message ?? 'Failed to load will details'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  // ==================== COMMENTS HANDLERS ====================

  Future<void> _onGetWillComments(
    GetWillCommentsEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      emit(const WillLoading());
      final response = await repository.getWillComments(event.willId);
      if (response.isSuccess && response.data != null) {
        emit(CommentsLoaded(response.data!));
      } else {
        emit(WillError(response.message ?? 'Failed to load comments'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }

  Future<void> _onAddWillComment(
    AddWillCommentEvent event,
    Emitter<WillState> emit,
  ) async {
    try {
      final request = AddCommentRequest(
        willId: event.willId,
        comment: event.comment,
      );
      final response = await repository.addWillComment(request);
      if (response.isSuccess && response.data != null) {
        emit(CommentAdded(response.data!.commentId));
      } else {
        emit(WillError(response.message ?? 'Failed to add comment'));
      }
    } catch (e) {
      emit(WillError(getErrorMessage(e)));
    }
  }
}
