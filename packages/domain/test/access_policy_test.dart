import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  const marko = User(id: UserId('marko'), name: 'Marko', role: Role.worker);
  const janko = User(id: UserId('janko'), name: 'Janko', role: Role.worker);
  const owner = User(id: UserId('gazda'), name: 'Gazda', role: Role.owner);
  final interval = WorkInterval.parse(
    start: DateTime.utc(2026, 11, 10, 6),
    end: DateTime.utc(2026, 11, 10, 12),
  ).valueOrNull!;
  final markos = WorkOrder(
    id: const WorkOrderId('o1'),
    parcelId: const ParcelId('p1'),
    operation: AgroOperation.plowing,
    workerId: marko.id,
    machineId: const MachineId('t1'),
    interval: interval,
  );

  test('each app takes its own role', () {
    expect(AccessPolicy.canUseFieldApp(marko), isTrue);
    expect(AccessPolicy.canUseFieldApp(owner), isFalse);
    expect(AccessPolicy.canUseBackoffice(owner), isTrue);
    expect(AccessPolicy.canUseBackoffice(marko), isFalse);
  });

  test('a worker sees only his own orders and the owner sees every order', () {
    expect(AccessPolicy.canView(marko, markos), isTrue);
    expect(AccessPolicy.canView(janko, markos), isFalse);
    expect(AccessPolicy.canView(owner, markos), isTrue);
  });
}
