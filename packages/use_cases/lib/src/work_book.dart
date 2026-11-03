import 'package:domain/domain.dart';
import 'package:equatable/equatable.dart';

final class WorkBook extends Equatable {
  const WorkBook({
    required this.orders,
    required this.parcels,
    required this.workers,
    required this.machines,
    required this.stock,
  });

  const WorkBook.empty()
    : orders = const [],
      parcels = const [],
      workers = const [],
      machines = const [],
      stock = const [];

  final List<WorkOrder> orders;
  final List<Parcel> parcels;
  final List<User> workers;
  final List<Machine> machines;
  final List<StockItem> stock;

  List<WorkOrder> ordersOf(UserId workerId) => orders.where((o) => o.workerId == workerId).toList();

  List<WorkOrder> ordersOn(ParcelId parcelId) => orders.where((o) => o.parcelId == parcelId).toList();

  List<User> get fieldWorkers => workers.where((w) => w.role == Role.worker).toList();

  List<WorkOrder> ordersIn(WorkOrderStage stage) => orders.where((o) => o.status.stage == stage).toList();

  WorkOrder? find(WorkOrderId id) => orders.where((o) => o.id == id).firstOrNull;

  Parcel? parcelOf(WorkOrder order) => parcels.where((p) => p.id == order.parcelId).firstOrNull;

  User? workerOf(WorkOrder order) => workers.where((w) => w.id == order.workerId).firstOrNull;

  Machine? machineOf(WorkOrder order) => machines.where((m) => m.id == order.machineId).firstOrNull;

  StockItem? stockItem(StockItemId id) => stock.where((item) => item.id == id).firstOrNull;

  Hectares? remainingFor(WorkOrder order) {
    final parcel = parcelOf(order);
    if (parcel == null) return null;
    return remainingHectares(parcel: parcel, operation: order.operation, ordersOnParcel: ordersOn(order.parcelId));
  }

  @override
  List<Object?> get props => [orders, parcels, workers, machines, stock];
}
