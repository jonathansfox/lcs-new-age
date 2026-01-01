import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Central translation interface for LCS New Age
///
/// NCurses-style API: Use English strings directly in code.
/// Translations are looked up at runtime from ARB files.
///
/// Example:
///   addstr("Press any key to continue.");  // Translates automatically
///   addstr(LcsI18n.format("You hit the {target}!", {"target": "goblin"}));
class LcsI18n {
  static bool _initialized = false;
  static String _currentLocale = 'en';
  static final Map<String, Map<String, dynamic>> _translations = {};
  static final Set<String> _missingTranslations = <String>{};

  /// Initialize the translation system with the specified locale
  static Future<void> initialize([String locale = 'en']) async {
    if (_initialized) return;

    _currentLocale = locale;
    Intl.defaultLocale = locale;
    await _loadLocale(locale);

    // Preload English as fallback
    if (locale != 'en') {
      await _loadLocale('en');
    }

    _initialized = true;
  }

  /// Load ARB file for the specified locale
  static Future<void> _loadLocale(String locale) async {
    try {
      final String jsonString = await rootBundle.loadString(
        'lib/l10n/app_$locale.arb',
      );
      final Map<String, dynamic> jsonData =
          json.decode(jsonString) as Map<String, dynamic>;
      _translations[locale] = jsonData;
    } catch (e) {
      // print('LcsI18n: Failed to load locale "$locale": $e');
    }
  }

  /// Get the current locale
  static String get currentLocale => _currentLocale;

  /// Check if initialized
  static bool get isInitialized => _initialized;

  /// Translate a literal English string
  ///
  /// NCurses-style usage via console wrappers:
  ///   addstr("Press any key to continue.");
  ///   mvaddstr(10, 5, "Game Over");
  static String translate(String englishText, {String? context}) {
    if (!_initialized) {
      return englishText;
    }

    try {
      final localeData = _translations[_currentLocale];
      if (localeData != null && localeData.containsKey(englishText)) {
        return localeData[englishText] as String;
      }

      // Fallback to English
      if (_currentLocale != 'en') {
        final enData = _translations['en'];
        if (enData != null && enData.containsKey(englishText)) {
          return enData[englishText] as String;
        }
      }

      // Track missing translations
      if (!englishText.startsWith('@@')) {
        _missingTranslations.add(englishText);
      }
      return englishText;
    } catch (e) {
      // print('LcsI18n: Translation error for "$englishText": $e');
      return englishText;
    }
  }

  /// Shorthand alias
  static String tr(String englishText, {String? context}) =>
      translate(englishText, context: context);

  /// Format a string with named parameters
  ///
  /// This is called internally by console wrappers when params are provided.
  /// Direct usage:
  ///   addstr("You hit the {target}!", params: {"target": "goblin"});
  ///   addstr("{name} has been rescued.", params: {"name": "John"});
  static String format(String englishTemplate, Map<String, dynamic> params) {
    String translated = translate(englishTemplate);

    // Replace {param} with values
    params.forEach((key, value) {
      translated = translated.replaceAll('{$key}', value.toString());
    });

    return translated;
  }

  /// Handle plural forms using ICU pluralization
  ///
  /// This is called internally by console wrappers when they detect a count parameter.
  /// Direct usage:
  ///   addstr("You have {count} items.", params: {"count": itemCount, "context": "inventory_items"});
  static String plural(int count, {required String context}) {
    if (!_initialized) {
      return _defaultPlural(count, context);
    }

    try {
      final localeData = _translations[_currentLocale];
      if (localeData != null && localeData.containsKey('@@plurals')) {
        final plurals = localeData['@@plurals'] as Map<String, dynamic>?;
        if (plurals != null && plurals.containsKey(context)) {
          final pluralData = plurals[context] as Map<String, dynamic>;

          return Intl.plural(
            count,
            zero: (pluralData['zero'] as String? ?? '').replaceAll(
              '{count}',
              count.toString(),
            ),
            one: (pluralData['one'] as String? ?? '').replaceAll(
              '{count}',
              count.toString(),
            ),
            other: (pluralData['other'] as String? ?? '').replaceAll(
              '{count}',
              count.toString(),
            ),
            locale: _currentLocale,
          );
        }
      }

      // Fallback to English plurals
      if (_currentLocale != 'en') {
        final enData = _translations['en'];
        if (enData != null && enData.containsKey('@@plurals')) {
          final plurals = enData['@@plurals'] as Map<String, dynamic>?;
          if (plurals != null && plurals.containsKey(context)) {
            final pluralData = plurals[context] as Map<String, dynamic>;

            return Intl.plural(
              count,
              zero: (pluralData['zero'] as String? ?? '').replaceAll(
                '{count}',
                count.toString(),
              ),
              one: (pluralData['one'] as String? ?? '').replaceAll(
                '{count}',
                count.toString(),
              ),
              other: (pluralData['other'] as String? ?? '').replaceAll(
                '{count}',
                count.toString(),
              ),
              locale: 'en',
            );
          }
        }
      }

      return _defaultPlural(count, context);
    } catch (e) {
      // print('LcsI18n: Plural error for count $count, context "$context": $e');
      return _defaultPlural(count, context);
    }
  }

  static String _defaultPlural(int count, String context) {
    if (count == 0) return '';
    if (count == 1) return 'one $context';
    return '$count $context';
  }

  /// Change the current locale at runtime
  static Future<void> setLocale(String locale) async {
    _currentLocale = locale;
    Intl.defaultLocale = locale;

    if (!_translations.containsKey(locale)) {
      await _loadLocale(locale);
    }
  }

  /// Get missing translations (for debugging)
  static Set<String> getMissingTranslations() {
    return Set<String>.from(_missingTranslations);
  }

  /// Reset state (for testing)
  static void reset() {
    _initialized = false;
    _currentLocale = 'en';
    _translations.clear();
    _missingTranslations.clear();
  }
}
