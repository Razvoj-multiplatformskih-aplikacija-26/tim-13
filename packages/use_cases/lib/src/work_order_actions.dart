import 'package:domain/domain.dart';

import 'clock.dart';
import 'ports/work_order_repository.dart';
import 'work_book.dart';

const _attempts = 3;

final class _WorkOrderAction {
  const _WorkOrderAction({required this.repository, required this.clock});

  final WorkOrderRepository repository;
  final Clock clock;

  Future<Result<WorkOrder>> run(
    WorkOrderId id,
    User by,
    Result<WorkOrder> Function(WorkOrder order, WorkBook book) decide,
  ) async {
    Result<WorkOrder> outcome = const Failure(NotFound());
    for (var attempt = 0; attempt < _attempts; attempt++) {
      final book = await repository.workBook();
      final order = book.find(id);
      if (order == null || !AccessPolicy.canView(by, order)) return const Failure(NotFound());
      switch (decide(order, book)) {
        case Failure(:final error):
          return Failure(error);
        case Success(:final value):
          final from = order.status.stage;
          outcome = await repository.save(value, from: from);
          if (outcome case Failure(error: InvalidTransition(from: final current)) when current != from) continue;
          return outcome;
      }
    }
    return outcome;
  }
}

final class StartWorkOrder extends _WorkOrderAction {
  const StartWorkOrder({required super.repository, required super.clock});

  Future<Result<WorkOrder>> call({required WorkOrderId id, required User by}) => run(
    id,
    by,
    (order, book) => startWorkOrder(order, by: by, now: clock.now(), orders: book.orders, stock: book.stock),
  );
}

final class SubmitWorkReport extends _WorkOrderAction {
  const SubmitWorkReport({required super.repository, required super.clock});

  Future<Result<WorkOrder>> call({
    required WorkOrderId id,
    required Hectares processed,
    required FuelLiters fuel,
    MaterialUse? material,
    required User by,
  }) => run(id, by, (order, book) {
    final parcel = book.parcelOf(order);
    if (parcel == null) return const Failure(NotFound());
    return submitWorkReport(
      order,
      report: WorkReport(processed: processed, fuel: fuel, material: material, submittedAt: clock.now()),
      parcel: parcel,
      ordersOnParcel: book.ordersOn(order.parcelId),
      by: by,
    );
  });
}

final class CancelWorkOrder extends _WorkOrderAction {
  const CancelWorkOrder({required super.repository, required super.clock});

  Future<Result<WorkOrder>> call({required WorkOrderId id, required ReasonText reason, required User by}) =>
      run(id, by, (order, book) => cancelWorkOrder(order, reason: reason, by: by, now: clock.now()));
}

final class ApproveWorkOrder extends _WorkOrderAction {
  const ApproveWorkOrder({required super.repository, required super.clock});

  Future<Result<WorkOrder>> call({required WorkOrderId id, required User by}) =>
      run(id, by, (order, book) => approveWorkOrder(order, by: by, now: clock.now()));
}

final class RejectWorkOrder extends _WorkOrderAction {
  const RejectWorkOrder({required super.repository, required super.clock});

  Future<Result<WorkOrder>> call({required WorkOrderId id, required ReasonText reason, required User by}) =>
      run(id, by, (order, book) => rejectWorkOrder(order, reason: reason, by: by, now: clock.now()));
}

final class PlanWorkOrder {
  const PlanWorkOrder({required this.repository});

  final WorkOrderRepository repository;

  Future<Result<WorkOrder>> call({
    required ParcelId parcelId,
    required AgroOperation operation,
    required UserId workerId,
    required MachineId machineId,
    required WorkInterval interval,
    MaterialUse? material,
    required User by,
  }) async {
    final book = await repository.workBook();
    final result = planWorkOrder(
      parcelId: parcelId,
      operation: operation,
      workerId: workerId,
      machineId: machineId,
      interval: interval,
      material: material,
      orders: book.orders,
      by: by,
    );
    return switch (result) {
      Failure(:final error) => Failure(error),
      Success(:final value) => await repository.create(value),
    };
  }
}
