import 'package:dio/dio.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/repositories/vault_repository.dart';
import '../models/vault_models.dart';

class VaultRepositoryImpl implements VaultRepository {
  final ApiClient _apiClient;

  VaultRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  // ──────────────────────────────────────────────
  // Vault Items (unified)
  // ──────────────────────────────────────────────

  @override
  Future<List<VaultItem>> listItems() async {
    final response = await _apiClient.get(ApiEndpoints.vaultAssets);
    final result = VaultResponse<List<VaultItem>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => VaultItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Failed to list vault items');
    }
    return result.data ?? [];
  }

  @override
  Future<VaultItem> createItem(VaultItemCreate payload) async {
    final response = await _apiClient.post(
      ApiEndpoints.vaultAssets,
      data: payload.toJson(),
    );
    final result = VaultResponse<VaultItem>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => VaultItem.fromJson(data as Map<String, dynamic>),
    );
    if (!result.isSuccess || result.data == null) {
      throw Exception(result.message ?? 'Failed to create vault item');
    }
    return result.data!;
  }

  @override
  Future<void> deleteItem(String id) async {
    final response = await _apiClient.delete(ApiEndpoints.vaultAsset(id));
    final result = VaultResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      null,
    );
    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Failed to delete vault item');
    }
  }

  // ──────────────────────────────────────────────
  // Files
  // ──────────────────────────────────────────────

  @override
  Future<VaultUploadResult> uploadFile(String filePath, String fileName, {String? assetId}) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final queryParams = <String, dynamic>{};
    if (assetId != null && assetId.isNotEmpty) {
      queryParams['asset_id'] = assetId;
    }
    final response = await _apiClient.post(
      ApiEndpoints.vaultFilesUpload,
      data: formData,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final rawData = response.data as Map<String, dynamic>;
    final result = VaultResponse<VaultFile>.fromJson(
      rawData,
      (data) => VaultFile.fromJson(data as Map<String, dynamic>),
    );
    if (!result.isSuccess || result.data == null) {
      throw Exception(result.message ?? 'Failed to upload file');
    }
    // Extract asset_id from response (may be in data or top-level)
    final responseData = rawData['data'] as Map<String, dynamic>?;
    final returnedAssetId = responseData?['asset_id'] as String? ??
        rawData['asset_id'] as String? ??
        assetId;
    return VaultUploadResult(file: result.data!, assetId: returnedAssetId);
  }

  @override
  Future<List<VaultFile>> listItemFiles(String assetId) async {
    final response = await _apiClient.get(ApiEndpoints.vaultAssetFiles(assetId));
    final result = VaultResponse<List<VaultFile>>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => (data as List<dynamic>)
          .map((e) => VaultFile.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Failed to list item files');
    }
    return result.data ?? [];
  }

  @override
  Future<void> deleteFile(String fileId) async {
    final response = await _apiClient.delete(ApiEndpoints.vaultFile(fileId));
    final result = VaultResponse<dynamic>.fromJson(
      response.data as Map<String, dynamic>,
      null,
    );
    if (!result.isSuccess) {
      throw Exception(result.message ?? 'Failed to delete file');
    }
  }

  // ──────────────────────────────────────────────
  // Preferences
  // ──────────────────────────────────────────────

  @override
  Future<VaultPreference?> getPreference() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.vaultPreferences);
      final result = VaultResponse<VaultPreference>.fromJson(
        response.data as Map<String, dynamic>,
        (data) => VaultPreference.fromJson(data as Map<String, dynamic>),
      );
      return result.data;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<VaultPreference> savePreference(VaultPreference preference) async {
    final response = await _apiClient.post(
      ApiEndpoints.vaultPreferences,
      data: preference.toJson(),
    );
    final result = VaultResponse<VaultPreference>.fromJson(
      response.data as Map<String, dynamic>,
      (data) => VaultPreference.fromJson(data as Map<String, dynamic>),
    );
    if (!result.isSuccess || result.data == null) {
      throw Exception(result.message ?? 'Failed to save vault preference');
    }
    return result.data!;
  }

  // ──────────────────────────────────────────────
  // Will Data
  // ──────────────────────────────────────────────

  @override
  Future<List<WillPerson>> getWillPeople() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.willPeople);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => WillPerson.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<WillAsset>> getWillAssets() async {
    try {
      final response = await _apiClient.get(ApiEndpoints.userWillAssets);
      final data = response.data['data'];
      if (data is List) {
        return data
            .map((e) => WillAsset.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
