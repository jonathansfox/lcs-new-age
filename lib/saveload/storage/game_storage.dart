import 'package:lcs_new_age/saveload/save_load.dart';

abstract class GameStorage {
  /// Initialize the storage system
  Future<void> init();

  /// Save a game file
  Future<void> saveGame(SaveFile saveFile);

  /// Load a game file by ID
  Future<SaveFile?> loadGame(String gameId);

  /// List all available game IDs
  Future<List<String>> listGameIds();

  /// Delete a game by ID
  Future<void> deleteGame(String gameId);

  /// Close any open connections/resources
  Future<void> close();

  /// Update the last played game ID
  Future<void> updateLastGameId(String gameId);
}
