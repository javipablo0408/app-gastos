import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:app_contabilidad/core/providers/database_provider.dart';
export 'package:app_contabilidad/core/providers/database_provider.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/file_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/data/datasources/local/report_service.dart';
import 'package:app_contabilidad/data/datasources/remote/sync_service.dart';
import 'package:app_contabilidad/data/services/search_service.dart';
import 'package:app_contabilidad/data/services/recurring_expenses_service.dart';
import 'package:app_contabilidad/data/services/recurring_incomes_service.dart';
import 'package:app_contabilidad/data/services/savings_goals_service.dart';
import 'package:app_contabilidad/data/services/statistics_service.dart';
import 'package:app_contabilidad/data/services/notification_service.dart';
import 'package:app_contabilidad/data/services/currency_service.dart';
import 'package:app_contabilidad/data/services/ocr_service.dart';
import 'package:app_contabilidad/data/services/backup_service.dart';
import 'package:app_contabilidad/data/services/recurring_executor_service.dart';
import 'package:app_contabilidad/data/services/export_service.dart';
import 'package:app_contabilidad/data/services/tags_service.dart';
import 'package:app_contabilidad/data/services/bills_service.dart';
import 'package:app_contabilidad/data/services/shared_expenses_service.dart';
import 'package:app_contabilidad/data/services/debt_analysis_service.dart';
import 'package:app_contabilidad/data/services/financial_projection_service.dart';
import 'package:app_contabilidad/data/services/period_comparison_service.dart';
import 'package:app_contabilidad/data/services/intelligent_suggestions_service.dart';

/// Provider del servicio de archivos
final fileServiceProvider = Provider<FileService>((ref) {
  return FileService();
});

/// Provider del servicio de logs de cambios
final changeLogServiceProvider = Provider<ChangeLogService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return ChangeLogService(databaseService);
});

/// Provider del servicio de reportes
final reportServiceProvider = Provider<ReportService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return ReportService(databaseService);
});

/// Provider del cliente HTTP
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Provider del servicio de sincronización
final syncServiceProvider = Provider<SyncService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final httpClient = ref.watch(httpClientProvider);
  final service = SyncService(databaseService, changeLogService, httpClient);
  service.initialize();
  return service;
});

/// Provider del servicio de búsqueda
final searchServiceProvider = Provider<SearchService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return SearchService(databaseService);
});

/// Provider del servicio de gastos recurrentes
final recurringExpensesServiceProvider = Provider<RecurringExpensesService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  return RecurringExpensesService(databaseService, changeLogService);
});

/// Provider del servicio de ingresos recurrentes
final recurringIncomesServiceProvider = Provider<RecurringIncomesService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  return RecurringIncomesService(databaseService, changeLogService);
});

final savingsGoalsServiceProvider = Provider<SavingsGoalsService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  return SavingsGoalsService(databaseService, changeLogService);
});

/// Provider del servicio de estadísticas
final statisticsServiceProvider = Provider<StatisticsService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return StatisticsService(databaseService);
});

/// Provider del servicio de notificaciones
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService();
  service.initialize();
  return service;
});

/// Provider del servicio de monedas
final currencyServiceProvider = Provider<CurrencyService>((ref) {
  return CurrencyService();
});

/// Provider del servicio OCR
final ocrServiceProvider = Provider<OCRService>((ref) {
  return OCRService();
});

/// Provider del servicio de backup
final backupServiceProvider = Provider<BackupService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return BackupService(databaseService);
});

/// Provider del servicio ejecutor de recurrentes
final recurringExecutorServiceProvider = Provider<RecurringExecutorService>((ref) {
  final recurringExpensesService = ref.watch(recurringExpensesServiceProvider);
  final recurringIncomesService = ref.watch(recurringIncomesServiceProvider);
  return RecurringExecutorService(recurringExpensesService, recurringIncomesService);
});

/// Provider del servicio de exportación
final exportServiceProvider = Provider<ExportService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return ExportService(databaseService);
});

/// Provider del servicio de etiquetas
final tagsServiceProvider = Provider<TagsService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  return TagsService(databaseService, changeLogService);
});

/// Provider del servicio de facturas
final billsServiceProvider = Provider<BillsService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return BillsService(databaseService, changeLogService, notificationService);
});

/// Provider del servicio de gastos compartidos
final sharedExpensesServiceProvider = Provider<SharedExpensesService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  final changeLogService = ref.watch(changeLogServiceProvider);
  return SharedExpensesService(databaseService, changeLogService);
});

/// Provider del servicio de análisis de deudas
final debtAnalysisServiceProvider = Provider<DebtAnalysisService>((ref) {
  final sharedExpensesService = ref.watch(sharedExpensesServiceProvider);
  return DebtAnalysisService(sharedExpensesService);
});

/// Provider del servicio de proyecciones financieras
final financialProjectionServiceProvider = Provider<FinancialProjectionService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return FinancialProjectionService(databaseService);
});

/// Provider del servicio de comparación de períodos
final periodComparisonServiceProvider = Provider<PeriodComparisonService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return PeriodComparisonService(databaseService);
});

/// Provider del servicio de sugerencias inteligentes
final intelligentSuggestionsServiceProvider = Provider<IntelligentSuggestionsService>((ref) {
  final databaseService = ref.watch(databaseServiceProvider);
  return IntelligentSuggestionsService(databaseService);
});

