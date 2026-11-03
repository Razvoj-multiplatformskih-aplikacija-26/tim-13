import 'package:domain/domain.dart';

const worker = User(id: UserId('marko'), name: 'Marko', role: Role.worker);
const otherWorker = User(id: UserId('janko'), name: 'Janko', role: Role.worker);
const owner = User(id: UserId('gazda'), name: 'Gazda', role: Role.owner);

final now = DateTime(2026, 11, 2, 12);

Hectares ha(String input) => Hectares.parse(input).valueOrNull!;

FuelLiters liters(String input) => FuelLiters.parse(input).valueOrNull!;

ReasonText reason(String input) => ReasonText.parse(input).valueOrNull!;

MaterialUse material(String item, int quantity) => MaterialUse.parse(StockItemId(item), '$quantity').valueOrNull!;

WorkInterval interval(int startHour, int endHour) =>
    WorkInterval.parse(start: DateTime(2026, 11, 3, startHour), end: DateTime(2026, 11, 3, endHour)).valueOrNull!;

WorkReport report(String hectares) => WorkReport(processed: ha(hectares), fuel: liters('40'), submittedAt: now);

final parcel = Parcel(id: const ParcelId('p1'), name: 'Njiva', area: ha('10'));

WorkOrder order({
  String id = 'o1',
  AgroOperation operation = AgroOperation.plowing,
  WorkOrderStatus status = const Planned(),
  UserId workerId = const UserId('marko'),
  MachineId machineId = const MachineId('t1'),
  WorkInterval? workInterval,
  ParcelId parcelId = const ParcelId('p1'),
  MaterialUse? use,
}) => WorkOrder(
  id: WorkOrderId(id),
  parcelId: parcelId,
  operation: operation,
  workerId: workerId,
  machineId: machineId,
  interval: workInterval ?? interval(8, 12),
  material: use,
  status: status,
);

WorkOrderStatus completed(String hectares) => Completed(report: report(hectares), approvedBy: owner.id, at: now);
