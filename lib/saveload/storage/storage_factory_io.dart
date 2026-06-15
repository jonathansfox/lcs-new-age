import 'package:lcs_new_age/saveload/storage/game_storage.dart';
import 'package:lcs_new_age/saveload/storage/sembast_storage.dart';

/// Native (desktop/mobile) backend, backed by sembast over dart:io.
GameStorage createGameStorage() => SembastStorage();
