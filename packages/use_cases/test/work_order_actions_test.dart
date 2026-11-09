import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

const worker = User(id: UserId('marko'), name: 'Marko', role: Role.worker);
const owner = User(id: UserId('gazda'), name: 'Gazda', role: Role.owner);
final now = DateTime(2026, 11, 2, 12);

final class MemoryRepository implements WorkOrderRepository {
  MemoryRepository(this.book);

  WorkBook book;
  List<WorkOrder> racing = [];

  @override
  Future<WorkBook> workBook() async => book;

  void _store(WorkOrder order) => book = WorkBook(
    orders: [...book.orders.where((o) => o.id != order.id), order],
    parcels: book.parcels,
    workers: book.workers,
    machines: book.machines,
    stock: book.stock,
  );

  @override
  Future<Result<WorkOrder>> create(NewWorkOrder order) async {
    final created = order.withId(const WorkOrderId('new'));
    _store(created);
    return Success(created);
  }

  @override
  Future<Result<WorkOrder>> save(WorkOrder order, {required WorkOrderStage from}) async {
    if (racing.isNotEmpty) _store(racing.removeAt(0));
    final current = book.find(order.id)?.status.stage;
    if (current == null) return const Failure(NotFound());
    if (current != from) return Failure(InvalidTransition(from: current, to: order.status.stage));
    _store(order);
    return Success(order);
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

  test('planning a free slot creates the order with the id from the repository', () async {
    final result = await PlanWorkOrder(repository: repository)(
      parcelId: const ParcelId('p1'),
      operation: AgroOperation.plowing,
      workerId: const UserId('janko'),
      machineId: const MachineId('t2'),
      interval: interval,
      by: owner,
    );
    expect(result.valueOrNull?.id, const WorkOrderId('new'));
    expect(repository.book.orders, hasLength(2));
  });

  test('a worker does not see an order of another worker', () async {
    const janko = User(id: UserId('janko'), name: 'Janko', role: Role.worker);
    final start = StartWorkOrder(repository: repository, clock: FixedClock(now));
    expect((await start(id: plowing.id, by: janko)).errorOrNull, const NotFound());
  });

  test('a late client gets the rule checked again on the fresh order', () async {
    final cancelled = cancelWorkOrder(
      plowing,
      reason: ReasonText.parse('Kiša').valueOrNull!,
      by: owner,
      now: now,
    ).valueOrNull!;
    repository.racing = [cancelled];

    final result = await StartWorkOrder(repository: repository, clock: FixedClock(now))(id: plowing.id, by: worker);

    expect(result.errorOrNull, const InvalidTransition(from: WorkOrderStage.cancelled, to: WorkOrderStage.inProgress));
    expect(repository.book.find(plowing.id)?.status, isA<Cancelled>());
  });
}
