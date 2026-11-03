import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../result.dart';

final class Hectares extends Equatable {
  const Hectares._(this.hundredths);

  static const zero = Hectares._(0);

  static final _format = RegExp(r'^(\d{1,5})(?:[.,](\d{1,2}))?$');

  final int hundredths;

  double get value => hundredths / 100;

  bool get isZero => hundredths == 0;

  static Result<Hectares> parse(String input) {
    final match = _format.firstMatch(input.trim());
    if (match == null) return const Failure(InvalidHectares());
    final whole = int.parse(match.group(1)!);
    final fraction = int.parse((match.group(2) ?? '').padRight(2, '0'));
    final hundredths = whole * 100 + fraction;
    if (hundredths == 0) return const Failure(InvalidHectares());
    return Success(Hectares._(hundredths));
  }

  Hectares operator +(Hectares other) => Hectares._(hundredths + other.hundredths);

  Hectares minus(Hectares other) => Hectares._(hundredths > other.hundredths ? hundredths - other.hundredths : 0);

  bool operator >(Hectares other) => hundredths > other.hundredths;

  @override
  List<Object?> get props => [hundredths];
}
