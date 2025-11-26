import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:app_contabilidad/core/utils/constants.dart';
import 'package:app_contabilidad/core/utils/logger.dart';

part 'database.g.dart';

/// Tabla de categorías
class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get imagePath => text().nullable()(); // Ruta de imagen personalizada
  IntColumn get type => integer()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de gastos
class Expenses extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get billFilePath => text().nullable()(); // Ruta del archivo PDF de factura
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de ingresos
class Incomes extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get description => text()();
  TextColumn get categoryId => text()();
  DateTimeColumn get date => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de presupuestos
class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text()();
  RealColumn get amount => real()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de logs de cambios
class ChangeLogs extends Table {
  TextColumn get id => text()();
  IntColumn get type => integer()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  IntColumn get action => integer()();
  DateTimeColumn get timestamp => dateTime()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  TextColumn get data => text().nullable()(); // JSON string

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de gastos recurrentes
class RecurringExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get categoryId => text()();
  IntColumn get recurrenceType => integer()(); // 0=daily, 1=weekly, 2=monthly, 3=yearly
  IntColumn get recurrenceValue => integer()(); // Cada cuántos días/semanas/meses
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastExecuted => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de ingresos recurrentes
class RecurringIncomes extends Table {
  TextColumn get id => text()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get categoryId => text()();
  IntColumn get recurrenceType => integer()(); // 0=daily, 1=weekly, 2=monthly, 3=yearly
  IntColumn get recurrenceValue => integer()(); // Cada cuántos días/semanas/meses
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get lastExecuted => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de objetivos de ahorro
class SavingsGoals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text()();
  RealColumn get targetAmount => real()();
  RealColumn get currentAmount => real().withDefault(const Constant(0.0))();
  DateTimeColumn get targetDate => dateTime()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de etiquetas/tags
class Tags extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de relación gastos-etiquetas
class ExpenseTags extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de relación ingresos-etiquetas
class IncomeTags extends Table {
  TextColumn get id => text()();
  TextColumn get incomeId => text()();
  TextColumn get tagId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de gastos compartidos
class SharedExpenses extends Table {
  TextColumn get id => text()();
  TextColumn get expenseId => text()();
  TextColumn get participants => text()(); // JSON string de participantes
  IntColumn get splitType => integer()(); // 0=equal, 1=percentage, 2=amount
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Tabla de facturas/pagos
class Bills extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  RealColumn get amount => real()();
  TextColumn get categoryId => text().nullable()();
  DateTimeColumn get dueDate => dateTime()();
  DateTimeColumn get paidDate => dateTime().nullable()();
  BoolColumn get isPaid => boolean().withDefault(const Constant(false))();
  IntColumn get reminderDays => integer().withDefault(const Constant(3))(); // Días antes para recordatorio
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// Los enums están definidos en domain/entities para evitar duplicación

/// Base de datos principal
@DriftDatabase(tables: [
  Categories,
  Expenses,
  Incomes,
  Budgets,
  ChangeLogs,
  RecurringExpenses,
  RecurringIncomes,
  SavingsGoals,
  Tags,
  ExpenseTags,
  IncomeTags,
  SharedExpenses,
  Bills,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        // Crear índices para mejorar rendimiento
        await customStatement('CREATE INDEX idx_expenses_date ON expenses(date)');
        await customStatement('CREATE INDEX idx_expenses_category ON expenses(category_id)');
        await customStatement('CREATE INDEX idx_incomes_date ON incomes(date)');
        await customStatement('CREATE INDEX idx_incomes_category ON incomes(category_id)');
        await customStatement('CREATE INDEX idx_changelog_synced ON change_logs(synced)');
        await customStatement('CREATE INDEX idx_changelog_timestamp ON change_logs(timestamp)');
        await customStatement('CREATE INDEX idx_recurring_expenses_active ON recurring_expenses(is_active)');
        await customStatement('CREATE INDEX idx_recurring_expenses_start ON recurring_expenses(start_date)');
        await customStatement('CREATE INDEX idx_recurring_incomes_active ON recurring_incomes(is_active)');
        await customStatement('CREATE INDEX idx_recurring_incomes_start ON recurring_incomes(start_date)');
        await customStatement('CREATE INDEX idx_savings_completed ON savings_goals(is_completed)');
        await customStatement('CREATE INDEX idx_expense_tags_expense ON expense_tags(expense_id)');
        await customStatement('CREATE INDEX idx_expense_tags_tag ON expense_tags(tag_id)');
        await customStatement('CREATE INDEX idx_income_tags_income ON income_tags(income_id)');
        await customStatement('CREATE INDEX idx_income_tags_tag ON income_tags(tag_id)');
        await customStatement('CREATE INDEX idx_bills_due_date ON bills(due_date)');
        await customStatement('CREATE INDEX idx_bills_paid ON bills(is_paid)');
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Migración de versión 1 a 2: agregar tablas nuevas
          await m.createTable(recurringExpenses);
          await m.createTable(savingsGoals);
          await customStatement('CREATE INDEX idx_recurring_expenses_active ON recurring_expenses(is_active)');
          await customStatement('CREATE INDEX idx_recurring_expenses_start ON recurring_expenses(start_date)');
          await customStatement('CREATE INDEX idx_savings_completed ON savings_goals(is_completed)');
        }
        if (from < 3) {
          // Migración de versión 2 a 3: agregar tabla de ingresos recurrentes
          await m.createTable(recurringIncomes);
          await customStatement('CREATE INDEX idx_recurring_incomes_active ON recurring_incomes(is_active)');
          await customStatement('CREATE INDEX idx_recurring_incomes_start ON recurring_incomes(start_date)');
        }
        if (from < 4) {
          // Migración de versión 3 a 4: agregar campo imagePath a categorías
          await customStatement('ALTER TABLE categories ADD COLUMN image_path TEXT');
        }
        if (from < 5) {
          // Migración de versión 4 a 5: agregar tablas de tags, gastos compartidos y facturas
          await m.createTable(tags);
          await m.createTable(expenseTags);
          await m.createTable(incomeTags);
          await m.createTable(sharedExpenses);
          await m.createTable(bills);
          await customStatement('CREATE INDEX idx_expense_tags_expense ON expense_tags(expense_id)');
          await customStatement('CREATE INDEX idx_expense_tags_tag ON expense_tags(tag_id)');
          await customStatement('CREATE INDEX idx_income_tags_income ON income_tags(income_id)');
          await customStatement('CREATE INDEX idx_income_tags_tag ON income_tags(tag_id)');
          await customStatement('CREATE INDEX idx_bills_due_date ON bills(due_date)');
          await customStatement('CREATE INDEX idx_bills_paid ON bills(is_paid)');
        }
        if (from < 6) {
          // Migración de versión 5 a 6: agregar columna bill_file_path a expenses
          // SQLite no tiene forma directa de verificar si una columna existe,
          // así que intentamos agregarla y si falla, asumimos que ya existe
          try {
            await customStatement('ALTER TABLE expenses ADD COLUMN bill_file_path TEXT');
            appLogger.i('Migración v6: Columna bill_file_path agregada exitosamente');
          } catch (e) {
            // Si la columna ya existe, SQLite lanzará un error pero podemos continuar
            final errorMsg = e.toString().toLowerCase();
            if (errorMsg.contains('duplicate column') || 
                errorMsg.contains('already exists')) {
              appLogger.i('Migración v6: Columna bill_file_path ya existe, omitiendo');
            } else {
              // Otro tipo de error, lo registramos pero continuamos
              appLogger.w('Migración v6: Error al agregar columna bill_file_path: $e');
            }
          }
        }
      },
    );
  }
}

/// Abre la conexión a la base de datos
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, AppConstants.databaseName));
    return NativeDatabase(file);
  });
}

