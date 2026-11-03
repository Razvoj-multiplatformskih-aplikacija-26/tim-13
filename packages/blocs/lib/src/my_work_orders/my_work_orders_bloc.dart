import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'my_work_orders_event.dart';
part 'my_work_orders_state.dart';

final class MyWorkOrdersBloc extends Bloc<MyWorkOrdersEvent, MyWorkOrdersState> {
  MyWorkOrdersBloc({
    required this.getWorkBook,
    required this.startWorkOrder,
    required this.cancelWorkOrder,
    required this.worker,
  }) : super(const MyWorkOrdersLoading()) {
    on<MyWorkOrdersRequested>((event, emit) async {
      emit(const MyWorkOrdersLoading());
      await _reload(emit);
    });
    on<MyWorkOrdersRefreshed>((event, emit) => _reload(emit));
    on<WorkOrderStartRequested>(
      (event, emit) => _act(
        emit,
        event.id,
        () => startWorkOrder(id: event.id, by: worker),
        success: const WorkOrderStarted(),
      ),
    );
    on<WorkOrderCancellationRequested>(
      (event, emit) => _act(
        emit,
        event.id,
        () => cancelWorkOrder(id: event.id, reason: event.reason, by: worker),
        success: const WorkOrderCancelled(),
      ),
    );
    on<MyWorkOrdersNoticeAcknowledged>((event, emit) {
      final current = state;
      if (current is MyWorkOrdersLoaded && current.notice != null) emit(current.copyWith());
    });
  }

  final GetWorkBook getWorkBook;
  final StartWorkOrder startWorkOrder;
  final CancelWorkOrder cancelWorkOrder;
  final User worker;
  int _request = 0;

  Future<void> _reload(Emitter<MyWorkOrdersState> emit, {MyWorkOrdersNotice? notice}) async {
    final request = ++_request;
    try {
      final book = await getWorkBook();
      if (request != _request) return;
      final mine = book.ordersOf(worker.id)..sort((a, b) => a.interval.start.compareTo(b.interval.start));
      if (mine.isEmpty) {
        emit(const MyWorkOrdersEmpty());
        return;
      }
      emit(
        MyWorkOrdersLoaded(
          book: book,
          active: mine.where((o) => !o.status.isFinal).toList(),
          history: mine.where((o) => o.status.isFinal).toList().reversed.toList(),
          actions: {for (final order in mine) order.id: availableActions(order, by: worker)},
          notice: notice,
        ),
      );
    } on Exception catch (cause) {
      if (request == _request) emit(MyWorkOrdersFailure(cause));
    }
  }

  Future<void> _act(
    Emitter<MyWorkOrdersState> emit,
    WorkOrderId id,
    Future<Result<WorkOrder>> Function() action, {
    required MyWorkOrdersNotice success,
  }) async {
    final current = state;
    if (current is! MyWorkOrdersLoaded || current.isBusy) return;
    emit(current.copyWith(busyId: id));
    try {
      switch (await action()) {
        case Success():
          await _reload(emit, notice: success);
        case Failure(:final error):
          emit(current.copyWith(notice: WorkOrderActionRejected(error)));
      }
    } on Exception catch (cause) {
      emit(current.copyWith(notice: WorkOrderActionFailed(cause)));
    }
  }
}
