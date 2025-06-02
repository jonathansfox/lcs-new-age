import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lcs_new_age/saveload/game_storage.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SembastStorage implements GameStorage {
  static const String _storeName = 'save';
  static const int _version = 1;

  final Map<String, Database> _openDatabases = {};

  @override
  Future<void> init() async {
    // No initialization needed as we'll open databases on demand
  }

  Future<Directory> _getAppDataDirectory() async {
    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA']!;
      final appDir = Directory(join(appData, 'LCS New Age', 'lcs_new_age'));
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } else {
      // Fallback to documents directory for non-Windows platforms
      return await getApplicationDocumentsDirectory();
    }
  }

  String _getDbName(String gameId) => 'lcs_new_age_$gameId.db';

  Future<Database> _getDatabase(String gameId) async {
    if (_openDatabases.containsKey(gameId)) {
      return _openDatabases[gameId]!;
    }

    final appDataDir = await _getAppDataDirectory();
    final dbPath = join(appDataDir.path, _getDbName(gameId));
    final db = await databaseFactoryIo.openDatabase(
      dbPath,
      version: _version,
      onVersionChanged: (db, oldVersion, newVersion) async {
        if (oldVersion < 1) {
          final store = stringMapStoreFactory.store(_storeName);
          if (!(await store.count(db) >= 0)) {
            // Store doesn't exist yet, create it
            await store.add(db, {});
          }
        }
      },
    );
    _openDatabases[gameId] = db;
    return db;
  }

  @override
  Future<void> saveGame(SaveFile saveFile) async {
    final db = await _getDatabase(saveFile.gameId);
    final store = stringMapStoreFactory.store(_storeName);

    await store.record('save').put(db, {
      'data': jsonEncode(saveFile.toJson()),
      'lastPlayed': saveFile.lastPlayed?.toIso8601String(),
    });
    await _updateGameIdsList(saveFile.gameId, add: true);
    await updateLastGameId(saveFile.gameId);
  }

  @override
  Future<SaveFile?> loadGame(String gameId) async {
    final db = await _getDatabase(gameId);
    final store = stringMapStoreFactory.store(_storeName);

    final record = await store.record('save').get(db);
    if (record == null) return null;

    try {
      final data = jsonDecode(record['data']! as String);

      return SaveFile.fromJson(data);
    } catch (e) {
      debugPrint('Error loading save game $gameId: $e');
      return null;
    }
  }

  @override
  Future<List<String>> listGameIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('sembast_game_ids') ?? [];
  }

  @override
  Future<void> deleteGame(String gameId) async {
    final db = await _getDatabase(gameId);
    await db.close();
    _openDatabases.remove(gameId);

    // Delete the database file
    final appDataDir = await _getAppDataDirectory();
    final dbPath = join(appDataDir.path, _getDbName(gameId));
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      await dbFile.delete();
    }

    await _updateGameIdsList(gameId, add: false);
  }

  @override
  Future<void> close() async {
    for (final db in _openDatabases.values) {
      await db.close();
    }
    _openDatabases.clear();
  }

  @override
  Future<void> updateLastGameId(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastGameId', int.parse(gameId));
  }

  Future<void> _updateGameIdsList(String gameId, {bool add = true}) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> gameIds = prefs.getStringList('sembast_game_ids') ?? [];
    if (add && !gameIds.contains(gameId)) {
      gameIds.add(gameId);
      await prefs.setStringList('sembast_game_ids', gameIds);
    } else if (!add) {
      gameIds.remove(gameId);
      await prefs.setStringList('sembast_game_ids', gameIds);
    }
  }
}
