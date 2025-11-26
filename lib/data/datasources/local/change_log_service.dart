import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/change_log.dart';
import 'package:uuid/uuid.dart';

/// Servicio para gestionar logs de cambios para sincronización
class ChangeLogService {
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  ChangeLogService(this._databaseService);

  /// Registra la creación de una entidad
  Future<Result<ChangeLog>> logCreate({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final changeLog = ChangeLog(
        id: _uuid.v4(),
        type: ChangeLogType.create,
        entityType: entityType,
        entityId: entityId,
        action: ChangeLogAction.local,
        timestamp: DateTime.now(),
        synced: false,
        data: data,
      );

      final result = await _databaseService.createChangeLog(changeLog);
      return result.fold(
        (failure) => Left<Failure, ChangeLog>(failure),
        (log) => Right<Failure, ChangeLog>(log as ChangeLog),
      );
    } catch (e) {
      appLogger.e('Error logging create', error: e);
      return Left(DatabaseFailure('Error al registrar creación: ${e.toString()}'));
    }
  }

  /// Registra la actualización de una entidad
  Future<Result<ChangeLog>> logUpdate({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final changeLog = ChangeLog(
        id: _uuid.v4(),
        type: ChangeLogType.update,
        entityType: entityType,
        entityId: entityId,
        action: ChangeLogAction.local,
        timestamp: DateTime.now(),
        synced: false,
        data: data,
      );

      final result = await _databaseService.createChangeLog(changeLog);
      return result.fold(
        (failure) => Left<Failure, ChangeLog>(failure),
        (log) => Right<Failure, ChangeLog>(log as ChangeLog),
      );
    } catch (e) {
      appLogger.e('Error logging update', error: e);
      return Left(DatabaseFailure('Error al registrar actualización: ${e.toString()}'));
    }
  }

  /// Registra la eliminación de una entidad
  Future<Result<ChangeLog>> logDelete({
    required String entityType,
    required String entityId,
    Map<String, dynamic>? data,
  }) async {
    try {
      final changeLog = ChangeLog(
        id: _uuid.v4(),
        type: ChangeLogType.delete,
        entityType: entityType,
        entityId: entityId,
        action: ChangeLogAction.local,
        timestamp: DateTime.now(),
        synced: false,
        data: data,
      );

      final result = await _databaseService.createChangeLog(changeLog);
      return result.fold(
        (failure) => Left<Failure, ChangeLog>(failure),
        (log) => Right<Failure, ChangeLog>(log as ChangeLog),
      );
    } catch (e) {
      appLogger.e('Error logging delete', error: e);
      return Left(DatabaseFailure('Error al registrar eliminación: ${e.toString()}'));
    }
  }

  /// Obtiene todos los logs pendientes de sincronizar
  Future<Result<List<ChangeLog>>> getPendingLogs() async {
    return await _databaseService.getPendingChangeLogs();
  }

  /// Marca logs como sincronizados
  Future<Result<void>> markAsSynced(List<String> logIds) async {
    return await _databaseService.markChangeLogsAsSynced(logIds);
  }

  /// Limpia logs antiguos ya sincronizados (más de 30 días)
  Future<Result<void>> cleanOldSyncedLogs() async {
    try {
      // Esta funcionalidad se puede implementar en DatabaseService si es necesario
      // Por ahora, los logs se mantienen para auditoría
      return const Right(null);
    } catch (e) {
      appLogger.e('Error cleaning old synced logs', error: e);
      return Left(DatabaseFailure('Error al limpiar logs antiguos: ${e.toString()}'));
    }
  }
}

