import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/constants.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';

/// Servicio de backup automático
class BackupService {
  final DatabaseService _databaseService;

  BackupService(this._databaseService);

  /// Crea un backup de la base de datos
  Future<Result<String>> createBackup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(appDir.path, AppConstants.backupFolderName));
      
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupFileName = 'backup_$timestamp.db';
      final backupPath = p.join(backupDir.path, backupFileName);

      // Copiar archivo de base de datos
      final dbFile = File(p.join(appDir.path, AppConstants.databaseName));
      if (await dbFile.exists()) {
        await dbFile.copy(backupPath);
        appLogger.i('Backup created: $backupPath');
        return Right(backupPath);
      } else {
        return Left(FileFailure('Base de datos no encontrada'));
      }
    } catch (e) {
      appLogger.e('Error creating backup', error: e);
      return Left(FileFailure('Error al crear backup: ${e.toString()}'));
    }
  }

  /// Restaura un backup
  Future<Result<void>> restoreBackup(String backupPath) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = p.join(appDir.path, AppConstants.databaseName);
      
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return Left(FileFailure('Archivo de backup no encontrado'));
      }

      // Cerrar conexión actual
      await _databaseService.close();

      // Copiar backup sobre la base de datos actual
      await backupFile.copy(dbPath);

      appLogger.i('Backup restored from: $backupPath');
      return const Right(null);
    } catch (e) {
      appLogger.e('Error restoring backup', error: e);
      return Left(FileFailure('Error al restaurar backup: ${e.toString()}'));
    }
  }

  /// Lista todos los backups disponibles
  Future<Result<List<String>>> listBackups() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory(p.join(appDir.path, AppConstants.backupFolderName));
      
      if (!await backupDir.exists()) {
        return const Right([]);
      }

      final files = backupDir.listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.db'))
          .map((f) => f.path)
          .toList()
        ..sort((a, b) => b.compareTo(a)); // Más recientes primero

      return Right(files);
    } catch (e) {
      appLogger.e('Error listing backups', error: e);
      return Left(FileFailure('Error al listar backups: ${e.toString()}'));
    }
  }

  /// Elimina backups antiguos (más de 30 días)
  Future<Result<void>> cleanOldBackups({int daysToKeep = 30}) async {
    try {
      final backupsResult = await listBackups();
      if (backupsResult.isFailure) {
        return Left(backupsResult.errorOrNull!);
      }

      final backups = backupsResult.valueOrNull ?? [];
      final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
      int deletedCount = 0;

      for (final backupPath in backups) {
        final file = File(backupPath);
        final stat = await file.stat();
        
        if (stat.modified.isBefore(cutoffDate)) {
          await file.delete();
          deletedCount++;
        }
      }

      appLogger.i('Cleaned $deletedCount old backups');
      return const Right(null);
    } catch (e) {
      appLogger.e('Error cleaning old backups', error: e);
      return Left(FileFailure('Error al limpiar backups: ${e.toString()}'));
    }
  }

  /// Programa backup automático
  Future<void> scheduleAutomaticBackup({Duration interval = const Duration(days: 1)}) async {
    // TODO: Implementar con WorkManager o similar
    appLogger.i('Automatic backup scheduling not implemented yet');
  }
}

