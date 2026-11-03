import 'package:equatable/equatable.dart';

import 'identifiers.dart';

enum Role { worker, owner }

final class User extends Equatable {
  const User({required this.id, required this.name, required this.role});

  final UserId id;
  final String name;
  final Role role;

  bool get isOwner => role == Role.owner;

  @override
  List<Object?> get props => [id, name, role];
}
