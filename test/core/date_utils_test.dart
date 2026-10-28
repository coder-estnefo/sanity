import 'package:flutter_test/flutter_test.dart';
import 'package:sanity/core/utils/date_utils.dart';

void main() {
  group('daysFree', () {
    test('same day is 0', () {
      expect(daysFree(DateTime(2026, 5, 1, 23), DateTime(2026, 5, 1, 1)), 0);
    });

    test('counts calendar days regardless of time of day', () {
      expect(daysFree(DateTime(2026, 5, 1, 23, 59), DateTime(2026, 5, 2, 0, 1)), 1);
      expect(daysFree(DateTime(2026, 1, 1), DateTime(2026, 1, 31, 23, 59)), 30);
    });

    test('is DST-safe', () {
      // Spans typical DST changes in March / October.
      expect(daysFree(DateTime(2026, 3, 1), DateTime(2026, 4, 1)), 31);
      expect(daysFree(DateTime(2026, 10, 1), DateTime(2026, 11, 1)), 31);
    });

    test('future quit date yields 0', () {
      expect(daysFree(DateTime(2027), DateTime(2026)), 0);
    });

    test('leap year', () {
      expect(daysFree(DateTime(2028, 2, 28), DateTime(2028, 3, 1)), 2);
    });
  });
}

