import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

final class QuietSeason implements WorkOrderRepository {
  const QuietSeason();

  @override
  Future<WorkBook> workBook() async => const WorkBook.empty();

  @override
  Future<WorkOrderId> nextId() async => const WorkOrderId('tiha-sezona');

  @override
  Future<WorkOrder> save(WorkOrder order) async => order;
}
