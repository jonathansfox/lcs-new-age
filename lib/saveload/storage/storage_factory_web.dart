import 'package:lcs_new_age/saveload/storage/game_storage.dart';
import 'package:lcs_new_age/saveload/storage/web_storage.dart';

GameStorage createGameStorage() => WebStorage();
