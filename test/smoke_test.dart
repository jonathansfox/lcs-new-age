import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/i18n/i18n.dart';
import 'package:lcs_new_age/main.dart' as app;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Smoke Tests', () {
    test('i18n initializes without errors', () async {
      await LcsI18n.initialize();
      expect(LcsI18n.isInitialized, isTrue);
    });

    test('app can be created without crashing', () {
      expect(app.MainApp.new, returnsNormally);
    });

    test('NCurses-style translations work', () async {
      await LcsI18n.initialize();

      // Test that we can use plain English strings
      expect(() => LcsI18n.translate('Loading...'), returnsNormally);
      expect(() => LcsI18n.translate('Game Over'), returnsNormally);
      expect(
        () => LcsI18n.format('You hit the {target}!', {'target': 'goblin'}),
        returnsNormally,
      );
      expect(
        () => LcsI18n.plural(5, context: 'inventory_items'),
        returnsNormally,
      );
    });

    test('basic translation pipeline works end-to-end', () async {
      await LcsI18n.initialize();

      // Test NCurses-style: plain English in code
      final result = LcsI18n.format('You hit the {target}!', {
        'target': 'goblin',
      });

      expect(result, equals('You hit the goblin!'));
      expect(result, isA<String>());
      expect(result, isNotEmpty);
    });
  });
}
