import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' hide ChangeLog;
import 'package:app_contabilidad/data/models/database.dart' as drift show ChangeLog;
import 'package:app_contabilidad/domain/entities/change_log.dart' as domain;

/// Extensión para convertir ChangeLog (entidad) a ChangeLogCompanion (modelo)
extension ChangeLogModelExtension on domain.ChangeLog {
  ChangeLogsCompanion toCompanion() {
    return ChangeLogsCompanion.insert(
      id: id,
      type: _mapChangeLogTypeToInt(type),
      entityType: entityType,
      entityId: entityId,
      action: _mapChangeLogActionToInt(action),
      timestamp: timestamp,
      synced: Value(synced),
      data: Value(data != null ? jsonEncode(data) : null),
    );
  }
}

/// Extensión para convertir ChangeLog (modelo Drift) a ChangeLog (entidad)
extension ChangeLogDataExtension on drift.ChangeLog {
  domain.ChangeLog toEntity() {
    return domain.ChangeLog(
      id: id,
      type: _mapChangeLogTypeFromInt(type),
      entityType: entityType,
      entityId: entityId,
      action: _mapChangeLogActionFromInt(action),
      timestamp: timestamp,
      synced: synced,
      data: data != null ? jsonDecode(data!) as Map<String, dynamic> : null,
    );
  }
}

/// Mapea ChangeLogType a int
int _mapChangeLogTypeToInt(domain.ChangeLogType type) {
  switch (type) {
    case domain.ChangeLogType.create:
      return 0;
    case domain.ChangeLogType.update:
      return 1;
    case domain.ChangeLogType.delete:
      return 2;
  }
}

/// Mapea int a ChangeLogType
domain.ChangeLogType _mapChangeLogTypeFromInt(int value) {
  switch (value) {
    case 0:
      return domain.ChangeLogType.create;
    case 1:
      return domain.ChangeLogType.update;
    case 2:
      return domain.ChangeLogType.delete;
    default:
      return domain.ChangeLogType.create;
  }
}

/// Mapea ChangeLogAction a int
int _mapChangeLogActionToInt(domain.ChangeLogAction action) {
  switch (action) {
    case domain.ChangeLogAction.local:
      return 0;
    case domain.ChangeLogAction.remote:
      return 1;
    case domain.ChangeLogAction.merge:
      return 2;
  }
}

/// Mapea int a ChangeLogAction
domain.ChangeLogAction _mapChangeLogActionFromInt(int value) {
  switch (value) {
    case 0:
      return domain.ChangeLogAction.local;
    case 1:
      return domain.ChangeLogAction.remote;
    case 2:
      return domain.ChangeLogAction.merge;
    default:
      return domain.ChangeLogAction.local;
  }
}

