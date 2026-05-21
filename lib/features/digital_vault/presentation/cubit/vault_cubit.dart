import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/vault_repository.dart';
import '../../data/models/vault_models.dart';
import 'vault_state.dart';

class VaultCubit extends Cubit<VaultState> {
  final VaultRepository _repository;

  VaultCubit({required VaultRepository repository})
      : _repository = repository,
        super(const VaultInitial());

  // ─────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────

  List<VaultItem> get _currentItems {
    final s = state;
    if (s is VaultLoaded) return s.items;
    if (s is VaultOperationLoading) return s.items;
    if (s is VaultOperationSuccess) return s.items;
    if (s is VaultError) return s.items;
    return const [];
  }

  List<WillPerson> get _currentWillPeople {
    final s = state;
    if (s is VaultLoaded) return s.willPeople;
    if (s is VaultOperationLoading) return s.willPeople;
    if (s is VaultOperationSuccess) return s.willPeople;
    if (s is VaultError) return s.willPeople;
    return const [];
  }

  List<WillAsset> get _currentWillAssets {
    final s = state;
    if (s is VaultLoaded) return s.willAssets;
    if (s is VaultOperationLoading) return s.willAssets;
    if (s is VaultOperationSuccess) return s.willAssets;
    if (s is VaultError) return s.willAssets;
    return const [];
  }

  // ─────────────────────────────────────────
  // Load all vault items + will data
  // ─────────────────────────────────────────

  Future<void> loadAll() async {
    emit(const VaultLoading());
    try {
      final results = await Future.wait([
        _repository.listItems(),
        _repository.getWillPeople(),
        _repository.getWillAssets(),
      ]);
      emit(VaultLoaded(
        results[0] as List<VaultItem>,
        willPeople: results[1] as List<WillPerson>,
        willAssets: results[2] as List<WillAsset>,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString()));
    }
  }

  // ─────────────────────────────────────────
  // Create / Update
  // ─────────────────────────────────────────

  Future<void> createItem(VaultItemCreate payload) async {
    final current = _currentItems;
    final wp = _currentWillPeople;
    final wa = _currentWillAssets;
    emit(VaultOperationLoading(current, willPeople: wp, willAssets: wa));
    try {
      final created = await _repository.createItem(payload);
      final freshList = await _repository.listItems();
      emit(VaultOperationSuccess(
        items: freshList,
        message: 'Item saved to vault',
        willPeople: wp,
        willAssets: wa,
        lastItem: created,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString(), items: current, willPeople: wp, willAssets: wa));
    }
  }

  // ─────────────────────────────────────────
  // Delete
  // ─────────────────────────────────────────

  Future<void> deleteItem(String id) async {
    final current = _currentItems;
    final wp = _currentWillPeople;
    final wa = _currentWillAssets;
    emit(VaultOperationLoading(current, willPeople: wp, willAssets: wa));
    try {
      await _repository.deleteItem(id);
      final updated = current.where((i) => i.id != id).toList();
      emit(VaultOperationSuccess(
        items: updated,
        message: 'Item deleted',
        willPeople: wp,
        willAssets: wa,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString(), items: current, willPeople: wp, willAssets: wa));
    }
  }

  // ─────────────────────────────────────────
  // Create message with files
  // ─────────────────────────────────────────

  /// Uploads files first (getting an asset_id from the first upload if needed),
  /// then creates the message vault item with that asset_id.
  Future<void> createMessageItem(
    VaultItemCreate payload, {
    List<String> filePaths = const [],
    List<String> fileNames = const [],
  }) async {
    final current = _currentItems;
    final wp = _currentWillPeople;
    final wa = _currentWillAssets;
    emit(VaultOperationLoading(current, willPeople: wp, willAssets: wa));
    try {
      String? assetId = payload.assetId;

      // Upload files sequentially; first upload may create the asset_id
      for (var i = 0; i < filePaths.length; i++) {
        final result = await _repository.uploadFile(
          filePaths[i],
          fileNames[i],
          assetId: assetId,
        );
        assetId ??= result.assetId;
      }

      // Create the vault asset, attaching the asset_id from file uploads
      final finalPayload = VaultItemCreate(
        assetId: assetId,
        type: payload.type,
        data: payload.data,
      );
      final created = await _repository.createItem(finalPayload);
      final freshList = await _repository.listItems();
      emit(VaultOperationSuccess(
        items: freshList,
        message: 'Message saved to vault',
        willPeople: wp,
        willAssets: wa,
        lastItem: created,
      ));
    } catch (e) {
      emit(VaultError(message: e.toString(), items: current, willPeople: wp, willAssets: wa));
    }
  }

  // ─────────────────────────────────────────
  // File operations
  // ─────────────────────────────────────────

  Future<VaultUploadResult?> uploadFile(String filePath, String fileName, {String? assetId}) async {
    try {
      return await _repository.uploadFile(filePath, fileName, assetId: assetId);
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteVaultFile(String fileId) async {
    try {
      await _repository.deleteFile(fileId);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<VaultFile>> listItemFiles(String assetId) async {
    try {
      return await _repository.listItemFiles(assetId);
    } catch (_) {
      return const [];
    }
  }

  // ─────────────────────────────────────────
  // Preferences
  // ─────────────────────────────────────────

  Future<VaultPreference?> loadPreference() async {
    try {
      return await _repository.getPreference();
    } catch (_) {
      return null;
    }
  }

  Future<bool> savePreference(VaultPreference preference) async {
    try {
      await _repository.savePreference(preference);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────
  // Will data (refresh independently)
  // ─────────────────────────────────────────

  Future<void> loadWillPeople() async {
    try {
      final people = await _repository.getWillPeople();
      final s = state;
      if (s is VaultLoaded) {
        emit(VaultLoaded(s.items, willPeople: people, willAssets: s.willAssets));
      }
    } catch (_) {}
  }

  Future<void> loadWillAssets() async {
    try {
      final assets = await _repository.getWillAssets();
      final s = state;
      if (s is VaultLoaded) {
        emit(VaultLoaded(s.items, willPeople: s.willPeople, willAssets: assets));
      }
    } catch (_) {}
  }

  // ─────────────────────────────────────────
  // Acknowledge success → go back to loaded
  // ─────────────────────────────────────────

  void acknowledgeSuccess() {
    final s = state;
    if (s is VaultOperationSuccess) {
      emit(VaultLoaded(s.items, willPeople: s.willPeople, willAssets: s.willAssets));
    }
  }
}
