import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'data/fake_work_orders.dart';
import 'data/quiet_season.dart';
import 'data/seed.dart';

final class AppDependencies {
  AppDependencies({required this.clock, required this.worker, required WorkOrderRepository orders, this.fakeOrders})
    : getWorkBook = GetWorkBook(repository: orders),
      startWorkOrder = StartWorkOrder(repository: orders, clock: clock),
      submitWorkReport = SubmitWorkReport(repository: orders, clock: clock),
      cancelWorkOrder = CancelWorkOrder(repository: orders, clock: clock);

  factory AppDependencies.fake({Clock clock = const SystemClock(), Duration? latency}) {
    final orders = latency == null ? FakeWorkOrders(clock: clock) : FakeWorkOrders(clock: clock, latency: latency);
    return AppDependencies(clock: clock, worker: marko, orders: orders, fakeOrders: orders);
  }

  factory AppDependencies.quietSeason() =>
      AppDependencies(clock: const SystemClock(), worker: marko, orders: const QuietSeason());

  final Clock clock;
  final User worker;
  final GetWorkBook getWorkBook;
  final StartWorkOrder startWorkOrder;
  final SubmitWorkReport submitWorkReport;
  final CancelWorkOrder cancelWorkOrder;
  final FakeWorkOrders? fakeOrders;
}
