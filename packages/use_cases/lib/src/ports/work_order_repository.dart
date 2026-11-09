import 'package:domain/domain.dart';

import '../work_book.dart';

abstract interface class WorkOrderRepository {
  Future<WorkBook> workBook();

  Future<Result<WorkOrder>> create(NewWorkOrder order);

  Future<Result<WorkOrder>> save(WorkOrder order, {required WorkOrderStage from});
}
