import 'package:dio/dio.dart';
import 'dart:typed_data';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../models/document_generation_response.dart';
import '../models/will_complete_detail_response.dart';
import '../models/video_call_models.dart';

class WillDocumentService {
  final ApiClient _apiClient = ApiClient();
  final SecureStorageService _storage = SecureStorageService();
  static const String _documentPreviewEndpoint = '/will/document/preview';

  /// Fetches the will document preview as binary PDF data
  /// Note: Uses direct Dio call for binary response handling
  Future<Uint8List?> fetchWillDocumentPreview(String willId) async {
    try {
      final token = await _storage.getAccessToken();
      
      if (token == null) {
        print('❌ No authentication token available');
        return null;
      }

      print('📍 Fetching document preview for will: $willId');
      
      // Use a separate Dio instance for binary response
      final dio = Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl));
      final response = await dio.get(
        _documentPreviewEndpoint,
        queryParameters: {'will_id': willId},
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json, text/plain, */*',
          },
          validateStatus: (status) => status != null && status < 500,
          responseType: ResponseType.bytes,
        ),
      );

      print('📊 RESPONSE STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        if (response.data is Uint8List) {
          final pdfData = response.data as Uint8List;
          print('✅ Received ${pdfData.length} bytes of PDF data');
          return pdfData;
        } else if (response.data is List<int>) {
          final pdfData = Uint8List.fromList(response.data as List<int>);
          print('✅ Converted ${pdfData.length} bytes to Uint8List');
          return pdfData;
        } else {
          print('⚠️ Unexpected response type: ${response.data.runtimeType}');
          return null;
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized (401): Token may be invalid or expired');
        return null;
      } else {
        print('❌ Error fetching document preview: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching will document: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Generate will document and get URLs for PDF, watermarked PDF, and cover image
  Future<DocumentGenerationResponse?> generateWillDocument(String willId) async {
    try {
      print('🌐 Generating document for will ID: "$willId"');
      
      final response = await _apiClient.get(
        ApiEndpoints.documentGenerate(willId),
      );

      print('📊 DOCUMENT GENERATION STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final documentResponse = DocumentGenerationResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        
        if (documentResponse.isSuccess && documentResponse.data != null) {
          print('✅ Document generated successfully: ${documentResponse.data!.documentId}');
          print('📄 PDF URL: ${documentResponse.data!.url}');
          print('🔒 Watermarked URL: ${documentResponse.data!.watermarkedUrl}');
          print('🖼️ Cover URL: ${documentResponse.data!.coverUrl}');
          return documentResponse;
        } else {
          print('⚠️ Document generation response not successful');
          return null;
        }
      } else {
        print('❌ Error generating document: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception generating will document: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get complete will details including already-generated document URLs
  /// This should be used when the will has already been generated
  Future<WillCompleteDetailResponse?> getWillCompleteDetail(String willId) async {
    try {
      print('🌐 Fetching complete details for will ID: "$willId"');
      
      final response = await _apiClient.get(
        ApiEndpoints.willCompleteDetail(willId),
      );

      print('📊 WILL DETAIL STATUS: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final detailResponse = WillCompleteDetailResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
        
        if (detailResponse.isSuccess && detailResponse.data != null) {
          print('✅ Will details retrieved successfully');
          print('📄 Document ID: ${detailResponse.data!.documentId}');
          print('📄 Will Status: ${detailResponse.data!.willInfo.status}');
          print('📄 Original PDF: ${detailResponse.data!.willOriginal}');
          print('🔒 Watermarked PDF: ${detailResponse.data!.willWatermarked}');
          print('🖼️ Cover Image: ${detailResponse.data!.willCoverImage}');
          return detailResponse;
        } else {
          print('⚠️ Will detail response not successful');
          return null;
        }
      } else {
        print('❌ Error fetching will details: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception fetching will details: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Get will signing URL
  /// Calls GET /will/sign?will_id={willId} and returns the signing URL.
  /// Throws on failure so callers can access the error message.
  Future<String?> getWillSignUrl(String willId) async {
    print('🌐 Fetching sign URL for will ID: "$willId"');

    final response = await _apiClient.get(
      ApiEndpoints.willSign(willId),
    );

    print('📊 SIGN URL STATUS: ${response.statusCode}');
    print('📦 RESPONSE: ${response.data}');

    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        // Try common response shapes: { data: "url" }, { data: { url: "..." } }, { url: "..." }
        final innerData = data['data'];
        if (innerData is String) {
          return innerData;
        } else if (innerData is Map<String, dynamic>) {
          return innerData['url'] as String? ?? innerData['sign_url'] as String? ?? innerData['signing_url'] as String?;
        }
        return data['url'] as String? ?? data['sign_url'] as String?;
      } else if (data is String) {
        return data;
      }
      return null;
    } else {
      print('❌ Error fetching sign URL: ${response.statusCode}');
      return null;
    }
  }

  /// Upload signed will document
  /// Returns the response message on success, null on failure
  Future<String?> uploadSignedDocument(String willId, String filePath) async {
    try {
      print('🌐 Uploading signed document for will ID: "$willId"');
      print('📁 File path: $filePath');
      
      // Create FormData with the file
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: filePath.split('/').last,
        ),
      });

      final response = await _apiClient.post(
        ApiEndpoints.uploadSignedDocument(willId),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );

      print('📊 UPLOAD STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');
      
      if (response.statusCode == 200) {
        print('✅ Signed document uploaded successfully');
        // The API returns a string response
        if (response.data is String) {
          return response.data as String;
        } else if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          return data['message'] as String? ?? 'Upload successful';
        }
        return 'Upload successful';
      } else {
        print('❌ Error uploading signed document: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception uploading signed document: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Update will location/address
  /// Returns true on success, false on failure
  Future<bool> updateWillLocation(String willId, String location) async {
    try {
      print('🌐 Updating will location for will ID: "$willId"');
      print('📍 Location: $location');
      
      final response = await _apiClient.post(
        ApiEndpoints.updateWillLocation,
        data: {
          'will_id': willId,
          'location': location,
        },
      );

      print('📊 LOCATION UPDATE STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');
      
      if (response.statusCode == 200) {
        print('✅ Will location updated successfully');
        return true;
      } else {
        print('❌ Error updating will location: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Exception updating will location: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }

  /// Create a meeting for a will
  /// POST /user/meeting/create with body { 'will_id': willId }
  /// Returns the API response (map) on success, null on failure
  Future<MeetingInfo?> createMeeting(String willId) async {
    try {
      print('🌐 Creating meeting for will ID: "$willId"');
      final response = await _apiClient.post(
        ApiEndpoints.userMeetingCreate,
        data: {
          'will_id': willId,
        },
      );

      print('📊 MEETING CREATE STATUS: ${response.statusCode}');
      print('📦 MEETING RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final body = response.data;

        if (body is Map<String, dynamic> && body['data'] is Map<String, dynamic>) {
          return MeetingInfo.fromJson(body['data']);
        }

        return null;
      } else {
        print('❌ Error creating meeting: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception creating meeting: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Join a meeting for a will
  /// GET /user/meeting/join?will_id={willId}
  /// Returns meeting info (map) on success, null on failure
  Future<MeetingInfo?> joinMeeting(String willId) async {
    try {
      print('🌐 Joining meeting for will ID: "$willId"');
      final response = await _apiClient.get(
        ApiEndpoints.userMeetingJoin,
        queryParameters: {'will_id': willId},
      );

      print('📊 MEETING JOIN STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');

      if (response.statusCode == 200) {
        if (response.data is Map<String, dynamic>) {
          return MeetingInfo.fromJson(response.data as Map<String, dynamic>);
        }
        if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
          return MeetingInfo.fromJson(response.data['data'] as Map<String, dynamic>);
        }
        return null;
      } else {
        print('❌ Error joining meeting: ${response.statusCode}');
        if (response.data != null) {
          print('📦 Error response: ${response.data}');
        }
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception joining meeting: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Start meeting recording
  /// POST /user/meeting/start-recording
  ///
  /// All recording layout and canvas config is handled server-side:
  ///   - mixedVideoLayout=1 (best-fit), 720×1280 portrait, 15fps
  ///   - Screen share active → only screen stream in channel → fills canvas
  ///   - No screen share     → participant cameras in a grid
  Future<RecordingInfo?> startMeetingRecording(String meetingId) async {
    try {
      print('🌐 Starting recording for meeting ID: "$meetingId"');

      final response = await _apiClient.post(
        ApiEndpoints.userMeetingStartRecording,
        data: {'meeting_id': meetingId, 'device_type': 'MOBILE'},
      );

      print('📊 START RECORDING STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          // API returns { resourceId: '...', sid: '...' }
          return RecordingInfo.fromJson(response.data as Map<String, dynamic>);
        }
        if (response.data is Map && response.data['data'] is Map<String, dynamic>) {
          return RecordingInfo.fromJson(response.data['data'] as Map<String, dynamic>);
        }
        // Some APIs return nested shapes; try to find keys
        if (response.data is Map) {
          final map = response.data as Map;
          if (map.containsKey('resourceId') || map.containsKey('resource_id')) {
            return RecordingInfo.fromJson(Map<String, dynamic>.from(map));
          }
        }
        return null;
      } else {
        print('❌ Error starting recording: ${response.statusCode}');
        if (response.data != null) print('📦 Error response: ${response.data}');
        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Exception starting recording: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }

  /// Stop meeting recording
  /// POST /user/meeting/stop-recording with { meeting_id }
  /// Returns true on success
  Future<bool> stopMeetingRecording(String meetingId) async {
    try {
      print('🌐 Stopping recording for meeting ID: "$meetingId"');
      final response = await _apiClient.post(
        ApiEndpoints.userMeetingStopRecording,
        data: {'meeting_id': meetingId},
      );

      print('📊 STOP RECORDING STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Recording stopped successfully');
        return true;
      } else {
        print('❌ Error stopping recording: ${response.statusCode}');
        if (response.data != null) print('📦 Error response: ${response.data}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Exception stopping recording: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }


  /// Stop the meeting
  /// POST /user/meeting/stop with { meeting_id }
  /// Returns true on success
  Future<bool> stopMeeting(String meetingId) async {
    try {
      print('🌐 Stopping meeting ID: "$meetingId"');
      final response = await _apiClient.post(
        ApiEndpoints.userMeetingStop,
        data: {'meeting_id': meetingId},
      );

      print('📊 MEETING STOP STATUS: ${response.statusCode}');
      print('📦 RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Meeting stopped successfully');
        return true;
      } else {
        print('❌ Error stopping meeting: ${response.statusCode}');
        if (response.data != null) print('📦 Error response: ${response.data}');
        return false;
      }
    } catch (e, stackTrace) {
      print('❌ Exception stopping meeting: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }
}
