import 'package:shared_preferences/shared_preferences.dart';

class GameOptions {
  static const String _encounterWarningsKey = 'encounterWarnings';
  static const String _mouseInputKey = 'mouseInput';
  static const String _interfacePgUpKey = 'interfacePgUp';
  static const String _languageKey = 'language';
  bool encounterWarnings = false;
  bool mouseInput = true;
  String interfacePgUp = "[";
  String language = 'en';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    encounterWarnings = prefs.getBool(_encounterWarningsKey) ?? false;
    mouseInput = prefs.getBool(_mouseInputKey) ?? true;
    interfacePgUp = prefs.getString(_interfacePgUpKey) ?? "[";
    language = prefs.getString(_languageKey) ?? 'en';
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_encounterWarningsKey, encounterWarnings);
    await prefs.setBool(_mouseInputKey, mouseInput);
    await prefs.setString(_interfacePgUpKey, interfacePgUp);
    await prefs.setString(_languageKey, language);
  }
}

final gameOptions = GameOptions();
