import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/i18n/i18n.dart';

void main() {
  group('LcsI18n Tests', () {
    setUp(() async {
      // Reset i18n state before each test
      LcsI18n.reset();
    });

    test('initialize with default locale', () async {
      await LcsI18n.initialize();
      expect(LcsI18n.isInitialized, isTrue);
      expect(LcsI18n.currentLocale, equals('en'));
    });

    test('initialize with custom locale', () async {
      await LcsI18n.initialize('es');
      expect(LcsI18n.currentLocale, equals('es'));
    });

    test('translate returns original text when not initialized', () {
      const message = 'Test message';
      final result = LcsI18n.translate(message);
      // In debug mode, untranslated strings get [!!] prefix
      expect(result, anyOf([equals(message), equals('[!!] $message')]));
    });

    test('translate returns original text when initialized', () async {
      await LcsI18n.initialize();
      const message = 'Test message';
      final result = LcsI18n.translate(message);
      expect(result, equals(message));
    });

    test('tr shorthand works', () async {
      await LcsI18n.initialize();
      const message = 'Test message';
      final result = LcsI18n.tr(message);
      expect(result, equals(message));
    });

    test('translateFormat with parameters', () async {
      await LcsI18n.initialize();
      const fmt = 'Hello {0}, you have {1} items';
      final result = LcsI18n.translateFormat(fmt, ['Alice', 5]);
      expect(result, equals('Hello Alice, you have 5 items'));
    });

    test('plural handling - zero', () async {
      await LcsI18n.initialize();
      final result = LcsI18n.plural(
        0,
        zero: 'no items',
        one: 'one item',
        other: 'many items',
      );
      expect(result, equals('no items'));
    });

    test('plural handling - one', () async {
      await LcsI18n.initialize();
      final result = LcsI18n.plural(
        1,
        zero: 'no items',
        one: 'one item',
        other: 'many items',
      );
      expect(result, equals('one item'));
    });

    test('plural handling - other', () async {
      await LcsI18n.initialize();
      final result = LcsI18n.plural(
        5,
        zero: 'no items',
        one: 'one item',
        other: 'many items',
      );
      expect(result, equals('many items'));
    });

    test('select handling', () async {
      await LcsI18n.initialize();
      final cases = {
        'male': 'He is ready',
        'female': 'She is ready',
        'other': 'They are ready',
      };

      expect(LcsI18n.select('male', cases), equals('He is ready'));
      expect(LcsI18n.select('female', cases), equals('She is ready'));
      expect(LcsI18n.select('unknown', cases), equals('They are ready'));
    });

    test('setLocale changes current locale', () async {
      await LcsI18n.initialize('en');
      expect(LcsI18n.currentLocale, equals('en'));

      await LcsI18n.setLocale('fr');
      expect(LcsI18n.currentLocale, equals('fr'));
    });

    test('availableLocales returns English initially', () {
      final locales = LcsI18n.availableLocales;
      expect(locales, contains('en'));
      expect(locales.length, equals(1));
    });

    test('hasTranslation returns false initially', () {
      expect(LcsI18n.hasTranslation('any message'), isFalse);
    });

    test('getMissingTranslations returns empty set initially', () {
      final missing = LcsI18n.getMissingTranslations();
      expect(missing, isEmpty);
    });
  });
}
