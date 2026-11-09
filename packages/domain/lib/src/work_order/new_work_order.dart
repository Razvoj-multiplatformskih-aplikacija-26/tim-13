import 'package:equatable/equatable.dart';

import '../farm/agro_operation.dart';
import '../identifiers.dart';
import 'material_use.dart';
import 'work_interval.dart';
import 'work_order.dart';
import 'work_order_status.dart';

final class NewWorkOrder extends Equatable {
  const NewWorkOrder({
    required this.parcelId,
    required this.operation,
    required this.workerId,
    required this.machineId,
    required this.interval,
    this.material,
  });

  final ParcelId parcelId;
  final AgroOperation operation;
  final UserId workerId;
  final MachineId machineId;
  final WorkInterval interval;
  final MaterialUse? material;

  WorkOrder withId(WorkOrderId id) => WorkOrder(
    id: id,
    parcelId: parcelId,
    operation: operation,
    workerId: workerId,
    machineId: machineId,
    interval: interval,
    material: material,
    status: const Planned(),
  );

  @override
  List<Object?> get props => [parcelId, operation, workerId, machineId, interval, material];
}
