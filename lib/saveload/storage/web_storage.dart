import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:idb_shim/idb_browser.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/saveload/storage/game_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Web backend backed by a single IndexedDB database with one object store
/// holding one record per save, keyed by gameId.
class WebStorage implements GameStorage {
  static const String _dbName = 'lcs_new_age';
  static const String _storeName = 'saves';
  static const int _version = 1;

  Database? _db;

  Database get _database => _db!;

  @override
  Future<void> init() async {
    final idbFactory = getIdbFactory()!;
    _db = await idbFactory.open(_dbName, version: _version,
        onUpgradeNeeded: (event) {
      final Database db = event.database;
      if (!db.objectStoreNames.contains(_storeName)) {
        db.createObjectStore(_storeName);
      }
    });
  }

  @override
  Future<void> saveGame(SaveFile saveFile) async {
    final txn = _database.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.put(jsonEncode(saveFile.toJson()), saveFile.gameId);
    await txn.completed;
  }

  @override
  Future<SaveFile?> loadGame(String gameId) async {
    final txn = _database.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final dynamic data = await store.getObject(gameId);
    if (data == null) return null;

    try {
      return SaveFile.fromJson(
          jsonDecode(data as String) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('Error loading save game $gameId: $e');
      return null;
    }
  }

  @override
  Future<List<String>> listGameIds() async {
    final txn = _database.transaction(_storeName, idbModeReadOnly);
    final store = txn.objectStore(_storeName);
    final keys = await store.getAllKeys();
    return keys.map((k) => k.toString()).toList();
  }

  @override
  Future<void> deleteGame(String gameId) async {
    final txn = _database.transaction(_storeName, idbModeReadWrite);
    final store = txn.objectStore(_storeName);
    await store.delete(gameId);
    await txn.completed;
  }

  @override
  Future<void> close() async {
    _db?.close();
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
