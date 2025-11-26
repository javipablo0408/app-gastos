import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/tags_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/tag.dart';
import 'package:uuid/uuid.dart';

/// Estado de etiquetas
class TagsState {
  final List<Tag> tags;
  final bool isLoading;
  final String? error;

  TagsState({
    this.tags = const [],
    this.isLoading = false,
    this.error,
  });

  TagsState copyWith({
    List<Tag>? tags,
    bool? isLoading,
    String? error,
  }) {
    return TagsState(
      tags: tags ?? this.tags,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar etiquetas
class TagsViewModel extends StateNotifier<TagsState> {
  final TagsService _service;
  final Uuid _uuid = const Uuid();

  TagsViewModel(this._service) : super(TagsState()) {
    loadTags();
  }

  /// Carga todas las etiquetas
  Future<void> loadTags({bool forceRefresh = false}) async {
    if (!forceRefresh && state.tags.isNotEmpty && !state.isLoading) {
      return;
    }
    
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllTags();

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (tags) {
        state = state.copyWith(
          tags: tags,
          isLoading: false,
        );
      },
    );
  }

  /// Crea una nueva etiqueta
  Future<Result<Tag>> createTag({
    required String name,
    required String color,
  }) async {
    final tag = Tag(
      id: _uuid.v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _service.createTag(tag);

    result.fold(
      (failure) {},
      (created) {
        final currentTags = List<Tag>.from(state.tags);
        currentTags.insert(0, created);
        state = state.copyWith(
          tags: currentTags,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza una etiqueta
  Future<Result<Tag>> updateTag(Tag tag) async {
    final updated = tag.copyWith(updatedAt: DateTime.now());
    final result = await _service.updateTag(updated);

    result.fold(
      (failure) {},
      (updatedTag) {
        final currentTags = List<Tag>.from(state.tags);
        final index = currentTags.indexWhere((t) => t.id == updatedTag.id);
        if (index != -1) {
          currentTags[index] = updatedTag;
          state = state.copyWith(
            tags: currentTags,
            isLoading: false,
          );
        } else {
          loadTags(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina una etiqueta
  Future<Result<void>> deleteTag(String id) async {
    final result = await _service.deleteTag(id);

    result.fold(
      (failure) {},
      (_) {
        final currentTags = List<Tag>.from(state.tags);
        currentTags.removeWhere((t) => t.id == id);
        state = state.copyWith(
          tags: currentTags,
          isLoading: false,
        );
      },
    );

    return result;
  }
}

/// Provider del ViewModel de etiquetas
final tagsViewModelProvider =
    StateNotifierProvider.autoDispose<TagsViewModel, TagsState>((ref) {
  ref.keepAlive();
  final service = ref.watch(tagsServiceProvider);
  return TagsViewModel(service);
});

