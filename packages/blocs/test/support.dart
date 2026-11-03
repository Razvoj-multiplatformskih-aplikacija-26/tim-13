import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

const worker = User(id: UserId('marko'), name: 'Marko', role: Role.worker);
const owner = User(id: UserId('gazda'), name: 'Gazda', role: Role.owner);
final now = DateTime(2026, 11, 2, 12);

final area = Hectares.parse('10').valueOrNull!;
final parcel = Parcel(id: const ParcelId('p1'), name: 'Njiva', area: area);

WorkInterval hours(int start, int end) =>
    WorkInterval.parse(start: DateTime(2026, 11, 3, start), end: DateTime(2026, 11, 3, end)).valueOrNull!;

final plowing = WorkOrder(
  id: const WorkOrderId('o1'),
  parcelId: parcel.id,
  operation: AgroOperation.plowing,
  workerId: worker.id,
  machineId: const MachineId('t1'),
  interval: hours(8, 12),
);

final fertilizing = WorkOrder(
  id: const WorkOrderId('o2'),
  parcelId: parcel.id,
  operation: AgroOperation.fertilizing,
  workerId: worker.id,
  machineId: const MachineId('t1'),
  interval: hours(12, 14),
);

WorkOrder awaiting(String id) => WorkOrder(
  id: WorkOrderId(id),
  parcelId: parcel.id,
  operation: AgroOperation.plowing,
  workerId: worker.id,
  machineId: const MachineId('t1'),
  interval: hours(6, 7),
  status: AwaitingConfirmation(
    report: WorkReport(processed: area, fuel: FuelLiters.parse('40').valueOrNull!, submittedAt: now),
  ),
);

final class FakeRepository implements WorkOrderRepository {
  FakeRepository({List<WorkOrder>? orders}) : orders = orders ?? [plowing];

  List<WorkOrder> orders;
  bool failing = false;

  @override
  Future<WorkBook> workBook() async {
    if (failing) throw const RepositoryException('Simulated outage');
    return WorkBook(
      orders: orders,
      parcels: [parcel],
      workers: const [worker],
      machines: const [Machine(id: MachineId('t1'), name: 'Traktor')],
      stock: const [],
    );
  }

  @override
  Future<WorkOrderId> nextId() async => const WorkOrderId('new');

  @override
  Future<WorkOrder> save(WorkOrder order) async {
    orders = [...orders.where((o) => o.id != order.id), order];
    return order;
  }
}
