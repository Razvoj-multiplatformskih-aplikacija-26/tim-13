import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('previousPhaseDone', () {
    test('the first phase has no precondition', () {
      expect(previousPhaseDone(operation: AgroOperation.plowing, ordersOnParcel: const []), isTrue);
    });

    test('needs a finished order of the previous phase', () {
      expect(previousPhaseDone(operation: AgroOperation.fertilizing, ordersOnParcel: const []), isFalse);
      expect(previousPhaseDone(operation: AgroOperation.fertilizing, ordersOnParcel: [order()]), isFalse);
      expect(
        previousPhaseDone(
          operation: AgroOperation.fertilizing,
          ordersOnParcel: [order(status: completed('10'))],
        ),
        isTrue,
      );
    });

    test('ignores cancelled orders but waits for every other order of the phase', () {
      final cancelled = order(
        id: 'o2',
        status: Cancelled(reason: reason('Kiša'), cancelledBy: owner.id, at: now),
      );
      final done = order(status: completed('10'));
      expect(previousPhaseDone(operation: AgroOperation.fertilizing, ordersOnParcel: [done, cancelled]), isTrue);
      expect(
        previousPhaseDone(
          operation: AgroOperation.fertilizing,
          ordersOnParcel: [
            done,
            order(id: 'o3'),
          ],
        ),
        isFalse,
      );
    });
  });

  group('remainingHectares', () {
    test('counts submitted and approved reports of the same phase only', () {
      final remaining = remainingHectares(
        parcel: parcel,
        operation: AgroOperation.plowing,
        ordersOnParcel: [
          order(status: completed('4')),
          order(
            id: 'o2',
            status: AwaitingConfirmation(report: report('2.5')),
          ),
          order(id: 'o3', operation: AgroOperation.fertilizing, status: completed('10')),
        ],
      );
      expect(remaining, ha('3.5'));
    });

    test('does not count a rejected report', () {
      final rejected = Rejected(report: report('9'), reason: reason('Pogrešno'), rejectedBy: owner.id, at: now);
      final remaining = remainingHectares(
        parcel: parcel,
        operation: AgroOperation.plowing,
        ordersOnParcel: [order(status: rejected)],
      );
      expect(remaining, ha('10'));
    });

    test('checkReportedArea allows exactly the remainder', () {
      expect(checkReportedArea(ha('3'), remaining: ha('3')).isSuccess, isTrue);
      expect(checkReportedArea(ha('3.01'), remaining: ha('3')).errorOrNull, ExceedsParcelArea(ha('3')));
    });
  });

  group('stockShortfall', () {
    const urea = StockItem(
      id: StockItemId('urea'),
      name: 'Urea',
      kind: StockKind.fertilizer,
      unit: StockUnit.kilogram,
      available: 100,
    );

    test('is zero when there is enough', () {
      expect(stockShortfall(material: material('urea', 100), stock: const [urea], orders: const []), 0);
    });

    test('subtracts what running orders have reserved', () {
      final running = order(
        status: InProgress(startedAt: now),
        use: material('urea', 40),
      );
      expect(stockShortfall(material: material('urea', 100), stock: const [urea], orders: [running]), 40);
    });

    test('treats an unknown item as empty', () {
      expect(stockShortfall(material: material('x', 5), stock: const [urea], orders: const []), 5);
    });
  });

  group('assignmentError', () {
    final existing = order(workInterval: interval(8, 12));

    DomainError? errorFor({String worker = 'marko', String machine = 't1', int from = 10, int to = 14}) =>
        assignmentError(
          workerId: UserId(worker),
          machineId: MachineId(machine),
          interval: interval(from, to),
          orders: [existing],
        );

    test('finds a busy worker and a busy machine', () {
      expect(errorFor(machine: 't2'), const WorkerBusy());
      expect(errorFor(worker: 'janko'), const MachineBusy());
    });

    test('touching intervals do not overlap', () {
      expect(errorFor(from: 12, to: 14), isNull);
    });

    test('a different worker and machine are free', () {
      expect(errorFor(worker: 'janko', machine: 't2'), isNull);
    });

    test('cancelled orders do not occupy anyone', () {
      final cancelled = existing.withStatus(Cancelled(reason: reason('Kvar'), cancelledBy: owner.id, at: now));
      final error = assignmentError(
        workerId: existing.workerId,
        machineId: existing.machineId,
        interval: existing.interval,
        orders: [cancelled],
      );
      expect(error, isNull);
    });
  });
}
