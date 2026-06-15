import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:lcs_new_age/saveload/storage/game_storage.dart';
import 'package:lcs_new_age/saveload/storage/save_load.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Native backend backed by a single sembast database with one store holding
/// one record per save, keyed by gameId.
class SembastStorage implements GameStorage {
  static const String _dbName = 'lcs_new_age.db';
  static const String _storeName = 'saves';
  static const int _version = 1;

  Database? _db;
  final _store = stringMapStoreFactory.store(_storeName);

  Database get _database => _db!;

  @override
  Future<void> init() async {
    final appDataDir = await _getAppDataDirectory();
    final dbPath = join(appDataDir.path, _dbName);
    _db = await databaseFactoryIo.openDatabase(dbPath, version: _version);
  }

  Future<Directory> _getAppDataDirectory() async {
    final appData = Platform.environment['APPDATA'];
    if (Platform.isWindows && appData != null) {
      final appDir = Directory(join(appData, 'LCS New Age', 'lcs_new_age'));
      if (!appDir.existsSync()) {
        await appDir.create(recursive: true);
      }
      return appDir;
    } else {
      // Fallback to documents directory for non-Windows platforms (and for
      // Windows if APPDATA is somehow unset, rather than crashing).
      return await getApplicationDocumentsDirectory();
    }
  }

  @override
  Future<void> saveGame(SaveFile saveFile) async {
    await _store.record(saveFile.gameId).put(_database, {
      'data': jsonEncode(saveFile.toJson()),
      'lastPlayed': saveFile.lastPlayed?.toIso8601String(),
    });
  }

  @override
  Future<SaveFile?> loadGame(String gameId) async {
    final record = await _store.record(gameId).get(_database);
    if (record == null) return null;

    try {
      final data = jsonDecode(record['data']! as String);
      return SaveFile.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error loading save game $gameId: $e');
      return null;
    }
  }

  @override
  Future<List<String>> listGameIds() async {
    return _store.findKeys(_database);
  }

  @override
  Future<void> deleteGame(String gameId) async {
    await _store.record(gameId).delete(_database);
  }

  @override
  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  @override
  Future<void> updateLastGameId(String gameId) async {
    final int? id = int.tryParse(gameId);
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('lastGameId', id);
  }
}
