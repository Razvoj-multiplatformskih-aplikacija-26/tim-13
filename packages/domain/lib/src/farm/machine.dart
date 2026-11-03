import 'package:equatable/equatable.dart';

import '../identifiers.dart';

final class Machine extends Equatable {
  const Machine({required this.id, required this.name});

  final MachineId id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}
