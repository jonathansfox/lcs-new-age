import 'dart:async';
import 'package:intl/intl.dart';

/// Central translation interface for LCS New Age
///
/// Provides translation lookup, message formatting, and locale management.
/// Initially supports fallback to English, with full ARB-based translations
/// to be added in subsequent phases.
class LcsI18n {
  static bool _initialized = false;
  static String _currentLocale = 'en';

  /// Initialize the translation system with the specified locale
  /// Call this before starting the game loop
  static Future<void> initialize([String locale = 'en']) async {
    if (_initialized) return;

    _currentLocale = locale;
    Intl.defaultLocale = locale;

    // TODO: Load ARB files when available
    // await initializeMessages(locale);

    _initialized = true;
  }

  /// Get the current locale
  static String get currentLocale => _currentLocale;

  /// Check if the translation system is initialized
  static bool get isInitialized => _initialized;

  /// Translate a literal string with fallback to the original
  /// This is for simple messages with no interpolation
  static String translate(String message, {String? context}) {
    if (!_initialized) {
      return _addDebugPrefix(message);
    }

    try {
      // TODO: Replace with actual ARB lookup when available
      // return Intl.message(message, name: message, desc: context);
      return message;
    } catch (e) {
      // Fallback to original message if translation fails
      return message;
    }
  }

  /// Shorthand alias for translate() - matches common i18n conventions
  static String tr(String message, {String? context}) =>
      translate(message, context: context);

  /// Translate a format string with parameter substitution
  /// Use this when the game logic calls printf-style functions
  static String translateFormat(
    String fmt,
    List<Object> args, {
    String? context,
  }) {
    final translatedFmt = translate(fmt, context: context);
    return _applyFormat(translatedFmt, args);
  }

  /// Apply parameter substitution to a format string
  /// Simple placeholder replacement: {0}, {1}, etc.
  static String _applyFormat(String fmt, List<Object> args) {
    String result = fmt;
    for (int i = 0; i < args.length; i++) {
      result = result.replaceAll('{$i}', args[i].toString());
    }
    return result;
  }

  /// Plural handling using ICU format when available, fallback to simple logic
  static String plural(
    int count, {
    required String zero,
    required String one,
    required String other,
    String? context,
  }) {
    if (!_initialized) {
      return _addDebugPrefix(_selectPlural(count, zero, one, other));
    }

    try {
      // TODO: Replace with ICU plural when ARB files are available
      // return Intl.plural(count, zero: zero, one: one, other: other,
      //                    name: context ?? 'plural', args: [count]);
      return _selectPlural(count, zero, one, other);
    } catch (e) {
      return _selectPlural(count, zero, one, other);
    }
  }

  /// Simple plural selection logic as fallback
  static String _selectPlural(
    int count,
    String zero,
    String one,
    String other,
  ) {
    if (count == 0) return zero;
    if (count == 1) return one;
    return other;
  }

  /// Gender/selection handling using ICU format when available
  static String select(
    String value,
    Map<String, String> cases, {
    String? context,
  }) {
    if (!_initialized) {
      return _addDebugPrefix(cases[value] ?? cases['other'] ?? '');
    }

    try {
      // TODO: Replace with ICU select when ARB files are available
      // return Intl.select(value, cases, name: context ?? 'select');
      return cases[value] ?? cases['other'] ?? '';
    } catch (e) {
      return cases[value] ?? cases['other'] ?? '';
    }
  }

  /// Change the current locale at runtime
  static Future<void> setLocale(String locale) async {
    _currentLocale = locale;
    Intl.defaultLocale = locale;

    // TODO: Reload ARB files when available
    // await initializeMessages(locale);
  }

  /// Get list of available locales
  static List<String> get availableLocales => [
    'en',
  ]; // TODO: Expand when ARB files added

  /// Add debug prefix to untranslated strings during development
  static String _addDebugPrefix(String message) {
    // Only add prefix in debug mode or when explicitly testing
    bool debugMode = false;
    assert(debugMode = true);
    if (debugMode) {
      return "[!!] $message";
    }
    return message;
  }

  /// Check if a translation exists for the given message
  static bool hasTranslation(String message) {
    // TODO: Implement when ARB files are available
    return false; // Always false until translations are loaded
  }

  /// Get all missing translations (for debugging and coverage analysis)
  static Set<String> getMissingTranslations() {
    // TODO: Track missing translations during runtime
    return <String>{};
  }

  /// Clear translation cache and reset state
  static void reset() {
    _initialized = false;
    _currentLocale = 'en';
    // TODO: Clear any cached translations
  }
}
