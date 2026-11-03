import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'work_orders_board_event.dart';
part 'work_orders_board_state.dart';

final class WorkOrdersBoardBloc extends Bloc<WorkOrdersBoardEvent, WorkOrdersBoardState> {
  WorkOrdersBoardBloc({
    required this.getWorkBook,
    required this.approveWorkOrder,
    required this.rejectWorkOrder,
    required this.cancelWorkOrder,
    required this.owner,
  }) : super(const BoardLoading()) {
    on<BoardRequested>((event, emit) async {
      emit(const BoardLoading());
      await _load(emit);
    });
    on<BoardRefreshed>((event, emit) => _load(emit));
    on<BoardFilterChanged>((event, emit) {
      final current = state;
      if (current is BoardLoaded) {
        final next = current.copyWith(filter: event.stage, clearFilter: event.stage == null, cursor: 0);
        emit(next.copyWith(cursor: next.indexOfSelected ?? 0));
      }
    });
    on<BoardOrderSelected>((event, emit) => _select(emit, event.id));
    on<BoardCursorMoved>((event, emit) {
      final current = state;
      if (current is BoardLoaded) emit(current.copyWith(cursor: current.clampCursor(current.cursor + event.rows)));
    });
    on<BoardCursorActivated>(
      (event, emit) => _select(emit, switch (state) {
        final BoardLoaded current => current.orderAtCursor?.id,
        _ => null,
      }),
    );
    on<BoardApprovalRequested>((event, emit) => _act(emit, event.id, () => approveWorkOrder(id: event.id, by: owner)));
    on<BoardRejectionRequested>(
      (event, emit) => _act(emit, event.id, () => rejectWorkOrder(id: event.id, reason: event.reason, by: owner)),
    );
    on<BoardCancellationRequested>(
      (event, emit) => _act(emit, event.id, () => cancelWorkOrder(id: event.id, reason: event.reason, by: owner)),
    );
    on<BoardNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is BoardLoaded && current.notice != null) emit(current.copyWith(clearNotice: true));
    });
  }

  final GetWorkBook getWorkBook;
  final ApproveWorkOrder approveWorkOrder;
  final RejectWorkOrder rejectWorkOrder;
  final CancelWorkOrder cancelWorkOrder;
  final User owner;
  int _request = 0;

  Map<WorkOrderId, Set<WorkOrderAction>> _actionsFor(WorkBook book) => {
    for (final order in book.orders) order.id: availableActions(order, by: owner),
  };

  Future<void> _load(Emitter<WorkOrdersBoardState> emit, {BoardNotice? notice}) async {
    final request = ++_request;
    final previous = state;
    try {
      final book = await getWorkBook();
      if (request != _request) return;
      if (book.orders.isEmpty) {
        emit(const BoardEmpty());
        return;
      }
      final loaded = previous is BoardLoaded
          ? previous.copyWith(book: book, actions: _actionsFor(book), notice: notice, clearNotice: notice == null)
          : BoardLoaded(book: book, actions: _actionsFor(book), notice: notice);
      emit(loaded.copyWith(cursor: loaded.clampCursor(loaded.cursor), notice: notice, clearNotice: notice == null));
    } on Exception catch (cause) {
      if (request == _request) emit(BoardFailure(cause));
    }
  }

  void _select(Emitter<WorkOrdersBoardState> emit, WorkOrderId? id) {
    final current = state;
    if (current is! BoardLoaded) return;
    if (id == null) {
      emit(current.copyWith(clearSelection: true));
      return;
    }
    if (current.book.find(id) == null) return;
    final selected = current.copyWith(selectedId: id);
    emit(selected.copyWith(cursor: selected.indexOfSelected ?? selected.cursor));
  }

  Future<void> _act(
    Emitter<WorkOrdersBoardState> emit,
    WorkOrderId id,
    Future<Result<WorkOrder>> Function() action,
  ) async {
    final current = state;
    if (current is! BoardLoaded || current.isBusy) return;
    emit(current.copyWith(busyId: id, clearNotice: true));
    try {
      switch (await action()) {
        case Success(:final value):
          await _load(emit, notice: BoardActionSucceeded(value));
        case Failure(:final error):
          emit(current.copyWith(notice: BoardActionRejected(error)));
      }
    } on Exception catch (cause) {
      emit(current.copyWith(notice: BoardActionFailed(cause)));
    }
  }
}
