part of 'my_work_orders_bloc.dart';

sealed class MyWorkOrdersState extends Equatable {
  const MyWorkOrdersState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class MyWorkOrdersLoading extends MyWorkOrdersState {
  const MyWorkOrdersLoading();
}

final class MyWorkOrdersFailure extends MyWorkOrdersState {
  const MyWorkOrdersFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'MyWorkOrdersFailure($cause)';
}

final class MyWorkOrdersEmpty extends MyWorkOrdersState {
  const MyWorkOrdersEmpty();
}

final class MyWorkOrdersLoaded extends MyWorkOrdersState {
  const MyWorkOrdersLoaded({
    required this.book,
    required this.active,
    required this.history,
    required this.actions,
    this.notice,
    this.busyId,
  });

  final WorkBook book;
  final List<WorkOrder> active;
  final List<WorkOrder> history;
  final Map<WorkOrderId, Set<WorkOrderAction>> actions;
  final MyWorkOrdersNotice? notice;
  final WorkOrderId? busyId;

  bool get isBusy => busyId != null;

  Set<WorkOrderAction> actionsFor(WorkOrder order) => actions[order.id] ?? const {};

  MyWorkOrdersLoaded copyWith({MyWorkOrdersNotice? notice, WorkOrderId? busyId}) => MyWorkOrdersLoaded(
    book: book,
    active: active,
    history: history,
    actions: actions,
    notice: notice,
    busyId: busyId,
  );

  @override
  List<Object?> get props => [book, active, history, actions, notice, busyId];

  @override
  String toString() => 'MyWorkOrdersLoaded(${active.length} active, ${history.length} in history)';
}

sealed class MyWorkOrdersNotice extends Equatable {
  const MyWorkOrdersNotice();

  @override
  List<Object?> get props => const [];
}

final class WorkOrderStarted extends MyWorkOrdersNotice {
  const WorkOrderStarted();
}

final class WorkOrderCancelled extends MyWorkOrdersNotice {
  const WorkOrderCancelled();
}

final class WorkOrderActionRejected extends MyWorkOrdersNotice {
  const WorkOrderActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class WorkOrderActionFailed extends MyWorkOrdersNotice {
  const WorkOrderActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
