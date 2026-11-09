import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class QuietSeason implements WorkOrderRepository {
  const QuietSeason();

  @override
  Future<WorkBook> workBook() async => const WorkBook.empty();

  @override
  Future<Result<WorkOrder>> create(NewWorkOrder order) async => Success(order.withId(const WorkOrderId('tiha-sezona')));

  @override
  Future<Result<WorkOrder>> save(WorkOrder order, {required WorkOrderStage from}) async => const Failure(NotFound());
}
