import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/budget.dart';
import 'package:app_contabilidad/domain/entities/savings_goal.dart';

/// Servicio de notificaciones y alertas
class NotificationService {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializa el servicio de notificaciones
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
    appLogger.i('Notification service initialized');
  }

  /// Maneja el tap en una notificación
  void _onNotificationTapped(NotificationResponse response) {
    appLogger.i('Notification tapped: ${response.payload}');
    // TODO: Navegar a la pantalla correspondiente
  }

  /// Muestra una notificación simple
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'app_contabilidad',
      'Notificaciones',
      channelDescription: 'Notificaciones de la app de contabilidad',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  /// Programa una notificación
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'app_contabilidad',
      'Notificaciones',
      channelDescription: 'Notificaciones programadas',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledDate, tz.local),
      details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Notifica sobre presupuesto excedido
  Future<void> notifyBudgetExceeded(Budget budget, double usedAmount) async {
    final percentage = budget.getUsedPercentage(usedAmount);
    await showNotification(
      id: 1,
      title: '⚠️ Presupuesto Excedido',
      body:
          'El presupuesto de "${budget.category?.name}" está al ${percentage.toStringAsFixed(1)}%',
      payload: 'budget:${budget.id}',
    );
  }

  /// Notifica sobre presupuesto cerca del límite
  Future<void> notifyBudgetNearLimit(Budget budget, double usedAmount) async {
    final percentage = budget.getUsedPercentage(usedAmount);
    await showNotification(
      id: 2,
      title: '📊 Presupuesto Cerca del Límite',
      body:
          'El presupuesto de "${budget.category?.name}" está al ${percentage.toStringAsFixed(1)}%',
      payload: 'budget:${budget.id}',
    );
  }

  /// Notifica sobre objetivo de ahorro alcanzado
  Future<void> notifyGoalReached(SavingsGoal goal) async {
    await showNotification(
      id: 3,
      title: '🎉 ¡Objetivo Alcanzado!',
      body: 'Has alcanzado tu objetivo: "${goal.name}"',
      payload: 'goal:${goal.id}',
    );
  }

  /// Notifica sobre objetivo cerca del límite
  Future<void> notifyGoalNearLimit(SavingsGoal goal) async {
    final percentage = goal.getCompletionPercentage();
    await showNotification(
      id: 4,
      title: '💪 Casi lo Logras',
      body:
          'Tu objetivo "${goal.name}" está al ${percentage.toStringAsFixed(1)}%',
      payload: 'goal:${goal.id}',
    );
  }

  /// Programa recordatorio de gasto recurrente
  Future<void> scheduleRecurringExpenseReminder({
    required int id,
    required String description,
    required DateTime date,
  }) async {
    await scheduleNotification(
      id: id,
      title: '💸 Recordatorio de Gasto',
      body: 'No olvides registrar: $description',
      scheduledDate: date,
      payload: 'recurring:$id',
    );
  }

  /// Cancela una notificación programada
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancela todas las notificaciones
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}

