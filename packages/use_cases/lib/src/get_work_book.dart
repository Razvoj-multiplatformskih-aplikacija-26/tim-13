import 'ports/work_order_repository.dart';
import 'work_book.dart';

final class GetWorkBook {
  const GetWorkBook({required this.repository});

  final WorkOrderRepository repository;

  Future<WorkBook> call() => repository.workBook();
}
