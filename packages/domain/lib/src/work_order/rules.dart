import '../errors.dart';
import '../farm/agro_operation.dart';
import '../farm/parcel.dart';
import '../farm/stock_item.dart';
import '../identifiers.dart';
import '../result.dart';
import 'hectares.dart';
import 'material_use.dart';
import 'work_interval.dart';
import 'work_order.dart';
import 'work_order_status.dart';

bool previousPhaseDone({required AgroOperation operation, required List<WorkOrder> ordersOnParcel}) {
  final previous = operation.previous;
  if (previous == null) return true;
  final phase = ordersOnParcel.where((o) => o.operation == previous && !o.status.isCancelled).toList();
  return phase.isNotEmpty && phase.every((o) => o.status is Completed);
}

Hectares remainingHectares({
  required Parcel parcel,
  required AgroOperation operation,
  required List<WorkOrder> ordersOnParcel,
}) {
  final reported = ordersOnParcel
      .where((o) => o.operation == operation)
      .map((o) => o.status.countedReport?.processed)
      .nonNulls
      .fold(Hectares.zero, (sum, processed) => sum + processed);
  return parcel.area.minus(reported);
}

Result<Hectares> checkReportedArea(Hectares processed, {required Hectares remaining}) =>
    processed > remaining ? Failure(ExceedsParcelArea(remaining)) : Success(processed);

int stockShortfall({required MaterialUse material, required List<StockItem> stock, required List<WorkOrder> orders}) {
  final available = stock.where((item) => item.id == material.item).map((item) => item.available).firstOrNull ?? 0;
  final reserved = orders
      .where((o) => o.status is InProgress && o.material?.item == material.item)
      .fold(0, (sum, o) => sum + o.material!.quantity);
  final missing = material.quantity + reserved - available;
  return missing > 0 ? missing : 0;
}

List<WorkOrder> assignmentConflicts({
  required UserId workerId,
  required MachineId machineId,
  required WorkInterval interval,
  required List<WorkOrder> orders,
}) => [
  for (final order in orders)
    if (!order.status.isCancelled &&
        (order.workerId == workerId || order.machineId == machineId) &&
        order.interval.overlaps(interval))
      order,
];

DomainError? assignmentError({
  required UserId workerId,
  required MachineId machineId,
  required WorkInterval interval,
  required List<WorkOrder> orders,
}) {
  final conflicts = assignmentConflicts(workerId: workerId, machineId: machineId, interval: interval, orders: orders);
  if (conflicts.isEmpty) return null;
  return conflicts.any((o) => o.workerId == workerId) ? const WorkerBusy() : const MachineBusy();
}
