import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../result.dart';

final class FuelLiters extends Equatable {
  const FuelLiters._(this.value);

  static const max = 2000;

  static final _format = RegExp(r'^\d{1,5}(?:[.,]\d{1,2})?$');

  final double value;

  static Result<FuelLiters> parse(String input) {
    final text = input.trim();
    if (!_format.hasMatch(text)) return const Failure(InvalidFuelAmount());
    final value = double.parse(text.replaceAll(',', '.'));
    if (value <= 0 || value > max) return const Failure(InvalidFuelAmount());
    return Success(FuelLiters._(value));
  }

  @override
  List<Object?> get props => [value];
}
