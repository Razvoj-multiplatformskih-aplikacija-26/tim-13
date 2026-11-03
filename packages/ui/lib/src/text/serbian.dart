import 'package:domain/domain.dart';

const serbianLatinLanguage = 'sr';
const serbianLatinScript = 'Latn';

extension RoleLabel on Role {
  String get label => switch (this) {
    Role.worker => 'Radnik',
    Role.owner => 'Gazda',
  };
}

extension WorkOrderStageLabel on WorkOrderStage {
  String get label => switch (this) {
    WorkOrderStage.planned => 'Planiran',
    WorkOrderStage.inProgress => 'U toku',
    WorkOrderStage.awaitingConfirmation => 'Čeka potvrdu',
    WorkOrderStage.completed => 'Završen',
    WorkOrderStage.rejected => 'Odbijen',
    WorkOrderStage.cancelled => 'Otkazan',
  };
}

extension AgroOperationLabel on AgroOperation {
  String get label => switch (this) {
    AgroOperation.plowing => 'Oranje',
    AgroOperation.fertilizing => 'Đubrenje',
    AgroOperation.seedbedPreparation => 'Setvospremanje',
    AgroOperation.sowing => 'Sejanje',
    AgroOperation.spraying => 'Prskanje',
    AgroOperation.harvesting => 'Vršaj',
  };
}

extension StockUnitLabel on StockUnit {
  String get label => switch (this) {
    StockUnit.kilogram => 'kg',
    StockUnit.liter => 'l',
  };
}

String _twoDigits(int value) => value.toString().padLeft(2, '0');

String formatDate(DateTime value) => '${value.day}. ${value.month}. ${value.year}.';

String formatTime(DateTime value) => '${_twoDigits(value.hour)}:${_twoDigits(value.minute)}';

String formatInterval(WorkInterval interval) =>
    '${formatDate(interval.start)} ${formatTime(interval.start)}–${formatTime(interval.end)}';

String formatDecimal(double value) {
  final text = value.toStringAsFixed(2).replaceAll('.', ',');
  return text.replaceFirst(RegExp(r',?0+$'), '');
}

String formatHectares(Hectares value) => '${formatDecimal(value.value)} ha';

String formatLiters(FuelLiters value) => '${formatDecimal(value.value)} l';
