import 'package:domain/domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/seed.dart';

void main() {
  final orders = seedOrders(DateTime(2026, 11, 2, 12));

  test('the worker has at least ten orders with every stage represented', () {
    final mine = orders.where((o) => o.workerId == marko.id).toList();
    expect(mine.length, greaterThanOrEqualTo(10));
    expect(mine.map((o) => o.status.stage).toSet(), WorkOrderStage.values.toSet());
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

  test('no phase reports more than the parcel area', () {
    for (final parcel in seedParcels) {
      final onParcel = orders.where((o) => o.parcelId == parcel.id).toList();
      for (final operation in AgroOperation.values) {
        final reported = onParcel
            .where((o) => o.operation == operation)
            .map((o) => o.status.countedReport?.processed.hundredths ?? 0)
            .fold(0, (sum, value) => sum + value);
        expect(reported, lessThanOrEqualTo(parcel.area.hundredths), reason: '${parcel.name} $operation');
      }
    }
  });
}
