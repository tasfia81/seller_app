import 'package:flutter_test/flutter_test.dart';
import 'package:seller_app/core/utils/bn_format.dart';
import 'package:seller_app/core/utils/validators.dart';

void main() {
  group('BnFormat', () {
    test('money uses Bangla digits and South Asian grouping', () {
      expect(BnFormat.money(124500), '৳১,২৪,৫০০');
      expect(BnFormat.money(450), '৳৪৫০');
      expect(BnFormat.qty(1.5), '১.৫');
    });

    test('NID is always masked', () {
      expect(BnFormat.maskNid('1234567894521'), '•••• •••• ৪৫২১');
    });

    test('phone formatting', () {
      expect(BnFormat.phone('01712345678'), '০১৭১২-৩৪৫৬৭৮');
    });
  });

  group('Validators', () {
    test('Bangladeshi mobile numbers', () {
      expect(Validators.mobile('01712345678'), isNull);
      expect(Validators.mobile('০১৭১২৩৪৫৬৭৮'), isNull);
      expect(Validators.mobile('+8801712345678'), isNull);
      expect(Validators.mobile('01212345678'), isNotNull);
      expect(Validators.mobile('0171234'), isNotNull);
    });

    test('date of birth: no future dates, minimum age', () {
      final now = DateTime(2026, 11, 21);
      expect(Validators.dateOfBirth(DateTime(2027, 1, 1), now: now), isNotNull);
      expect(Validators.dateOfBirth(DateTime(2010, 1, 1), now: now), isNotNull);
      expect(Validators.dateOfBirth(DateTime(2000, 1, 1), now: now), isNull);
    });

    test('password rules', () {
      expect(Validators.password('short1'), isNotNull);
      expect(Validators.password('longpassword'), isNotNull);
      expect(Validators.password('longpass12'), isNull);
      expect(Validators.confirm('a', 'b'), isNotNull);
    });
  });
}
