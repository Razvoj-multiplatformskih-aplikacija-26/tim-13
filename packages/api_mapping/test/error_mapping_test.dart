import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  final errors = <DomainError>[
    const InvalidHectares(),
    const InvalidFuelAmount(),
    const InvalidMaterialQuantity(),
    const ReasonRequired(),
    const ReasonTooLong(201),
    const InvalidInterval(),
    ExceedsParcelArea(Hectares.parse('3,5').valueOrNull!),
    ExceedsParcelArea(Hectares.zero),
    const PreviousPhaseNotDone(AgroOperation.sowing),
    const InsufficientStock(item: StockItemId('s-urea'), missing: 250),
    const MaterialRequired(),
    const WorkerBusy(),
    const MachineBusy(),
    const InvalidTransition(from: WorkOrderStage.cancelled, to: WorkOrderStage.inProgress),
    const NotAllowed(),
    const NotFound(),
  ];

  test('every domain error crosses the network and comes back the same', () {
    for (final error in errors) {
      final json = error.toProblem().toJson();
      expect(ProblemDto.fromJson(json).toDomainError(), error, reason: '${error.runtimeType}');
    }
  });

  test('the status tells what kind of no it is', () {
    expect(const InvalidHectares().toProblem().status, 422);
    expect(const WorkerBusy().toProblem().status, 409);
    expect(const InvalidTransition(from: WorkOrderStage.planned, to: WorkOrderStage.completed).toProblem().status, 409);
    expect(const NotAllowed().toProblem().status, 403);
    expect(const NotFound().toProblem().status, 404);
  });

  test('a limit changed on the server reaches the message of an older client', () {
    final fromNewerServer = ProblemDto.fromJson(const ReasonTooLong(150, max: 100).toProblem().toJson());
    expect(fromNewerServer.toDomainError(), const ReasonTooLong(150, max: 100));
  });

  test('an older client does not know a new code and does not crash', () {
    const unknown = ProblemDto(status: 422, code: 'frost-warning', title: 'Frost warning');
    const missingData = ProblemDto(status: 422, code: ErrorCodes.reasonTooLong, title: 'Reason too long');
    const strangeStage = ProblemDto(
      status: 409,
      code: ErrorCodes.invalidTransition,
      title: 'Invalid transition',
      from: 'paused',
      to: WorkOrderStatusDto.inProgress,
    );
    expect(unknown.toDomainError(), isNull);
    expect(missingData.toDomainError(), isNull);
    expect(strangeStage.toDomainError(), isNull);
  });
}
