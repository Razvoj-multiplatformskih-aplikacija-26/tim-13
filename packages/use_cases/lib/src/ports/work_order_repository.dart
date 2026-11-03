import 'package:domain/domain.dart';

import '../work_book.dart';

abstract interface class WorkOrderRepository {
  Future<WorkBook> workBook();

  Future<WorkOrderId> nextId();

  Future<WorkOrder> save(WorkOrder order);
}
