import 'package:domain/domain.dart';
import 'package:test/test.dart';

void main() {
  group('Hectares', () {
    test('accepts a comma or a dot and keeps two decimals exactly', () {
      expect(Hectares.parse('12,5').valueOrNull?.hundredths, 1250);
      expect(Hectares.parse('0.1').valueOrNull?.hundredths, 10);
    });

    test('rejects zero, text and more than two decimals', () {
      for (final input in ['0', '', 'abc', '1.234', '-3']) {
        expect(Hectares.parse(input), const Failure<Hectares>(InvalidHectares()), reason: input);
      }
    });

    test('minus never goes below zero', () {
      final one = Hectares.parse('1').valueOrNull!;
      final two = Hectares.parse('2').valueOrNull!;
      expect(one.minus(two), Hectares.zero);
    });
  });

  group('FuelLiters', () {
    test('accepts values up to the maximum', () {
      expect(FuelLiters.parse('${FuelLiters.max}').isSuccess, isTrue);
    });

    test('rejects zero and values above the maximum', () {
      expect(FuelLiters.parse('0').errorOrNull, const InvalidFuelAmount());
      expect(FuelLiters.parse('${FuelLiters.max + 1}').errorOrNull, const InvalidFuelAmount());
    });
  });

  group('ReasonText', () {
    test('is required', () {
      expect(ReasonText.parse('   ').errorOrNull, const ReasonRequired());
    });

    test('counts characters, not code units', () {
      expect(ReasonText.parse('🌾' * ReasonText.maxLength).isSuccess, isTrue);
      expect(ReasonText.parse('🌾' * 201).errorOrNull, const ReasonTooLong(201));
    });
  });

  group('WorkInterval', () {
    final start = DateTime(2026, 11, 3, 8);

    test('must end after it starts', () {
      expect(WorkInterval.parse(start: start, end: start).errorOrNull, const InvalidInterval());
    });
  });
}
