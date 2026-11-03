import 'package:equatable/equatable.dart';

import '../identifiers.dart';
import '../work_order/hectares.dart';

final class Parcel extends Equatable {
  const Parcel({required this.id, required this.name, required this.area});

  final ParcelId id;
  final String name;
  final Hectares area;

  @override
  List<Object?> get props => [id, name, area];
}
