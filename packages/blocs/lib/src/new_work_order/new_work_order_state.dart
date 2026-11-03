part of 'new_work_order_bloc.dart';

final class NewWorkOrderDraft extends Equatable {
  const NewWorkOrderDraft({
    required this.parcelId,
    required this.operation,
    required this.workerId,
    required this.machineId,
    required this.day,
    this.startHour = 8,
    this.endHour = 12,
    this.stockItemId,
    this.quantity = '',
  });

  factory NewWorkOrderDraft.initial(WorkBook book, DateTime day) => NewWorkOrderDraft(
    parcelId: book.parcels.firstOrNull?.id,
    operation: AgroOperation.plowing,
    workerId: book.workers.firstOrNull?.id,
    machineId: book.machines.firstOrNull?.id,
    day: DateTime(day.year, day.month, day.day),
  );

  final ParcelId? parcelId;
  final AgroOperation operation;
  final UserId? workerId;
  final MachineId? machineId;
  final DateTime day;
  final int startHour;
  final int endHour;
  final StockItemId? stockItemId;
  final String quantity;

  DateTime get start => DateTime(day.year, day.month, day.day, startHour);

  DateTime get end => DateTime(day.year, day.month, day.day, endHour);

  NewWorkOrderDraft copyWith({
    ParcelId? parcelId,
    AgroOperation? operation,
    UserId? workerId,
    MachineId? machineId,
    DateTime? day,
    int? startHour,
    int? endHour,
    StockItemId? stockItemId,
    bool clearStock = false,
    String? quantity,
  }) => NewWorkOrderDraft(
    parcelId: parcelId ?? this.parcelId,
    operation: operation ?? this.operation,
    workerId: workerId ?? this.workerId,
    machineId: machineId ?? this.machineId,
    day: day ?? this.day,
    startHour: startHour ?? this.startHour,
    endHour: endHour ?? this.endHour,
    stockItemId: clearStock ? null : (stockItemId ?? this.stockItemId),
    quantity: quantity ?? this.quantity,
  );

  @override
  List<Object?> get props => [parcelId, operation, workerId, machineId, day, startHour, endHour, stockItemId, quantity];
}

sealed class NewWorkOrderState extends Equatable {
  const NewWorkOrderState({required this.draft});

  final NewWorkOrderDraft draft;

  @override
  List<Object?> get props => [draft];

  @override
  String toString() => '$runtimeType';
}

final class NewWorkOrderEditing extends NewWorkOrderState {
  const NewWorkOrderEditing({required super.draft, this.error});

  final DomainError? error;

  bool get canSubmit => error == null;

  @override
  List<Object?> get props => [...super.props, error];
}

final class NewWorkOrderSubmitting extends NewWorkOrderState {
  const NewWorkOrderSubmitting({required super.draft});
}

final class NewWorkOrderSucceeded extends NewWorkOrderState {
  const NewWorkOrderSucceeded({required super.draft, required this.order});

  final WorkOrder order;

  @override
  List<Object?> get props => [...super.props, order];
}

final class NewWorkOrderRejected extends NewWorkOrderState {
  const NewWorkOrderRejected({required super.draft, required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [...super.props, error];
}

final class NewWorkOrderFailed extends NewWorkOrderState {
  const NewWorkOrderFailed({required super.draft, required this.cause});

  final Object cause;

  @override
  List<Object?> get props => [...super.props, cause];
}
