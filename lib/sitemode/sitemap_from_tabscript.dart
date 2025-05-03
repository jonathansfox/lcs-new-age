// ignore_for_file: constant_identifier_names

import 'package:flutter/services.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

// This comment is included for posterity, but tabscript approach is extremely
// outdated (from 2009) and the roadmap it gives will not be pursued.
//  - Jonathan S. Fox, 2024
//
// ---------------------------------------------------------------------
//
// OBJECTIVE: SUPPORT TAB-SEPARATED CONFIGURATION FILES
//   TO MAKE LCS CONTENT HIGHLY MODDABLE AND DATA-DRIVEN,
//   INCLUDING EQUIPMENT, LOCATIONS, MAPS, CREATURES,
//   AND ANY ADDITIONAL SYSTEMS THAT WOULD BENEFIT FROM
//   THIS APPROACH
//
// CONFIG FILE FORMAT
//
// (newline) (leading whitespace) COMMAND (delimiting whitespace) VALUE
//
// Initial tests for the tab-separated configuration files
// will be a full-scale implementation of sitemap creation
// using the sitemaps.txt config file. From there, support
// can be extended to additional systems.
//
// Sitemaps Short-Term Roadmap (Feb 12, 2009):
// [x] convert names of tiles, scripts, specials, uniques, and
//     loots to game data in their respective configSite___ objects
// [x] sitemap construction logic, to build the actual map in
//     the game when player visits a site, in various configSite___
//     objects (this is a new method, say, build() for example),
//     with the exception of the configSiteLoot, which will remain
//     no-op until later (the data structure and logic of loot
//     handling will need to be revised to support dynamic loot)
// [x] move definitions to headers files, include correct headers,
//     etc. (sitemap stuff should probably go in its own file,
//     perhaps where the existing map building logic is now)
// [x] global sitemaps vector containing configSiteMap objects
// [x] global build_site(string) function that calls .build() on
//     the sitemap with the specified name
// [x] add all additional defines and enumerations assumed in the
//     code
// [x] link these to the actual game
//   [x] call the configSiteMap construction logic instead of the
//       existing map creation code when visiting a site
//   [x] for now, just hard-code the sitemap names into the site
//       data, parameterization will come when site data is moved
//       to config files
//   [x] load in sitemaps.txt on game start
// [x] BENCHMARK: SUCCESSFUL COMPILE
// [x] verify names are correct in sitemaps.txt
// [x] ensure all maps are supported in the sitemaps.txt configuration
//     file
// [x] test game extensively and fix any remaining problems
//   [x] resolve off by 1 errors if they occur
// [x] clean deprecated map generation code
// [x] BENCHMARK: TERRAIN AND SPECIALS CONFIGURABLE AND ACTIVE IN GAME
// [x] SVN commit of all new files and changes
// [ ] change loot data storage to static item storage on map tiles
// [ ] propogate changes to dropped loot in combat and all other
//     areas where stuff exists on the floor in the game world
// [ ] implement .build() method for configSiteLoot
// [ ] ensure loot data is transferred to config file
// [ ] clean deprecated loot generation code
// [ ] any additional changes required to support new loot system
// [ ] BENCHMARK: LOOT CHANGES COMPLETED, SITEMAPS FULLY CONFIGURABLE
//
//
// Long-Term Roadmap to Configuration File Bliss:
//
// [x] Sitemaps configuration
// [ ] Site data configuration (prereq for National LCS)
// [x] Weapons configuration
// [x] Clothing configuration
// [ ] Creature type configuration
// [ ] Organizations configuration? (are we still doing organizations?)
// ... and more?
//
// ~ Jonathan S. Fox

const SITEMAP_ADDTYPE_OR = 1;
const SITEMAP_ADDTYPE_ANDNOT = 2;

const ROOMDIMENSION = 3;

enum SitemapScripts { room, hallwayYAxis, stairs, stairsRandom }

List<ConfigSiteMap> sitemaps = [];

// Builds a site based on the name provided
void buildSite(String name) {
  for (int i = 0; i < sitemaps.length; i++) {
    if (sitemaps[i].name == name) {
      sitemaps[i].build();
      return;
    }
  }
  // Backup: use a generic
  buildSite("GENERIC_UNSECURE");
}

// - configurable is a base class object for anything
//   that is implemented in the config file
// - configurable objects implement a configure() method
//   that takes two strings, a command and a value
abstract class Configurable {
  void configure(String command, String value);
}

// configSiteCommand is anything the configSiteMap stores in its array of stuff to build
abstract class ConfigSiteCommand extends Configurable {
  void build();
}

// configSiteMap derives from configurable, is a sitemap
class ConfigSiteMap extends Configurable {
  @override
  void configure(String command, String value) {
    if (command == "NAME") {
      name = value;
    } else if (command == "USE") {
      parent = value;
    } else if (command == "TILE") {
      currentCommand = ConfigSiteTile(value);
      commands.add(currentCommand);
    } else if (command == "SCRIPT") {
      currentCommand = ConfigSiteScript(value);
      commands.add(currentCommand);
    } else if (command == "SPECIAL") {
      currentCommand = ConfigSiteSpecial(value);
      commands.add(currentCommand);
    } else if (command == "UNIQUE") {
      currentCommand = ConfigSiteUnique(value);
      commands.add(currentCommand);
    } else if (command == "LOOT") {
      currentCommand = ConfigSiteLoot(value);
      commands.add(currentCommand);
    } else {
      currentCommand.configure(command, value);
    }
  }

  void build() {
    if (parent != null) buildSite(parent!);
    for (int step = 0; step < commands.length; step++) {
      commands[step].build();
    }
  }

  late String name;
  String? parent;
  List<ConfigSiteCommand> commands = [];
  late ConfigSiteCommand currentCommand;
}

// Paints tiles during map creation
class ConfigSiteTile extends ConfigSiteCommand {
  ConfigSiteTile(String value) {
    tile = switch (value) {
      "EXIT" => SITEBLOCK_EXIT,
      "BLOCK" => SITEBLOCK_BLOCK,
      "DOOR" => SITEBLOCK_DOOR,
      "KNOWN" => SITEBLOCK_KNOWN,
      "LOOT" => SITEBLOCK_LOOT,
      "LOCKED" => SITEBLOCK_LOCKED,
      "KLOCK" => SITEBLOCK_KLOCK,
      "CLOCK" => SITEBLOCK_CLOCK,
      "RESTRICTED" => SITEBLOCK_RESTRICTED,
      "BLOODY" => SITEBLOCK_BLOODY,
      "BLOODY2" => SITEBLOCK_BLOODY2,
      "GRASSY" => SITEBLOCK_GRASSY,
      "OUTDOOR" => SITEBLOCK_OUTDOOR,
      "DEBRIS" => SITEBLOCK_DEBRIS,
      "GRAFFITI" => SITEBLOCK_GRAFFITI,
      "GRAFFITI_CCS" => SITEBLOCK_GRAFFITI_CCS,
      "GRAFFITI_OTHER" => SITEBLOCK_GRAFFITI_OTHER,
      "FIRE_START" => SITEBLOCK_FIRE_START,
      "FIRE_PEAK" => SITEBLOCK_FIRE_PEAK,
      "FIRE_END" => SITEBLOCK_FIRE_END,
      "OPEN" => 0,
      _ => 0,
    };
  }

  @override
  void configure(String command, String value) {
    if (command == "XSTART") {
      xstart = int.parse(value) + (MAPX >> 1);
    } else if (command == "XEND") {
      xend = int.parse(value) + (MAPX >> 1);
    } else if (command == "X") {
      xstart = xend = int.parse(value) + (MAPX >> 1);
    } else if (command == "YSTART") {
      ystart = int.parse(value);
    } else if (command == "YEND") {
      yend = int.parse(value);
    } else if (command == "Y") {
      ystart = yend = int.parse(value);
    } else if (command == "ZSTART") {
      zstart = int.parse(value);
    } else if (command == "ZEND") {
      zend = int.parse(value);
    } else if (command == "Z") {
      zstart = zend = int.parse(value);
    } else if (command == "NOTE") {
      if (value == "ADD") {
        addtype = SITEMAP_ADDTYPE_OR;
      } else if (value == "SUBTRACT") {
        addtype = SITEMAP_ADDTYPE_ANDNOT;
      }
    }
  }

  @override
  void build() {
    for (SiteTile node in levelMap.range(
        xstart, ystart, zstart, xend + 1, yend + 1, zend + 1)) {
      if (addtype == SITEMAP_ADDTYPE_OR) {
        node.flag |= tile;
      } else if (addtype == SITEMAP_ADDTYPE_ANDNOT) {
        node.flag &= ~tile;
      } else {
        node.flag = tile;
      }
    }
  }

  int xstart = 0, xend = 0, ystart = 0, yend = 0, zstart = 0, zend = 0;
  late int tile;
  int addtype = 0;
}

// Executes a complex set of code during map creation
class ConfigSiteScript extends ConfigSiteCommand {
  ConfigSiteScript(String value) {
    if (value == "ROOM") {
      script = SitemapScripts.room;
    } else if (value == "HALLWAY_YAXIS") {
      script = SitemapScripts.hallwayYAxis;
    } else if (value == "STAIRS") {
      script = SitemapScripts.stairs;
    } else if (value == "STAIRS_RANDOM") {
      script = SitemapScripts.stairsRandom;
    }
  }
  @override
  void configure(String command, String value) {
    if (command == "XSTART") {
      xstart = int.parse(value) + (MAPX >> 1);
    } else if (command == "XEND") {
      xend = int.parse(value) + (MAPX >> 1);
    } else if (command == "YSTART") {
      ystart = int.parse(value);
    } else if (command == "YEND") {
      yend = int.parse(value);
    } else if (command == "ZSTART") {
      zstart = int.parse(value);
    } else if (command == "ZEND") {
      zend = int.parse(value);
    }
  }

  @override
  void build() {
    if (script == SitemapScripts.room) {
      for (int z = zstart; z <= zend; z++) {
        generateRoom(xstart, ystart, xend - xstart, yend - ystart, z);
      }
    } else if (script == SitemapScripts.hallwayYAxis) {
      for (int z = zstart; z <= zend; z++) {
        generateHallwayY(xstart, ystart, xend - xstart, yend - ystart, z);
      }
    } else if (script == SitemapScripts.stairs) {
      generateStairs(
          xstart, ystart, zstart, xend - xstart, yend - ystart, zend - zstart);
    } else if (script == SitemapScripts.stairsRandom) {
      generateStairsRandom(
          xstart, ystart, zstart, xend - xstart, yend - ystart, zend - zstart);
    }
  }

  int xstart = 0, xend = 0, ystart = 0, yend = 0, zstart = 0, zend = 0;
  late SitemapScripts script;

  /* recursive dungeon-generating algorithm */
  void generateRoom(int rx, int ry, int dx, int dy, int z) {
    for (SiteTile node in levelMap.range(rx, ry, z, rx + dx, ry + dy, z + 1)) {
      node.wall = false;
    }
    // Chance to stop iterating for large rooms
    if ((dx <= (ROOMDIMENSION + 1) || dy <= (ROOMDIMENSION + 1)) &&
        dx < dy * 2 &&
        dy < dx * 2 &&
        lcsRandom(2) == 0) {
      return;
    }
    // Very likely to stop iterating for small rooms
    if (dx <= ROOMDIMENSION && dy <= ROOMDIMENSION) return;
    // Guaranteed to stop iterating for hallways
    if (dx <= 1 || dy <= 1) return;
    //LAY DOWN WALL AND ITERATE
    if ((lcsRandom(2) == 0 || dy <= ROOMDIMENSION) && dx > ROOMDIMENSION) {
      int wx = rx + lcsRandom(dx - ROOMDIMENSION) + 1;
      for (int wy = 0; wy < dy; wy++) {
        levelMap[wx][ry + wy][z].wall = true;
      }
      int rny = lcsRandom(dy);
      levelMap[wx][ry + rny][z].wall = false;
      levelMap[wx][ry + rny][z].door = true;
      if (lcsRandom(3) == 0) levelMap[wx][ry + rny][z].locked = true;
      generateRoom(rx, ry, wx - rx, dy, z);
      generateRoom(wx + 1, ry, rx + dx - wx - 1, dy, z);
    } else {
      int wy = ry + lcsRandom(dy - ROOMDIMENSION) + 1;
      for (int wx = 0; wx < dx; wx++) {
        levelMap[rx + wx][wy][z].flag |= SITEBLOCK_BLOCK;
      }
      int rnx = lcsRandom(dx);
      levelMap[rx + rnx][wy][z].wall = false;
      levelMap[rx + rnx][wy][z].door = true;
      if (lcsRandom(3) == 0) levelMap[rx + rnx][wy][z].locked = true;
      generateRoom(rx, ry, dx, wy - ry, z);
      generateRoom(rx, wy + 1, dx, ry + dy - wy - 1, z);
    }
  }

  /* generates a hallway with rooms on either side */
  void generateHallwayY(int rx, int ry, int dx, int dy, int z) {
    for (int y = ry; y < ry + dy; y++) {
      // Clear hallway
      levelMap[rx][y][z].flag = 0;
      // Every four tiles
      if (y % 4 == 0) {
        // Pick a door location for the left
        int doorY = y + lcsRandom(3) - 1;
        // Create the left door
        levelMap[rx - 1][doorY][z].wall = false;
        levelMap[rx - 1][doorY][z].door = true;
        // Construct apartment on the left
        generateRoom(rx - dx - 1, y - 1, dx, 3, z);
        // Pick a door location for the right
        doorY = y + lcsRandom(3) - 1;
        // Create the right door
        levelMap[rx + 1][doorY][z].wall = false;
        levelMap[rx + 1][doorY][z].door = true;
        // Construct apartment on the right
        generateRoom(rx + 2, y - 1, dx, 3, z);
      }
    }
  }

  /* generates a stairwell */
  void generateStairs(int rx, int ry, int rz, int dx, int dy, int dz) {
    for (int z = rz; z <= rz + dz; z++) {
      if (z > rz) // If not bottom floor, add down stairs
      {
        if (z % 2 > 0) // Causes stairwell to swap sides every other floor
        {
          // Purge all tiles other than restriction, add stairs
          levelMap[rx + dx][ry + dy][z].flag &= SITEBLOCK_RESTRICTED;
          levelMap[rx + dx][ry + dy][z].special = TileSpecial.stairsDown;
        } else {
          levelMap[rx][ry][z].flag &= SITEBLOCK_RESTRICTED;
          levelMap[rx][ry][z].special = TileSpecial.stairsDown;
        }
      }
      if (z < rz + dz) // If not top floor, add up stairs
      {
        if (z % 2 == 0) {
          // Purge all tiles other than restriction, add stairs
          levelMap[rx + dx][ry + dy][z].flag &= SITEBLOCK_RESTRICTED;
          levelMap[rx + dx][ry + dy][z].special = TileSpecial.stairsUp;
        } else {
          levelMap[rx][ry][z].flag &= SITEBLOCK_RESTRICTED;
          levelMap[rx][ry][z].special = TileSpecial.stairsUp;
        }
      }
    }
  }

  /* generates randomly placed stairs, one up and one down per z-level except
      for top and bottom where there only be one down respectively one up. */
  void generateStairsRandom(int rx, int ry, int rz, int dx, int dy, int dz) {
    int x, y, z;
    List<(int, int)> secure = [],
        secureAbove = [],
        unsecure = [],
        unsecureAbove = [];
    bool validTile(int x, int y, int z) =>
        !levelMap[x][y][z].losObstructed &&
        !levelMap[x][y][z].outdoor &&
        levelMap[x][y][z].special == TileSpecial.none;
    // Look through bottom level for secure and unsecure tiles.
    for (int xi = xstart; xi <= xend; xi++) {
      for (int yi = ystart; yi <= yend; yi++) {
        if (validTile(xi, yi, zstart)) {
          if (levelMap[xi][yi][zstart].restricted) {
            secure.add((xi, yi));
          } else {
            unsecure.add((xi, yi));
          }
        }
      }
    }
    for (int zi = zstart + 1; zi <= zend; zi++) {
      // Look through level above for secure and unsecure tiles.
      for (int xi = xstart; xi <= xend; xi++) {
        for (int yi = ystart; yi <= yend; yi++) {
          if (validTile(xi, yi, zi)) {
            if (levelMap[xi][yi][zi].restricted) {
              secureAbove.add((xi, yi));
            } else {
              unsecureAbove.add((xi, yi));
            }
          }
        }
      }
      // Stairs in secure areas should only lead into secure areas.
      // Removing secure tiles without secure tiles above them.
      secure.removeWhere((element) =>
          !secureAbove.any((e) => e.$1 == element.$1 && e.$2 == element.$2));
      // Stairs in unsecure areas should only lead into unsecure areas.
      // Removing unsecure tiles without unsecure tiles above them.
      unsecure.removeWhere((element) =>
          !unsecureAbove.any((e) => e.$1 == element.$1 && e.$2 == element.$2));
      // Place stairs in secure area if possible, otherwise unsecure area.
      if (secure.isNotEmpty) {
        (x, y) = secure.random;
        z = zi - 1;
        // The tile receiving the stairs down will not eligible for stairs
        // up later.
        secureAbove
            .removeWhere((element) => element.$1 == x && element.$2 == y);
      } else if (unsecure.isNotEmpty) {
        (x, y) = unsecure.random;
        z = zi - 1;
        // The tile receiving the stairs down will not eligible for stairs
        // up later.
        unsecureAbove
            .removeWhere((element) => element.$1 == x && element.$2 == y);
      } else {
        continue; //Nowhere to place stairs.
      }
      levelMap[x][y][z].special = TileSpecial.stairsUp;
      levelMap[x][y][z + 1].special = TileSpecial.stairsDown;
      // Move up on level for next iteration.
      secure = secureAbove;
      secureAbove.clear();
      unsecure = unsecureAbove;
      unsecureAbove.clear();
    }
  }
}

TileSpecial specialLookup(String value) {
  return switch (value) {
    "LAB_COSMETICS_CAGEDANIMALS" => TileSpecial.cagedRabbits,
    "LAB_GENETIC_CAGEDANIMALS" => TileSpecial.cagedMonsters,
    "POLICESTATION_LOCKUP" => TileSpecial.policeStationLockup,
    "COURTHOUSE_LOCKUP" => TileSpecial.courthouseLockup,
    "COURTHOUSE_JURYROOM" => TileSpecial.courthouseJuryRoom,
    "PRISON_CONTROL" => TileSpecial.prisonControl,
    "PRISON_CONTROL_LOW" => TileSpecial.prisonControlLow,
    "PRISON_CONTROL_MEDIUM" => TileSpecial.prisonControlMedium,
    "PRISON_CONTROL_HIGH" => TileSpecial.prisonControlHigh,
    "INTEL_SUPERCOMPUTER" => TileSpecial.intelSupercomputer,
    "SWEATSHOP_EQUIPMENT" => TileSpecial.sweatshopEquipment,
    "POLLUTER_EQUIPMENT" => TileSpecial.polluterEquipment,
    "LAB_EQUIPMENT" => TileSpecial.labEquipment,
    "NUCLEAR_ONOFF" => TileSpecial.nuclearControlRoom,
    "HOUSE_PHOTOS" => TileSpecial.ceoSafe,
    "ARMYBASE_ARMORY" => TileSpecial.armory,
    "HOUSE_CEO" => TileSpecial.ceoOffice,
    "CORPORATE_FILES" => TileSpecial.corporateFiles,
    "RADIO_BROADCASTSTUDIO" => TileSpecial.radioBroadcastStudio,
    "NEWS_BROADCASTSTUDIO" => TileSpecial.cableBroadcastStudio,
    "APARTMENT_LANDLORD" => TileSpecial.apartmentLandlord,
    "APARTMENT_SIGN" => TileSpecial.signOne,
    "RESTAURANT_TABLE" => TileSpecial.table,
    "TENT" => TileSpecial.tent,
    "CAFE_COMPUTER" => TileSpecial.computer,
    "PARK_BENCH" => TileSpecial.parkBench,
    "STAIRS_UP" => TileSpecial.stairsUp,
    "STAIRS_DOWN" => TileSpecial.stairsDown,
    "CLUB_BOUNCER" => TileSpecial.clubBouncer,
    "CLUB_BOUNCER_SECONDVISIT" => TileSpecial.clubBouncerSecondVisit,
    _ => TileSpecial.none,
  };
}

// Drops specials down during map creation
class ConfigSiteSpecial extends ConfigSiteCommand {
  ConfigSiteSpecial(String value) {
    special = specialLookup(value);
  }
  @override
  void configure(String command, String value) {
    if (command == "XSTART") {
      xstart = int.parse(value) + (MAPX >> 1);
    } else if (command == "XEND") {
      xend = int.parse(value) + (MAPX >> 1);
    } else if (command == "X") {
      xstart = xend = int.parse(value) + (MAPX >> 1);
    } else if (command == "YSTART") {
      ystart = int.parse(value);
    } else if (command == "YEND") {
      yend = int.parse(value);
    } else if (command == "Y") {
      ystart = yend = int.parse(value);
    } else if (command == "ZSTART") {
      zstart = int.parse(value);
    } else if (command == "ZEND") {
      zend = int.parse(value);
    } else if (command == "Z") {
      zstart = zend = int.parse(value);
    } else if (command == "FREQ") {
      freq = int.parse(value);
    }
  }

  @override
  void build() {
    for (int x = xstart; x <= xend; x++) {
      for (int y = ystart; y <= yend; y++) {
        for (int z = zstart; z <= zend; z++) {
          if (lcsRandom(freq) == 0) levelMap[x][y][z].special = special;
        }
      }
    }
  }

  int xstart = 0, xend = 0, ystart = 0, yend = 0, zstart = 0, zend = 0;
  late TileSpecial special;
  int freq = 1;
}

class Coordinates {
  Coordinates(this.x, this.y, this.z);
  int x, y, z;
}

// Creates a unique during map creation
class ConfigSiteUnique extends ConfigSiteCommand {
  ConfigSiteUnique(String value)
      : xstart = (MAPX >> 1) - 5,
        xend = (MAPX >> 1) + 5,
        ystart = 10,
        yend = 20,
        zstart = 0,
        zend = 0 {
    unique = specialLookup(value);
  }

  @override
  void configure(String command, String value) {
    if (command == "Z") zstart = zend = int.parse(value);
  }

  @override
  void build() {
    int x, y, z;
    cleanSiteblockRestrictions();

    // Place unique
    List<Coordinates> secure = [], unsecure = [];
    for (SiteTile node in levelMap.all.where((node) =>
        node.x >= xstart &&
        node.x <= xend &&
        node.y >= ystart &&
        node.y <= yend &&
        node.z >= zstart &&
        node.z <= zend)) {
      if (node.door || node.wall || node.exit || node.outdoor) continue;
      if (node.special == TileSpecial.none) {
        if (node.restricted) {
          secure.add(Coordinates(node.x, node.y, node.z));
        } else {
          unsecure.add(Coordinates(node.x, node.y, node.z));
        }
      }
    }
    if (secure.isNotEmpty) {
      Coordinates choice = secure.random;
      x = choice.x;
      y = choice.y;
      z = choice.z;
    } else if (unsecure.isNotEmpty) {
      Coordinates choice = unsecure.random;
      x = choice.x;
      y = choice.y;
      z = choice.z;
    } else {
      return;
    }
    levelMap[x][y][z].special = unique;
  }

  int xstart, xend, ystart, yend, zstart, zend;
  late TileSpecial unique;
}

// Adds a loot type during map creation
class ConfigSiteLoot extends ConfigSiteCommand {
  ConfigSiteLoot(String value) : weight = 0 {
    if (value == "FINECLOTH") {
      loot = "LOOT_FINECLOTH";
    } else if (value == "CHEMICAL") {
      loot = "LOOT_CHEMICAL";
    } else if (value == "PDA") {
      loot = "LOOT_PDA";
    } else if (value == "LABEQUIPMENT") {
      loot = "LOOT_LABEQUIPMENT";
    } else if (value == "LAPTOP") {
      loot = "LOOT_COMPUTER";
    } else if (value == "CHEAPJEWELERY") {
      loot = "LOOT_CHEAPJEWELERY";
    } else if (value == "SECRETDOCUMENTS") {
      loot = "LOOT_SECRETDOCUMENTS";
    } else if (value == "CEOPHOTOS") {
      loot = "LOOT_CEOPHOTOS";
    } else if (value == "INTHQDISK") {
      loot = "LOOT_INTHQDISK";
    } else if (value == "CORPFILES") {
      loot = "LOOT_CORPFILES";
    } else if (value == "JUDGEFILES") {
      loot = "LOOT_JUDGEFILES";
    } else if (value == "RESEARCHFILES") {
      loot = "LOOT_RESEARCHFILES";
    } else if (value == "PRISONFILES") {
      loot = "LOOT_PRISONFILES";
    } else if (value == "CABLENEWSFILES") {
      loot = "LOOT_CABLENEWSFILES";
    } else if (value == "AMRADIOFILES") {
      loot = "LOOT_AMRADIOFILES";
    } else if (value == "POLICERECORDS") {
      loot = "LOOT_POLICERECORDS";
    } else if (value == "FINEJEWELERY") {
      loot = "LOOT_EXPENSIVEJEWELERY";
    } else if (value == "CELLPHONE") {
      loot = "LOOT_CELLPHONE";
    } else if (value == "MICROPHONE") {
      loot = "LOOT_MICROPHONE";
    } else if (value == "WATCH") {
      loot = "LOOT_WATCH";
    } else if (value == "SILVERWARE") {
      loot = "LOOT_SILVERWARE";
    } else if (value == "TRINKET") {
      loot = "LOOT_TRINKET";
    }
  }

  @override
  void configure(String command, String value) {
    if (command == "WEIGHT") weight = int.parse(value);
  }

  @override
  void build() {}

  late String loot;
  int weight;
}

// Reads in an entire configuration file
// Returns true for read successful, returns false if failed read
Future<bool> readConfigFile(String filename) async {
  Configurable? object;
  String file = await rootBundle.loadString(filename);
  Iterable<(String, String)> commands = file.split("\n").map(readLine).nonNulls;
  for (var (command, value) in commands) {
    if (command == "OBJECT") {
      object = createObject(value);
    } else if (object != null) {
      object.configure(command, value);
    } else {
      debugPrint("Unknown command $filename: $command $value");
      return false; // Unknown command and no object to give it to; failed read
    }
  }

  return true;
}

// readLine reads a line from the file, parses it
(String, String)? readLine(String line) {
  // if line starts with #, it's a comment so skip it
  if (line.isEmpty || line[0] == '#') return null;

  // Strip leading/trailing whitespace and replace tabs with spaces
  // Split command from value and build Command object
  List<String> parts = line.trim().replaceAll("\t", " ").split(" ");
  if (parts.length >= 2) return (parts.first, parts.last);
  return null;
}

// Constructs the new object, returns a pointer to it
Configurable? createObject(String objectType) {
  Configurable? object;
  if (objectType == "SITEMAP") {
    object = ConfigSiteMap();
    sitemaps.add(object as ConfigSiteMap);
  }
  return object;
}
