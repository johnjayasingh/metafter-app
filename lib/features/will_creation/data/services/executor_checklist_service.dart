import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/constants/app_enums.dart';

/// Represents a single executor checklist item returned from the API.
class ExecutorChecklistEntry {
  final ExecutorChecklistItem item;
  final bool isSelected;

  const ExecutorChecklistEntry({
    required this.item,
    required this.isSelected,
  });

  factory ExecutorChecklistEntry.fromJson(Map<String, dynamic> json) {
    return ExecutorChecklistEntry(
      item: ExecutorChecklistItem.fromString(
              json['checklist_item']?.toString()) ??
          ExecutorChecklistItem.locateDeceasedRecentWill,
      isSelected: json['is_selected'] == true,
    );
  }
}

/// Service for the /will/executor-checklist API endpoint.
class ExecutorChecklistService {
  final ApiClient _apiClient = ApiClient();

  /// Fetches the executor checklist for a given will.
  /// Returns a map of [ExecutorChecklistItem] → isSelected.
  Future<Map<ExecutorChecklistItem, bool>> getChecklist(String willId) async {
    try {
      print('🚀 Fetching executor checklist for will: $willId');
      final response = await _apiClient.get(
        ApiEndpoints.executorChecklist,
        queryParameters: {'will_id': willId},
      );
      print('📊 EXECUTOR CHECKLIST STATUS: ${response.statusCode}');
      print('📄 EXECUTOR CHECKLIST RESPONSE: ${response.data}');

      final result = <ExecutorChecklistItem, bool>{};

      // Initialise all items as unchecked
      for (final item in ExecutorChecklistItem.values) {
        result[item] = false;
      }

      if (response.statusCode == 200 && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;
          final innerData = responseMap['data'];

          if (innerData is Map<String, dynamic>) {
            // API returns { "data": { "INVESTMENTS": true, ... } }
            for (final entry in innerData.entries) {
              final item = ExecutorChecklistItem.fromString(entry.key);
              if (item != null) {
                result[item] = entry.value == true;
              }
            }
          } else if (innerData is List) {
            // Fallback: { "data": [ { "checklist_item": "...", "is_selected": true } ] }
            for (final entry in innerData) {
              if (entry is Map<String, dynamic>) {
                final parsed = ExecutorChecklistEntry.fromJson(entry);
                result[parsed.item] = parsed.isSelected;
              }
            }
          }
        }
      }
      return result;
    } catch (e, stackTrace) {
      print('❌ Error fetching executor checklist: $e');
      print('📍 Stack trace: $stackTrace');
      // Return all unchecked on failure
      return {
        for (final item in ExecutorChecklistItem.values) item: false,
      };
    }
  }

  /// Toggles a single checklist item on the server.
  Future<bool> toggleChecklistItem({
    required String willId,
    required ExecutorChecklistItem item,
    required bool isSelected,
  }) async {
    try {
      print(
          '🚀 Toggling checklist item: ${item.value} → $isSelected for will: $willId');
      final response = await _apiClient.post(
        ApiEndpoints.executorChecklist,
        data: {
          'will_id': willId,
          'checklist_item': item.value,
          'is_selected': isSelected,
        },
      );
      print('📊 TOGGLE CHECKLIST STATUS: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e, stackTrace) {
      print('❌ Error toggling checklist item: $e');
      print('📍 Stack trace: $stackTrace');
      return false;
    }
  }
}
