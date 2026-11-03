import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../result.dart';

final class WorkInterval extends Equatable {
  const WorkInterval._(this.start, this.end);

  final DateTime start;
  final DateTime end;

  static Result<WorkInterval> parse({required DateTime start, required DateTime end}) {
    if (!end.isAfter(start)) return const Failure(InvalidInterval());
    return Success(WorkInterval._(start, end));
  }

  bool overlaps(WorkInterval other) => start.isBefore(other.end) && other.start.isBefore(end);

  @override
  List<Object?> get props => [start, end];
}
