import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'seed.dart';

final class FakeWorkOrders implements WorkOrderRepository {
  FakeWorkOrders({required Clock clock, this.latency = const Duration(milliseconds: 700)})
    : _orders = seedOrders(clock.now());

  final Duration latency;
  final List<WorkOrder> _orders;
  int failingRequests = 0;
  int emptyResponses = 0;
  int _nextId = 1;

  Future<void> _roundTrip() async {
    await Future<void>.delayed(latency);
    if (failingRequests > 0) {
      failingRequests--;
      throw const RepositoryException('Simulated outage');
    }
  }

  @override
  Future<WorkBook> workBook() async {
    await _roundTrip();
    if (emptyResponses > 0) {
      emptyResponses--;
      return const WorkBook.empty();
    }
    return WorkBook(
      orders: List.of(_orders),
      parcels: seedParcels,
      workers: const [marko, janko],
      machines: seedMachines,
      stock: seedStock,
    );
  }

  @override
  Future<WorkOrderId> nextId() async => WorkOrderId('lokalni-${_nextId++}');

  @override
  Future<WorkOrder> save(WorkOrder order) async {
    await _roundTrip();
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index < 0) {
      _orders.add(order);
    } else {
      _orders[index] = order;
    }
    return order;
  }
}
