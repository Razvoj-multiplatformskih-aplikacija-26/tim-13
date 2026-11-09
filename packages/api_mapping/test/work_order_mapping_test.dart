import 'package:api_contract/api_contract.dart';
import 'package:api_mapping/api_mapping.dart';
import 'package:domain/domain.dart';
import 'package:test/test.dart';
import 'package:use_cases/use_cases.dart';

void main() {
  const marko = User(id: UserId('u-marko'), name: 'Marko Jovanović', role: Role.worker);
  const gazda = User(id: UserId('u-gazda'), name: 'Stevan Ilić', role: Role.owner);
  final interval = WorkInterval.parse(
    start: DateTime.utc(2026, 11, 10, 6),
    end: DateTime.utc(2026, 11, 10, 14),
  ).valueOrNull!;
  final hectares = Hectares.parse('12,5').valueOrNull!;
  final fuel = FuelLiters.parse('75,55').valueOrNull!;
  final urea = MaterialUse.parse(const StockItemId('s-urea'), '700').valueOrNull!;
  final report = WorkReport(processed: hectares, fuel: fuel, submittedAt: DateTime.utc(2026, 11, 10, 15));
  final reason = ReasonText.parse('Utrošak goriva je pogrešno unet.').valueOrNull!;
  final at = DateTime.utc(2026, 11, 11, 8);

  WorkOrder order(WorkOrderStatus status) => WorkOrder(
    id: const WorkOrderId('n-07'),
    parcelId: const ParcelId('p-polje'),
    operation: AgroOperation.fertilizing,
    workerId: marko.id,
    machineId: const MachineId('m-t1'),
    interval: interval,
    material: urea,
    status: status,
  );

  test('every status survives the trip to the contract and back', () {
    final statuses = <WorkOrderStatus>[
      const Planned(),
      InProgress(startedAt: interval.start),
      AwaitingConfirmation(report: report),
      Completed(report: report, approvedBy: gazda.id, at: at),
      Rejected(report: report, reason: reason, rejectedBy: gazda.id, at: at),
      Cancelled(reason: reason, cancelledBy: marko.id, at: at),
    ];
    for (final status in statuses) {
      final original = order(status);
      final json = original.toDto().toJson();
      expect(WorkOrderDto.fromJson(json).toDomain(), original, reason: status.stage.name);
    }
  });

  test('area travels in ares and fuel in centiliters', () {
    final dto = report.toDto();
    expect(dto.processedAres, 1250);
    expect(dto.fuelCentiliters, 7555);
    expect(dto.toDomain(), report);
  });

  test('the work book survives the trip', () {
    final book = WorkBook(
      orders: [order(const Planned())],
      parcels: [Parcel(id: const ParcelId('p-polje'), name: 'Veliko polje', area: hectares)],
      workers: const [marko, gazda],
      machines: const [Machine(id: MachineId('m-t1'), name: 'Traktor IMT 577')],
      stock: const [
        StockItem(
          id: StockItemId('s-urea'),
          name: 'Urea',
          kind: StockKind.fertilizer,
          unit: StockUnit.kilogram,
          available: 5000,
        ),
      ],
    );
    expect(WorkBookDto.fromJson(book.toDto().toJson()).toDomain(), book);
  });

  test('a status without the data it needs is refused', () {
    const broken = WorkOrderStatusDto(kind: WorkOrderStatusDto.completed);
    expect(broken.toDomain, throwsFormatException);
    expect(() => const WorkOrderStatusDto(kind: 'lost').toDomain(), throwsFormatException);
  });

  test('a request that breaks a rule comes back as the domain error, not as a broken request', () {
    const zeroArea = SubmitReportDto(processedAres: 0, fuelCentiliters: 1000);
    const tooMuchFuel = SubmitReportDto(processedAres: 100, fuelCentiliters: 999999);
    final backwards = NewWorkOrderDto(
      parcelId: 'p-salas',
      operation: OperationCodes.plowing,
      workerId: 'u-janko',
      machineId: 'm-t2',
      start: DateTime.utc(2026, 11, 12, 12),
      end: DateTime.utc(2026, 11, 12, 6),
    );

    expect(zeroArea.toDomain().errorOrNull, const InvalidHectares());
    expect(tooMuchFuel.toDomain().errorOrNull, const InvalidFuelAmount());
    expect(backwards.toDomain().errorOrNull, const InvalidInterval());
    expect(const ReasonDto(reason: '   ').toDomain().errorOrNull, const ReasonRequired());
  });

  test('requests built by a client are read back by the server', () {
    final created = NewWorkOrder(
      parcelId: const ParcelId('p-polje'),
      operation: AgroOperation.fertilizing,
      workerId: marko.id,
      machineId: const MachineId('m-t1'),
      interval: interval,
      material: urea,
    );
    final sent = submitReportDto(processed: hectares, fuel: fuel, material: urea);

    expect(NewWorkOrderDto.fromJson(created.toDto().toJson()).toDomain().valueOrNull, created);
    expect(SubmitReportDto.fromJson(sent.toJson()).toDomain().valueOrNull, (
      processed: hectares,
      fuel: fuel,
      material: urea,
    ));
    expect(reason.toDto().toDomain().valueOrNull, reason);
  });

  test('users and their roles survive the trip', () {
    expect(UserDto.fromJson(gazda.toDto().toJson()).toDomain(), gazda);
    expect(() => const UserDto(id: 'x', name: 'X', role: 'guest').toDomain(), throwsFormatException);
  });
}
