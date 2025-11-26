import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/data/models/database.dart' as db;
import 'package:app_contabilidad/data/datasources/local/database_service.dart';

/// Provider de la base de datos
final databaseProvider = Provider<db.AppDatabase>((ref) {
  return db.AppDatabase();
});

/// Provider del servicio de base de datos
final databaseServiceProvider = Provider<DatabaseService>((ref) {
  final database = ref.watch(databaseProvider);
  return DatabaseService(database);
});

