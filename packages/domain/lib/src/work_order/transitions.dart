import '../errors.dart';
import '../farm/agro_operation.dart';
import '../farm/parcel.dart';
import '../farm/stock_item.dart';
import '../identifiers.dart';
import '../result.dart';
import '../user.dart';
import 'access_policy.dart';
import 'material_use.dart';
import 'reason_text.dart';
import 'rules.dart';
import 'work_interval.dart';
import 'work_order.dart';
import 'work_order_status.dart';
import 'work_report.dart';

enum WorkOrderAction { start, report, cancel, approve, reject }

Set<WorkOrderAction> availableActions(WorkOrder order, {required User by}) {
  final stage = order.status.stage;
  final isMine = AccessPolicy.canWorkOn(by, order);
  final decides = AccessPolicy.canDecide(by);
  return {
    if (isMine && canTransition(stage, WorkOrderStage.inProgress)) WorkOrderAction.start,
    if (isMine && canTransition(stage, WorkOrderStage.awaitingConfirmation)) WorkOrderAction.report,
    if (AccessPolicy.canCancel(by, order) && canTransition(stage, WorkOrderStage.cancelled)) WorkOrderAction.cancel,
    if (decides && canTransition(stage, WorkOrderStage.completed)) WorkOrderAction.approve,
    if (decides && canTransition(stage, WorkOrderStage.rejected)) WorkOrderAction.reject,
  };
}

Failure<WorkOrder> _invalid(WorkOrder order, WorkOrderStage to) =>
    Failure(InvalidTransition(from: order.status.stage, to: to));

Result<WorkOrder> planWorkOrder({
  required WorkOrderId id,
  required ParcelId parcelId,
  required AgroOperation operation,
  required UserId workerId,
  required MachineId machineId,
  required WorkInterval interval,
  required MaterialUse? material,
  required List<WorkOrder> orders,
  required User by,
}) {
  if (!AccessPolicy.canPlan(by)) return const Failure(NotAllowed());
  if (operation.requiresStock && material == null) return const Failure(MaterialRequired());
  final error = assignmentError(workerId: workerId, machineId: machineId, interval: interval, orders: orders);
  if (error != null) return Failure(error);
  return Success(
    WorkOrder(
      id: id,
      parcelId: parcelId,
      operation: operation,
      workerId: workerId,
      machineId: machineId,
      interval: interval,
      material: material,
    ),
  );
}

Result<WorkOrder> startWorkOrder(
  WorkOrder order, {
  required User by,
  required DateTime now,
  required List<WorkOrder> orders,
  required List<StockItem> stock,
}) {
  if (!AccessPolicy.canWorkOn(by, order)) return const Failure(NotAllowed());
  if (!canTransition(order.status.stage, WorkOrderStage.inProgress)) return _invalid(order, WorkOrderStage.inProgress);
  final ordersOnParcel = orders.where((o) => o.parcelId == order.parcelId).toList();
  if (!previousPhaseDone(operation: order.operation, ordersOnParcel: ordersOnParcel)) {
    return Failure(PreviousPhaseNotDone(order.operation.previous!));
  }
  final material = order.material;
  if (material != null) {
    final missing = stockShortfall(material: material, stock: stock, orders: orders);
    if (missing > 0) return Failure(InsufficientStock(item: material.item, missing: missing));
  }
  return Success(order.withStatus(InProgress(startedAt: now)));
}

Result<WorkOrder> submitWorkReport(
  WorkOrder order, {
  required WorkReport report,
  required Parcel parcel,
  required List<WorkOrder> ordersOnParcel,
  required User by,
}) {
  if (!AccessPolicy.canWorkOn(by, order)) return const Failure(NotAllowed());
  if (!canTransition(order.status.stage, WorkOrderStage.awaitingConfirmation)) {
    return _invalid(order, WorkOrderStage.awaitingConfirmation);
  }
  final remaining = remainingHectares(parcel: parcel, operation: order.operation, ordersOnParcel: ordersOnParcel);
  return switch (checkReportedArea(report.processed, remaining: remaining)) {
    Failure(:final error) => Failure(error),
    Success() => Success(order.withStatus(AwaitingConfirmation(report: report))),
  };
}

Result<WorkOrder> approveWorkOrder(WorkOrder order, {required User by, required DateTime now}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  final report = order.status.countedReport;
  if (report == null || !canTransition(order.status.stage, WorkOrderStage.completed)) {
    return _invalid(order, WorkOrderStage.completed);
  }
  return Success(order.withStatus(Completed(report: report, approvedBy: by.id, at: now)));
}

Result<WorkOrder> rejectWorkOrder(
  WorkOrder order, {
  required ReasonText reason,
  required User by,
  required DateTime now,
}) {
  if (!AccessPolicy.canDecide(by)) return const Failure(NotAllowed());
  final report = order.status.countedReport;
  if (report == null || !canTransition(order.status.stage, WorkOrderStage.rejected)) {
    return _invalid(order, WorkOrderStage.rejected);
  }
  return Success(order.withStatus(Rejected(report: report, reason: reason, rejectedBy: by.id, at: now)));
}

Result<WorkOrder> cancelWorkOrder(
  WorkOrder order, {
  required ReasonText reason,
  required User by,
  required DateTime now,
}) {
  if (!AccessPolicy.canCancel(by, order)) return const Failure(NotAllowed());
  if (!canTransition(order.status.stage, WorkOrderStage.cancelled)) return _invalid(order, WorkOrderStage.cancelled);
  return Success(order.withStatus(Cancelled(reason: reason, cancelledBy: by.id, at: now)));
}
