import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_contabilidad/core/providers/providers.dart';
import 'package:app_contabilidad/data/services/bills_service.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/domain/entities/bill.dart';
import 'package:uuid/uuid.dart';

/// Estado de facturas
class BillsState {
  final List<Bill> bills;
  final bool isLoading;
  final String? error;
  final bool showUnpaidOnly;

  BillsState({
    this.bills = const [],
    this.isLoading = false,
    this.error,
    this.showUnpaidOnly = false,
  });

  BillsState copyWith({
    List<Bill>? bills,
    bool? isLoading,
    String? error,
    bool? showUnpaidOnly,
  }) {
    return BillsState(
      bills: bills ?? this.bills,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      showUnpaidOnly: showUnpaidOnly ?? this.showUnpaidOnly,
    );
  }

  List<Bill> get unpaidBills => bills.where((b) => !b.isPaid).toList();
  List<Bill> get overdueBills => bills.where((b) => b.isOverdue).toList();
  List<Bill> get dueSoonBills => bills.where((b) => b.isDueSoon).toList();
}

/// ViewModel para gestionar facturas
class BillsViewModel extends StateNotifier<BillsState> {
  final BillsService _service;
  final Uuid _uuid = const Uuid();

  BillsViewModel(this._service) : super(BillsState()) {
    loadBills();
  }

  /// Carga todas las facturas
  Future<void> loadBills({bool forceRefresh = false}) async {
    if (!forceRefresh && state.bills.isNotEmpty && !state.isLoading) {
      return;
    }
    
    if (state.isLoading) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);

    final result = await _service.getAllBills(
      unpaidOnly: state.showUnpaidOnly,
    );

    result.fold(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (bills) {
        state = state.copyWith(
          bills: bills,
          isLoading: false,
        );
      },
    );
  }

  /// Cambia el filtro de facturas pagadas/no pagadas
  void toggleUnpaidOnly() {
    state = state.copyWith(showUnpaidOnly: !state.showUnpaidOnly);
    loadBills(forceRefresh: true);
  }

  /// Crea una nueva factura
  Future<Result<Bill>> createBill({
    required String name,
    String? description,
    required double amount,
    String? categoryId,
    required DateTime dueDate,
    int reminderDays = 3,
  }) async {
    final bill = Bill(
      id: _uuid.v4(),
      name: name,
      description: description,
      amount: amount,
      categoryId: categoryId,
      dueDate: dueDate,
      reminderDays: reminderDays,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await _service.createBill(bill);

    result.fold(
      (failure) {},
      (created) {
        final currentBills = List<Bill>.from(state.bills);
        currentBills.insert(0, created);
        state = state.copyWith(
          bills: currentBills,
          isLoading: false,
        );
      },
    );

    return result;
  }

  /// Actualiza una factura
  Future<Result<Bill>> updateBill(Bill bill) async {
    final updated = bill.copyWith(updatedAt: DateTime.now());
    final result = await _service.updateBill(updated);

    result.fold(
      (failure) {},
      (updatedBill) {
        final currentBills = List<Bill>.from(state.bills);
        final index = currentBills.indexWhere((b) => b.id == updatedBill.id);
        if (index != -1) {
          currentBills[index] = updatedBill;
          state = state.copyWith(
            bills: currentBills,
            isLoading: false,
          );
        } else {
          loadBills(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Marca una factura como pagada
  Future<Result<Bill>> markAsPaid(String id) async {
    final result = await _service.markBillAsPaid(id);

    result.fold(
      (failure) {},
      (updatedBill) {
        final currentBills = List<Bill>.from(state.bills);
        final index = currentBills.indexWhere((b) => b.id == updatedBill.id);
        if (index != -1) {
          currentBills[index] = updatedBill;
          state = state.copyWith(
            bills: currentBills,
            isLoading: false,
          );
        } else {
          loadBills(forceRefresh: true);
        }
      },
    );

    return result;
  }

  /// Elimina una factura
  Future<Result<void>> deleteBill(String id) async {
    final result = await _service.deleteBill(id);

    result.fold(
      (failure) {},
      (_) {
        final currentBills = List<Bill>.from(state.bills);
        currentBills.removeWhere((b) => b.id == id);
        state = state.copyWith(
          bills: currentBills,
          isLoading: false,
        );
      },
    );

    return result;
  }
}

/// Provider del ViewModel de facturas
final billsViewModelProvider =
    StateNotifierProvider.autoDispose<BillsViewModel, BillsState>((ref) {
  ref.keepAlive();
  final service = ref.watch(billsServiceProvider);
  return BillsViewModel(service);
});

