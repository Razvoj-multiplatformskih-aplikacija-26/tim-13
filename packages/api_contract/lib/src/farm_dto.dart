import 'json.dart';

final class UserDto {
  const UserDto({required this.id, required this.name, required this.role});

  static const worker = 'worker';
  static const owner = 'owner';

  final String id;
  final String name;
  final String role;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'role': role};

  factory UserDto.fromJson(Map<String, Object?> json) =>
      UserDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'), role: jsonString(json, 'role'));
}

final class ParcelDto {
  const ParcelDto({required this.id, required this.name, required this.areaAres});

  final String id;
  final String name;
  final int areaAres;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'areaAres': areaAres};

  factory ParcelDto.fromJson(Map<String, Object?> json) =>
      ParcelDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'), areaAres: jsonInt(json, 'areaAres'));
}

final class MachineDto {
  const MachineDto({required this.id, required this.name});

  final String id;
  final String name;

  Map<String, Object?> toJson() => {'id': id, 'name': name};

  factory MachineDto.fromJson(Map<String, Object?> json) =>
      MachineDto(id: jsonString(json, 'id'), name: jsonString(json, 'name'));
}

final class StockItemDto {
  const StockItemDto({
    required this.id,
    required this.name,
    required this.kind,
    required this.unit,
    required this.available,
  });

  static const fertilizer = 'fertilizer';
  static const chemical = 'chemical';

  static const kilogram = 'kilogram';
  static const liter = 'liter';

  final String id;
  final String name;
  final String kind;
  final String unit;
  final int available;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'kind': kind, 'unit': unit, 'available': available};

  factory StockItemDto.fromJson(Map<String, Object?> json) => StockItemDto(
    id: jsonString(json, 'id'),
    name: jsonString(json, 'name'),
    kind: jsonString(json, 'kind'),
    unit: jsonString(json, 'unit'),
    available: jsonInt(json, 'available'),
  );
}
