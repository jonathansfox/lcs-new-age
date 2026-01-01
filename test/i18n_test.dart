import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/i18n/i18n.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LcsI18n Tests - NCurses Style', () {
    setUp(() async {
      LcsI18n.reset();
    });

    test('initialize with default locale', () async {
      await LcsI18n.initialize();
      expect(LcsI18n.isInitialized, isTrue);
      expect(LcsI18n.currentLocale, equals('en_US'));
    });

    test('initialize with custom locale', () async {
      await LcsI18n.initialize('pt_BR');
      expect(LcsI18n.currentLocale, equals('pt_BR'));
    });

    test('translate simple strings in English', () async {
      await LcsI18n.initialize('en_US');

      expect(LcsI18n.translate('Loading...'), equals('Loading...'));
      expect(LcsI18n.translate('Game Over'), equals('Game Over'));
      expect(
        LcsI18n.translate('Press any key to continue.'),
        equals('Press any key to continue.'),
      );
    });

    test('translate simple strings in Portuguese', () async {
      await LcsI18n.initialize('pt_BR');

      expect(LcsI18n.translate('Loading...'), equals('Carregando...'));
      expect(LcsI18n.translate('Game Over'), equals('Fim de Jogo'));
      expect(
        LcsI18n.translate('Press any key to continue.'),
        equals('Pressione qualquer tecla para continuar.'),
      );
    });

    test('format strings with parameters in English', () async {
      await LcsI18n.initialize('en_US');

      expect(
        LcsI18n.format("{name}'s corpse has been recovered.", {'name': 'John'}),
        equals("John's corpse has been recovered."),
      );

      expect(
        LcsI18n.format('{name} has been rescued.', {'name': 'Jane'}),
        equals('Jane has been rescued.'),
      );

      expect(
        LcsI18n.format('You hit the {target}!', {'target': 'Conservative'}),
        equals('You hit the Conservative!'),
      );
    });

    test('format strings with parameters in Portuguese', () async {
      await LcsI18n.initialize('pt_BR');

      expect(
        LcsI18n.format("{name}'s corpse has been recovered.", {'name': 'João'}),
        equals('O cadáver de João foi recuperado.'),
      );

      expect(
        LcsI18n.format('{name} has been rescued.', {'name': 'Maria'}),
        equals('Maria foi resgatado.'),
      );

      expect(
        LcsI18n.format('You hit the {target}!', {'target': 'Conservador'}),
        equals('Você acertou o Conservador!'),
      );
    });

    test('plural handling - zero in English', () async {
      await LcsI18n.initialize('en_US');
      expect(
        LcsI18n.plural(0, context: 'inventory_items'),
        equals('You have no items.'),
      );
    });

    test('plural handling - one in English', () async {
      await LcsI18n.initialize('en_US');
      expect(
        LcsI18n.plural(1, context: 'inventory_items'),
        equals('You have one item.'),
      );
    });

    test('plural handling - other in English', () async {
      await LcsI18n.initialize('en_US');
      expect(
        LcsI18n.plural(5, context: 'inventory_items'),
        equals('You have 5 items.'),
      );
    });

    test('plural handling in Portuguese', () async {
      await LcsI18n.initialize('pt_BR');
      expect(
        LcsI18n.plural(0, context: 'inventory_items'),
        equals('Você não tem itens.'),
      );
      expect(
        LcsI18n.plural(1, context: 'inventory_items'),
        equals('Você tem um item.'),
      );
      expect(
        LcsI18n.plural(5, context: 'inventory_items'),
        equals('Você tem 5 itens.'),
      );
    });

    test('complex plural - members escape in English', () async {
      await LcsI18n.initialize('en_US');
      expect(LcsI18n.plural(0, context: 'members_escape'), equals(''));
      expect(
        LcsI18n.plural(1, context: 'members_escape'),
        equals('Another imprisoned LCS member also gets out!'),
      );
      expect(
        LcsI18n.plural(5, context: 'members_escape'),
        equals('5 other LCS members escape in the riot!'),
      );
    });

    test('complex plural - members escape in Portuguese', () async {
      await LcsI18n.initialize('pt_BR');
      expect(LcsI18n.plural(0, context: 'members_escape'), equals(''));
      expect(
        LcsI18n.plural(1, context: 'members_escape'),
        equals('Outro membro preso do LCS também escapa!'),
      );
      expect(
        LcsI18n.plural(5, context: 'members_escape'),
        equals('5 outros membros do LCS escapam no motim!'),
      );
    });

    test('shorthand tr() method works', () async {
      await LcsI18n.initialize('en_US');
      expect(LcsI18n.tr('Loading...'), equals('Loading...'));
    });

    test('fallback to English for missing translations', () async {
      await LcsI18n.initialize('pt_BR');
      const untranslated = 'This message does not exist';
      expect(LcsI18n.translate(untranslated), equals(untranslated));
    });

    test('locale switching works', () async {
      await LcsI18n.initialize('en_US');
      expect(LcsI18n.translate('Game Over'), equals('Game Over'));

      await LcsI18n.setLocale('pt_BR');
      expect(LcsI18n.translate('Game Over'), equals('Fim de Jogo'));

      await LcsI18n.setLocale('en_US');
      expect(LcsI18n.translate('Game Over'), equals('Game Over'));
    });

    test('missing translations are tracked', () async {
      await LcsI18n.initialize('en_US');
      const missing = 'This string is not translated';
      LcsI18n.translate(missing);
      expect(LcsI18n.getMissingTranslations(), contains(missing));
    });
  });
}
