import 'package:domain/domain.dart';
import 'package:test/test.dart';

import 'fixtures.dart';

void main() {
  group('canTransition', () {
    const allowed = {
      (WorkOrderStage.planned, WorkOrderStage.inProgress),
      (WorkOrderStage.rejected, WorkOrderStage.inProgress),
      (WorkOrderStage.inProgress, WorkOrderStage.awaitingConfirmation),
      (WorkOrderStage.awaitingConfirmation, WorkOrderStage.completed),
      (WorkOrderStage.awaitingConfirmation, WorkOrderStage.rejected),
      (WorkOrderStage.planned, WorkOrderStage.cancelled),
      (WorkOrderStage.inProgress, WorkOrderStage.cancelled),
      (WorkOrderStage.rejected, WorkOrderStage.cancelled),
    };

    test('allows exactly the listed transitions', () {
      for (final from in WorkOrderStage.values) {
        for (final to in WorkOrderStage.values) {
          expect(canTransition(from, to), allowed.contains((from, to)), reason: '$from -> $to');
        }
      }
    });
  });

  group('availableActions', () {
    test('a worker starts and reports their own order', () {
      expect(availableActions(order(), by: worker), {WorkOrderAction.start, WorkOrderAction.cancel});
      expect(
        availableActions(
          order(status: InProgress(startedAt: now)),
          by: worker,
        ),
        {WorkOrderAction.report, WorkOrderAction.cancel},
      );
    });

    test('a worker has no actions on an order of someone else', () {
      expect(availableActions(order(), by: otherWorker), isEmpty);
    });

    test('the owner decides on a submitted report', () {
      expect(
        availableActions(
          order(status: AwaitingConfirmation(report: report('1'))),
          by: owner,
        ),
        {WorkOrderAction.approve, WorkOrderAction.reject},
      );
    });

    test('a final order has no actions', () {
      expect(availableActions(order(status: completed('1')), by: owner), isEmpty);
    });
  });

  group('startWorkOrder', () {
    test('moves a planned order to in progress', () {
      final result = startWorkOrder(order(), by: worker, now: now, orders: const [], stock: const []);
      expect(result.valueOrNull?.status, InProgress(startedAt: now));
    });

    test('respects the order of phases', () {
      final fertilizing = order(operation: AgroOperation.fertilizing);
      final result = startWorkOrder(fertilizing, by: worker, now: now, orders: [fertilizing], stock: const []);
      expect(result.errorOrNull, const PreviousPhaseNotDone(AgroOperation.plowing));
    });

    test('blocks spraying without enough stock', () {
      final harvested = order(id: 'o0', operation: AgroOperation.sowing, status: completed('10'));
      final spraying = order(operation: AgroOperation.spraying, use: material('hem', 10));
      const stock = [
        StockItem(
          id: StockItemId('hem'),
          name: 'Herbicid',
          kind: StockKind.chemical,
          unit: StockUnit.liter,
          available: 4,
        ),
      ];
      final result = startWorkOrder(spraying, by: worker, now: now, orders: [harvested, spraying], stock: stock);
      expect(result.errorOrNull, const InsufficientStock(item: StockItemId('hem'), missing: 6));
    });

    test('someone else cannot start the order', () {
      final result = startWorkOrder(order(), by: otherWorker, now: now, orders: const [], stock: const []);
      expect(result.errorOrNull, const NotAllowed());
    });

    test('a rejected order goes back to work', () {
      final rejected = order(
        status: Rejected(report: report('1'), reason: reason('Dorada'), rejectedBy: owner.id, at: now),
      );
      expect(startWorkOrder(rejected, by: worker, now: now, orders: [rejected], stock: const []).isSuccess, isTrue);
    });
  });

  group('submitWorkReport', () {
    final running = order(status: InProgress(startedAt: now));

    test('moves the order to awaiting confirmation', () {
      final result = submitWorkReport(
        running,
        report: report('10'),
        parcel: parcel,
        ordersOnParcel: [running],
        by: worker,
      );
      expect(result.valueOrNull?.status, AwaitingConfirmation(report: report('10')));
    });

    test('rejects more than the parcel has left', () {
      final result = submitWorkReport(
        running,
        report: report('10.01'),
        parcel: parcel,
        ordersOnParcel: [running],
        by: worker,
      );
      expect(result.errorOrNull, ExceedsParcelArea(ha('10')));
    });

    test('cannot be sent for an order that was not started', () {
      final planned = order();
      final result = submitWorkReport(
        planned,
        report: report('1'),
        parcel: parcel,
        ordersOnParcel: [planned],
        by: worker,
      );
      expect(result.errorOrNull, isA<InvalidTransition>());
    });
  });

  group('decisions', () {
    final submitted = order(status: AwaitingConfirmation(report: report('5')));

    test('approval keeps the report', () {
      expect(approveWorkOrder(submitted, by: owner, now: now).valueOrNull?.status.countedReport, report('5'));
    });

    test('rejection carries the reason', () {
      final status = rejectWorkOrder(submitted, reason: reason('Gorivo'), by: owner, now: now).valueOrNull?.status;
      expect((status as Rejected?)?.reason, reason('Gorivo'));
    });

    test('a worker cannot decide', () {
      expect(approveWorkOrder(submitted, by: worker, now: now).errorOrNull, const NotAllowed());
      expect(rejectWorkOrder(submitted, reason: reason('x'), by: worker, now: now).errorOrNull, const NotAllowed());
    });

    test('only a submitted report can be approved', () {
      expect(approveWorkOrder(order(), by: owner, now: now).errorOrNull, isA<InvalidTransition>());
    });
  });

  group('cancelWorkOrder', () {
    test('the assigned worker and the owner may cancel', () {
      expect(cancelWorkOrder(order(), reason: reason('Kiša'), by: worker, now: now).isSuccess, isTrue);
      expect(cancelWorkOrder(order(), reason: reason('Kiša'), by: owner, now: now).isSuccess, isTrue);
    });

    test('another worker may not', () {
      expect(
        cancelWorkOrder(order(), reason: reason('Kiša'), by: otherWorker, now: now).errorOrNull,
        const NotAllowed(),
      );
    });

    test('a submitted report can no longer be cancelled', () {
      final submitted = order(status: AwaitingConfirmation(report: report('5')));
      expect(
        cancelWorkOrder(submitted, reason: reason('Kiša'), by: owner, now: now).errorOrNull,
        isA<InvalidTransition>(),
      );
    });
  });

  group('planWorkOrder', () {
    Result<NewWorkOrder> plan({AgroOperation operation = AgroOperation.plowing, User by = owner, MaterialUse? use}) =>
        planWorkOrder(
          parcelId: parcel.id,
          operation: operation,
          workerId: worker.id,
          machineId: const MachineId('t2'),
          interval: interval(8, 10),
          material: use,
          orders: [order(workerId: const UserId('janko'), machineId: const MachineId('t1'))],
          by: by,
        );

    test('creates a planned order once it gets an id', () {
      final created = plan().valueOrNull!.withId(const WorkOrderId('n-99'));
      expect(created.id, const WorkOrderId('n-99'));
      expect(created.status, const Planned());
    });

    test('only the owner plans', () {
      expect(plan(by: worker).errorOrNull, const NotAllowed());
    });

    test('fertilizing needs a material', () {
      expect(plan(operation: AgroOperation.fertilizing).errorOrNull, const MaterialRequired());
    });
  });
}
