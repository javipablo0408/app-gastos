import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/domain/entities/tag.dart';

/// Servicio para gestionar etiquetas/tags
class TagsService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;

  TagsService(this._databaseService, this._changeLogService);

  /// Obtiene todas las etiquetas
  Future<Result<List<Tag>>> getAllTags({bool includeDeleted = false}) async {
    return await _databaseService.getAllTags(includeDeleted: includeDeleted);
  }

  /// Crea una etiqueta
  Future<Result<Tag>> createTag(Tag tag) async {
    final result = await _databaseService.createTag(tag);
    result.fold(
      (_) {},
      (created) async {
        await _changeLogService.logCreate(
          entityType: 'tag',
          entityId: created.id,
        );
      },
    );
    return result;
  }

  /// Actualiza una etiqueta
  Future<Result<Tag>> updateTag(Tag tag) async {
    final result = await _databaseService.updateTag(tag);
    result.fold(
      (_) {},
      (updated) async {
        await _changeLogService.logUpdate(
          entityType: 'tag',
          entityId: updated.id,
        );
      },
    );
    return result;
  }

  /// Elimina una etiqueta
  Future<Result<void>> deleteTag(String id) async {
    final result = await _databaseService.deleteTag(id);
    result.fold(
      (_) {},
      (_) async {
        await _changeLogService.logDelete(
          entityType: 'tag',
          entityId: id,
        );
      },
    );
    return result;
  }
}

