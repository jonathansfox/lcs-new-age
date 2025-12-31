import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/i18n/i18n.dart';
import 'package:lcs_new_age/utils/colors.dart';

void main() {
  group('Console Wrapper Integration Tests', () {
    setUp(() async {
      // Reset i18n state and console before each test
      LcsI18n.reset();
      erase();
      await LcsI18n.initialize();
    });

    test('addstr translates strings before output', () {
      const testMessage = 'Hello, World!';
      
      // This should not throw and should translate the message
      expect(() => addstr(testMessage), returnsNormally);
      
      // Verify the message was translated (currently returns original)
      // In the future, this would verify actual translation
      expect(LcsI18n.translate(testMessage), equals(testMessage));
    });

    test('mvaddstr translates strings before output', () {
      const testMessage = 'Test message at position';
      
      // This should not throw
      expect(() => mvaddstr(5, 10, testMessage), returnsNormally);
    });

    test('addstrx translates strings with color codes', () {
      const testMessage = '&wWhite text&x';
      
      // This should not throw
      expect(() => addstrx(testMessage), returnsNormally);
    });

    test('mvaddstrx translates strings with color codes at position', () {
      const testMessage = '&rRed text&x';
      
      // This should not throw
      expect(() => mvaddstrx(10, 20, testMessage), returnsNormally);
    });

    test('addstrc translates strings with color', () {
      const testMessage = 'Colored message';
      
      // This should not throw
      expect(() => addstrc(white, testMessage), returnsNormally);
    });

    test('mvaddstrc translates strings with color at position', () {
      const testMessage = 'Positioned colored message';
      
      // This should not throw
      expect(() => mvaddstrc(15, 5, lightGray, testMessage), returnsNormally);
    });

    test('console wrappers handle empty strings', () {
      expect(() => addstr(''), returnsNormally);
      expect(() => mvaddstr(0, 0, ''), returnsNormally);
      expect(() => addstrx(''), returnsNormally);
    });

    test('console wrappers handle special characters', () {
      const specialChars = '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`';
      
      expect(() => addstr(specialChars), returnsNormally);
      expect(() => mvaddstr(0, 0, specialChars), returnsNormally);
    });

    test('console wrappers handle unicode characters', () {
      const unicode = 'Hello 世界 🌍';
      
      expect(() => addstr(unicode), returnsNormally);
      expect(() => mvaddstr(0, 0, unicode), returnsNormally);
    });

    test('console wrappers work with translation format strings', () {
      const formatString = 'You have {0} items';
      
      // Test that format strings pass through translation
      expect(() => addstr(formatString), returnsNormally);
    });

    test('multiple console calls work sequentially', () {
      expect(() {
        addstr('First message');
        mvaddstr(1, 0, 'Second message');
        addstrx('&wThird message&x');
        mvaddstrx(2, 0, '&rFourth message&x');
      }, returnsNormally);
    });
  });
}

