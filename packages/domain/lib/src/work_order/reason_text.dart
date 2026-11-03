import 'package:characters/characters.dart';
import 'package:equatable/equatable.dart';

import '../errors.dart';
import '../result.dart';

final class ReasonText extends Equatable {
  const ReasonText._(this.text);

  static const maxLength = 200;

  final String text;

  static Result<ReasonText> parse(String input) {
    final text = input.trim();
    final length = text.characters.length;
    if (length == 0) return const Failure(ReasonRequired());
    if (length > maxLength) return Failure(ReasonTooLong(length));
    return Success(ReasonText._(text));
  }

  @override
  List<Object?> get props => [text];
}
