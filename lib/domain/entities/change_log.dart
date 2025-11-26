import 'package:equatable/equatable.dart';

/// Entidad de log de cambios para sincronización
class ChangeLog extends Equatable {
  final String id;
  final ChangeLogType type;
  final String entityType;
  final String entityId;
  final ChangeLogAction action;
  final DateTime timestamp;
  final bool synced;
  final Map<String, dynamic>? data;

  const ChangeLog({
    required this.id,
    required this.type,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.timestamp,
    this.synced = false,
    this.data,
  });

  ChangeLog copyWith({
    String? id,
    ChangeLogType? type,
    String? entityType,
    String? entityId,
    ChangeLogAction? action,
    DateTime? timestamp,
    bool? synced,
    Map<String, dynamic>? data,
  }) {
    return ChangeLog(
      id: id ?? this.id,
      type: type ?? this.type,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      timestamp: timestamp ?? this.timestamp,
      synced: synced ?? this.synced,
      data: data ?? this.data,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        entityType,
        entityId,
        action,
        timestamp,
        synced,
        data,
      ];
}

/// Tipo de log de cambios
enum ChangeLogType {
  create,
  update,
  delete,
}

/// Acción del log de cambios
enum ChangeLogAction {
  local,
  remote,
  merge,
}

