import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/will_repository.dart';
import '../models/will_models.dart';
import '../models/family_models.dart';
import '../models/gift_models.dart';
import '../models/will_detail_models.dart';

class WillRepositoryImpl implements WillRepository {
  final ApiClient _apiClient;

  WillRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==================== WILL INITIAL ====================

  @override
  Future<WillResponse<InitialWillData>> createInitialWill(InitialWillRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.willInitial,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => InitialWillData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<InitialWillData>> getInitialWill(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willInitial,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) => InitialWillData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<MedicalProofUploadData>> uploadMedicalProof({
    required String willId,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      'medical_document': await MultipartFile.fromFile(
        filePath,
        filename: fileName,
      ),
    });

    final response = await _apiClient.post(
      ApiEndpoints.medicalProof,
      data: formData,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) => MedicalProofUploadData.fromJson(data),
    );
  }

  // ==================== FAMILY INITIAL ====================

  @override
  Future<WillResponse<FamilyInitialData>> createFamilyInitial(FamilyInitialRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.familyInitial,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => FamilyInitialData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<FamilyInitialData>> getFamilyInitial(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.familyInitial,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) => FamilyInitialData.fromJson(data),
    );
  }

  // ==================== PARTNER (CURRENT/DEFACTO/FORMER) ====================

  @override
  Future<WillResponse<PartnerData>> addPartner(PartnerRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.partner,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => PartnerData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<PartnerData>>> getPartners(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.partner,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => PartnerData.fromJson(item)).toList();
        }
        return <PartnerData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deletePartner({
    required String willId,
    required String partnerId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.deletePartner(willId, partnerId),
    );

    return WillResponse.fromJson(response.data, null);
  }

  // Legacy aliases for backward compatibility
  @override
  Future<WillResponse<PartnerData>> addFormerPartner(PartnerRequest request) => addPartner(request);
  
  @override
  Future<WillResponse<List<PartnerData>>> getFormerPartners(String willId) => getPartners(willId);
  
  @override
  Future<WillResponse<void>> deleteFormerPartner({
    required String willId,
    required String partnerId,
  }) => deletePartner(willId: willId, partnerId: partnerId);

  // ==================== DEPENDENT PERSON ====================

  @override
  Future<WillResponse<DependentPersonData>> addDependentPerson(DependentPersonRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.dependentPerson,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => DependentPersonData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<DependentPersonData>>> getDependentPersons(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.dependentPerson,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => DependentPersonData.fromJson(item)).toList();
        }
        return <DependentPersonData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteDependentPerson({
    required String willId,
    required String dependentId,
    String? guardianId,
  }) async {
    // Use the generic Will Person delete endpoint
    final response = await _apiClient.delete(
      ApiEndpoints.deleteWillPerson(willId, dependentId),
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== PET ====================

  @override
  Future<WillResponse<PetData>> addPet(PetRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.pet,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => PetData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<PetData>>> getPets(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.pet,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => PetData.fromJson(item)).toList();
        }
        return <PetData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deletePet({
    required String willId,
    required String petId,
    required String caretakerId,
  }) async {
    final queryParams = {
      'will_id': willId,
      'will_pet_id': petId,
      'care_taker_id': caretakerId,
    };
    
    final response = await _apiClient.delete(
      ApiEndpoints.pet,
      queryParameters: queryParams,
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== BENEFICIARY PERSON ====================

  @override
  Future<WillResponse<BeneficiaryPersonData>> addBeneficiaryPerson(BeneficiaryPersonRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.beneficiaryPerson,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => BeneficiaryPersonData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<BeneficiaryPersonData>>> getBeneficiaryPersons(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.beneficiaryPerson,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) {
            // API returns {beneficiary: {...}, guardian: {...}} structure
            final beneficiaryData = item['beneficiary'] as Map<String, dynamic>? ?? item;
            final guardianData = item['guardian'] as Map<String, dynamic>?;
            
            // Merge guardian into beneficiary data for parsing
            final mergedData = Map<String, dynamic>.from(beneficiaryData);
            if (guardianData != null) {
              mergedData['guardian'] = guardianData;
            }
            
            return BeneficiaryPersonData.fromJson(mergedData);
          }).toList();
        }
        return <BeneficiaryPersonData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteBeneficiaryPerson({
    required String willId,
    required String beneficiaryId,
  }) async {
    // Use the generic Will Person delete endpoint
    final response = await _apiClient.delete(
      ApiEndpoints.deleteWillPerson(willId, beneficiaryId),
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== CHARITY ====================

  @override
  Future<WillResponse<CharityData>> createCharity(CharityRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.charity,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => CharityData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<CharityData>>> getAllCharities() async {
    final response = await _apiClient.get(ApiEndpoints.charity);

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => CharityData.fromJson(item)).toList();
        }
        return <CharityData>[];
      },
    );
  }

  // ==================== BENEFICIARY CHARITY ====================

  @override
  Future<WillResponse<BeneficiaryCharityData>> addBeneficiaryCharity(BeneficiaryCharityRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.beneficiaryCharity,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => BeneficiaryCharityData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<BeneficiaryCharityData>>> getBeneficiaryCharities(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.beneficiaryCharity,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        // API returns {charities: [...]} so extract the array
        final charitiesList = data is Map ? (data['charities'] ?? data) : data;
        if (charitiesList is List) {
          return charitiesList.map((item) => BeneficiaryCharityData.fromJson(item)).toList();
        }
        return <BeneficiaryCharityData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteBeneficiaryCharity({
    required String willId,
    required String beneficiaryCharityId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.beneficiaryCharity,
      queryParameters: {
        'will_id': willId,
        'beneficiary_charity_id': beneficiaryCharityId,
      },
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== WILL ASSET ====================

  @override
  Future<WillResponse<WillAsset>> addWillAsset(WillAssetRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.willAsset,
      data: request.toJson(),
    );

    // API returns empty data on create success, handle it gracefully
    try {
      return WillResponse.fromJson(
        response.data,
        (data) {
          // Check if data is actually empty/null
          if (data == null || 
              data == '' || 
              (data is Map && data.isEmpty) ||
              (data is String && data.isEmpty)) {
            // Return a minimal placeholder since API doesn't return the created asset
            return WillAsset(
              id: '',
              willId: request.willId,
              assetType: request.assetType,
              institution: request.institution,
              description: request.description,
            );
          }
          return WillAsset.fromJson(data);
        },
      );
    } catch (e) {
      // If parsing fails but we got a success response, create a success response manually
      if (response.data['status'] == 'success') {
        return WillResponse<WillAsset>(
          status: 'success',
          message: response.data['message'],
          data: WillAsset(
            id: '',
            willId: request.willId,
            assetType: request.assetType,
            institution: request.institution,
            description: request.description,
          ),
        );
      }
      rethrow;
    }
  }

  @override
  Future<WillResponse<List<WillAsset>>> getWillAssets(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willAsset,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => WillAsset.fromJson(item)).toList();
        }
        return <WillAsset>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteAsset({
    required String willId,
    required String assetId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.willAsset,
      queryParameters: {
        'will_id': willId,
        'asset_id': assetId,
      },
    );

    return WillResponse.fromJson(
      response.data,
      (_) => null,
    );
  }

  @override
  Future<WillResponse<List<AssetTypeItem>>> getAssetTypeCatalog() async {
    final response = await _apiClient.get(ApiEndpoints.willAssetsCatalog);

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => AssetTypeItem.fromJson(item)).toList();
        }
        return <AssetTypeItem>[];
      },
    );
  }

  @override
  Future<WillResponse<List<InstitutionItem>>> getAssetInstitutions(String assetTypeId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willAssetInstitutions,
      queryParameters: {'asset_id': assetTypeId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => InstitutionItem.fromJson(item)).toList();
        }
        return <InstitutionItem>[];
      },
    );
  }

  // ==================== GIFT ====================

  @override
  Future<WillResponse<GiftData>> createGift(GiftRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.willGift,
      data: request.toJson(),
    );

    // Handle empty data response from API
    final responseData = response.data;
    final dataField = responseData['data'];
    
    // Check if data is null, empty string, or empty object
    final bool hasValidData = dataField != null && 
                              dataField != '' && 
                              dataField.toString().trim().isNotEmpty &&
                              (dataField is! Map || dataField.isNotEmpty);

    return WillResponse<GiftData>(
      status: responseData['status'] as String,
      message: responseData['message'] as String?,
      data: hasValidData ? GiftData.fromJson(dataField) : null,
    );
  }

  @override
  Future<WillResponse<List<GiftData>>> getGifts(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willGift,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => GiftData.fromJson(item)).toList();
        }
        return <GiftData>[];
      },
    );
  }

  // ==================== GIFT BENEFICIARY ====================

  @override
  Future<WillResponse<dynamic>> addGiftBeneficiary(GiftBeneficiaryRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.giftBeneficiary,
      data: request.toJson(),
    );

    // API returns {beneficiary_id: xxx}, not a full GiftBeneficiaryData object
    return WillResponse.fromJson(
      response.data,
      (data) => data, // Return raw data
    );
  }

  @override
  Future<WillResponse<List<GiftBeneficiaryData>>> getGiftBeneficiaries(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.giftBeneficiary,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => GiftBeneficiaryData.fromJson(item)).toList();
        }
        return <GiftBeneficiaryData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteGiftBeneficiary({
    required String willId,
    required String beneficiaryId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.giftBeneficiary,
      queryParameters: {
        'will_id': willId,
        'beneficiary_id': beneficiaryId,
      },
    );
    return WillResponse.fromJson(response.data, (_) => null);
  }

  // ==================== WILL ALLOCATION ====================

  @override
  Future<WillResponse<void>> setBeneficiaryAllocation(BeneficiaryAllocationRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.willAllocation,
      data: request.toJson(),
    );

    return WillResponse.fromJson(response.data, null);
  }

  @override
  Future<WillResponse<BeneficiaryAllocationResponse>> getBeneficiaryAllocation(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willAllocation,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) => BeneficiaryAllocationResponse.fromJson(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
      ),
    );
  }

  // ==================== WITNESS ====================

  @override
  Future<WillResponse<WitnessData>> addWitness(WitnessRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.witness,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => WitnessData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<WitnessData>>> getWitnesses(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.witness,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => WitnessData.fromJson(item)).toList();
        }
        return <WitnessData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteWitness({
    required String willId,
    required String witnessId,
  }) async {
    // Use the generic Will Person delete endpoint
    final response = await _apiClient.delete(
      ApiEndpoints.deleteWillPerson(willId, witnessId),
    );

    return WillResponse<void>(
      status: response.data['status'] as String,
      message: response.data['message'] as String?,
      data: null,
    );
  }

  // ==================== EXECUTOR ====================

  @override
  Future<WillResponse<ExecutorData>> allocateExecutor(ExecutorRequest request) async {
    print('👥 ALLOCATING EXECUTOR: willId=${request.willId}, beneficiaryId=${request.beneficiaryId}');
    final requestJson = request.toJson();
    print('👥 REQUEST JSON: $requestJson');
    
    final response = await _apiClient.post(
      ApiEndpoints.executorAllocate,
      data: requestJson,
    );

    print('👥 ALLOCATE RESPONSE: ${response.data}');

    return WillResponse.fromJson(
      response.data,
      (data) => ExecutorData.fromJson(data),
    );
  }

  @override
  Future<WillResponse<List<ExecutorData>>> getExecutors(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.executor,
      queryParameters: {'will_id': willId},
    );

    print('🔍 Raw response.data type: ${response.data.runtimeType}');
    print('🔍 Raw response.data: ${response.data}');

    return WillResponse.fromJson(
      response.data,
      (data) {
        print('🔍 Parsing data, type: ${data.runtimeType}');
        print('🔍 Data content: $data');
        
        if (data is Map<String, dynamic>) {
          final List<ExecutorData> allExecutors = [];
          
          // Parse personal executors
          if (data['personal_executors'] != null && data['personal_executors'] is List) {
            print('🔍 Found ${(data['personal_executors'] as List).length} personal executors');
            final personalExecutors = (data['personal_executors'] as List)
                .map((item) {
                  // Add will_id to the item for parsing
                  final itemWithWillId = Map<String, dynamic>.from(item);
                  if (!itemWithWillId.containsKey('will_id')) {
                    itemWithWillId['will_id'] = willId;
                  }
                  return ExecutorData.fromJson(itemWithWillId);
                })
                .toList();
            allExecutors.addAll(personalExecutors);
          }
          
          // Parse professional executors
          if (data['professional_executors'] != null && data['professional_executors'] is List) {
            print('🔍 Found ${(data['professional_executors'] as List).length} professional executors');
            final professionalExecutors = (data['professional_executors'] as List)
                .map((item) {
                  print('🔍 Parsing professional executor: $item');
                  // Add will_id to the item for parsing
                  final itemWithWillId = Map<String, dynamic>.from(item);
                  if (!itemWithWillId.containsKey('will_id')) {
                    itemWithWillId['will_id'] = willId;
                  }
                  print('🔍 Item with will_id: $itemWithWillId');
                  final executor = ExecutorData.fromJson(itemWithWillId);
                  print('🔍 Parsed executor: ${executor.executor.firstName} ${executor.executor.lastName}, isProfessional: ${executor.isProfessional}');
                  return executor;
                })
                .toList();
            allExecutors.addAll(professionalExecutors);
          }
          
          print('🔍 Total executors parsed: ${allExecutors.length}');
          return allExecutors;
        }
        print('🔍 Data is not a Map, returning empty list');
        return <ExecutorData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deallocateExecutor({
    required String willId,
    required String executorId,
  }) async {
    // Use the generic Will Person delete endpoint
    final response = await _apiClient.delete(
      ApiEndpoints.deleteWillPerson(willId, executorId),
    );

    return WillResponse.fromJson(response.data, null);
  }

  @override
  Future<WillResponse<void>> addProfessionalExecutor({
    required String userId,
    required String willId,
    bool isPrimary = true,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.professionalExecutor,
      data: {
        'user_id': userId,
        'will_id': willId,
        'is_primary': isPrimary,
      },
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== EXECUTION RULES ====================

  @override
  Future<WillResponse<void>> addExecutionRules(ExecutionRuleRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.executionRule,
      data: request.toJson(),
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== ALL WILLS ====================

  @override
  Future<WillResponse<List<WillSummary>>> getAllWills({bool isInvited = false}) async {
    final response = await _apiClient.get(
      ApiEndpoints.allWills,
      queryParameters: {'is_invited': isInvited},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => WillSummary.fromJson(item)).toList();
        }
        return <WillSummary>[];
      },
    );
  }

  // ==================== WILL COMPLETE DETAIL ====================

  @override
  Future<WillResponse<WillCompleteDetail>> getWillCompleteDetail(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willCompleteDetail(willId),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => WillCompleteDetail.fromJson(data),
    );
  }

  // ==================== COMMENTS ====================

  @override
  Future<WillResponse<List<WillComment>>> getWillComments(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.documentComments(willId),
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data.map((item) => WillComment.fromJson(item)).toList();
        }
        return <WillComment>[];
      },
    );
  }

  @override
  Future<WillResponse<AddCommentResponse>> addWillComment(AddCommentRequest request) async {
    final response = await _apiClient.post(
      ApiEndpoints.documentComment,
      data: request.toJson(),
    );

    return WillResponse.fromJson(
      response.data,
      (data) => AddCommentResponse.fromJson(data),
    );
  }

  // ==================== WILL PERSONS ====================

  @override
  Future<WillResponse<List<WillPersonData>>> getWillPersons(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.willPersons,
      queryParameters: {'will_id': willId},
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data
              .map((item) => WillPersonData.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <WillPersonData>[];
      },
    );
  }

  @override
  Future<WillResponse<void>> deleteWillPerson({
    required String willId,
    required String personRoleId,
  }) async {
    final response = await _apiClient.delete(
      ApiEndpoints.deleteWillPerson(willId, personRoleId),
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== WILL LOCATION ====================

  @override
  Future<WillResponse<void>> updateWillLocation({
    required String willId,
    required String location,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.updateWillLocation,
      data: {
        'will_id': willId,
        'location': location,
      },
    );

    return WillResponse.fromJson(response.data, null);
  }

  // ==================== NOTIFICATION RECIPIENTS ====================

  @override
  Future<WillResponse<List<WillUserData>>> getWillUsersByRoles(
    String willId,
    List<String> roles,
  ) async {
    final response = await _apiClient.get(
      ApiEndpoints.willUsers(willId, roles),
    );

    return WillResponse.fromJson(
      response.data,
      (data) {
        if (data is List) {
          return data
              .map((item) => WillUserData.fromJson(item as Map<String, dynamic>))
              .toList();
        }
        return <WillUserData>[];
      },
    );
  }

  @override
  Future<WillResponse<String>> sendNotificationRecipients(
    String willId,
    List<int> userIds,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.willNotification,
      data: {
        'will_id': willId,
        'will_users': userIds,
      },
    );

    return WillResponse.fromJson(
      response.data,
      (data) => data?.toString() ?? '',
    );
  }
}
