import 'package:domain/domain.dart';

T valid<T>(Result<T> result, Object? source) => switch (result) {
  Success(:final value) => value,
  Failure(:final error) => throw FormatException('The domain rejects this value: $error', source),
};

String decimal(int hundredths) => '${hundredths ~/ 100}.${(hundredths % 100).toString().padLeft(2, '0')}';
