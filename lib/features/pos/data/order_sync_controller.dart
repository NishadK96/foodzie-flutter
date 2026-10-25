import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models.dart';
import '../presentation/pos_controller.dart';
import 'demo_repository.dart';
import 'pos_data_controller.dart';

final orderSyncControllerProvider =
    NotifierProvider<OrderSyncController, OrderSyncState>(
      OrderSyncController.new,
    );

class OrderSyncState {
  const OrderSyncState({
    this.orderIds = const {},
    this.processing = false,
    this.error,
  });

  final Map<int, int> orderIds;
  final bool processing;
  final String? error;

  OrderSyncState copyWith({
    Map<int, int>? orderIds,
    bool? processing,
    String? error,
    bool clearError = false,
  }) => OrderSyncState(
    orderIds: orderIds ?? this.orderIds,
    processing: processing ?? this.processing,
    error: clearError ? null : error ?? this.error,
  );
}

class OrderSyncController extends Notifier<OrderSyncState> {
  @override
  OrderSyncState build() => const OrderSyncState();

  bool get _isLive => ref.read(menuRepositoryProvider) is! DemoMenuRepository;

  Future<int?> sendToKitchen() async {
    if (!_isLive) {
      ref.read(posControllerProvider.notifier).sendToKitchen();
      return null;
    }
    return _run(() async {
      final pos = ref.read(posControllerProvider);
      final orderId = await _ensureOrder(pos, sendToKitchen: true);
      ref.read(posControllerProvider.notifier).sendToKitchen();
      await ref.read(posDataControllerProvider.notifier).refresh();
      return orderId;
    });
  }

  Future<CompletedOrder?> completePayment(
    PaymentMethod method, {
    List<PaymentAllocation> payments = const [],
  }) async {
    if (!_isLive) {
      return ref
          .read(posControllerProvider.notifier)
          .completePayment(method, payments: payments);
    }
    final result = await _run(() async {
      final pos = ref.read(posControllerProvider);
      final orderId = await _ensureOrder(pos, sendToKitchen: false);
      final api = ref.read(posApiRepositoryProvider);
      if (payments.isEmpty) {
        await api.payOrder(orderId, method);
      } else {
        await api.splitPayment(orderId, payments);
      }
      final completed = ref
          .read(posControllerProvider.notifier)
          .completePayment(method, payments: payments);
      state = state.copyWith(
        orderIds: {...state.orderIds}..remove(pos.selectedTable),
      );
      await ref.read(posDataControllerProvider.notifier).refresh();
      return completed;
    });
    return result;
  }

  Future<int> _ensureOrder(PosState pos, {required bool sendToKitchen}) async {
    final existing = state.orderIds[pos.selectedTable];
    if (existing != null) return existing;
    final table = pos.selectedTable == 0
        ? null
        : pos.tables
              .where((item) => item.number == pos.selectedTable)
              .firstOrNull;
    final response = await ref
        .read(posApiRepositoryProvider)
        .submitOrder(
          lines: pos.cart,
          table: table,
          note: pos.activeNote,
          fixedDiscountPaise: pos.fixedDiscountPaise,
          percentageDiscountBasisPoints: pos.percentageDiscountBasisPoints,
          sendToKitchen: sendToKitchen,
        );
    final order = response['order'];
    final id = order is Map ? int.tryParse('${order['id']}') : null;
    if (id == null) throw StateError('The server did not return an order id.');
    state = state.copyWith(
      orderIds: {...state.orderIds, pos.selectedTable: id},
    );
    return id;
  }

  Future<T?> _run<T>(Future<T> Function() operation) async {
    if (state.processing) return null;
    state = state.copyWith(processing: true, clearError: true);
    try {
      return await operation();
    } catch (error) {
      state = state.copyWith(error: error.toString());
      return null;
    } finally {
      state = state.copyWith(processing: false);
    }
  }
}
