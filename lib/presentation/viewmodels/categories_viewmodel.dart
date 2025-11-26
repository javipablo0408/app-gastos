import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:uuid/uuid.dart';

/// Estado de la lista de categorías
class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? error;

  CategoriesState({
    this.categories = const [],
    this.isLoading = false,
    this.error,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? error,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// ViewModel para gestionar categorías
class CategoriesViewModel extends StateNotifier<CategoriesState> {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final Uuid _uuid = const Uuid();

  CategoriesViewModel(this._databaseService, this._changeLogService)
      : super(CategoriesState()) {
    // Cargar datos iniciales
    loadCategories();
  }

  /// Carga todas las categorías
  Future<void> loadCategories({bool forceRefresh = false}) async {
    // Si ya hay datos y no es un refresh forzado, no cargar
    if (!forceRefresh && state.categories.isNotEmpty && !state.isLoading) {
      return;
    }
    
    // Si ya está cargando, no iniciar otra carga
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _databaseService.getAllCategories();

    result.fold(
      (failure) {
        appLogger.e('Error loading categories: ${failure.message}');
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (categories) {
        appLogger.d('Loaded ${categories.length} categories');
        state = state.copyWith(
          categories: categories,
          isLoading: false,
          error: null,
        );
      },
    );
  }

  /// Crea una nueva categoría
  Future<Result<Category>> createCategory({
    required String name,
    required String icon,
    required String color,
    required CategoryType type,
    String? imagePath,
  }) async {
    final category = Category(
      id: _uuid.v4(),
      name: name,
      icon: icon,
      color: color,
      imagePath: imagePath,
      type: type,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _databaseService.createCategory(category);

    result.fold(
      (failure) {},
      (createdCategory) async {
        // Registrar en change log
        await _changeLogService.logCreate(
          entityType: 'category',
          entityId: createdCategory.id,
        );
        // Recargar lista
        await loadCategories(forceRefresh: true);
      },
    );

    return result;
  }

  /// Actualiza una categoría
  Future<Result<Category>> updateCategory(Category category) async {
    final updated = category.copyWith(updatedAt: DateTime.now());
    final result = await _databaseService.updateCategory(updated);

    result.fold(
      (failure) {},
      (updatedCategory) async {
        // Registrar en change log
        await _changeLogService.logUpdate(
          entityType: 'category',
          entityId: updatedCategory.id,
        );
        // Recargar lista
        await loadCategories(forceRefresh: true);
      },
    );

    return result;
  }

  /// Elimina una categoría
  Future<Result<void>> deleteCategory(String id) async {
    final result = await _databaseService.deleteCategory(id);

    result.fold(
      (failure) {},
      (_) async {
        // Registrar en change log
        await _changeLogService.logDelete(
          entityType: 'category',
          entityId: id,
        );
        // Recargar lista
        await loadCategories(forceRefresh: true);
      },
    );

    return result;
  }
}

/// Provider del ViewModel de categorías
final categoriesViewModelProvider =
    StateNotifierProvider.autoDispose<CategoriesViewModel, CategoriesState>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final viewModel = CategoriesViewModel(databaseService, changeLogService);
  // Mantener el provider vivo para evitar recargas innecesarias
  ref.keepAlive();
  return viewModel;
});

