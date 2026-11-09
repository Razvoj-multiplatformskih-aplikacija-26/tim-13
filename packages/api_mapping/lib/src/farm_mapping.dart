import 'package:api_contract/api_contract.dart';
import 'package:domain/domain.dart';

import 'parsing.dart';

extension HectaresMapping on Hectares {
  int toAres() => hundredths;
}

Result<Hectares> hectaresFromAres(int ares) =>
    ares < 0 ? const Failure(InvalidHectares()) : Hectares.parse(decimal(ares));

extension FuelLitersMapping on FuelLiters {
  int toCentiliters() => (value * 100).round();
}

Result<FuelLiters> fuelFromCentiliters(int centiliters) =>
    centiliters < 0 ? const Failure(InvalidFuelAmount()) : FuelLiters.parse(decimal(centiliters));

extension RoleMapping on Role {
  String toDto() => switch (this) {
    Role.worker => UserDto.worker,
    Role.owner => UserDto.owner,
  };
}

Role roleFromDto(String role) => switch (role) {
  UserDto.worker => Role.worker,
  UserDto.owner => Role.owner,
  _ => throw FormatException('Unknown role', role),
};

extension UserMapping on User {
  UserDto toDto() => UserDto(id: id.value, name: name, role: role.toDto());
}

extension UserDtoMapping on UserDto {
  User toDomain() => User(id: UserId(id), name: name, role: roleFromDto(role));
}

extension AgroOperationMapping on AgroOperation {
  String toDto() => switch (this) {
    AgroOperation.plowing => OperationCodes.plowing,
    AgroOperation.fertilizing => OperationCodes.fertilizing,
    AgroOperation.seedbedPreparation => OperationCodes.seedbedPreparation,
    AgroOperation.sowing => OperationCodes.sowing,
    AgroOperation.spraying => OperationCodes.spraying,
    AgroOperation.harvesting => OperationCodes.harvesting,
  };
}

AgroOperation operationFromDto(String operation) => switch (operation) {
  OperationCodes.plowing => AgroOperation.plowing,
  OperationCodes.fertilizing => AgroOperation.fertilizing,
  OperationCodes.seedbedPreparation => AgroOperation.seedbedPreparation,
  OperationCodes.sowing => AgroOperation.sowing,
  OperationCodes.spraying => AgroOperation.spraying,
  OperationCodes.harvesting => AgroOperation.harvesting,
  _ => throw FormatException('Unknown operation', operation),
};

extension ParcelMapping on Parcel {
  ParcelDto toDto() => ParcelDto(id: id.value, name: name, areaAres: area.toAres());
}

extension ParcelDtoMapping on ParcelDto {
  Parcel toDomain() => Parcel(id: ParcelId(id), name: name, area: valid(hectaresFromAres(areaAres), areaAres));
}

extension MachineMapping on Machine {
  MachineDto toDto() => MachineDto(id: id.value, name: name);
}

extension MachineDtoMapping on MachineDto {
  Machine toDomain() => Machine(id: MachineId(id), name: name);
}

extension StockItemMapping on StockItem {
  StockItemDto toDto() => StockItemDto(
    id: id.value,
    name: name,
    kind: switch (kind) {
      StockKind.fertilizer => StockItemDto.fertilizer,
      StockKind.chemical => StockItemDto.chemical,
    },
    unit: switch (unit) {
      StockUnit.kilogram => StockItemDto.kilogram,
      StockUnit.liter => StockItemDto.liter,
    },
    available: available,
  );
}

extension StockItemDtoMapping on StockItemDto {
  StockItem toDomain() => StockItem(
    id: StockItemId(id),
    name: name,
    kind: switch (kind) {
      StockItemDto.fertilizer => StockKind.fertilizer,
      StockItemDto.chemical => StockKind.chemical,
      _ => throw FormatException('Unknown stock kind', kind),
    },
    unit: switch (unit) {
      StockItemDto.kilogram => StockUnit.kilogram,
      StockItemDto.liter => StockUnit.liter,
      _ => throw FormatException('Unknown stock unit', unit),
    },
    available: available,
  );
}
