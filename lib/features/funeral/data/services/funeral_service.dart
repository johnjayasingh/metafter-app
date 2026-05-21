import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/funeral_models.dart';

class FuneralService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch funeral details for current user (includes attendees)
  Future<FuneralResponse<FuneralModel>> getFuneralDetails() async {
    try {
      print('Fetching funeral details');

      final response = await _apiClient.get(
        ApiEndpoints.funeral,
      );

      print('FUNERAL FETCH STATUS: ${response.statusCode}');
      print('FUNERAL DATA: ${response.data}');

      if (response.data['data'] == null) {
        return const FuneralResponse(
          status: 'success',
          message: 'No funeral preferences found',
          data: null,
        );
      }

      return FuneralResponse.fromJson(
        response.data,
        (data) => FuneralModel.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error fetching funeral details: $e');
      print('Stack trace: $stackTrace');
      return const FuneralResponse(
        status: 'failure',
        message: 'Failed to fetch funeral details',
      );
    }
  }

  /// Create or update funeral details
  Future<FuneralResponse<FuneralModel>> createOrUpdateFuneral(
      FuneralModel funeral) async {
    try {
      print('Creating/Updating funeral details');
      print('FUNERAL DATA: ${funeral.toJson()}');

      final response = await _apiClient.post(
        ApiEndpoints.funeral,
        data: funeral.toJson(),
      );

      print('FUNERAL UPDATE STATUS: ${response.statusCode}');
      print('FUNERAL UPDATE RESPONSE: ${response.data}');

      return FuneralResponse.fromJson(
        response.data,
        (data) => FuneralModel.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error updating funeral details: $e');
      print('Stack trace: $stackTrace');
      return const FuneralResponse(
        status: 'failure',
        message: 'Failed to update funeral details',
      );
    }
  }

  /// Create or update funeral attendees (recipients for legacy messages)
  Future<FuneralResponse<List<FuneralAttendeeModel>>> updateAttendees(
    List<FuneralAttendeeModel> attendees,
  ) async {
    try {
      print('Updating funeral attendees');
      print('ATTENDEES DATA: ${attendees.map((a) => a.toJson()).toList()}');

      final response = await _apiClient.post(
        ApiEndpoints.funeralAttendees,
        data: attendees.map((a) => a.toJson()).toList(),
      );

      print('ATTENDEES UPDATE STATUS: ${response.statusCode}');
      print('ATTENDEES UPDATE RESPONSE: ${response.data}');

      return FuneralResponse.fromJson(
        response.data,
        (data) {
          if (data is List) {
            return data
                .map((e) =>
                    FuneralAttendeeModel.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <FuneralAttendeeModel>[];
        },
      );
    } catch (e, stackTrace) {
      print('Error updating attendees: $e');
      print('Stack trace: $stackTrace');
      return const FuneralResponse(
        status: 'failure',
        message: 'Failed to update attendees',
      );
    }
  }

  /// Upload legacy video file
  Future<FuneralResponse<void>> uploadLegacyVideo(File videoFile) async {
    try {
      print('Uploading legacy video');

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          videoFile.path,
          filename: videoFile.path.split('/').last,
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.funeralLegacyVideo,
        data: formData,
      );

      print('VIDEO UPLOAD STATUS: ${response.statusCode}');
      print('VIDEO UPLOAD RESPONSE: ${response.data}');

      return FuneralResponse.fromJson(response.data, null);
    } catch (e, stackTrace) {
      print('Error uploading video: $e');
      print('Stack trace: $stackTrace');
      return const FuneralResponse(
        status: 'failure',
        message: 'Failed to upload legacy video',
      );
    }
  }

  /// Get music options list
  Future<FuneralResponse<List<MusicOption>>> getMusicOptions() async {
    try {
      print('Fetching music options');

      final response = await _apiClient.get(
        ApiEndpoints.funeralMusic,
      );

      print('MUSIC FETCH STATUS: ${response.statusCode}');
      print('MUSIC DATA: ${response.data}');

      return FuneralResponse.fromJson(
        response.data,
        (data) {
          if (data is List) {
            return data
                .map((e) => MusicOption.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          return <MusicOption>[];
        },
      );
    } catch (e, stackTrace) {
      print('Error fetching music options: $e');
      print('Stack trace: $stackTrace');
      return const FuneralResponse(
        status: 'failure',
        message: 'Failed to fetch music options',
      );
    }
  }

  /// Fetch list of family members / will people for direction_by selection
  Future<List<WillPerson>> getWillPeople() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.willPeople,
      );

      print('WILL PEOPLE STATUS: ${response.statusCode}');
      print('WILL PEOPLE DATA: ${response.data}');

      final data = response.data['data'];
      if (data is List) {
        return data
            .map(
                (item) => WillPerson.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching will people: $e');
      return [];
    }
  }

  /// Fetch science donation institutions
  Future<List<ScienceDonationInstitution>>
      getScienceDonationInstitutions() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.funeralScienceDonationInstitutions,
      );

      print('SCIENCE INSTITUTIONS STATUS: ${response.statusCode}');
      print('SCIENCE INSTITUTIONS DATA: ${response.data}');

      final data = response.data['data'];
      if (data is List) {
        return data
            .map((item) => ScienceDonationInstitution.fromJson(
                item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching science donation institutions: $e');
      return [];
    }
  }
}
