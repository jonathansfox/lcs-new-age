import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/i18n/i18n.dart';

String getConsoleLine(int y) {
  return console.buffer[y].map((ch) => ch.glyph).join();
}

void resetConsole() {
  erase();
  move(0, 0);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Console Wrapper Tests - Params Support', () {
    setUp(() async {
      await LcsI18n.initialize('en');
      resetConsole();
    });

    tearDown(() async {
      LcsI18n.reset();
    });

    test('addstr with params formats string', () {
      expect(() {
        addstr('You hit the {target}!', params: {'target': 'goblin'});
      }, returnsNormally);
    });

    test('addstr with count and context uses plural', () {
      expect(() {
        addstr(
          'You have {count} items.',
          params: {'count': 5, 'context': 'inventory_items'},
        );
      }, returnsNormally);
    });

    test('mvaddstr with params formats string', () {
      expect(() {
        mvaddstr(5, 10, '{name} has been rescued.', params: {'name': 'Jane'});
      }, returnsNormally);
    });

    test('mvaddstr with count and context uses plural', () {
      expect(() {
        mvaddstr(
          10,
          1,
          '{count} members escape.',
          params: {'count': 3, 'context': 'members_escape'},
        );
      }, returnsNormally);
    });

    test('addstr format actually translates correctly in English', () async {
      resetConsole();
      await LcsI18n.initialize('en');
      addstr('You hit the {target}!', params: {'target': 'goblin'});
      expect(getConsoleLine(0), equals('You hit the goblin!'));
    });

    test('addstr format actually translates correctly in Portuguese', () async {
      resetConsole();
      await LcsI18n.initialize('pt');
      addstr('You hit the {target}!', params: {'target': 'goblin'});
      expect(getConsoleLine(0), equals('Você acertou o goblin!'));
    });
  });
}
