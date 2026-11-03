part of 'new_work_order_bloc.dart';

sealed class NewWorkOrderEvent {
  const NewWorkOrderEvent();
}

final class NewWorkOrderDraftChanged extends NewWorkOrderEvent {
  const NewWorkOrderDraftChanged(this.draft);

  final NewWorkOrderDraft draft;
}

final class NewWorkOrderSubmitted extends NewWorkOrderEvent {
  const NewWorkOrderSubmitted();
}
