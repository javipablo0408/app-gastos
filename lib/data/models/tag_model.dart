import 'package:drift/drift.dart';
import 'package:app_contabilidad/data/models/database.dart' as db;
import 'package:app_contabilidad/domain/entities/tag.dart';

/// Extensión para convertir Tag a Companion de Drift
extension TagModelExtension on Tag {
  db.TagsCompanion toCompanion() {
    return db.TagsCompanion(
      id: Value(id),
      name: Value(name),
      color: Value(color),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      syncId: Value(syncId),
    );
  }
}

/// Extensión para convertir Drift Tag a Entity
extension TagDataExtension on db.Tag {
  Tag toEntity() {
    return Tag(
      id: id,
      name: name,
      color: color,
      createdAt: createdAt,
      updatedAt: updatedAt,
      isDeleted: isDeleted,
      syncId: syncId,
    );
  }
}

