import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

/// Summary model for a probate request shown in the list view.
class ProbateSummary {
  final String id;
  final String surname;
  final String givenNames;
  final String status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? documentName;

  const ProbateSummary({
    required this.id,
    required this.surname,
    required this.givenNames,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    this.documentName,
  });

  String get fullName =>
      givenNames.isNotEmpty ? '$givenNames $surname' : surname;

  factory ProbateSummary.fromJson(Map<String, dynamic> json) {
    return ProbateSummary(
      id: json['id']?.toString() ?? json['probate_id']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      givenNames: json['given_names']?.toString() ?? '',
      status: json['status']?.toString() ?? 'Pending',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'].toString())
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'].toString())
          : null,
      documentName: json['document_name']?.toString(),
    );
  }
}

/// Service for the /will/probate API endpoint.
class ProbateService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the list of probate requests for the current user.
  Future<List<ProbateSummary>> getProbateRequests() async {
    try {
      print('🚀 Fetching probate requests');
      final response = await _apiClient.get(ApiEndpoints.probate);
      print('📊 PROBATE LIST STATUS: ${response.statusCode}');
      print('📄 PROBATE LIST RESPONSE: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is List) {
          return (response.data as List)
              .map((e) =>
                  ProbateSummary.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        if (response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          // Support wrapped responses like { "probate_requests": [...] }
          final list = data['probate_requests'] ?? data['data'] ?? data['results'];
          if (list is List) {
            return list
                .map((e) =>
                    ProbateSummary.fromJson(e as Map<String, dynamic>))
                .toList();
          }
          // Single object → wrap in list
          return [ProbateSummary.fromJson(data)];
        }
      }
      return [];
    } catch (e, stackTrace) {
      print('❌ Error fetching probate requests: $e');
      print('📍 Stack trace: $stackTrace');
      return [];
    }
  }

  /// Sends a probate request (multipart/form-data).
  ///
  /// All fields are optional per the OpenAPI spec.
  /// If [documentPath] is supplied, the file is uploaded as [probate_document].
  Future<Map<String, dynamic>?> createProbateRequest({
    String? surname,
    String? givenNames,
    String? gender,
    String? occupation,
    String? dateOfBirth,
    String? email,
    String? address,
    String? suburb,
    String? state,
    String? postcode,
    String? phoneNumber,
    String? serviceSource,
    String? deceasedLastKnownAddress,
    bool isDeceasedResident = false,
    bool isDeceasedLeftProperty = false,
    bool isDeceasedLeftWill = false,
    bool isExecutorApplying = false,
    bool isExecutorApplied = false,
    String? documentPath,
    String? documentName,
  }) async {
    try {
      print('🚀 Creating probate request');

      final Map<String, dynamic> fields = {
        'is_deceased_resident': isDeceasedResident,
        'is_deceased_left_property': isDeceasedLeftProperty,
        'is_deceased_left_will': isDeceasedLeftWill,
        'is_executor_applying': isExecutorApplying,
        'is_executor_applied': isExecutorApplied,
      };

      if (surname != null && surname.isNotEmpty) fields['surname'] = surname;
      if (givenNames != null && givenNames.isNotEmpty) {
        fields['given_names'] = givenNames;
      }
      if (gender != null && gender.isNotEmpty) fields['gender'] = gender;
      if (occupation != null && occupation.isNotEmpty) {
        fields['occupation'] = occupation;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        fields['date_of_birth'] = dateOfBirth;
      }
      if (email != null && email.isNotEmpty) fields['email'] = email;
      if (address != null && address.isNotEmpty) fields['address'] = address;
      if (suburb != null && suburb.isNotEmpty) fields['suburb'] = suburb;
      if (state != null && state.isNotEmpty) fields['state'] = state;
      if (postcode != null && postcode.isNotEmpty) fields['postcode'] = postcode;
      if (phoneNumber != null && phoneNumber.isNotEmpty) fields['phone_number'] = phoneNumber;
      if (serviceSource != null && serviceSource.isNotEmpty) fields['service_source'] = serviceSource;
      if (deceasedLastKnownAddress != null && deceasedLastKnownAddress.isNotEmpty) {
        fields['deceased_last_known_address'] = deceasedLastKnownAddress;
      }

      if (documentPath != null) {
        print('📁 Attaching document: $documentPath');
        fields['probate_document'] = await MultipartFile.fromFile(
          documentPath,
          filename: documentName ?? documentPath.split('/').last,
        );
      }

      final formData = FormData.fromMap(fields);

      final response = await _apiClient.post(
        ApiEndpoints.probate,
        data: formData,
      );

      print('📊 PROBATE STATUS: ${response.statusCode}');
      print('📄 PROBATE RESPONSE: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
      return null;
    } catch (e, stackTrace) {
      print('❌ Error creating probate request: $e');
      print('📍 Stack trace: $stackTrace');
      return null;
    }
  }
}
