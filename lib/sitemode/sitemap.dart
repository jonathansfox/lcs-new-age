// ignore_for_file: constant_identifier_names

/* re-create site from seed before squad arrives */
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_dame.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_tabscript.dart';
import 'package:lcs_new_age/utils/bitmask.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'sitemap.g.dart';

const ENCMAX = 10;
const RNG_SIZE = 4;
const MAPX = 70;
const MAPY = 23;
const MAPZ = 10;
List<List<List<SiteTile>>> levelMap = List.generate(
    MAPX,
    (x) => List.generate(
        MAPY, (y) => List.generate(MAPZ, (z) => SiteTile(x, y, z))));
Iterable<SiteTile> adjacentTiles(int x, int y, int z,
    {bool orthogonal = true}) sync* {
  for (int dx = -1; dx <= 1; dx++) {
    for (int dy = -1; dy <= 1; dy++) {
      if (dx == 0 && dy == 0) continue;
      if (x + dx < 0 || x + dx >= MAPX) continue;
      if (y + dy < 0 || y + dy >= MAPY) continue;
      if (orthogonal && dx != 0 && dy != 0) continue;
      yield levelMap[x + dx][y + dy][z];
    }
  }
}

SiteTile get currentTile => levelMap[locx][locy][locz];

extension LevelMap on List<List<List<SiteTile>>> {
  Iterable<SiteTile> get all sync* {
    for (int x = 0; x < MAPX; x++) {
      for (int y = 0; y < MAPY; y++) {
        for (int z = 0; z < MAPZ; z++) {
          yield this[x][y][z];
        }
      }
    }
  }

  Iterable<SiteTile> allOnFloor(int z) sync* {
    for (int x = 0; x < MAPX; x++) {
      for (int y = 0; y < MAPY; y++) {
        yield this[x][y][z];
      }
    }
  }

  SiteTile tile(int x, int y, int z) =>
      this[x.clamp(0, MAPX - 1)][y.clamp(0, MAPY - 1)][z.clamp(0, MAPZ - 1)];

  Iterable<SiteTile> range(
      int x1, int y1, int z1, int x2, int y2, int z2) sync* {
    for (int x = x1; x < x2; x++) {
      if (x < 0 || x >= MAPX) continue;
      for (int y = y1; y < y2; y++) {
        if (y < 0 || y >= MAPY) continue;
        for (int z = z1; z < z2; z++) {
          if (z < 0 || z >= MAPZ) continue;
          yield this[x][y][z];
        }
      }
    }
  }
}

SiteTile levelMapTile(int x, int y, int z) =>
    levelMap[x.clamp(0, MAPX - 1)][y.clamp(0, MAPY - 1)][z.clamp(0, MAPZ - 1)];
SiteTile? levelMapTileOrNull(int x, int y, int z) =>
    x < 0 || x >= MAPX || y < 0 || y >= MAPY || z < 0 || z >= MAPZ
        ? null
        : levelMap[x][y][z];
bool oldMapMode = false;

const SITEBLOCK_EXIT = BIT1;
const SITEBLOCK_BLOCK = BIT2;
const SITEBLOCK_DOOR = BIT3;
const SITEBLOCK_KNOWN = BIT4;
const SITEBLOCK_LOOT = BIT5;
const SITEBLOCK_LOCKED = BIT6;
const SITEBLOCK_KLOCK = BIT7;
const SITEBLOCK_CLOCK = BIT8;
const SITEBLOCK_RESTRICTED = BIT9;
const SITEBLOCK_BLOODY = BIT10;
const SITEBLOCK_BLOODY2 = BIT11;
const SITEBLOCK_GRASSY = BIT12;
const SITEBLOCK_OUTDOOR = BIT13;
const SITEBLOCK_DEBRIS = BIT14;
const SITEBLOCK_GRAFFITI = BIT15;
const SITEBLOCK_GRAFFITI_CCS = BIT16;
const SITEBLOCK_GRAFFITI_OTHER = BIT17;
const SITEBLOCK_FIRE_START = BIT18;
const SITEBLOCK_FIRE_PEAK = BIT19;
const SITEBLOCK_FIRE_END = BIT20;
const SITEBLOCK_CHAINLINK = BIT21;
const SITEBLOCK_ALARMED = BIT22;
const SITEBLOCK_METAL = BIT23;

const SIEGEFLAG_UNIT = BIT1;
const SIEGEFLAG_TRAP = BIT2;
const SIEGEFLAG_HEAVYUNIT = BIT3;
const SIEGEFLAG_UNIT_DAMAGED = BIT4;

enum TileSpecial {
  none,
  cagedRabbits,
  cagedMonsters,
  policeStationLockup,
  courthouseLockup,
  courthouseJuryRoom,
  prisonControl,
  prisonControlLow,
  prisonControlMedium,
  prisonControlHigh,
  intelSupercomputer,
  sweatshopEquipment,
  polluterEquipment,
  labEquipment,
  nuclearControlRoom,
  ceoSafe,
  ceoOffice,
  corporateFiles,
  radioBroadcastStudio,
  cableBroadcastStudio,
  apartmentLandlord,
  signOne,
  table,
  computer,
  tent,
  parkBench,
  stairsUp,
  stairsDown,
  clubBouncer,
  clubBouncerSecondVisit,
  armory,
  displayCase,
  signTwo,
  signThree,
  securityCheckpoint,
  securityMetalDetectors,
  securitySecondVisit,
  bankVault,
  bankTeller,
  bankMoney,
  ccsBoss,
  ovalOfficeNW,
  ovalOfficeNE,
  ovalOfficeSW,
  ovalOfficeSE,
}

class SiteTile {
  SiteTile(this.x, this.y, this.z);
  int x;
  int y;
  int z;
  TileSpecial special = TileSpecial.none;
  int flag = 0;
  int siegeflag = 0;
  bool inLOS = false;

  SiteTile? get left => levelMapTileOrNull(x - 1, y, z);
  SiteTile? get right => levelMapTileOrNull(x + 1, y, z);
  SiteTile? get up => levelMapTileOrNull(x, y - 1, z);
  SiteTile? get down => levelMapTileOrNull(x, y + 1, z);
  Iterable<SiteTile> neighbors({bool orthogonal = true}) =>
      adjacentTiles(x, y, z, orthogonal: orthogonal);

  bool get burning =>
      flag & SITEBLOCK_FIRE_PEAK > 0 ||
      flag & SITEBLOCK_FIRE_START > 0 ||
      flag & SITEBLOCK_FIRE_END > 0;
  bool get blocked => wall || door;
  bool get losObstructed => blocked || exit;
  bool get fireStart => flag & SITEBLOCK_FIRE_START > 0;
  set fireStart(bool value) => setFlag(SITEBLOCK_FIRE_START, value);
  bool get firePeak => flag & SITEBLOCK_FIRE_PEAK > 0;
  set firePeak(bool value) => setFlag(SITEBLOCK_FIRE_PEAK, value);
  bool get fireEnd => flag & SITEBLOCK_FIRE_END > 0;
  set fireEnd(bool value) => setFlag(SITEBLOCK_FIRE_END, value);
  bool get alarm => flag & SITEBLOCK_ALARMED > 0;
  set alarm(bool value) => setFlag(SITEBLOCK_ALARMED, value);
  bool get bloody => flag & SITEBLOCK_BLOODY > 0;
  set bloody(bool value) {
    setFlag(SITEBLOCK_BLOODY, value);
    if (value) bloodCounter++;
    if (bloodCounter > 10) {
      setFlag(SITEBLOCK_BLOODY2, true);
    }
  }

  bool get megaBloody => flag & SITEBLOCK_BLOODY2 > 0;
  set megaBloody(bool value) => setFlag(SITEBLOCK_BLOODY2, value);
  bool get chainlink => flag & SITEBLOCK_CHAINLINK > 0;
  set chainlink(bool value) => setFlag(SITEBLOCK_CHAINLINK, value);
  bool get metal => flag & SITEBLOCK_METAL > 0;
  set metal(bool value) => setFlag(SITEBLOCK_METAL, value);
  bool get debris => flag & SITEBLOCK_DEBRIS > 0;
  set debris(bool value) => setFlag(SITEBLOCK_DEBRIS, value);
  bool get door => flag & SITEBLOCK_DOOR > 0;
  set door(bool value) => setFlag(SITEBLOCK_DOOR, value);
  bool get exit =>
      flag & SITEBLOCK_EXIT > 0 ||
      x == 0 ||
      y == 0 ||
      x == MAPX - 1 ||
      y == MAPY - 1;
  set exit(bool value) => setFlag(SITEBLOCK_EXIT, value);
  bool get grass => flag & SITEBLOCK_GRASSY > 0;
  set grass(bool value) => setFlag(SITEBLOCK_GRASSY, value);
  bool get wall => flag & SITEBLOCK_BLOCK > 0;
  set wall(bool value) => setFlag(SITEBLOCK_BLOCK, value);
  bool get loot => flag & SITEBLOCK_LOOT > 0;
  set loot(bool value) => setFlag(SITEBLOCK_LOOT, value);
  bool get locked => flag & SITEBLOCK_LOCKED > 0;
  set locked(bool value) => setFlag(SITEBLOCK_LOCKED, value);
  bool get known => flag & SITEBLOCK_KNOWN > 0;
  set known(bool value) => setFlag(SITEBLOCK_KNOWN, value);
  bool get knownLock => flag & SITEBLOCK_KLOCK > 0;
  set knownLock(bool value) => setFlag(SITEBLOCK_KLOCK, value);
  bool get cantUnlock => flag & SITEBLOCK_CLOCK > 0;
  set cantUnlock(bool value) => setFlag(SITEBLOCK_CLOCK, value);
  bool get outdoor => flag & SITEBLOCK_OUTDOOR > 0;
  set outdoor(bool value) => setFlag(SITEBLOCK_OUTDOOR, value);
  bool get restricted => flag & SITEBLOCK_RESTRICTED > 0;
  set restricted(bool value) => setFlag(SITEBLOCK_RESTRICTED, value);
  bool get graffitiLCS => flag & SITEBLOCK_GRAFFITI > 0;
  set graffitiLCS(bool value) => setFlag(SITEBLOCK_GRAFFITI, value);
  bool get graffitiCCS => flag & SITEBLOCK_GRAFFITI_CCS > 0;
  set graffitiCCS(bool value) => setFlag(SITEBLOCK_GRAFFITI_CCS, value);
  bool get graffitiOther => flag & SITEBLOCK_GRAFFITI_OTHER > 0;
  set graffitiOther(bool value) => setFlag(SITEBLOCK_GRAFFITI_OTHER, value);
  bool get siegeUnit => siegeflag & SIEGEFLAG_UNIT > 0;
  set siegeUnit(bool value) => setSiegeFlag(SIEGEFLAG_UNIT, value);
  bool get siegeTrap => siegeflag & SIEGEFLAG_TRAP > 0;
  set siegeTrap(bool value) => setSiegeFlag(SIEGEFLAG_TRAP, value);
  bool get siegeHeavyUnit => siegeflag & SIEGEFLAG_HEAVYUNIT > 0;
  set siegeHeavyUnit(bool value) => setSiegeFlag(SIEGEFLAG_HEAVYUNIT, value);
  bool get siegeUnitDamaged => siegeflag & SIEGEFLAG_UNIT_DAMAGED > 0;
  set siegeUnitDamaged(bool value) =>
      setSiegeFlag(SIEGEFLAG_UNIT_DAMAGED, value);

  int bloodCounter = 0;

  void setFlag(int flag, bool value) {
    if (value) {
      this.flag |= flag;
    } else {
      this.flag &= ~flag;
    }
  }

  void setSiegeFlag(int flag, bool value) {
    if (value) {
      siegeflag |= flag;
    } else {
      siegeflag &= ~flag;
    }
  }
}

@JsonSerializable()
class SiteTileChange {
  SiteTileChange(this.x, this.y, this.z, this.flag);
  factory SiteTileChange.fromJson(Map<String, dynamic> json) =>
      _$SiteTileChangeFromJson(json);
  Map<String, dynamic> toJson() => _$SiteTileChangeToJson(this);
  int x, y, z;
  int flag;
}

Future<void> initsite(Site loc) async {
  //PREP
  if (activeSquad == null) return;
  for (Creature p in squad) {
    p.incapacitatedThisRound = false;
    p.justAttacked = false;
  }
  groundLoot.clear();

  //MAKE MAP
  int oldseed = nextRngSeed;
  nextRngSeed = loc.mapseed;

  // Try to load from a map file
  bool loaded = await tryBuildSiteFromDAME(loc);
  if (!loaded) {
    for (SiteTile tile in levelMap.all) {
      tile.flag = SITEBLOCK_BLOCK;
      tile.special = TileSpecial.none;
      tile.siegeflag = 0;
    }
  }
  if (loaded) {
    clearSecurityFromLCSSafehouses(loc);
  } else if (!oldMapMode) {
    buildSiteFromTabScript(loc);
  } else {
    buildSiteFromOldGenerator(loc);
  }
  clearAwayBlockedDoorways();
  deleteNonDoors();
  nextRngSeed = oldseed;
  if (oldMapMode) {
    //ADD RESTRICTIONS
    switch (loc.type) {
      case SiteType.cosmeticsLab:
      case SiteType.geneticsLab:
      case SiteType.policeStation:
      case SiteType.courthouse:
      case SiteType.prison:
      case SiteType.intelligenceHQ:
      case SiteType.armyBase:
      case SiteType.whiteHouse:
      case SiteType.amRadioStation:
      case SiteType.cableNewsStation:
        for (SiteTile tile
            in levelMap.range(2, 2, 0, MAPX - 2, MAPY - 2, MAPZ)) {
          tile.restricted = true;
        }
      default:
        break;
    }
    //ADD ACCESSORIES
    addOldMapSpecials(loc);
  }
  if (!loaded) {
    cleanSiteblockRestrictions();
  }
  addLoot(loc);

  /*******************************************************
   * Add semi-permanent changes inflicted by LCS and others
   *******************************************************/
  // Some sites need a minimum amount of graffiti
  int graffitiquota = 0;
  if (loc.type == SiteType.publicPark) graffitiquota = 5;
  if (loc.type == SiteType.homelessEncampment) graffitiquota = 2;
  if (loc.type == SiteType.drugHouse) graffitiquota = 30;
  if (loc.type == SiteType.tenement) graffitiquota = 10;
  for (int i = 0; i < loc.changes.length; i++) {
    int x = loc.changes[i].x, y = loc.changes[i].y, z = loc.changes[i].z;
    switch (loc.changes[i].flag) {
      case SITEBLOCK_GRAFFITI_OTHER: // Other tags
      case SITEBLOCK_GRAFFITI_CCS: // CCS tags
      case SITEBLOCK_GRAFFITI: // LCS tags
        graffitiquota--;
      case SITEBLOCK_DEBRIS: // Smashed walls, ash
        levelMap[x][y][z].flag &= ~SITEBLOCK_BLOCK;
        levelMap[x][y][z].flag &= ~SITEBLOCK_DOOR;
    }
    levelMap[x][y][z].flag |= loc.changes[i].flag;
  }
  // If there isn't enough graffiti for this site type, add some
  while (graffitiquota > 0) {
    int x = lcsRandom(MAPX - 2) + 1, y = lcsRandom(MAPY - 2) + 1, z = 0;
    if (loc.type == SiteType.tenement) z = lcsRandom(6);
    if (!(levelMap[x][y][z].flag & SITEBLOCK_BLOCK > 0) &&
        (!(levelMap[x][y][z].flag & SITEBLOCK_RESTRICTED > 0) ||
            loc.type == SiteType.drugHouse) &&
        !(levelMap[x][y][z].flag & SITEBLOCK_EXIT > 0) &&
        !(levelMap[x][y][z].flag & SITEBLOCK_GRAFFITI > 0) &&
        !(levelMap[x][y][z].flag & SITEBLOCK_GRAFFITI_OTHER > 0) &&
        !(levelMap[x][y][z].flag & SITEBLOCK_GRAFFITI_CCS > 0)) {
      if (levelMap[x + 1][y][z].flag & SITEBLOCK_BLOCK > 0 ||
          levelMap[x - 1][y][z].flag & SITEBLOCK_BLOCK > 0 ||
          levelMap[x][y + 1][z].flag & SITEBLOCK_BLOCK > 0 ||
          levelMap[x][y - 1][z].flag & SITEBLOCK_BLOCK > 0) {
        SiteTileChange change =
            SiteTileChange(x, y, z, SITEBLOCK_GRAFFITI_OTHER);
        loc.changes.add(change);
        levelMap[x][y][z].flag |= SITEBLOCK_GRAFFITI_OTHER;
        graffitiquota--;
      }
    }
  }
}

void floodVisitAllTiles(int startX, int startY, int startZ) {
  List<SiteTile?> toVisit = [levelMap[startX][startY][startZ]];
  while (toVisit.isNotEmpty) {
    SiteTile? current = toVisit.removeLast();
    if (current == null || current.known) continue;
    current.known = true;
    for (SiteTile neighbor in current.neighbors(orthogonal: false)) {
      if (!neighbor.known && !neighbor.losObstructed) {
        toVisit.add(neighbor);
      } else {
        neighbor.known = true;
      }
    }
    if (current.special == TileSpecial.stairsUp) {
      toVisit.add(current.up);
    }
    if (current.special == TileSpecial.stairsDown) {
      toVisit.add(current.down);
    }
  }
}

/* recursive dungeon-generating algorithm */
void generateroom(int rx, int ry, int dx, int dy, int z) {
  for (int x = rx; x < rx + dx; x++) {
    for (int y = ry; y < ry + dy; y++) {
      levelMap[x][y][z].flag &= ~SITEBLOCK_BLOCK;
    }
  }
  if ((dx <= 3 || dy <= 3) && oneIn(2)) return;
  if (dx <= 2 && dy <= 2) return;
  //LAY DOWN WALL AND ITERATE
  if ((oneIn(2) || dy <= 2) && dx > 2) {
    int wx = rx + lcsRandom(dx - 2) + 1;
    for (int wy = 0; wy < dy; wy++) {
      levelMap[wx][ry + wy][z].flag |= SITEBLOCK_BLOCK;
    }
    int rny = lcsRandom(dy);
    levelMap[wx][ry + rny][z].flag &= ~SITEBLOCK_BLOCK;
    levelMap[wx][ry + rny][z].flag |= SITEBLOCK_DOOR;
    if (oneIn(3)) levelMap[wx][ry + rny][z].flag |= SITEBLOCK_LOCKED;
    generateroom(rx, ry, wx - rx, dy, z);
    generateroom(wx + 1, ry, rx + dx - wx - 1, dy, z);
  } else {
    int wy = ry + lcsRandom(dy - 2) + 1;
    for (int wx = 0; wx < dx; wx++) {
      levelMap[rx + wx][wy][z].flag |= SITEBLOCK_BLOCK;
    }
    int rnx = lcsRandom(dx);
    levelMap[rx + rnx][wy][z].flag &= ~SITEBLOCK_BLOCK;
    levelMap[rx + rnx][wy][z].flag |= SITEBLOCK_DOOR;
    if (oneIn(3)) levelMap[rx + rnx][wy][z].flag |= SITEBLOCK_LOCKED;
    generateroom(rx, ry, dx, wy - ry, z);
    generateroom(rx, wy + 1, dx, ry + dy - wy - 1, z);
  }
}

/* marks the area around the specified tile as explored */
void knowmap(int locx, int locy, int locz) {
  levelMap[locx][locy][locz].flag |= SITEBLOCK_KNOWN;
  if (locx > 0) levelMap[locx - 1][locy][locz].flag |= SITEBLOCK_KNOWN;
  if (locx < MAPX - 1) levelMap[locx + 1][locy][locz].flag |= SITEBLOCK_KNOWN;
  if (locy > 0) levelMap[locx][locy - 1][locz].flag |= SITEBLOCK_KNOWN;
  if (locy < MAPY - 1) levelMap[locx][locy + 1][locz].flag |= SITEBLOCK_KNOWN;
  if (locx > 0 && locy > 0) {
    if (!(levelMap[locx - 1][locy][locz].flag & SITEBLOCK_BLOCK > 0) ||
        !(levelMap[locx][locy - 1][locz].flag & SITEBLOCK_BLOCK > 0)) {
      levelMap[locx - 1][locy - 1][locz].flag |= SITEBLOCK_KNOWN;
    }
  }
  if (locx < MAPX - 1 && locy > 0) {
    if (!(levelMap[locx + 1][locy][locz].flag & SITEBLOCK_BLOCK > 0) ||
        !(levelMap[locx][locy - 1][locz].flag & SITEBLOCK_BLOCK > 0)) {
      levelMap[locx + 1][locy - 1][locz].flag |= SITEBLOCK_KNOWN;
    }
  }
  if (locx > 0 && locy < MAPY - 1) {
    if (!(levelMap[locx - 1][locy][locz].flag & SITEBLOCK_BLOCK > 0) ||
        !(levelMap[locx][locy + 1][locz].flag & SITEBLOCK_BLOCK > 0)) {
      levelMap[locx - 1][locy + 1][locz].flag |= SITEBLOCK_KNOWN;
    }
  }
  if (locx < MAPX - 1 && locy < MAPY - 1) {
    if (!(levelMap[locx + 1][locy][locz].flag & SITEBLOCK_BLOCK > 0) ||
        !(levelMap[locx][locy + 1][locz].flag & SITEBLOCK_BLOCK > 0)) {
      levelMap[locx + 1][locy + 1][locz].flag |= SITEBLOCK_KNOWN;
    }
  }
}

void cleanSiteblockRestrictions() {
  // Clear out restrictions
  // (This is a really inefficient algorithm, but doesn't seem to be a
  // significant performance bottleneck.)
  bool acted;
  do {
    acted = false;
    for (SiteTile node in levelMap.range(2, 2, 0, MAPX - 2, MAPY - 2, MAPZ)) {
      //Un-restrict blocks if they have neighboring
      //unrestricted blocks
      if (!node.door && !node.wall && node.restricted) {
        if (node.neighbors().any((t) => !t.restricted && !t.wall)) {
          node.restricted = false;
          acted = true;
          continue;
        }
      }
      //Un-restrict and unlock doors if they lead between two
      //unrestricted sections. If they lead between one
      //unrestricted section and a restricted section, lock
      //them instead.
      else if (node.door && !node.wall && node.restricted) {
        if ((node.left?.restricted != true && node.right?.restricted != true) ||
            (node.up?.restricted != true && node.down?.restricted != true)) {
          //Unrestricted on two opposite sides
          //Unlock and unrestrict
          node.locked = false;
          node.restricted = false;
          acted = true;
          continue;
        } else if (node.neighbors().any((n) => !n.restricted) && !node.locked) {
          //Unrestricted on at least one side and I'm not locked
          //Lock doors leading to restricted areas
          node.locked = true;
          acted = true;
          continue;
        }
      }
    }
  } while (acted);
}

void buildSiteFromTabScript(Site loc) {
  switch (loc.type) {
    case SiteType.tenement:
    case SiteType.apartment:
    case SiteType.upscaleApartment:
      buildSite("RESIDENTIAL_APARTMENT");
    case SiteType.warehouse:
    case SiteType.drugHouse:
      buildSite("GENERIC_UNSECURE");
    case SiteType.homelessEncampment:
      buildSite("OUTDOOR_HOMELESS");
    case SiteType.bank:
    case SiteType.barAndGrill:
    case SiteType.bombShelter:
    case SiteType.bunker:
    case SiteType.fireStation:
      buildSite("GENERIC_LOBBY");
    case SiteType.cosmeticsLab:
      buildSite("LABORATORY_COSMETICS");
    case SiteType.geneticsLab:
      buildSite("LABORATORY_GENETICS");
    case SiteType.policeStation:
      buildSite("GOVERNMENT_POLICESTATION");
    case SiteType.courthouse:
      buildSite("GOVERNMENT_COURTHOUSE");
    case SiteType.prison:
      buildSite("GOVERNMENT_PRISON");
    case SiteType.intelligenceHQ:
      buildSite("GOVERNMENT_INTELLIGENCEHQ");
    case SiteType.whiteHouse:
      buildSite("GOVERNMENT_WHITE_HOUSE");
    case SiteType.armyBase:
      buildSite("GOVERNMENT_ARMYBASE");
    case SiteType.sweatshop:
      buildSite("INDUSTRY_SWEATSHOP");
    case SiteType.dirtyIndustry:
      buildSite("INDUSTRY_POLLUTER");
    case SiteType.nuclearPlant:
      buildSite("INDUSTRY_NUCLEAR");
    case SiteType.corporateHQ:
      buildSite("CORPORATE_HEADQUARTERS");
    case SiteType.ceoHouse:
      buildSite("CORPORATE_HOUSE");
    case SiteType.amRadioStation:
      buildSite("MEDIA_AMRADIO");
    case SiteType.cableNewsStation:
      buildSite("MEDIA_CABLENEWS");
    case SiteType.juiceBar:
      buildSite("BUSINESS_CAFE");
    case SiteType.internetCafe:
      buildSite("BUSINESS_INTERNETCAFE");
    case SiteType.latteStand:
      buildSite("OUTDOOR_LATTESTAND");
    case SiteType.veganCoOp:
      buildSite("GENERIC_ONEROOM");
    case SiteType.publicPark:
      buildSite("OUTDOOR_PUBLICPARK");
    default:
      buildSite("GENERIC_LOBBY");
  }
}

void buildSiteFromOldGenerator(Site loc) {
  // Last resort -- generate random map
  debugPrint("Building site from old generator! ${loc.type}");
  int centerX = MAPX >> 1;
  SiteTile entry = levelMapTile(centerX, 1, 0);
  entry.left?.exit = true;
  entry.right?.exit = true;
  entry.flag = 0;
  entry.down?.flag = SITEBLOCK_DOOR;
  if (loc.type == SiteType.upscaleApartment ||
      loc.type == SiteType.apartment ||
      loc.type == SiteType.tenement) {
    entry.special = TileSpecial.signOne;
    int height;
    int floors = lcsRandom(6) + 1, swap;
    for (int z = 0; z < floors; z++) {
      for (int y = 3; y < MAPY - 3; y++) {
        levelMap[MAPX >> 1][y][z].flag = 0;
        if (y % 4 == 0) {
          height = y + lcsRandom(3) - 1;
          levelMap[centerX - 1][height][z].flag = SITEBLOCK_DOOR;
          generateroom(centerX - 8, y - 1, 7, 3, z);
          height = y + lcsRandom(3) - 1;
          levelMap[centerX + 1][height][z].flag = SITEBLOCK_DOOR;
          generateroom(centerX + 2, y - 1, 7, 3, z);
          if (y == 4 && z == 0) {
            levelMap[centerX + 2][height][z].flag = 0;
            levelMap[centerX + 2][height][z].special =
                TileSpecial.apartmentLandlord;
          }
        }
      }
      swap = (z % 2) * 2 - 1;
      if (z > 0) {
        levelMap[(MAPX >> 1) + 1 * swap][MAPY - 4][z].flag = 0;
        levelMap[(MAPX >> 1) + 1 * swap][MAPY - 4][z].special =
            TileSpecial.stairsDown;
      }
      if (z < floors - 1) {
        levelMap[(MAPX >> 1) - 1 * swap][MAPY - 4][z].flag = 0;
        levelMap[(MAPX >> 1) - 1 * swap][MAPY - 4][z].special =
            TileSpecial.stairsUp;
      }
    }
  } else {
    switch (loc.type) {
      case SiteType.latteStand:
        for (int x = (MAPX >> 1) - 4; x <= (MAPX >> 1) + 4; x++) {
          for (int y = 0; y < 7; y++) {
            levelMap[x][y][0].flag = (x == (MAPX >> 1) - 4 ||
                    x == (MAPX >> 1) + 4 ||
                    y == 0 ||
                    y == 6
                ? SITEBLOCK_EXIT
                : 0);
            levelMap[x][y][0].special = TileSpecial.none;
            levelMap[x][y][0].siegeflag = 0;
          }
        }
      case SiteType.juiceBar:
      case SiteType.barAndGrill:
      case SiteType.veganCoOp:
      case SiteType.internetCafe:
        for (int x = (MAPX >> 1) - 4; x <= (MAPX >> 1) + 4; x++) {
          for (int y = 3; y < 10; y++) {
            levelMap[x][y][0].flag = 0;
            levelMap[x][y][0].special = TileSpecial.none;
            levelMap[x][y][0].siegeflag = 0;
          }
        }
      case SiteType.drugHouse:
        {
          int dx = lcsRandom(5) * 2 + 19,
              dy = lcsRandom(3) * 2 + 7,
              rx = (MAPX >> 1) - (dx >> 1),
              ry = 3;
          generateroom(rx, ry, dx, dy, 0);
          break;
        }
      default:
        {
          int dx = lcsRandom(5) * 2 + 35,
              dy = lcsRandom(3) * 2 + 15,
              rx = (MAPX >> 1) - (dx >> 1),
              ry = 3;
          generateroom(rx, ry, dx, dy, 0);
          break;
        }
    }
  }
}

void clearAwayBlockedDoorways() {
  for (SiteTile tile in levelMap.all) {
    if (tile.door) {
      // Blast open everything around a totally blocked door
      // (door will later be deleted)
      if (tile.neighbors().where((n) => !n.wall).isEmpty) {
        for (SiteTile n in tile.neighbors()) {
          n.wall = false;
        }
      }
      // Open up past doors that lead to walls
      void openUpInDirection(SiteTile? Function(SiteTile) next,
          Iterable<SiteTile?> Function(SiteTile?) neighbors) {
        SiteTile? n = next(tile);
        if (n == null) tile.wall = true;
        while (n != null) {
          n.wall = false;
          n.door = false;
          n = next(n);
          if (neighbors(n).any((n2) => n2?.blocked != false)) {
            break;
          }
        }
      }

      if (tile.left?.wall == false) {
        openUpInDirection((p0) => p0.right, (p0) => [p0?.up, p0?.down]);
      } else if (tile.right?.wall == false) {
        openUpInDirection((p0) => p0.left, (p0) => [p0?.up, p0?.down]);
      } else if (tile.up?.wall == false) {
        openUpInDirection((p0) => p0.down, (p0) => [p0?.left, p0?.right]);
      } else if (tile.down?.wall == false) {
        openUpInDirection((p0) => p0.up, (p0) => [p0?.left, p0?.right]);
      }
    }
  }
}

void deleteNonDoors() {
  for (SiteTile tile in levelMap.all) {
    if (tile.door) {
      if ((tile.left?.wall == true && tile.right?.wall == true) ||
          (tile.up?.wall == true && tile.down?.wall == true)) {
        continue;
      }
      tile.door = false;
      tile.locked = false;
    }
  }
}

// Clear high security, locked doors, alarms, and site specials
// from LCS non-apartment safehouses
void clearSecurityFromLCSSafehouses(Site loc) {
  if (loc.controller == SiteController.lcs &&
      loc.type != SiteType.apartment &&
      loc.type != SiteType.upscaleApartment &&
      loc.type != SiteType.tenement) {
    for (SiteTile tile in levelMap.all) {
      tile.locked = false;
      tile.restricted = false;
      tile.alarm = false;
      tile.special = TileSpecial.none;
    }
  }
}

Future<bool> tryBuildSiteFromDAME(Site loc) async {
  String mapName = switch (loc.type) {
    SiteType.tenement => "ApartmentIndustrial",
    SiteType.apartment => "ApartmentUniversity",
    SiteType.upscaleApartment => "ApartmentDowntown",
    SiteType.warehouse => "Warehouse",
    SiteType.homelessEncampment => "HomelessCamp",
    SiteType.drugHouse => "CrackHouse",
    SiteType.barAndGrill => "BarAndGrill",
    SiteType.bombShelter => "BombShelter",
    SiteType.bunker => "Bunker",
    SiteType.cosmeticsLab => "CosmeticsLab",
    SiteType.geneticsLab => "GeneticsLab",
    SiteType.policeStation => "PoliceStation",
    SiteType.courthouse => "Courthouse",
    SiteType.prison => "Prison",
    SiteType.intelligenceHQ => "IntelligenceHQ",
    SiteType.armyBase => "ArmyBase",
    SiteType.fireStation => "FireStation",
    SiteType.sweatshop => "Sweatshop",
    SiteType.dirtyIndustry => "Factory",
    SiteType.corporateHQ => "CorporateHQ",
    SiteType.ceoHouse => "CEOHouse",
    SiteType.amRadioStation => "RadioStation",
    SiteType.cableNewsStation => "CableNews",
    SiteType.juiceBar => "JuiceBar",
    SiteType.internetCafe => "InternetCafe",
    SiteType.latteStand => "LatteStand",
    SiteType.veganCoOp => "VeganCoOp",
    SiteType.publicPark => "Park",
    SiteType.bank => "Bank",
    SiteType.nuclearPlant => "NuclearPlant",
    SiteType.whiteHouse => "WhiteHouse",
    _ => "",
  };
  bool loaded = false;
  if (mapName != "") loaded = await readDAMEMap(mapName);
  return loaded;
}

void addOldMapSpecials(Site loc) {
  for (SiteTile tile in levelMap.range(2, 2, 0, MAPX - 2, MAPY - 2, MAPZ)) {
    if (!tile.door &&
        !tile.wall &&
        !tile.loot &&
        !tile.outdoor &&
        tile.restricted &&
        oneIn(10)) {
      if (oneIn(2)) {
        if (loc.type == SiteType.cosmeticsLab) {
          tile.special = TileSpecial.cagedRabbits;
        } else if (loc.type == SiteType.geneticsLab) {
          tile.special = TileSpecial.cagedMonsters;
        }
      } else {
        tile.special = TileSpecial.labEquipment;
      }
    }
    if (tile.flag == 0 && oneIn(10)) {
      if (loc.type == SiteType.sweatshop) {
        tile.special = TileSpecial.sweatshopEquipment;
      }
      if (loc.type == SiteType.dirtyIndustry) {
        tile.special = TileSpecial.polluterEquipment;
      }
      if (loc.type == SiteType.juiceBar ||
          loc.type == SiteType.barAndGrill ||
          loc.type == SiteType.latteStand) {
        tile.special = TileSpecial.table;
      }
      if (loc.type == SiteType.internetCafe) {
        if (oneIn(2)) {
          tile.special = TileSpecial.computer;
        } else {
          tile.special = TileSpecial.table;
        }
      }
      if (loc.type == SiteType.homelessEncampment) {
        tile.special = TileSpecial.tent;
      }
    }
  }
  SiteTile specialLocation() {
    Iterable<SiteTile> range = levelMap.all.where((t) =>
        t.x >= 2 &&
        t.y >= 2 &&
        t.x < MAPX - 2 &&
        t.y < MAPY - 2 &&
        !(t.x >= (MAPX >> 1) - 2 &&
            t.x <= (MAPX >> 1) + 2 &&
            t.y >= (MAPY >> 1) - 2 &&
            t.y <= 4));
    Iterable<SiteTile> candidates = range
        .where((t) => !t.blocked && !t.loot && t.special == TileSpecial.none);
    if (candidates.isNotEmpty) return candidates.random;
    return range.random;
  }

  //ADD FIRST SPECIAL
  SiteTile specialTile = specialLocation();
  switch (loc.type) {
    case SiteType.nuclearPlant:
      specialTile.special = TileSpecial.nuclearControlRoom;
    case SiteType.policeStation:
      specialTile.special = TileSpecial.policeStationLockup;
    case SiteType.courthouse:
      specialTile.special = TileSpecial.courthouseLockup;
    case SiteType.prison:
      specialTile.special = TileSpecial.prisonControl;
    case SiteType.intelligenceHQ:
      specialTile.special = TileSpecial.intelSupercomputer;
    case SiteType.corporateHQ:
      specialTile.special = TileSpecial.corporateFiles;
    case SiteType.ceoHouse:
      specialTile.special = TileSpecial.ceoSafe;
    case SiteType.armyBase:
      specialTile.special = TileSpecial.armory;
    case SiteType.amRadioStation:
      specialTile.special = TileSpecial.radioBroadcastStudio;
    case SiteType.cableNewsStation:
      specialTile.special = TileSpecial.cableBroadcastStudio;
    default:
      break;
  }
  //ADD SECOND SPECIAL
  specialTile = specialLocation();
  switch (loc.type) {
    case SiteType.courthouse:
      specialTile.special = TileSpecial.courthouseJuryRoom;
    default:
      break;
  }
}

void addLoot(Site loc) {
  //ADD LOOT
  final range = levelMap.range(2, 2, 0, MAPX - 2, MAPY - 2, MAPZ);
  bool highSecurityTiles = range.any((t) => t.restricted);
  for (SiteTile tile in levelMap.range(2, 2, 0, MAPX - 2, MAPY - 2, MAPZ)) {
    if (!tile.door &&
        !tile.wall &&
        !tile.outdoor &&
        tile.special == TileSpecial.none &&
        (tile.restricted || !highSecurityTiles) &&
        oneIn(10)) {
      switch (loc.type) {
        case SiteType.bank: // the valuables are in the vault
        case SiteType.homelessEncampment:
        case SiteType.drugHouse:
        case SiteType.juiceBar:
        case SiteType.barAndGrill:
        case SiteType.latteStand:
        case SiteType.veganCoOp:
        case SiteType.internetCafe:
        case SiteType.warehouse:
        case SiteType.bunker:
        case SiteType.bombShelter:
          break;
        default:
          tile.loot = true;
      }
    }
  }
}
