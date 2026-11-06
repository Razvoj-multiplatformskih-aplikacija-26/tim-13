import 'dart:convert';

import 'package:api_contract/api_contract.dart';
import 'package:test/test.dart';

Map<String, Object?> _overTheWire(Map<String, Object?> json) => jsonDecode(jsonEncode(json)) as Map<String, Object?>;

void main() {
  final submittedAt = DateTime.utc(2026, 11, 5, 16);
  final order = WorkOrderDto(
    id: 'n-07',
    parcelId: 'p-polje',
    operation: OperationCodes.fertilizing,
    workerId: 'u-marko',
    machineId: 'm-t1',
    start: DateTime.utc(2026, 11, 5, 6),
    end: DateTime.utc(2026, 11, 5, 14),
    material: const MaterialUseDto(itemId: 's-urea', quantity: 700),
    status: WorkOrderStatusDto(
      kind: WorkOrderStatusDto.awaitingConfirmation,
      report: WorkReportDto(processedAres: 1200, fuelCentiliters: 7550, submittedAt: submittedAt),
    ),
  );

  test('a work order survives the trip over the wire', () {
    final back = WorkOrderDto.fromJson(_overTheWire(order.toJson()));

    expect(back.toJson(), order.toJson());
    expect(back.status.report?.processedAres, 1200);
    expect(back.material?.quantity, 700);
  });

  test('instants travel in UTC and a time without a zone is refused', () {
    final json = order.toJson();

    expect(json['start'], '2026-11-05T06:00:00.000Z');
    expect(() => WorkOrderDto.fromJson({...json, 'start': '2026-11-05T07:00:00'}), throwsFormatException);
  });

  test('an older client reads a work order that carries a field it does not know yet', () {
    final fromNewerServer = {...order.toJson(), 'weather': 'sunny'};

    expect(WorkOrderDto.fromJson(fromNewerServer).id, 'n-07');
    expect(() => WorkOrderDto.fromJson({...fromNewerServer}..remove('parcelId')), throwsFormatException);
  });

  test('the work book carries every list', () {
    final book = WorkBookDto(
      orders: [order],
      parcels: const [ParcelDto(id: 'p-polje', name: 'Veliko polje', areaAres: 2000)],
      workers: const [UserDto(id: 'u-marko', name: 'Marko Jovanović', role: UserDto.worker)],
      machines: const [MachineDto(id: 'm-t1', name: 'Traktor IMT 577')],
      stock: const [
        StockItemDto(
          id: 's-urea',
          name: 'Urea',
          kind: StockItemDto.fertilizer,
          unit: StockItemDto.kilogram,
          available: 5000,
        ),
      ],
    );

    final back = WorkBookDto.fromJson(_overTheWire(book.toJson()));

    expect(back.toJson(), book.toJson());
  });

  test('a problem carries the code and the data of the rule, without a message for the user', () {
    const problem = ProblemDto(
      status: 422,
      code: ErrorCodes.exceedsParcelArea,
      title: 'Exceeds parcel area',
      remainingAres: 350,
    );

    final json = _overTheWire(problem.toJson());
    final back = ProblemDto.fromJson(json);

    expect(json['type'], ProblemDto.typeOf(ErrorCodes.exceedsParcelArea));
    expect(back.code, ErrorCodes.exceedsParcelArea);
    expect(back.remainingAres, 350);
    expect(json.containsKey('missing'), isFalse);
  });

  test('requests and the session round-trip', () {
    final created = NewWorkOrderDto(
      parcelId: 'p-salas',
      operation: OperationCodes.plowing,
      workerId: 'u-janko',
      machineId: 'm-t2',
      start: DateTime.utc(2026, 11, 7, 6),
      end: DateTime.utc(2026, 11, 7, 12),
    );
    const report = SubmitReportDto(processedAres: 840, fuelCentiliters: 9000);
    const reason = ReasonDto(reason: 'Kvar prskalice');
    final session = SessionDto(
      user: const UserDto(id: 'u-gazda', name: 'Stevan Ilić', role: UserDto.owner),
      expiresAt: DateTime.utc(2026, 11, 6, 20),
      token: 'header.payload.signature',
    );

    expect(NewWorkOrderDto.fromJson(_overTheWire(created.toJson())).toJson(), created.toJson());
    expect(SubmitReportDto.fromJson(_overTheWire(report.toJson())).toJson(), report.toJson());
    expect(ReasonDto.fromJson(_overTheWire(reason.toJson())).reason, 'Kvar prskalice');
    expect(SessionDto.fromJson(_overTheWire(session.toJson())).toJson(), session.toJson());
    expect(LoginDto.fromJson(const {'username': 'marko', 'password': 'x'}).cookie, isFalse);
  });

  test('paths name each action on a work order', () {
    expect(ApiPaths.start('n-01'), '/api/v1/work-orders/n-01/start');
    expect(ApiPaths.approval('n-01'), '/api/v1/work-orders/n-01/approval');
  });
}
