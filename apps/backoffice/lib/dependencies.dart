import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_work_orders.dart';
import 'data/seed.dart';

final class BackofficeDependencies {
  BackofficeDependencies({
    required this.clock,
    required this.owner,
    required WorkOrderRepository orders,
    this.fakeOrders,
  }) : getWorkBook = GetWorkBook(repository: orders),
       approveWorkOrder = ApproveWorkOrder(repository: orders, clock: clock),
       rejectWorkOrder = RejectWorkOrder(repository: orders, clock: clock),
       cancelWorkOrder = CancelWorkOrder(repository: orders, clock: clock),
       planWorkOrder = PlanWorkOrder(repository: orders);

  factory BackofficeDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final orders = latency == null ? FakeWorkOrders(clock: clock) : FakeWorkOrders(clock: clock, latency: latency);
    return BackofficeDependencies(clock: clock, owner: gazda, orders: orders, fakeOrders: orders);
  }

  final Clock clock;
  final User owner;
  final GetWorkBook getWorkBook;
  final ApproveWorkOrder approveWorkOrder;
  final RejectWorkOrder rejectWorkOrder;
  final CancelWorkOrder cancelWorkOrder;
  final PlanWorkOrder planWorkOrder;
  final FakeWorkOrders? fakeOrders;
}
