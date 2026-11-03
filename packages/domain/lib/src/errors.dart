import 'package:equatable/equatable.dart';

import 'farm/agro_operation.dart';
import 'identifiers.dart';
import 'work_order/hectares.dart';
import 'work_order/work_order_status.dart';

sealed class DomainError extends Equatable {
  const DomainError();

  @override
  List<Object?> get props => const [];
}

final class InvalidHectares extends DomainError {
  const InvalidHectares();
}

final class InvalidFuelAmount extends DomainError {
  const InvalidFuelAmount();
}

final class InvalidMaterialQuantity extends DomainError {
  const InvalidMaterialQuantity();
}

final class ReasonRequired extends DomainError {
  const ReasonRequired();
}

final class ReasonTooLong extends DomainError {
  const ReasonTooLong(this.length);

  final int length;

  @override
  List<Object?> get props => [length];
}

final class InvalidInterval extends DomainError {
  const InvalidInterval();
}

final class ExceedsParcelArea extends DomainError {
  const ExceedsParcelArea(this.remaining);

  final Hectares remaining;

  @override
  List<Object?> get props => [remaining];
}

final class PreviousPhaseNotDone extends DomainError {
  const PreviousPhaseNotDone(this.required);

  final AgroOperation required;

  @override
  List<Object?> get props => [required];
}

final class InsufficientStock extends DomainError {
  const InsufficientStock({required this.item, required this.missing});

  final StockItemId item;
  final int missing;

  @override
  List<Object?> get props => [item, missing];
}

final class MaterialRequired extends DomainError {
  const MaterialRequired();
}

final class WorkerBusy extends DomainError {
  const WorkerBusy();
}

final class MachineBusy extends DomainError {
  const MachineBusy();
}

final class InvalidTransition extends DomainError {
  const InvalidTransition({required this.from, required this.to});

  final WorkOrderStage from;
  final WorkOrderStage to;

  @override
  List<Object?> get props => [from, to];
}

final class NotAllowed extends DomainError {
  const NotAllowed();
}

final class NotFound extends DomainError {
  const NotFound();
}
