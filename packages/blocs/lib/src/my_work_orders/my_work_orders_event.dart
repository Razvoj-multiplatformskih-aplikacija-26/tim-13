part of 'my_work_orders_bloc.dart';

sealed class MyWorkOrdersEvent {
  const MyWorkOrdersEvent();
}

final class MyWorkOrdersRequested extends MyWorkOrdersEvent {
  const MyWorkOrdersRequested();
}

final class MyWorkOrdersRefreshed extends MyWorkOrdersEvent {
  const MyWorkOrdersRefreshed();
}

final class WorkOrderStartRequested extends MyWorkOrdersEvent {
  const WorkOrderStartRequested(this.id);

  final WorkOrderId id;
}

final class WorkOrderCancellationRequested extends MyWorkOrdersEvent {
  const WorkOrderCancellationRequested(this.id, {required this.reason});

  final WorkOrderId id;
  final ReasonText reason;
}

final class MyWorkOrdersNoticeAcknowledged extends MyWorkOrdersEvent {
  const MyWorkOrdersNoticeAcknowledged();
}
