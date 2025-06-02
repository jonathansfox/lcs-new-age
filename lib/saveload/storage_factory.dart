import 'package:flutter/foundation.dart';
import 'package:lcs_new_age/saveload/game_storage.dart';
import 'package:lcs_new_age/saveload/sembast_storage.dart';
import 'package:lcs_new_age/saveload/web_storage.dart';

class StorageFactory {
  static GameStorage createStorage() {
    if (kIsWeb) {
      return WebStorage();
    } else {
      return SembastStorage();
    }
  }
}
