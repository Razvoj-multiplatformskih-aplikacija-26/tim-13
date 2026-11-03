import 'package:equatable/equatable.dart';

import '../identifiers.dart';
import 'reason_text.dart';
import 'work_report.dart';

enum WorkOrderStage { planned, inProgress, awaitingConfirmation, completed, rejected, cancelled }

sealed class WorkOrderStatus extends Equatable {
  const WorkOrderStatus();

  WorkOrderStage get stage => switch (this) {
    Planned() => WorkOrderStage.planned,
    InProgress() => WorkOrderStage.inProgress,
    AwaitingConfirmation() => WorkOrderStage.awaitingConfirmation,
    Completed() => WorkOrderStage.completed,
    Rejected() => WorkOrderStage.rejected,
    Cancelled() => WorkOrderStage.cancelled,
  };

  bool get isFinal => switch (this) {
    Completed() || Cancelled() => true,
    Planned() || InProgress() || AwaitingConfirmation() || Rejected() => false,
  };

  bool get isCancelled => this is Cancelled;

  WorkReport? get countedReport => switch (this) {
    AwaitingConfirmation(:final report) || Completed(:final report) => report,
    Planned() || InProgress() || Rejected() || Cancelled() => null,
  };

  @override
  List<Object?> get props => const [];
}

final class Planned extends WorkOrderStatus {
  const Planned();
}

final class InProgress extends WorkOrderStatus {
  const InProgress({required this.startedAt});

  final DateTime startedAt;

  @override
  List<Object?> get props => [startedAt];
}

final class AwaitingConfirmation extends WorkOrderStatus {
  const AwaitingConfirmation({required this.report});

  final WorkReport report;

  @override
  List<Object?> get props => [report];
}

final class Completed extends WorkOrderStatus {
  const Completed({required this.report, required this.approvedBy, required this.at});

  final WorkReport report;
  final UserId approvedBy;
  final DateTime at;

  @override
  List<Object?> get props => [report, approvedBy, at];
}

final class Rejected extends WorkOrderStatus {
  const Rejected({required this.report, required this.reason, required this.rejectedBy, required this.at});

  final WorkReport report;
  final ReasonText reason;
  final UserId rejectedBy;
  final DateTime at;

  @override
  List<Object?> get props => [report, reason, rejectedBy, at];
}

final class Cancelled extends WorkOrderStatus {
  const Cancelled({required this.reason, required this.cancelledBy, required this.at});

  final ReasonText reason;
  final UserId cancelledBy;
  final DateTime at;

  @override
  List<Object?> get props => [reason, cancelledBy, at];
}

bool canTransition(WorkOrderStage from, WorkOrderStage to) => switch ((from, to)) {
  (WorkOrderStage.planned || WorkOrderStage.rejected, WorkOrderStage.inProgress) => true,
  (WorkOrderStage.inProgress, WorkOrderStage.awaitingConfirmation) => true,
  (WorkOrderStage.awaitingConfirmation, WorkOrderStage.completed || WorkOrderStage.rejected) => true,
  (WorkOrderStage.planned || WorkOrderStage.inProgress || WorkOrderStage.rejected, WorkOrderStage.cancelled) => true,
  _ => false,
};
