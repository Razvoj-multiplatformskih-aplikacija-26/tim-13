import 'package:equatable/equatable.dart';

import '../farm/agro_operation.dart';
import '../identifiers.dart';
import 'material_use.dart';
import 'work_interval.dart';
import 'work_order_status.dart';

final class WorkOrder extends Equatable {
  const WorkOrder({
    required this.id,
    required this.parcelId,
    required this.operation,
    required this.workerId,
    required this.machineId,
    required this.interval,
    this.material,
    this.status = const Planned(),
  });

  final WorkOrderId id;
  final ParcelId parcelId;
  final AgroOperation operation;
  final UserId workerId;
  final MachineId machineId;
  final WorkInterval interval;
  final MaterialUse? material;
  final WorkOrderStatus status;

  WorkOrder withStatus(WorkOrderStatus status) => WorkOrder(
    id: id,
    parcelId: parcelId,
    operation: operation,
    workerId: workerId,
    machineId: machineId,
    interval: interval,
    material: material,
    status: status,
  );

  @override
  List<Object?> get props => [id, parcelId, operation, workerId, machineId, interval, material, status];
}
