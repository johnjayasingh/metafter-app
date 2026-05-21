import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/business_repository.dart';
import '../models/business_models.dart';

class BusinessRepositoryImpl implements BusinessRepository {
  final ApiClient _apiClient;

  BusinessRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  // ==================== LAW FIRMS ====================

  @override
  Future<LawFirmsResponse> getLawFirms() async {
    final response = await _apiClient.get(ApiEndpoints.lawFirms);
    return LawFirmsResponse.fromJson(response.data);
  }

  // ==================== LAWYERS ====================

  @override
  Future<LawyersResponse> getLawyers(String lawFirmId) async {
    final response = await _apiClient.get(
      ApiEndpoints.lawFirmMembers(lawFirmId),
    );
    return LawyersResponse.fromJson(response.data);
  }

  // ==================== PROFESSIONAL LAWYER ASSIGNMENT ====================

  @override
  Future<BusinessResponse<String>> assignProfessionalLawyer(
    AssignProfessionalLawyerRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.professionalLawyer,
      data: request.toJson(),
    );
    return BusinessResponse.fromJson(
      response.data,
      (data) => data?.toString() ?? '',
    );
  }

  @override
  Future<LawyersListResponse> getAssignedLawyers(String willId) async {
    final response = await _apiClient.get(
      ApiEndpoints.lawyers(willId),
    );
    return LawyersListResponse.fromJson(response.data);
  }

  // ==================== PERSONAL LAWYER ====================

  @override
  Future<BusinessResponse<String>> savePersonalLawyer(
    PersonalLawyerRequest request,
  ) async {
    final response = await _apiClient.post(
      ApiEndpoints.personalLawyer,
      data: request.toJson(),
    );
    return BusinessResponse.fromJson(
      response.data,
      (data) => data?.toString() ?? '',
    );
  }
}
