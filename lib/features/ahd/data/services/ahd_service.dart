import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/ahd_dto.dart';
import '../models/ahd_models.dart';

class AhdService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch existing AHD data for the current user.
  /// Returns the raw JSON map so callers can parse into either
  /// [AhdCreateDto] (new) or [AhdFlowData] (legacy).
  Future<AhdResponse> getAhdDetails() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.ahd);
      final data = response.data;

      if (data == null || data['data'] == null) {
        return const AhdResponse(isSuccess: true, message: 'No AHD data found');
      }

      final ahdJson = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : null;

      return AhdResponse(
        isSuccess: true,
        message: 'Success',
        data: ahdJson,
      );
    } catch (e) {
      print('Error fetching AHD details: $e');
      return const AhdResponse(
        isSuccess: false,
        message: 'Failed to fetch AHD details',
      );
    }
  }

  /// Fetch existing AHD data and parse into a typed [AhdCreateDto].
  Future<AhdCreateDto?> getAhdDto() async {
    final response = await getAhdDetails();
    if (!response.isSuccess || response.data == null) return null;
    return AhdCreateDto.fromJson(response.data!);
  }

  /// Create or update AHD using the new [AhdCreateDto].
  /// Preferred path — produces exact API payloads matching web.
  Future<AhdResponse> createOrUpdateAhdDto(AhdCreateDto dto) async {
    try {
      final body = dto.toJson();
      print('AHD POST DATA (DTO): $body');

      final response = await _apiClient.post(
        ApiEndpoints.ahd,
        data: body,
      );

      print('AHD UPDATE STATUS: ${response.statusCode}');
      print('AHD UPDATE RESPONSE: ${response.data}');

      return AhdResponse(
        isSuccess: true,
        message: 'Success',
        data: response.data?['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error updating AHD: $e');
      return AhdResponse(
        isSuccess: false,
        message: 'Failed to save advance health directive',
      );
    }
  }

  /// Create or update AHD using legacy [AhdFlowData].
  /// Kept for backwards compatibility during migration — screens that
  /// haven't been rewritten yet still call this.
  Future<AhdResponse> createOrUpdateAhd(AhdFlowData flowData) async {
    try {
      final body = flowData.toApiJson();
      print('AHD POST DATA: $body');

      final response = await _apiClient.post(
        ApiEndpoints.ahd,
        data: body,
      );

      print('AHD UPDATE STATUS: ${response.statusCode}');
      print('AHD UPDATE RESPONSE: ${response.data}');

      return AhdResponse(
        isSuccess: true,
        message: 'Success',
        data: response.data?['data'] as Map<String, dynamic>?,
      );
    } catch (e) {
      print('Error updating AHD: $e');
      return AhdResponse(
        isSuccess: false,
        message: 'Failed to save advance health directive',
      );
    }
  }
}

class AhdResponse {
  final bool isSuccess;
  final String message;
  final Map<String, dynamic>? data;

  const AhdResponse({
    required this.isSuccess,
    required this.message,
    this.data,
  });
}
