import 'dart:convert';
import 'package:idb_shim/idb_browser.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IndexedDBStorage {
  static const String _storeName = 'save';
  static const int _version = 1;

  late IdbFactory _idbFactory;
  final Map<String, Database> _openDatabases = {};

  Future<void> init() async {
    _idbFactory = getIdbFactory()!;
  }

  String _getDbName(String gameId) => 'lcs_new_age_$gameId';

  Future<Database> _getDatabase(String gameId) async {
    if (_openDatabases.containsKey(gameId)) {
      return _openDatabases[gameId]!;
    }

    final dbName = _getDbName(gameId);
    final db = await _idbFactory.open(dbName, version: _version,
        onUpgradeNeeded: (event) {
      Database db = event.database;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    });
    _openDatabases[gameId] = db;
    return db;
  }

  Future<void> _updateGameIdsList(String gameId, {bool add = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gameIds =
        prefs.getStringList('indexeddb_game_ids') ?? [];
    if (add && !gameIds.contains(gameId)) {
      gameIds.add(gameId);
      await prefs.setStringList('indexeddb_game_ids', gameIds);
    } else if (!add) {
      gameIds.remove(gameId);
      await prefs.setStringList('indexeddb_game_ids', gameIds);
    }
  }

  Future<void> saveGame(SaveFile saveFile) async {
    final db = await _getDatabase(saveFile.gameId);
    final transaction = db.transaction(_storeName, 'readwrite');
    final store = transaction.objectStore(_storeName);

    await store.put(jsonEncode(saveFile.toJson()), 'save');
    await transaction.completed;
    await _updateGameIdsList(saveFile.gameId, add: true);
  }

  Future<SaveFile?> loadGame(String gameId) async {
    final db = await _getDatabase(gameId);
    final transaction = db.transaction(_storeName, 'readonly');
    final store = transaction.objectStore(_storeName);

    final dynamic data = await store.getObject('save');
    if (data == null) return null;

    try {
      return SaveFile.fromJson(jsonDecode(data as String));
    } catch (e) {
      debugPrint('Error loading save game $gameId: $e');
      return null;
    }
  }

  Future<List<String>> listGameIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('indexeddb_game_ids') ?? [];
  }

  Future<void> deleteGame(String gameId) async {
    final db = await _getDatabase(gameId);
    db.close();
    _openDatabases.remove(gameId);
    await _idbFactory.deleteDatabase(_getDbName(gameId));
    await _updateGameIdsList(gameId, add: false);
  }

  void close() {
    for (final db in _openDatabases.values) {
      db.close();
    }
    _openDatabases.clear();
  }
}
