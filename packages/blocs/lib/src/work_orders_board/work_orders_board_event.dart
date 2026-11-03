part of 'work_orders_board_bloc.dart';

sealed class WorkOrdersBoardEvent {
  const WorkOrdersBoardEvent();
}

final class BoardRequested extends WorkOrdersBoardEvent {
  const BoardRequested();
}

final class BoardRefreshed extends WorkOrdersBoardEvent {
  const BoardRefreshed();
}

final class BoardFilterChanged extends WorkOrdersBoardEvent {
  const BoardFilterChanged(this.stage);

  final WorkOrderStage? stage;
}

final class BoardOrderSelected extends WorkOrdersBoardEvent {
  const BoardOrderSelected(this.id);

  final WorkOrderId? id;
}

final class BoardCursorMoved extends WorkOrdersBoardEvent {
  const BoardCursorMoved(this.rows);

  final int rows;
}

final class BoardCursorActivated extends WorkOrdersBoardEvent {
  const BoardCursorActivated();
}

final class BoardApprovalRequested extends WorkOrdersBoardEvent {
  const BoardApprovalRequested(this.id);

  final WorkOrderId id;
}

final class BoardRejectionRequested extends WorkOrdersBoardEvent {
  const BoardRejectionRequested(this.id, {required this.reason});

  final WorkOrderId id;
  final ReasonText reason;
}

final class BoardCancellationRequested extends WorkOrdersBoardEvent {
  const BoardCancellationRequested(this.id, {required this.reason});

  final WorkOrderId id;
  final ReasonText reason;
}

final class BoardNoticeAcknowledged extends WorkOrdersBoardEvent {
  const BoardNoticeAcknowledged();
}
