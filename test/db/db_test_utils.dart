import 'package:metafter/core/db/app_database.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Opens a fresh in-memory app database backed by `sqflite_common_ffi`,
/// so repository tests run on the host without a device.
Future<Database> openTestDb() {
  sqfliteFfiInit();
  return AppDatabase.openAppDatabase(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
}
