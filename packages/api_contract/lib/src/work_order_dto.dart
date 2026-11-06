import 'farm_dto.dart';
import 'json.dart';

abstract final class OperationCodes {
  static const plowing = 'plowing';
  static const fertilizing = 'fertilizing';
  static const seedbedPreparation = 'seedbed-preparation';
  static const sowing = 'sowing';
  static const spraying = 'spraying';
  static const harvesting = 'harvesting';
}

final class MaterialUseDto {
  const MaterialUseDto({required this.itemId, required this.quantity});

  final String itemId;
  final int quantity;

  Map<String, Object?> toJson() => {'itemId': itemId, 'quantity': quantity};

  factory MaterialUseDto.fromJson(Map<String, Object?> json) =>
      MaterialUseDto(itemId: jsonString(json, 'itemId'), quantity: jsonInt(json, 'quantity'));
}

final class WorkReportDto {
  const WorkReportDto({
    required this.processedAres,
    required this.fuelCentiliters,
    required this.submittedAt,
    this.material,
  });

  final int processedAres;
  final int fuelCentiliters;
  final DateTime submittedAt;
  final MaterialUseDto? material;

  Map<String, Object?> toJson() => {
    'processedAres': processedAres,
    'fuelCentiliters': fuelCentiliters,
    'submittedAt': instantToJson(submittedAt),
    if (material case final material?) 'material': material.toJson(),
  };

  factory WorkReportDto.fromJson(Map<String, Object?> json) => WorkReportDto(
    processedAres: jsonInt(json, 'processedAres'),
    fuelCentiliters: jsonInt(json, 'fuelCentiliters'),
    submittedAt: jsonInstant(json, 'submittedAt'),
    material: switch (jsonOptionalObject(json, 'material')) {
      null => null,
      final material => MaterialUseDto.fromJson(material),
    },
  );
}

final class WorkOrderStatusDto {
  const WorkOrderStatusDto({required this.kind, this.startedAt, this.report, this.by, this.at, this.reason});

  static const planned = 'planned';
  static const inProgress = 'in-progress';
  static const awaitingConfirmation = 'awaiting-confirmation';
  static const completed = 'completed';
  static const rejected = 'rejected';
  static const cancelled = 'cancelled';

  final String kind;
  final DateTime? startedAt;
  final WorkReportDto? report;
  final String? by;
  final DateTime? at;
  final String? reason;

  Map<String, Object?> toJson() => {
    'kind': kind,
    if (startedAt case final startedAt?) 'startedAt': instantToJson(startedAt),
    if (report case final report?) 'report': report.toJson(),
    'by': ?by,
    if (at case final at?) 'at': instantToJson(at),
    'reason': ?reason,
  };

  factory WorkOrderStatusDto.fromJson(Map<String, Object?> json) => WorkOrderStatusDto(
    kind: jsonString(json, 'kind'),
    startedAt: jsonOptionalInstant(json, 'startedAt'),
    report: switch (jsonOptionalObject(json, 'report')) {
      null => null,
      final report => WorkReportDto.fromJson(report),
    },
    by: jsonOptionalString(json, 'by'),
    at: jsonOptionalInstant(json, 'at'),
    reason: jsonOptionalString(json, 'reason'),
  );
}

final class WorkOrderDto {
  const WorkOrderDto({
    required this.id,
    required this.parcelId,
    required this.operation,
    required this.workerId,
    required this.machineId,
    required this.start,
    required this.end,
    required this.status,
    this.material,
  });

  final String id;
  final String parcelId;
  final String operation;
  final String workerId;
  final String machineId;
  final DateTime start;
  final DateTime end;
  final WorkOrderStatusDto status;
  final MaterialUseDto? material;

  Map<String, Object?> toJson() => {
    'id': id,
    'parcelId': parcelId,
    'operation': operation,
    'workerId': workerId,
    'machineId': machineId,
    'start': instantToJson(start),
    'end': instantToJson(end),
    'status': status.toJson(),
    if (material case final material?) 'material': material.toJson(),
  };

  factory WorkOrderDto.fromJson(Map<String, Object?> json) => WorkOrderDto(
    id: jsonString(json, 'id'),
    parcelId: jsonString(json, 'parcelId'),
    operation: jsonString(json, 'operation'),
    workerId: jsonString(json, 'workerId'),
    machineId: jsonString(json, 'machineId'),
    start: jsonInstant(json, 'start'),
    end: jsonInstant(json, 'end'),
    status: WorkOrderStatusDto.fromJson(jsonObject(json['status'])),
    material: switch (jsonOptionalObject(json, 'material')) {
      null => null,
      final material => MaterialUseDto.fromJson(material),
    },
  );
}

final class WorkBookDto {
  const WorkBookDto({
    required this.orders,
    required this.parcels,
    required this.workers,
    required this.machines,
    required this.stock,
  });

  final List<WorkOrderDto> orders;
  final List<ParcelDto> parcels;
  final List<UserDto> workers;
  final List<MachineDto> machines;
  final List<StockItemDto> stock;

  Map<String, Object?> toJson() => {
    'orders': [for (final order in orders) order.toJson()],
    'parcels': [for (final parcel in parcels) parcel.toJson()],
    'workers': [for (final worker in workers) worker.toJson()],
    'machines': [for (final machine in machines) machine.toJson()],
    'stock': [for (final item in stock) item.toJson()],
  };

  factory WorkBookDto.fromJson(Map<String, Object?> json) => WorkBookDto(
    orders: [for (final order in jsonObjects(json, 'orders')) WorkOrderDto.fromJson(order)],
    parcels: [for (final parcel in jsonObjects(json, 'parcels')) ParcelDto.fromJson(parcel)],
    workers: [for (final worker in jsonObjects(json, 'workers')) UserDto.fromJson(worker)],
    machines: [for (final machine in jsonObjects(json, 'machines')) MachineDto.fromJson(machine)],
    stock: [for (final item in jsonObjects(json, 'stock')) StockItemDto.fromJson(item)],
  );
}

final class NewWorkOrderDto {
  const NewWorkOrderDto({
    required this.parcelId,
    required this.operation,
    required this.workerId,
    required this.machineId,
    required this.start,
    required this.end,
    this.material,
  });

  final String parcelId;
  final String operation;
  final String workerId;
  final String machineId;
  final DateTime start;
  final DateTime end;
  final MaterialUseDto? material;

  Map<String, Object?> toJson() => {
    'parcelId': parcelId,
    'operation': operation,
    'workerId': workerId,
    'machineId': machineId,
    'start': instantToJson(start),
    'end': instantToJson(end),
    if (material case final material?) 'material': material.toJson(),
  };

  factory NewWorkOrderDto.fromJson(Map<String, Object?> json) => NewWorkOrderDto(
    parcelId: jsonString(json, 'parcelId'),
    operation: jsonString(json, 'operation'),
    workerId: jsonString(json, 'workerId'),
    machineId: jsonString(json, 'machineId'),
    start: jsonInstant(json, 'start'),
    end: jsonInstant(json, 'end'),
    material: switch (jsonOptionalObject(json, 'material')) {
      null => null,
      final material => MaterialUseDto.fromJson(material),
    },
  );
}

final class SubmitReportDto {
  const SubmitReportDto({required this.processedAres, required this.fuelCentiliters, this.material});

  final int processedAres;
  final int fuelCentiliters;
  final MaterialUseDto? material;

  Map<String, Object?> toJson() => {
    'processedAres': processedAres,
    'fuelCentiliters': fuelCentiliters,
    if (material case final material?) 'material': material.toJson(),
  };

  factory SubmitReportDto.fromJson(Map<String, Object?> json) => SubmitReportDto(
    processedAres: jsonInt(json, 'processedAres'),
    fuelCentiliters: jsonInt(json, 'fuelCentiliters'),
    material: switch (jsonOptionalObject(json, 'material')) {
      null => null,
      final material => MaterialUseDto.fromJson(material),
    },
  );
}

final class ReasonDto {
  const ReasonDto({required this.reason});

  final String reason;

  Map<String, Object?> toJson() => {'reason': reason};

  factory ReasonDto.fromJson(Map<String, Object?> json) => ReasonDto(reason: jsonString(json, 'reason'));
}
