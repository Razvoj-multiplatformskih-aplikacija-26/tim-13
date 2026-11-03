import 'package:bloc/bloc.dart';
import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';
import 'package:use_cases/use_cases.dart';

part 'new_work_order_event.dart';
part 'new_work_order_state.dart';

final class NewWorkOrderBloc extends Bloc<NewWorkOrderEvent, NewWorkOrderState> {
  NewWorkOrderBloc({required this.planWorkOrder, required this.book, required this.owner, required DateTime day})
    : super(NewWorkOrderEditing(draft: NewWorkOrderDraft.initial(book, day))) {
    on<NewWorkOrderDraftChanged>((event, emit) => emit(_editing(_withStock(event.draft))));
    on<NewWorkOrderSubmitted>(_onSubmitted);
    add(NewWorkOrderDraftChanged(state.draft));
  }

  final PlanWorkOrder planWorkOrder;
  final WorkBook book;
  final User owner;

  NewWorkOrderDraft _withStock(NewWorkOrderDraft draft) {
    final kind = draft.operation.requiredStock;
    if (kind == null) return draft.copyWith(clearStock: true);
    if (book.stock.any((item) => item.id == draft.stockItemId && item.kind == kind)) return draft;
    final first = book.stock.where((item) => item.kind == kind).firstOrNull;
    return first == null ? draft.copyWith(clearStock: true) : draft.copyWith(stockItemId: first.id);
  }

  NewWorkOrderEditing _editing(NewWorkOrderDraft draft) =>
      NewWorkOrderEditing(draft: draft, error: _validate(draft).errorOrNull);

  Result<_Plan> _validate(NewWorkOrderDraft draft) {
    final parcelId = draft.parcelId;
    final workerId = draft.workerId;
    final machineId = draft.machineId;
    if (parcelId == null || workerId == null || machineId == null) return const Failure(NotFound());
    final interval = WorkInterval.parse(start: draft.start, end: draft.end);
    if (interval case Failure(:final error)) return Failure(error);
    final conflict = assignmentError(
      workerId: workerId,
      machineId: machineId,
      interval: interval.valueOrNull!,
      orders: book.orders,
    );
    if (conflict != null) return Failure(conflict);
    MaterialUse? material;
    if (draft.operation.requiresStock) {
      final item = draft.stockItemId;
      if (item == null) return const Failure(MaterialRequired());
      final parsed = MaterialUse.parse(item, draft.quantity);
      if (parsed case Failure(:final error)) return Failure(error);
      material = parsed.valueOrNull;
    }
    return Success(
      _Plan(
        parcelId: parcelId,
        workerId: workerId,
        machineId: machineId,
        interval: interval.valueOrNull!,
        material: material,
      ),
    );
  }

  Future<void> _onSubmitted(NewWorkOrderSubmitted event, Emitter<NewWorkOrderState> emit) async {
    final draft = state.draft;
    final plan = _validate(draft);
    if (plan case Failure(:final error)) {
      emit(NewWorkOrderEditing(draft: draft, error: error));
      return;
    }
    final value = plan.valueOrNull!;
    emit(NewWorkOrderSubmitting(draft: draft));
    try {
      final result = await planWorkOrder(
        parcelId: value.parcelId,
        operation: draft.operation,
        workerId: value.workerId,
        machineId: value.machineId,
        interval: value.interval,
        material: value.material,
        by: owner,
      );
      emit(switch (result) {
        Success(value: final order) => NewWorkOrderSucceeded(draft: draft, order: order),
        Failure(:final error) => NewWorkOrderRejected(draft: draft, error: error),
      });
    } on Exception catch (cause) {
      emit(NewWorkOrderFailed(draft: draft, cause: cause));
    }
  }
}

final class _Plan {
  const _Plan({
    required this.parcelId,
    required this.workerId,
    required this.machineId,
    required this.interval,
    required this.material,
  });

  final ParcelId parcelId;
  final UserId workerId;
  final MachineId machineId;
  final WorkInterval interval;
  final MaterialUse? material;
}
