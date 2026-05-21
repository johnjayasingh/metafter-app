import 'package:equatable/equatable.dart';
import '../../data/models/vault_models.dart';

// ─────────────────────────────────────────
// Base state
// ─────────────────────────────────────────
abstract class VaultState extends Equatable {
  const VaultState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data has been loaded.
class VaultInitial extends VaultState {
  const VaultInitial();
}

/// Fetching the list of items.
class VaultLoading extends VaultState {
  const VaultLoading();
}

/// Successfully loaded the item list.
class VaultLoaded extends VaultState {
  final List<VaultItem> items;
  final List<WillPerson> willPeople;
  final List<WillAsset> willAssets;

  const VaultLoaded(
    this.items, {
    this.willPeople = const [],
    this.willAssets = const [],
  });

  List<VaultItem> get messages =>
      items.where((i) => i.type == VaultAssetType.message).toList();
  List<VaultItem> get assets =>
      items.where((i) => i.type == VaultAssetType.asset).toList();
  List<VaultItem> get liabilities =>
      items.where((i) => i.type == VaultAssetType.liability).toList();
  List<VaultItem> get contacts =>
      items.where((i) => i.type == VaultAssetType.contact).toList();

  @override
  List<Object?> get props => [items, willPeople, willAssets];
}

/// A create / update / delete operation is in progress.
class VaultOperationLoading extends VaultState {
  final List<VaultItem> items;
  final List<WillPerson> willPeople;
  final List<WillAsset> willAssets;

  const VaultOperationLoading(
    this.items, {
    this.willPeople = const [],
    this.willAssets = const [],
  });

  @override
  List<Object?> get props => [items, willPeople, willAssets];
}

/// A create / update / delete operation completed successfully.
class VaultOperationSuccess extends VaultState {
  final List<VaultItem> items;
  final List<WillPerson> willPeople;
  final List<WillAsset> willAssets;
  final String message;
  final VaultItem? lastItem;

  const VaultOperationSuccess({
    required this.items,
    required this.message,
    this.willPeople = const [],
    this.willAssets = const [],
    this.lastItem,
  });

  @override
  List<Object?> get props => [items, message, lastItem, willPeople, willAssets];
}

/// An error occurred.
class VaultError extends VaultState {
  final String message;
  final List<VaultItem> items;
  final List<WillPerson> willPeople;
  final List<WillAsset> willAssets;

  const VaultError({
    required this.message,
    this.items = const [],
    this.willPeople = const [],
    this.willAssets = const [],
  });

  @override
  List<Object?> get props => [message, items, willPeople, willAssets];
}
