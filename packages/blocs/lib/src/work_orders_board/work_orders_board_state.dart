part of 'work_orders_board_bloc.dart';

sealed class WorkOrdersBoardState extends Equatable {
  const WorkOrdersBoardState();

  @override
  List<Object?> get props => const [];

  @override
  String toString() => '$runtimeType';
}

final class BoardLoading extends WorkOrdersBoardState {
  const BoardLoading();
}

final class BoardFailure extends WorkOrdersBoardState {
  const BoardFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];

  @override
  String toString() => 'BoardFailure($cause)';
}

final class BoardEmpty extends WorkOrdersBoardState {
  const BoardEmpty();
}

final class BoardLoaded extends WorkOrdersBoardState {
  const BoardLoaded({
    required this.book,
    required this.actions,
    this.filter,
    this.cursor = 0,
    this.selectedId,
    this.notice,
    this.busyId,
  });

  final WorkBook book;
  final Map<WorkOrderId, Set<WorkOrderAction>> actions;
  final WorkOrderStage? filter;
  final int cursor;
  final WorkOrderId? selectedId;
  final BoardNotice? notice;
  final WorkOrderId? busyId;

  bool get isBusy => busyId != null;

  List<WorkOrder> get visible {
    final filter = this.filter;
    final orders = filter == null ? [...book.orders] : book.orders.where((o) => o.status.stage == filter).toList();
    return orders..sort((a, b) => a.interval.start.compareTo(b.interval.start));
  }

  WorkOrder? get selected {
    final id = selectedId;
    return id == null ? null : book.find(id);
  }

  WorkOrder? get orderAtCursor {
    final orders = visible;
    return cursor < orders.length ? orders[cursor] : null;
  }

  int? get indexOfSelected {
    final index = visible.indexWhere((o) => o.id == selectedId);
    return index < 0 ? null : index;
  }

  int clampCursor(int value) {
    final count = visible.length;
    return count == 0 ? 0 : value.clamp(0, count - 1);
  }

  Set<WorkOrderAction> actionsFor(WorkOrder order) => actions[order.id] ?? const {};

  BoardLoaded copyWith({
    WorkBook? book,
    Map<WorkOrderId, Set<WorkOrderAction>>? actions,
    WorkOrderStage? filter,
    bool clearFilter = false,
    int? cursor,
    WorkOrderId? selectedId,
    bool clearSelection = false,
    BoardNotice? notice,
    bool clearNotice = false,
    WorkOrderId? busyId,
  }) => BoardLoaded(
    book: book ?? this.book,
    actions: actions ?? this.actions,
    filter: clearFilter ? null : (filter ?? this.filter),
    cursor: cursor ?? this.cursor,
    selectedId: clearSelection ? null : (selectedId ?? this.selectedId),
    notice: clearNotice ? null : (notice ?? this.notice),
    busyId: busyId,
  );

  @override
  List<Object?> get props => [book, actions, filter, cursor, selectedId, notice, busyId];

  @override
  String toString() => 'BoardLoaded(${visible.length} visible, cursor $cursor, selected ${selectedId?.value})';
}

sealed class BoardNotice extends Equatable {
  const BoardNotice();

  @override
  List<Object?> get props => const [];
}

final class BoardActionSucceeded extends BoardNotice {
  const BoardActionSucceeded(this.order);

  final WorkOrder order;

  @override
  List<Object?> get props => [order];
}

final class BoardActionRejected extends BoardNotice {
  const BoardActionRejected(this.error);

  final DomainError error;

  @override
  List<Object?> get props => [error];
}

final class BoardActionFailed extends BoardNotice {
  const BoardActionFailed(this.cause);

  final Object cause;

  @override
  List<Object?> get props => [cause];
}
