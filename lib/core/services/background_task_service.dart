import 'dart:io';
import 'package:workmanager/workmanager.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/data/services/recurring_executor_service.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/data/services/recurring_expenses_service.dart';
import 'package:app_contabilidad/data/services/recurring_incomes_service.dart';
import 'package:app_contabilidad/data/models/database.dart' as db;

/// Servicio para gestionar tareas en segundo plano
class BackgroundTaskService {
  static const String recurringTaskName = 'recurringTransactionsTask';
  static const String recurringTaskTag = 'recurring_transactions';

  /// Verifica si la plataforma soporta workmanager
  static bool get isSupported => Platform.isAndroid || Platform.isIOS;

  /// Inicializa el servicio de tareas en segundo plano
  static Future<void> initialize() async {
    if (!isSupported) {
      appLogger.i('BackgroundTaskService: Workmanager no está disponible en esta plataforma');
      return;
    }

    try {
      await Workmanager().initialize(
        callbackDispatcher,
        isInDebugMode: false,
      );
      appLogger.i('BackgroundTaskService inicializado');
    } catch (e) {
      appLogger.w('Error inicializando BackgroundTaskService: $e');
      // No lanzar error, solo registrar
    }
  }

  /// Programa la ejecución diaria de transacciones recurrentes
  static Future<void> scheduleRecurringTransactions() async {
    if (!isSupported) {
      appLogger.i('BackgroundTaskService: Programación de tareas no disponible en esta plataforma');
      return;
    }

    try {
      await Workmanager().registerPeriodicTask(
        recurringTaskName,
        recurringTaskTag,
        frequency: const Duration(hours: 24),
        initialDelay: const Duration(minutes: 5),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
      appLogger.i('Tarea periódica de transacciones recurrentes programada');
    } catch (e) {
      appLogger.w('Error programando tarea periódica: $e');
      // No lanzar error, solo registrar
    }
  }

  /// Cancela la tarea periódica
  static Future<void> cancelRecurringTransactions() async {
    if (!isSupported) {
      return;
    }

    try {
      await Workmanager().cancelByUniqueName(recurringTaskName);
      appLogger.i('Tarea periódica de transacciones recurrentes cancelada');
    } catch (e) {
      appLogger.w('Error cancelando tarea periódica: $e');
      // No lanzar error, solo registrar
    }
  }
}

/// Callback que se ejecuta cuando workmanager ejecuta la tarea
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    appLogger.i('Ejecutando tarea en segundo plano: ${task}');

    if (task == BackgroundTaskService.recurringTaskTag) {
      try {
        // Crear instancias necesarias
        final database = db.AppDatabase();
        final databaseService = DatabaseService(database);
        final changeLogService = ChangeLogService(databaseService);
        final recurringExpensesService = RecurringExpensesService(
          databaseService,
          changeLogService,
        );
        final recurringIncomesService = RecurringIncomesService(
          databaseService,
          changeLogService,
        );
        final executorService = RecurringExecutorService(
          recurringExpensesService,
          recurringIncomesService,
        );

        // Ejecutar transacciones recurrentes
        final result = await executorService.executeDueRecurringTransactions();
        
        result.fold(
          (failure) {
            appLogger.e('Error ejecutando transacciones recurrentes', error: failure);
            return Future.value(false);
          },
          (executionResult) {
            appLogger.i(
              'Transacciones recurrentes ejecutadas: ${executionResult.totalCreated}',
            );
            return Future.value(true);
          },
        );

        await database.close();
        return Future.value(true);
      } catch (e) {
        appLogger.e('Error en callback de workmanager', error: e);
        return Future.value(false);
      }
    }

    return Future.value(false);
  });
}

