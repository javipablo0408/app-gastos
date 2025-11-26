import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:app_contabilidad/presentation/viewmodels/categories_viewmodel.dart';
import 'package:app_contabilidad/domain/entities/category.dart';
import 'package:app_contabilidad/core/widgets/loading_widget.dart';
import 'package:app_contabilidad/presentation/widgets/bottom_navigation.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/datasources/local/file_service.dart';

/// Página de gestión de categorías
class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesViewModelProvider);
    final categoriesViewModel = ref.read(categoriesViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorías'),
      ),
      body: categoriesState.isLoading
          ? const LoadingWidget()
          : categoriesState.categories.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: () => categoriesViewModel.loadCategories(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: categoriesState.categories.length,
                    itemBuilder: (context, index) {
                      final category = categoriesState.categories[index];
                      return _buildCategoryCard(
                        context,
                        category,
                        categoriesViewModel,
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddCategoryDialog(context, categoriesViewModel),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context,
    Category category,
    CategoriesViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: category.imagePath != null && File(category.imagePath!).existsSync()
            ? ClipOval(
                child: Image.file(
                  File(category.imagePath!),
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return CircleAvatar(
                      backgroundColor: _parseColor(category.color),
                      child: Icon(
                        _parseIcon(category.icon),
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              )
            : CircleAvatar(
                backgroundColor: _parseColor(category.color),
                child: Icon(
                  _parseIcon(category.icon),
                  color: Colors.white,
                ),
              ),
        title: Text(category.name),
        subtitle: Text(_getTypeLabel(category.type)),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _showDeleteDialog(context, category, viewModel),
        ),
        onTap: () => _showEditCategoryDialog(context, category, viewModel),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.category,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay categorías',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar una',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  void _showAddCategoryDialog(
    BuildContext context,
    CategoriesViewModel viewModel,
  ) {
    _showCategoryDialog(context, viewModel);
  }

  void _showEditCategoryDialog(
    BuildContext context,
    Category category,
    CategoriesViewModel viewModel,
  ) {
    _showCategoryDialog(context, viewModel, category: category);
  }

  void _showCategoryDialog(
    BuildContext context,
    CategoriesViewModel viewModel, {
    Category? category,
  }) {
    final nameController = TextEditingController(text: category?.name ?? '');
    CategoryType selectedType = category?.type ?? CategoryType.expense;
    String selectedColor = category?.color ?? '#6366F1';
    String selectedIcon = category?.icon ?? 'shopping_cart';
    String? selectedImagePath = category?.imagePath;

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(category == null ? 'Nueva Categoría' : 'Editar Categoría'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    hintText: 'Ej: Comida',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CategoryType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: CategoryType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(_getTypeLabel(type)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Selector de color
                Text(
                  'Color',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    '#6366F1', '#EF4444', '#F59E0B', '#10B981', '#3B82F6',
                    '#8B5CF6', '#EC4899', '#F97316', '#06B6D4', '#84CC16',
                    '#6366F1', '#14B8A6', '#F43F5E', '#8B5CF6', '#0EA5E9',
                  ].map((colorHex) {
                    final isSelected = selectedColor == colorHex;
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = colorHex),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(colorHex),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.transparent,
                            width: isSelected ? 3 : 0,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Selector de imagen personalizada
                Text(
                  'Imagen Personalizada (Opcional)',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (selectedImagePath != null)
                      Expanded(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImagePath!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey.shade300,
                                    child: const Icon(Icons.broken_image),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                color: Colors.red,
                                onPressed: () => setState(() => selectedImagePath = null),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final fileService = ref.read(fileServiceProvider);
                            final result = await fileService.pickImageFromGallery();
                            result.fold(
                              (failure) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(failure.message)),
                                );
                              },
                              (imagePath) {
                                setState(() => selectedImagePath = imagePath);
                              },
                            );
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Cargar Imagen'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Selector de icono (solo si no hay imagen)
                if (selectedImagePath == null) ...[
                  Text(
                    'Icono',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _availableIcons.length,
                      itemBuilder: (context, index) {
                        final iconData = _availableIcons[index];
                        final iconString = _getIconString(iconData);
                        final isSelected = selectedIcon == iconString;
                        return GestureDetector(
                          onTap: () => setState(() => selectedIcon = iconString),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _parseColor(selectedColor)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? _parseColor(selectedColor)
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              color: isSelected ? Colors.white : Colors.grey.shade700,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                    ],
                  ],
                ),
              ),
              actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un nombre')),
                  );
                  return;
                }

                if (category == null) {
                  final result = await viewModel.createCategory(
                    name: nameController.text,
                    icon: selectedIcon,
                    color: selectedColor,
                    type: selectedType,
                    imagePath: selectedImagePath,
                  );

                  result.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failure.message)),
                      );
                    },
                    (_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoría creada')),
                      );
                    },
                  );
                } else {
                  final updated = category.copyWith(
                    name: nameController.text,
                    type: selectedType,
                    icon: selectedIcon,
                    color: selectedColor,
                    imagePath: selectedImagePath,
                  );

                  final result = await viewModel.updateCategory(updated);

                  result.fold(
                    (failure) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(failure.message)),
                      );
                    },
                    (_) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Categoría actualizada')),
                      );
                    },
                  );
                }
              },
              child: const Text('Guardar'),
            ),
              ],
            );
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    Category category,
    CategoriesViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Categoría'),
        content: Text('¿Estás seguro de eliminar "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await viewModel.deleteCategory(category.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Categoría eliminada')),
                );
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(CategoryType type) {
    switch (type) {
      case CategoryType.expense:
        return 'Gasto';
      case CategoryType.income:
        return 'Ingreso';
      case CategoryType.both:
        return 'Ambos';
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.grey;
    }
  }

  IconData _parseIcon(String iconString) {
    // Mapeo básico de iconos comunes
    final iconMap = {
      'shopping_cart': Icons.shopping_cart,
      'restaurant': Icons.restaurant,
      'home': Icons.home,
      'car': Icons.directions_car,
      'work': Icons.work,
      'school': Icons.school,
      'medical': Icons.medical_services,
      'entertainment': Icons.movie,
      'other': Icons.category,
      'trending_up': Icons.trending_up,
      'account_balance': Icons.account_balance,
      'savings': Icons.savings,
      'shopping_bag': Icons.shopping_bag,
      'fastfood': Icons.fastfood,
      'local_gas_station': Icons.local_gas_station,
      'fitness_center': Icons.fitness_center,
      'flight': Icons.flight,
      'hotel': Icons.hotel,
      'sports_soccer': Icons.sports_soccer,
      'music_note': Icons.music_note,
      'book': Icons.book,
      'laptop': Icons.laptop,
      'phone': Icons.phone,
      'wifi': Icons.wifi,
      'electric_bolt': Icons.electric_bolt,
      'water_drop': Icons.water_drop,
      'pets': Icons.pets,
      'child_care': Icons.child_care,
      'favorite': Icons.favorite,
      'gift': Icons.card_giftcard,
      'celebration': Icons.celebration,
      'local_hospital': Icons.local_hospital,
      'pharmacy': Icons.local_pharmacy,
      'beach_access': Icons.beach_access,
      'directions_bus': Icons.directions_bus,
      'train': Icons.train,
      'bike_scooter': Icons.bike_scooter,
    };
    return iconMap[iconString] ?? Icons.category;
  }

  String _getIconString(IconData iconData) {
    // Mapeo inverso de iconos
    final iconMap = {
      Icons.shopping_cart: 'shopping_cart',
      Icons.restaurant: 'restaurant',
      Icons.home: 'home',
      Icons.directions_car: 'car',
      Icons.work: 'work',
      Icons.school: 'school',
      Icons.medical_services: 'medical',
      Icons.movie: 'entertainment',
      Icons.category: 'other',
      Icons.trending_up: 'trending_up',
      Icons.account_balance: 'account_balance',
      Icons.savings: 'savings',
      Icons.shopping_bag: 'shopping_bag',
      Icons.fastfood: 'fastfood',
      Icons.local_gas_station: 'local_gas_station',
      Icons.fitness_center: 'fitness_center',
      Icons.flight: 'flight',
      Icons.hotel: 'hotel',
      Icons.sports_soccer: 'sports_soccer',
      Icons.music_note: 'music_note',
      Icons.book: 'book',
      Icons.laptop: 'laptop',
      Icons.phone: 'phone',
      Icons.wifi: 'wifi',
      Icons.electric_bolt: 'electric_bolt',
      Icons.water_drop: 'water_drop',
      Icons.pets: 'pets',
      Icons.child_care: 'child_care',
      Icons.favorite: 'favorite',
      Icons.card_giftcard: 'gift',
      Icons.celebration: 'celebration',
      Icons.local_hospital: 'local_hospital',
      Icons.local_pharmacy: 'pharmacy',
      Icons.beach_access: 'beach_access',
      Icons.directions_bus: 'directions_bus',
      Icons.train: 'train',
      Icons.bike_scooter: 'bike_scooter',
    };
    return iconMap[iconData] ?? 'other';
  }

  // Lista de iconos disponibles
  static final List<IconData> _availableIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.home,
    Icons.directions_car,
    Icons.work,
    Icons.school,
    Icons.medical_services,
    Icons.movie,
    Icons.category,
    Icons.trending_up,
    Icons.account_balance,
    Icons.savings,
    Icons.shopping_bag,
    Icons.fastfood,
    Icons.local_gas_station,
    Icons.fitness_center,
    Icons.flight,
    Icons.hotel,
    Icons.sports_soccer,
    Icons.music_note,
    Icons.book,
    Icons.laptop,
    Icons.phone,
    Icons.wifi,
    Icons.electric_bolt,
    Icons.water_drop,
    Icons.pets,
    Icons.child_care,
    Icons.favorite,
    Icons.card_giftcard,
    Icons.celebration,
    Icons.local_hospital,
    Icons.local_pharmacy,
    Icons.beach_access,
    Icons.directions_bus,
    Icons.train,
    Icons.bike_scooter,
  ];
}

