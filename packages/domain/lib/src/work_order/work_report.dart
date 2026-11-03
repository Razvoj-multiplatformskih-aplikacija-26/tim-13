import 'package:equatable/equatable.dart';

import 'fuel_liters.dart';
import 'hectares.dart';
import 'material_use.dart';

final class WorkReport extends Equatable {
  const WorkReport({required this.processed, required this.fuel, required this.submittedAt, this.material});

  final Hectares processed;
  final FuelLiters fuel;
  final DateTime submittedAt;
  final MaterialUse? material;

  @override
  List<Object?> get props => [processed, fuel, submittedAt, material];
}
