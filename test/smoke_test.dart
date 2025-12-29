import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/i18n/i18n.dart';
import 'package:lcs_new_age/main.dart' as app;

void main() {
  group('Smoke Tests', () {
    test('i18n initializes without errors', () async {
      expect(() async => await LcsI18n.initialize(), returnsNormally);
      expect(LcsI18n.isInitialized, isTrue);
    });

    test('app can be created without crashing', () {
      // Test that the main app can be instantiated
      expect(app.MainApp.new, returnsNormally);
    });

    test('console wrapper functions work', () {
      // Test that our console wrapper functions don't crash
      expect(() async {
        await LcsI18n.initialize();

        // These should not throw exceptions
        LcsI18n.translate('Test message');
        LcsI18n.translateFormat('Hello {0}', ['World']);
        LcsI18n.plural(1, zero: 'none', one: 'one', other: 'many');
        LcsI18n.select('male', {'male': 'he', 'female': 'she'});
      }, returnsNormally);
    });

    test('basic translation pipeline works end-to-end', () async {
      await LcsI18n.initialize();

      // Test the full pipeline: translate -> format -> result
      const template = 'You hit the {0}!';
      const target = 'goblin';
      final result = LcsI18n.translateFormat(template, [target]);

      expect(result, equals('You hit the goblin!'));
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });
}
