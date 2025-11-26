import 'package:equatable/equatable.dart';

/// Entidad de categoría
class Category extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String color;
  final String? imagePath; // Ruta de imagen personalizada
  final CategoryType type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.imagePath,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
  });

  Category copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? imagePath,
    CategoryType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      imagePath: imagePath ?? this.imagePath,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        color,
        imagePath,
        type,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
      ];
}

/// Tipo de categoría
enum CategoryType {
  expense,
  income,
  both,
}

