import 'package:dartz/dartz.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';
import 'package:app_contabilidad/data/datasources/local/database_service.dart';
import 'package:app_contabilidad/data/datasources/local/change_log_service.dart';
import 'package:app_contabilidad/data/services/notification_service.dart';
import 'package:app_contabilidad/domain/entities/bill.dart';

/// Servicio para gestionar facturas/pagos
class BillsService {
  final DatabaseService _databaseService;
  final ChangeLogService _changeLogService;
  final NotificationService _notificationService;

  BillsService(
    this._databaseService,
    this._changeLogService,
    this._notificationService,
  );

  /// Obtiene todas las facturas
  Future<Result<List<Bill>>> getAllBills({
    bool includeDeleted = false,
    bool unpaidOnly = false,
  }) async {
    return await _databaseService.getAllBills(
      includeDeleted: includeDeleted,
      unpaidOnly: unpaidOnly,
    );
  }

  /// Obtiene facturas próximas a vencer
  Future<Result<List<Bill>>> getUpcomingBills() async {
    final result = await getAllBills(unpaidOnly: true);
    return result.fold(
      (failure) => Left(failure),
      (bills) {
        final now = DateTime.now();
        final upcoming = bills.where((bill) {
          final daysUntilDue = bill.dueDate.difference(now).inDays;
          return daysUntilDue <= bill.reminderDays && daysUntilDue >= 0;
        }).toList();
        return Right(upcoming);
      },
    );
  }

  /// Crea una factura
  Future<Result<Bill>> createBill(Bill bill) async {
    final result = await _databaseService.createBill(bill);
    result.fold(
      (_) {},
      (created) async {
        await _changeLogService.logCreate(
          entityType: 'bill',
          entityId: created.id,
        );
        // Programar recordatorio si está próximo a vencer
        if (created.isDueSoon) {
          await _scheduleBillReminder(created);
        }
      },
    );
    return result;
  }

  /// Actualiza una factura
  Future<Result<Bill>> updateBill(Bill bill) async {
    final result = await _databaseService.updateBill(bill);
    result.fold(
      (_) {},
      (updated) async {
        await _changeLogService.logUpdate(
          entityType: 'bill',
          entityId: updated.id,
        );
        // Reprogramar recordatorio si es necesario
        if (updated.isDueSoon && !updated.isPaid) {
          await _scheduleBillReminder(updated);
        }
      },
    );
    return result;
  }

  /// Marca una factura como pagada
  Future<Result<Bill>> markBillAsPaid(String id) async {
    final billsResult = await getAllBills();
    return billsResult.fold(
      (failure) => Left(failure),
      (bills) async {
        final bill = bills.firstWhere((b) => b.id == id);
        final updated = bill.copyWith(
          isPaid: true,
          paidDate: DateTime.now(),
        );
        return await updateBill(updated);
      },
    );
  }

  /// Elimina una factura
  Future<Result<void>> deleteBill(String id) async {
    final result = await _databaseService.deleteBill(id);
    result.fold(
      (_) {},
      (_) async {
        await _changeLogService.logDelete(
          entityType: 'bill',
          entityId: id,
        );
      },
    );
    return result;
  }

  /// Programa un recordatorio para una factura
  Future<void> _scheduleBillReminder(Bill bill) async {
    final reminderDate = bill.dueDate.subtract(Duration(days: bill.reminderDays));
    if (reminderDate.isAfter(DateTime.now())) {
      await _notificationService.scheduleNotification(
        id: bill.id.hashCode,
        title: '💳 Recordatorio de Factura',
        body: 'La factura "${bill.name}" vence el ${bill.dueDate.day}/${bill.dueDate.month}',
        scheduledDate: reminderDate,
        payload: 'bill:${bill.id}',
      );
    }
  }

  /// Verifica y programa recordatorios para todas las facturas próximas
  Future<void> checkAndScheduleReminders() async {
    final result = await getUpcomingBills();
    result.fold(
      (failure) => appLogger.e('Error obteniendo facturas próximas', error: failure),
      (bills) async {
        for (final bill in bills) {
          await _scheduleBillReminder(bill);
        }
      },
    );
  }
}

