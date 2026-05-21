import '../../data/models/vault_models.dart';

/// Domain contract for the Digital Vault feature (unified API).
abstract class VaultRepository {
  /// GET /vault/assets – list all vault items.
  Future<List<VaultItem>> listItems();

  /// POST /vault/assets – create or update a vault item.
  Future<VaultItem> createItem(VaultItemCreate payload);

  /// DELETE /vault/assets/{id} – delete a vault item.
  Future<void> deleteItem(String id);

  /// POST /vault/files/upload?asset_id={id} – upload a file to a vault item.
  /// If [assetId] is null, the backend creates one and returns it in the response.
  Future<VaultUploadResult> uploadFile(String filePath, String fileName, {String? assetId});

  /// GET /vault/assets/{id}/files – list files for a vault item.
  Future<List<VaultFile>> listItemFiles(String assetId);

  /// DELETE /vault/files/{fileId} – delete a file.
  Future<void> deleteFile(String fileId);

  /// GET /vault/preferences – fetch vault preferences.
  Future<VaultPreference?> getPreference();

  /// POST /vault/preferences – save vault preferences.
  Future<VaultPreference> savePreference(VaultPreference preference);

  /// GET /user/will-people – list people from the user's will.
  Future<List<WillPerson>> getWillPeople();

  /// GET /user/will-assets – list assets from the user's will.
  Future<List<WillAsset>> getWillAssets();
}
