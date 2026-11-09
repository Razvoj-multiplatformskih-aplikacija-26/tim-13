import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';
import 'package:use_cases/use_cases.dart';

import 'farm_mapping.dart';
import 'parsing.dart';

typedef ReportInput = ({Hectares processed, FuelLiters fuel, MaterialUse? material});

T _required<T>(T? value, String field, Object? source) =>
    value ?? (throw FormatException('Expected "$field" in this status', source));

extension WorkOrderStageMapping on WorkOrderStage {
  String toDto() => switch (this) {
    WorkOrderStage.planned => WorkOrderStatusDto.planned,
    WorkOrderStage.inProgress => WorkOrderStatusDto.inProgress,
    WorkOrderStage.awaitingConfirmation => WorkOrderStatusDto.awaitingConfirmation,
    WorkOrderStage.completed => WorkOrderStatusDto.completed,
    WorkOrderStage.rejected => WorkOrderStatusDto.rejected,
    WorkOrderStage.cancelled => WorkOrderStatusDto.cancelled,
  };
}

WorkOrderStage stageFromDto(String kind) => switch (kind) {
  WorkOrderStatusDto.planned => WorkOrderStage.planned,
  WorkOrderStatusDto.inProgress => WorkOrderStage.inProgress,
  WorkOrderStatusDto.awaitingConfirmation => WorkOrderStage.awaitingConfirmation,
  WorkOrderStatusDto.completed => WorkOrderStage.completed,
  WorkOrderStatusDto.rejected => WorkOrderStage.rejected,
  WorkOrderStatusDto.cancelled => WorkOrderStage.cancelled,
  _ => throw FormatException('Unknown work order status', kind),
};

extension MaterialUseMapping on MaterialUse {
  MaterialUseDto toDto() => MaterialUseDto(itemId: item.value, quantity: quantity);
}

extension MaterialUseDtoMapping on MaterialUseDto {
  Result<MaterialUse> toDomain() => MaterialUse.parse(StockItemId(itemId), '$quantity');
}

MaterialUse? _material(MaterialUseDto? material) => material == null ? null : valid(material.toDomain(), material);

extension WorkReportMapping on WorkReport {
  WorkReportDto toDto() => WorkReportDto(
    processedAres: processed.toAres(),
    fuelCentiliters: fuel.toCentiliters(),
    submittedAt: submittedAt,
    material: material?.toDto(),
  );
}

extension WorkReportDtoMapping on WorkReportDto {
  WorkReport toDomain() => WorkReport(
    processed: valid(hectaresFromAres(processedAres), processedAres),
    fuel: valid(fuelFromCentiliters(fuelCentiliters), fuelCentiliters),
    submittedAt: submittedAt,
    material: _material(material),
  );
}

extension WorkOrderStatusMapping on WorkOrderStatus {
  WorkOrderStatusDto toDto() => switch (this) {
    Planned() => const WorkOrderStatusDto(kind: WorkOrderStatusDto.planned),
    InProgress(:final startedAt) => WorkOrderStatusDto(kind: WorkOrderStatusDto.inProgress, startedAt: startedAt),
    AwaitingConfirmation(:final report) => WorkOrderStatusDto(
      kind: WorkOrderStatusDto.awaitingConfirmation,
      report: report.toDto(),
    ),
    Completed(:final report, :final approvedBy, :final at) => WorkOrderStatusDto(
      kind: WorkOrderStatusDto.completed,
      report: report.toDto(),
      by: approvedBy.value,
      at: at,
    ),
    Rejected(:final report, :final reason, :final rejectedBy, :final at) => WorkOrderStatusDto(
      kind: WorkOrderStatusDto.rejected,
      report: report.toDto(),
      reason: reason.text,
      by: rejectedBy.value,
      at: at,
    ),
    Cancelled(:final reason, :final cancelledBy, :final at) => WorkOrderStatusDto(
      kind: WorkOrderStatusDto.cancelled,
      reason: reason.text,
      by: cancelledBy.value,
      at: at,
    ),
  };
}

extension WorkOrderStatusDtoMapping on WorkOrderStatusDto {
  WorkReport _report() => _required(report, 'report', kind).toDomain();

  UserId _by() => UserId(_required(by, 'by', kind));

  DateTime _at() => _required(at, 'at', kind);

  ReasonText _reason() => valid(ReasonText.parse(_required(reason, 'reason', kind)), reason);

  WorkOrderStatus toDomain() => switch (stageFromDto(kind)) {
    WorkOrderStage.planned => const Planned(),
    WorkOrderStage.inProgress => InProgress(startedAt: _required(startedAt, 'startedAt', kind)),
    WorkOrderStage.awaitingConfirmation => AwaitingConfirmation(report: _report()),
    WorkOrderStage.completed => Completed(report: _report(), approvedBy: _by(), at: _at()),
    WorkOrderStage.rejected => Rejected(report: _report(), reason: _reason(), rejectedBy: _by(), at: _at()),
    WorkOrderStage.cancelled => Cancelled(reason: _reason(), cancelledBy: _by(), at: _at()),
  };
}

extension WorkOrderMapping on WorkOrder {
  WorkOrderDto toDto() => WorkOrderDto(
    id: id.value,
    parcelId: parcelId.value,
    operation: operation.toDto(),
    workerId: workerId.value,
    machineId: machineId.value,
    start: interval.start,
    end: interval.end,
    status: status.toDto(),
    material: material?.toDto(),
  );
}

extension WorkOrderDtoMapping on WorkOrderDto {
  WorkOrder toDomain() => WorkOrder(
    id: WorkOrderId(id),
    parcelId: ParcelId(parcelId),
    operation: operationFromDto(operation),
    workerId: UserId(workerId),
    machineId: MachineId(machineId),
    interval: valid(WorkInterval.parse(start: start, end: end), id),
    material: _material(material),
    status: status.toDomain(),
  );
}

extension WorkBookMapping on WorkBook {
  WorkBookDto toDto() => WorkBookDto(
    orders: [for (final order in orders) order.toDto()],
    parcels: [for (final parcel in parcels) parcel.toDto()],
    workers: [for (final worker in workers) worker.toDto()],
    machines: [for (final machine in machines) machine.toDto()],
    stock: [for (final item in stock) item.toDto()],
  );
}

extension WorkBookDtoMapping on WorkBookDto {
  WorkBook toDomain() => WorkBook(
    orders: [for (final order in orders) order.toDomain()],
    parcels: [for (final parcel in parcels) parcel.toDomain()],
    workers: [for (final worker in workers) worker.toDomain()],
    machines: [for (final machine in machines) machine.toDomain()],
    stock: [for (final item in stock) item.toDomain()],
  );
}

extension NewWorkOrderMapping on NewWorkOrder {
  NewWorkOrderDto toDto() => NewWorkOrderDto(
    parcelId: parcelId.value,
    operation: operation.toDto(),
    workerId: workerId.value,
    machineId: machineId.value,
    start: interval.start,
    end: interval.end,
    material: material?.toDto(),
  );
}

extension NewWorkOrderDtoMapping on NewWorkOrderDto {
  Result<NewWorkOrder> toDomain() {
    final operation = operationFromDto(this.operation);
    final interval = WorkInterval.parse(start: start, end: end);
    if (interval case Failure(:final error)) return Failure(error);
    final material = this.material?.toDomain();
    if (material case Failure(:final error)) return Failure(error);
    return Success(
      NewWorkOrder(
        parcelId: ParcelId(parcelId),
        operation: operation,
        workerId: UserId(workerId),
        machineId: MachineId(machineId),
        interval: interval.valueOrNull!,
        material: material?.valueOrNull,
      ),
    );
  }
}

SubmitReportDto submitReportDto({required Hectares processed, required FuelLiters fuel, MaterialUse? material}) =>
    SubmitReportDto(
      processedAres: processed.toAres(),
      fuelCentiliters: fuel.toCentiliters(),
      material: material?.toDto(),
    );

extension SubmitReportDtoMapping on SubmitReportDto {
  Result<ReportInput> toDomain() {
    final processed = hectaresFromAres(processedAres);
    if (processed case Failure(:final error)) return Failure(error);
    final fuel = fuelFromCentiliters(fuelCentiliters);
    if (fuel case Failure(:final error)) return Failure(error);
    final material = this.material?.toDomain();
    if (material case Failure(:final error)) return Failure(error);
    return Success((processed: processed.valueOrNull!, fuel: fuel.valueOrNull!, material: material?.valueOrNull));
  }
}

extension ReasonTextMapping on ReasonText {
  ReasonDto toDto() => ReasonDto(reason: text);
}

extension ReasonDtoMapping on ReasonDto {
  Result<ReasonText> toDomain() => ReasonText.parse(reason);
}
