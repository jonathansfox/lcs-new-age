import 'package:flutter/services.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';

// The old guide to how the DAME maps work. DAME essentially doesn't exist
// anymore so this is left here for reference. We need a new method for
// editing custom maps moving forward.
//  - Jonathan S. Fox, 2024
//
//  -----------------------------------------------------------------------
//
//   Edit maps using DAME, the "Deadly Alien Map Editor". You can find a maps.dam file
// to open with DAME in the /dev directory. You can find DAME here (try search engine if link
// is out of date):
//   http://dambots.com/dame-editor/
//
//   Open up the maps.dam file in DAME. On one side, in the layers listing, you'll see the existing
// maps. Use the check boxes to hide and show maps. You can create new maps by copying the old ones;
// right click a top-level group (like NuclearPlant) and select Duplicate. Rename the new map based
// on the conventions described below.
//   Editing using the Paint tool ('B') is easy; click the tile you want in the tiles panel, then click
// the map view to paint with that tile. You may need to experiment a bit to figure out what the
// specials icons represent, but I've tried to make it pretty self-explanatory. Box-drawing to fill
// large areas is possible, but a little clunky -- use the Tile Matrix tool ('M') and fill the entire
// matrix with the tile you want to use by dragging tiles from the tiles panel. You can then box-drag
// to fill large areas.
//   When you're done editing, save maps.dam and use File.Export to create the map source files the
// game can run. In the Export Project dialog, use "csvTilemap.lua" for the LUA exporter. CSV dir should
// be "../art" and File Extension should be "csv". These are probably the defaults. Press "Export" and
// it will automagically build the map source files. You're done -- run the game and visit that
// location to view the results in-game. You don't even need to make a new game.
//   To remove a map from the game and go back to the old map generation modes, just delete the .csv
// files. You may also want to clean up the maps.dam file, removing any old maps you don't want, since
// it'll try to generate them again next time you export.
//
//   Map naming conventions:
// "mapCSV_[NAMEHERE]_Tiles.csv" - Tile map
// "mapCSV_[NAMEHERE]_Specials.csv" - Special locations (vault, equipment, lockup, etc.)
//   [NAMEHERE] is the name in quotes below, and it's what the maps are called in the DAME layer list.
// For example, for the industrial apartment, the DAME name is "ApartmentIndustrial", and the
// exported file name is "mapCSV_ApartmentIndustrial_Tiles.csv". DAME should add the prefix and suffix
// to the exported files automatically.
//
//   Additional Notes:
// 1. All maps MUST have both a tile map and a special map, even if the special map is blank. This
// goes for both first floor maps and otherwise.
// 2. For multi-floor maps, add up stairs to the special map, then create a new set of maps for
// each additional floor, appending "2" to the location name for the second floor, "3" for
// third floor, and so on. For example, a second floor to the industrial apartments would have the
// name "ApartmentIndustrial2" in DAME, and export as "mapCSV_ApartmentIndustrial2_Tiles.csv".
//
//  - Jonathan S. Fox

Future<bool> readDAMEMap(String filename) async {
  String prefix = "assets/maps/mapCSV_";

  // clear any old map data
  for (SiteTile tile in levelMap.all) {
    tile.flag = 0;
    tile.special = TileSpecial.none;
    tile.siegeflag = 0;
  }

  // Try first floor (eg "mapCSV_Bank_Tiles.csv"), abort this method if it doesn't exist
  if (!await readMapFile("$prefix${filename}_Tiles.csv", 0, readMapCBTiles)) {
    debugPrint("No DAME map file for Tiles found $prefix${filename}_Tiles.csv");
    return false;
  }
  if (!await readMapFile(
      "$prefix${filename}_Specials.csv", 0, readMapCBSpecials)) {
    debugPrint(
        "No DAME map file for Specials found $prefix${filename}_Specials.csv");
    return false;
  }

  // Try upper levels (eg "mapCSV_Bank2_Tiles.csv"), but don't sweat it if they don't exist
  for (int z = 1; z < MAPZ; z++) {
    String str = (z + 1).toString();
    if (!await readMapFile(
        "$prefix$filename${str}_Tiles.csv", z, readMapCBTiles)) {
      break;
    }
    if (!await readMapFile(
        "$prefix$filename${str}_Specials.csv", z, readMapCBSpecials)) {
      break;
    }
  }

  debugPrint("DAME map loaded for $filename");
  return true;
}

AssetManifest? _assetManifest;
Future<AssetManifest> get assetManifest async {
  _assetManifest ??= await AssetManifest.loadFromAssetBundle(rootBundle);
  return _assetManifest!;
}

Future<bool> readMapFile(String filename, int zLevel,
    void Function(int, int, int, int) callback) async {
  try {
    // open the file in question
    debugPrint("Loading map file $filename");
    List<String> assetKeys = (await assetManifest).listAssets();
    if (!assetKeys.contains(filename)) return false;
    String mapString = await rootBundle.loadString(filename);
    debugPrint("Map file $filename loaded");

    // abort if the file couldn't be opened
    List<String> lines = mapString.split("\n");
    for (int y = 0, z = zLevel; y < lines.length; y++) {
      String line = lines[y];
      line.trim();

      // split csv
      List<String> values = line.split(",");
      for (int x = 0; x < values.length; x++) {
        if (values[x].isEmpty) continue;

        // pass values to callback
        callback(x, y, z, int.parse(values[x]));
      }
    }
  } catch (e) {
    debugPrint(e.toString());
    return false;
  }
  return true;
}

void readMapCBSpecials(int x, int y, int z, int i) {
  levelMap[x][y][z].special = switch (i) {
    1 => TileSpecial.cagedRabbits,
    2 => TileSpecial.cagedMonsters,
    3 => TileSpecial.policeStationLockup,
    4 => TileSpecial.courthouseLockup,
    5 => TileSpecial.courthouseJuryRoom,
    6 => TileSpecial.prisonControl,
    7 => TileSpecial.prisonControlLow,
    8 => TileSpecial.prisonControlMedium,
    9 => TileSpecial.prisonControlHigh,
    10 => TileSpecial.intelSupercomputer,
    11 => TileSpecial.sweatshopEquipment,
    12 => TileSpecial.polluterEquipment,
    13 => TileSpecial.nuclearControlRoom,
    14 => TileSpecial.ceoSafe,
    15 => TileSpecial.ceoOffice,
    16 => TileSpecial.corporateFiles,
    17 => TileSpecial.radioBroadcastStudio,
    18 => TileSpecial.cableBroadcastStudio,
    19 => TileSpecial.apartmentLandlord,
    20 => TileSpecial.signOne,
    21 => TileSpecial.table,
    22 => TileSpecial.computer,
    23 => TileSpecial.parkBench,
    24 => TileSpecial.stairsUp,
    25 => TileSpecial.stairsDown,
    26 => TileSpecial.clubBouncer,
    27 => TileSpecial.clubBouncerSecondVisit,
    28 => TileSpecial.armory,
    29 => TileSpecial.displayCase,
    30 => TileSpecial.signTwo,
    31 => TileSpecial.signThree,
    32 => TileSpecial.securityCheckpoint,
    33 => TileSpecial.securityMetalDetectors,
    34 => TileSpecial.securitySecondVisit,
    35 => TileSpecial.bankVault,
    36 => TileSpecial.bankTeller,
    37 => TileSpecial.bankMoney,
    38 => TileSpecial.ccsBoss,
    39 => TileSpecial.ovalOfficeNW,
    40 => TileSpecial.ovalOfficeNE,
    41 => TileSpecial.ovalOfficeSW,
    42 => TileSpecial.ovalOfficeSE,
    _ => TileSpecial.none,
  };
}

void makeDoor(int x, int y, int z, {int flags = 0}) {
  final tile = levelMap[x][y][z];
  tile.flag = SITEBLOCK_DOOR | flags;
  tile.restricted = tile.neighbors().any((n) => n.restricted);
}

void readMapCBTiles(int x, int y, int z, int i) {
  switch (i) {
    case 2:
      levelMap[x][y][z].flag = SITEBLOCK_BLOCK;
    case 3:
      levelMap[x][y][z].flag = SITEBLOCK_EXIT;
    case 4:
      levelMap[x][y][z].flag = SITEBLOCK_GRASSY;
    case 5:
      makeDoor(x, y, z);
    case 6:
      makeDoor(x, y, z, flags: SITEBLOCK_LOCKED);
    case 7:
      levelMap[x][y][z].flag |= SITEBLOCK_RESTRICTED;
      if (x > 0 && (levelMap[x - 1][y][z].flag & SITEBLOCK_DOOR) > 0) {
        levelMap[x - 1][y][z].flag |= SITEBLOCK_RESTRICTED;
      }
      if (y > 0 && (levelMap[x][y - 1][z].flag & SITEBLOCK_DOOR) > 0) {
        levelMap[x][y - 1][z].flag |= SITEBLOCK_RESTRICTED;
      }
    case 8:
      levelMap[x][y][z].flag |= SITEBLOCK_CHAINLINK;
    case 9:
      makeDoor(x, y, z, flags: SITEBLOCK_LOCKED | SITEBLOCK_ALARMED);
    case 10:
      levelMap[x][y][z].flag = SITEBLOCK_BLOCK | SITEBLOCK_METAL;
    case 11:
      makeDoor(x, y, z, flags: SITEBLOCK_LOCKED | SITEBLOCK_METAL);
    default:
      levelMap[x][y][z].flag = 0;
  }
}
