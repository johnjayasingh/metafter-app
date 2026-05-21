import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/profile_models.dart';

class ProfileService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch current user profile
  Future<ProfileResponse> getProfile() async {
    try {
      print('🌐 Fetching user profile');

      final response = await _apiClient.get(
        ApiEndpoints.userProfile,
      );

      print('📊 PROFILE FETCH STATUS: ${response.statusCode}');
      print('📄 PROFILE DATA: ${response.data}');

      return ProfileResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      print('❌ Error fetching profile: $e');
      print('📍 Stack trace: $stackTrace');
      return const ProfileResponse(
        status: 'failure',
        message: 'Failed to fetch profile',
      );
    }
  }

  /// Update user profile
  Future<ProfileResponse> updateProfile(UserProfileUpdateRequest request) async {
    try {
      print('🌐 Updating user profile');
      print('📤 UPDATE DATA: ${request.toJson()}');

      final response = await _apiClient.post(
        ApiEndpoints.updateProfile,
        data: request.toJson(),
      );

      print('📊 PROFILE UPDATE STATUS: ${response.statusCode}');
      print('📄 PROFILE UPDATE RESPONSE: ${response.data}');

      return ProfileResponse.fromJson(response.data);
    } catch (e, stackTrace) {
      print('❌ Error updating profile: $e');
      print('📍 Stack trace: $stackTrace');
      return const ProfileResponse(
        status: 'failure',
        message: 'Failed to update profile',
      );
    }
  }
}
