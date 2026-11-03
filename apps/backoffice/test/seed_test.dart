import 'package:backoffice/data/seed.dart';
import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final orders = seedOrders(DateTime(2026, 11, 2, 12));

  test('every stage is represented', () {
    expect(orders.map((o) => o.status.stage).toSet(), WorkOrderStage.values.toSet());
    expect(orders.length, greaterThanOrEqualTo(20));
  });

  test('nobody is booked twice', () {
    for (final order in orders.where((o) => !o.status.isCancelled)) {
      final others = orders.where((o) => o.id != order.id).toList();
      final conflicts = assignmentConflicts(
        workerId: order.workerId,
        machineId: order.machineId,
        interval: order.interval,
        orders: others,
      );
      expect(conflicts, isEmpty, reason: order.id.value);
    }
  });

  test('work already started respects the order of phases', () {
    for (final order in orders.where((o) => o.status is! Planned && !o.status.isCancelled)) {
      final onParcel = orders.where((o) => o.parcelId == order.parcelId).toList();
      expect(
        previousPhaseDone(operation: order.operation, ordersOnParcel: onParcel),
        isTrue,
        reason: order.id.value,
      );
    }
  });
}
