import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const worker = User(id: UserId('marko'), name: 'Marko', role: Role.worker);
const owner = User(id: UserId('gazda'), name: 'Gazda', role: Role.owner);
final now = DateTime(2026, 11, 2, 12);

final class MemoryRepository implements WorkOrderRepository {
  MemoryRepository(this.book);

  WorkBook book;

  @override
  Future<WorkBook> workBook() async => book;

  @override
  Future<WorkOrderId> nextId() async => const WorkOrderId('new');

  @override
  Future<WorkOrder> save(WorkOrder order) async {
    book = WorkBook(
      orders: [...book.orders.where((o) => o.id != order.id), order],
      parcels: book.parcels,
      workers: book.workers,
      machines: book.machines,
      stock: book.stock,
    );
    return order;
  }
}

void main() {
  final area = Hectares.parse('10').valueOrNull!;
  final interval = WorkInterval.parse(start: now, end: now.add(const Duration(hours: 4))).valueOrNull!;
  final plowing = WorkOrder(
    id: const WorkOrderId('o1'),
    parcelId: const ParcelId('p1'),
    operation: AgroOperation.plowing,
    workerId: worker.id,
    machineId: const MachineId('t1'),
    interval: interval,
  );
  late MemoryRepository repository;

  setUp(() {
    repository = MemoryRepository(
      WorkBook(
        orders: [plowing],
        parcels: [Parcel(id: const ParcelId('p1'), name: 'Njiva', area: area)],
        workers: const [worker],
        machines: const [],
        stock: const [],
      ),
    );
  });

  test('a started order is saved', () async {
    final start = StartWorkOrder(repository: repository, clock: FixedClock(now));
    final result = await start(id: plowing.id, by: worker);
    expect(result.isSuccess, isTrue);
    expect(repository.book.find(plowing.id)?.status, InProgress(startedAt: now));
  });

  test('a rejected action changes nothing', () async {
    final start = StartWorkOrder(repository: repository, clock: FixedClock(now));
    final result = await start(id: plowing.id, by: owner);
    expect(result.errorOrNull, const NotAllowed());
    expect(repository.book.find(plowing.id)?.status, const Planned());
  });

  test('an unknown order is not found', () async {
    final approve = ApproveWorkOrder(repository: repository, clock: FixedClock(now));
    expect((await approve(id: const WorkOrderId('x'), by: owner)).errorOrNull, const NotFound());
  });

  test('the whole flow from start to approval', () async {
    final clock = FixedClock(now);
    await StartWorkOrder(repository: repository, clock: clock)(id: plowing.id, by: worker);
    final report = await SubmitWorkReport(repository: repository, clock: clock)(
      id: plowing.id,
      processed: area,
      fuel: FuelLiters.parse('40').valueOrNull!,
      by: worker,
    );
    expect(report.valueOrNull?.status, isA<AwaitingConfirmation>());
    await ApproveWorkOrder(repository: repository, clock: clock)(id: plowing.id, by: owner);
    expect(repository.book.find(plowing.id)?.status, isA<Completed>());
    expect(repository.book.remainingFor(plowing), Hectares.zero);
  });

  test('planning refuses a busy worker', () async {
    final plan = PlanWorkOrder(repository: repository);
    final result = await plan(
      parcelId: const ParcelId('p1'),
      operation: AgroOperation.plowing,
      workerId: worker.id,
      machineId: const MachineId('t2'),
      interval: interval,
      by: owner,
    );
    expect(result.errorOrNull, const WorkerBusy());
    expect(repository.book.orders, hasLength(1));
  });
}
