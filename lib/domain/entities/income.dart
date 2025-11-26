import 'package:equatable/equatable.dart';
import 'package:app_contabilidad/domain/entities/category.dart';

/// Entidad de ingreso
class Income extends Equatable {
  final String id;
  final double amount;
  final String description;
  final String categoryId;
  final Category? category;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? syncId;
  final int version;

  const Income({
    required this.id,
    required this.amount,
    required this.description,
    required this.categoryId,
    this.category,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.syncId,
    this.version = 1,
  });

  Income copyWith({
    String? id,
    double? amount,
    String? description,
    String? categoryId,
    Category? category,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? syncId,
    int? version,
  }) {
    return Income(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      category: category ?? this.category,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      syncId: syncId ?? this.syncId,
      version: version ?? this.version,
    );
  }

  @override
  List<Object?> get props => [
        id,
        amount,
        description,
        categoryId,
        category,
        date,
        createdAt,
        updatedAt,
        isDeleted,
        syncId,
        version,
      ];
}

