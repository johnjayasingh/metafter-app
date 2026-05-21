import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/api_exceptions.dart';
import '../models/poa_dto.dart';
import '../models/poa_models.dart';

class PoaService {
  final ApiClient _apiClient = ApiClient();

  /// Fetch existing POA data for the current user (legacy PoaData model).
  Future<PoaResponse<PoaData>> getPoaDetails() async {
    try {
      final response = await _apiClient.get(
        ApiEndpoints.powerOfAttorney,
      );

      if (response.data['data'] == null) {
        return const PoaResponse(
          status: 'success',
          message: 'No POA data found',
          data: null,
        );
      }

      return PoaResponse.fromJson(
        response.data,
        (data) => PoaData.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error fetching POA details: $e');
      print('Stack trace: $stackTrace');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to fetch POA details',
      );
    }
  }

  /// Fetch existing POA data and parse into typed [PowerOfAttorneyDto].
  Future<PowerOfAttorneyDto?> getPoaDto() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.powerOfAttorney);
      if (response.data['data'] == null) return null;
      final json = response.data['data'] as Map<String, dynamic>;
      return PowerOfAttorneyDto.fromJson(json);
    } catch (e) {
      print('Error fetching POA DTO: $e');
      return null;
    }
  }

  /// Fetch all persons previously added to the user's wills.
  Future<List<Map<String, dynamic>>> getWillPeople() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.willPeople);
      final data = response.data['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      print('Error fetching will people for POA: $e');
      return [];
    }
  }

  /// Create or update POA using the new [PowerOfAttorneyDto].
  /// Preferred path — produces exact API payloads matching web.
  Future<PoaResponse<PoaData>> createOrUpdatePoaDto(
      PowerOfAttorneyDto dto) async {
    try {
      final body = dto.toJson();
      print('POA POST DATA (DTO): $body');

      final response = await _apiClient.post(
        ApiEndpoints.powerOfAttorney,
        data: body,
      );

      print('POA UPDATE STATUS: ${response.statusCode}');
      print('POA UPDATE RESPONSE: ${response.data}');

      return PoaResponse.fromJson(
        response.data,
        (data) => PoaData.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error updating POA (DTO): $e');
      print('Stack trace: $stackTrace');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to save power of attorney',
      );
    }
  }

  /// Create or update POA using legacy [PoaFlowData].
  /// Kept for backwards compatibility during migration.
  Future<PoaResponse<PoaData>> createOrUpdatePoa(PoaFlowData flowData) async {
    try {
      final body = flowData.toApiJson();
      print('POA POST DATA: $body');

      final response = await _apiClient.post(
        ApiEndpoints.powerOfAttorney,
        data: body,
      );

      print('POA UPDATE STATUS: ${response.statusCode}');
      print('POA UPDATE RESPONSE: ${response.data}');

      // The API stores only ONE notification per POA.
      // States with notification UI.
      const notifStates = ['queensland', 'new_south_wales', 'victoria', 'northern_territory'];
      final stateNorm = flowData.state?.toLowerCase();
      if (notifStates.contains(stateNorm)) {
        // Determine notification_type from matters:
        //   - If health matters selected → HEALTH
        //   - NT always uses health notification
        //   - If only financial matters → FINANCIAL
        final bool hasHealth = flowData.matters.contains('PERSONAL_HEALTH') ||
            stateNorm == 'northern_territory';
        final String notifType = hasHealth ? 'HEALTH' : 'FINANCIAL';

        // Pick the correct set of fields based on which section is active
        if (hasHealth) {
          await createPoaNotification(
            notificationType: notifType,
            notifyWho: flowData.notifyWho,
            notifyWhatOption: flowData.notifyWhatOption,
            notifyPersons: flowData.notifyPersons,
            notifyInstructions: flowData.notifyInstructions,
            notifyOtherText: flowData.notifyWhatOtherText,
          );
        } else {
          await createPoaNotification(
            notificationType: notifType,
            notifyWho: flowData.financialNotifyWho,
            notifyWhatOption: flowData.financialNotifyWhatOption,
            notifyPersons: flowData.financialNotifyPersons,
            notifyInstructions: flowData.financialNotifyInstructions,
            notifyOtherText: flowData.financialNotifyWhatOtherText,
          );
        }
      }

      return PoaResponse.fromJson(
        response.data,
        (data) => PoaData.fromJson(data as Map<String, dynamic>),
      );
    } catch (e, stackTrace) {
      print('Error updating POA: $e');
      print('Stack trace: $stackTrace');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to save power of attorney',
      );
    }
  }

  /// Create a POA notification using the new [PoaNotificationDto].
  Future<PoaResponse<Map<String, dynamic>>> createPoaNotificationDto(
      PoaNotificationDto dto) async {
    try {
      final body = dto.toJson();
      print('POA NOTIFICATION DATA (DTO): $body');

      final response = await _apiClient.post(
        ApiEndpoints.poaNotification,
        data: body,
      );

      return PoaResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error creating POA notification (DTO): $e');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to create POA notification',
      );
    }
  }

  /// Send POA notification via POST /user/poa-notification (legacy).
  ///
  /// [notificationType] should be 'HEALTH' or 'FINANCIAL'.
  Future<PoaResponse<Map<String, dynamic>>> createPoaNotification({
    required String notificationType,
    required String? notifyWho,
    required String? notifyWhatOption,
    required List<PoaPersonData> notifyPersons,
    String? notifyInstructions,
    String? notifyOtherText,
  }) async {
    try {
      final notifyFor = <String>[];
      if (notifyWho != null) {
        notifyFor.add(notifyWho);
      }

      // Map UI value to API enum
      String? apiNotifyOf;
      if (notifyWhatOption == 'WRITTEN_NOTICE') {
        apiNotifyOf = 'WRITTEN_INTENTION_NOTICE';
      } else {
        apiNotifyOf = notifyWhatOption;
      }

      // Use the correct detail text based on the option:
      // - "OTHER" → use notifyOtherText (the "Please specify" field)
      // - otherwise → use notifyInstructions (general instructions field)
      final detailText = notifyWhatOption == 'OTHER'
          ? notifyOtherText
          : notifyInstructions;

      final body = <String, dynamic>{
        'notify_for': notifyFor,
        'notification_type': notificationType,
        'notify_of': apiNotifyOf,
        'notify_of_detail': detailText,
        'attorneys': notifyPersons
            .map((p) => {
                  'full_name': p.fullName,
                  'email': p.email,
                  'phone': p.phone,
                  'address': p.address,
                })
            .toList(),
      };
      print('POA NOTIFICATION DATA ($notificationType): $body');

      final response = await _apiClient.post(
        ApiEndpoints.poaNotification,
        data: body,
      );

      return PoaResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error creating POA notification: $e');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to create POA notification',
      );
    }
  }

  /// Fetch POA notifications (health & financial).
  Future<List<Map<String, dynamic>>> getPoaNotifications() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.poaNotification);
      final data = response.data['data'];
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      if (data is Map<String, dynamic>) {
        return [data];
      }
      return [];
    } catch (e) {
      print('Error fetching POA notifications: $e');
      return [];
    }
  }

  // ── Attorney CRUD ──────────────────────────────────────────────────────────

  /// Create attorney using new [AttorneyForPoaDto].
  Future<PoaResponse<Map<String, dynamic>>> createAttorneyForPoaDto(
      AttorneyForPoaDto dto) async {
    try {
      final body = dto.toJson();
      print('CREATE ATTORNEY DATA (DTO): $body');

      final response = await _apiClient.post(
        ApiEndpoints.attorneyForPoa,
        data: body,
      );

      return PoaResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error creating attorney (DTO): $e');
      final msg = e is ApiException ? e.message : 'Failed to create attorney';
      return PoaResponse(
        status: 'failure',
        message: msg,
      );
    }
  }

  /// Fetch all attorneys assigned to the current user's active POA.
  Future<List<PoaPersonData>> getAttorneysForPoa() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.attorneysForPoa);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((item) =>
                PoaPersonData.fromApiJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attorneys for POA: $e');
      return [];
    }
  }

  /// Fetch attorneys as typed DTOs.
  Future<List<AttorneyForPoaResponseDto>> getAttorneysForPoaDto() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.attorneysForPoa);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((item) => AttorneyForPoaResponseDto.fromJson(
                item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Error fetching attorneys DTO: $e');
      return [];
    }
  }

  /// Fetch attorneys filtered by [type].
  Future<List<PoaPersonData>> getAttorneysByType(AttorneyType type) async {
    final all = await getAttorneysForPoa();
    return all.where((a) => a.attorneyType == type).toList();
  }

  /// Delete all attorneys of a given [type] for the current POA.
  Future<void> deleteAttorneysByType(AttorneyType type) async {
    final existing = await getAttorneysByType(type);
    for (final a in existing) {
      if (a.attorneyPoaId != null) {
        await deleteAttorneyForPoa(a.attorneyPoaId!);
      }
    }
  }

  /// Create a new attorney for the current user's POA (legacy).
  Future<PoaResponse<Map<String, dynamic>>> createAttorneyForPoa(
    PoaPersonData person, {
    required AttorneyType type,
  }) async {
    try {
      final body = person.toApiJson(typeOverride: type);
      print('CREATE ATTORNEY DATA: $body');

      final response = await _apiClient.post(
        ApiEndpoints.attorneyForPoa,
        data: body,
      );

      return PoaResponse.fromJson(
        response.data,
        (data) => data as Map<String, dynamic>,
      );
    } catch (e) {
      print('Error creating attorney: $e');
      final msg = e is ApiException ? e.message : 'Failed to create attorney';
      return PoaResponse(
        status: 'failure',
        message: msg,
      );
    }
  }

  /// Update an existing attorney by deleting the old record and creating a new one.
  /// The API does not support PUT on this endpoint.
  Future<PoaResponse<Map<String, dynamic>>> updateAttorneyForPoa(
    PoaPersonData person, {
    required AttorneyType type,
  }) async {
    try {
      // Delete the existing attorney-POA link first
      if (person.attorneyPoaId != null) {
        await deleteAttorneyForPoa(person.attorneyPoaId!);
      }

      // Create a new attorney record
      return await createAttorneyForPoa(person, type: type);
    } catch (e) {
      print('Error updating attorney: $e');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to update attorney',
      );
    }
  }

  /// Delete an attorney-POA relationship by [attorneyPoaId].
  Future<PoaResponse<void>> deleteAttorneyForPoa(int attorneyPoaId) async {
    try {
      final response = await _apiClient.delete(
        ApiEndpoints.deleteAttorneyForPoa(attorneyPoaId),
      );

      return PoaResponse(
        status: response.data['status'] as String? ?? 'success',
        message: response.data['message'] as String? ?? '',
      );
    } catch (e) {
      print('Error deleting attorney: $e');
      return const PoaResponse(
        status: 'failure',
        message: 'Failed to delete attorney',
      );
    }
  }
}
