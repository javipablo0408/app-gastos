import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:uuid/uuid.dart';

/// Servicio de inicialización de datos por defecto
class InitializationService {
  final DatabaseService _databaseService;
  final Uuid _uuid = const Uuid();

  InitializationService(this._databaseService);

  /// Inicializa categorías por defecto si no existen
  Future<void> initializeDefaultCategories() async {
    final categoriesResult = await _databaseService.getAllCategories();
    
    if (categoriesResult.isFailure) return;
    
    final existingCategories = categoriesResult.valueOrNull ?? [];
    
    // Si ya hay categorías, no inicializar
    if (existingCategories.isNotEmpty) return;

    // IDs fijos para categorías por defecto (para mantener consistencia)
    // Categorías de gastos por defecto
    final defaultCategories = [
      Category(
        id: 'default-expense-food',
        name: 'Comida',
        icon: 'restaurant',
        color: '#FF6B6B',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-transport',
        name: 'Transporte',
        icon: 'car',
        color: '#4ECDC4',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-shopping',
        name: 'Compras',
        icon: 'shopping_cart',
        color: '#95E1D3',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-entertainment',
        name: 'Entretenimiento',
        icon: 'entertainment',
        color: '#F38181',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-health',
        name: 'Salud',
        icon: 'medical',
        color: '#AA96DA',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-education',
        name: 'Educación',
        icon: 'school',
        color: '#FCBAD3',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-expense-home',
        name: 'Hogar',
        icon: 'home',
        color: '#FFD93D',
        type: CategoryType.expense,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      // Categorías de ingresos por defecto
      Category(
        id: 'default-income-salary',
        name: 'Salario',
        icon: 'work',
        color: '#6BCB77',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-income-freelance',
        name: 'Freelance',
        icon: 'work',
        color: '#4D96FF',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-income-investments',
        name: 'Inversiones',
        icon: 'trending_up',
        color: '#95E1D3',
        type: CategoryType.income,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Category(
        id: 'default-both-other',
        name: 'Otros',
        icon: 'other',
        color: '#C7CEEA',
        type: CategoryType.both,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Crear todas las categorías (solo si no existen)
    for (final category in defaultCategories) {
      // Verificar si la categoría ya existe antes de crearla
      final existingCategoryResult = await _databaseService.getCategoryById(category.id);
      final shouldCreate = existingCategoryResult.fold(
        (_) => true, // Si hay error, intentar crear
        (existingCategory) => existingCategory == null, // Si no existe, crear
      );
      
      if (shouldCreate) {
        await _databaseService.createCategory(category);
      }
    }
  }
}


