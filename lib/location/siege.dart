import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'siege.g.dart';

@JsonSerializable()
class Siege {
  Siege();
  factory Siege.fromJson(Map<String, dynamic> json) => _$SiegeFromJson(json);
  Map<String, dynamic> toJson() => _$SiegeToJson(this);
  SiegeType activeSiegeType = SiegeType.none;
  bool get underSiege => activeSiegeType != SiegeType.none;
  bool _underAttack = false;
  bool get underAttack => underSiege && _underAttack;
  set underAttack(bool value) => _underAttack = value;
  int attackTime = 0;
  int kills = 0;
  int tanks = 0;
  SiegeEscalation escalationState = SiegeEscalation.police;
  bool lightsOff = false;
  bool camerasOff = false;
  int timeUntilCops = -1;
  int timeuntilcorps = -1;
  @JsonKey(defaultValue: -1)
  int timeuntilRuralMob = -1;
  int timeuntilccs = -1;
  int timeuntilcia = -1;
}

enum SiegeType {
  none,
  police,
  cia,
  angryRuralMob,
  corporateMercs,
  ccs,
}

enum SiegeEscalation {
  police,
  nationalGuard,
  tanks,
  bombers;

  SiegeEscalation escalate() {
    switch (this) {
      case SiegeEscalation.police:
        return SiegeEscalation.nationalGuard;
      case SiegeEscalation.nationalGuard:
        return SiegeEscalation.tanks;
      case SiegeEscalation.tanks:
        return SiegeEscalation.bombers;
      case SiegeEscalation.bombers:
        return SiegeEscalation.bombers;
    }
  }
}

int numberEating(Site loc) =>
    pool.where((e) => e.location == loc && e.alive).length;

int foodDaysLeft(Site loc) {
  int eaters = numberEating(loc);
  if (eaters == 0) return -1;
  return (loc.compound.rations / eaters).round();
}

Future<void> giveUp(Site? loc) async {
  if (loc == null) return;
  if (loc.rent > 0) loc.controller = SiteController.unaligned;
  if (loc.siege.activeSiegeType == SiegeType.police) {
    await surrenderToAuthorities(loc);
  } else {
    await surrenderAndDie(loc);
  }
  loc.siege.activeSiegeType = SiegeType.none;
  loc.loot.clear();
  vehiclePool.removeWhere((v) => v.location == loc);
}

Future<void> surrenderAndDie(Site loc) async {
  int killNumber = 0;
  for (Creature c in loc.creaturesPresent) {
    if (c.alive && c.align == Alignment.liberal) {
      killNumber++;
    }
    c.squad = null;
    c.die();
    c.location = null;
  }

  if (loc.siege.activeSiegeType == SiegeType.ccs &&
      loc.rent == 0 &&
      loc.type == SiteType.warehouse) {
    loc.controller = SiteController.ccs;
  }

  erase();
  mvaddstrc(1, 1, lightGray, "Everyone in the ${loc.name} is slain.");
  await getKey();

  if (killNumber > 3) {
    NewsStory.prepare(NewsStories.massacre)
      ..loc = loc
      ..siegebodycount = killNumber
      ..siegetype = loc.siege.activeSiegeType;
  }

  switch (loc.siege.activeSiegeType) {
    case SiegeType.police:
      await checkForDefeat(Ending.policeSiege);
    case SiegeType.cia:
      await checkForDefeat(Ending.ciaSiege);
    case SiegeType.angryRuralMob:
      await checkForDefeat(Ending.hicksSiege);
    case SiegeType.corporateMercs:
      await checkForDefeat(Ending.corporateSiege);
    case SiegeType.ccs:
      await checkForDefeat(Ending.ccsSiege);
    case SiegeType.none:
      await checkForDefeat(Ending.dead);
  }
}

Future<void> surrenderToAuthorities(Site loc) async {
  Site policeStation = sites.firstWhere(
      (l) => l.cityId == loc.cityId && l.type == SiteType.policeStation);
  //END SIEGE
  erase();
  String raiders;
  if (loc.siege.activeSiegeType == SiegeType.police) {
    if (loc.siege.escalationState == SiegeEscalation.police) {
      raiders = "police";
    } else {
      raiders = "soldiers";
    }
  } else {
    raiders = "software bugs";
  }
  mvaddstr(
      1, 1, "The $raiders confiscate everything, including Squad weapons.");

  Iterable<Creature> present =
      pool.where((e) => e.location == loc && e.alive).toList();
  Iterable<Creature> alive = present.where((e) => e.alive);
  Iterable<Creature> kidnapped = present.where((e) =>
      e.location == loc && e.missing && e.align == Alignment.conservative);
  Iterable<Creature> missing = alive.where((e) => e.missing);
  Iterable<Creature> rescued = missing.where((e) => e.alive);
  Iterable<Creature> liberals =
      alive.where((e) => e.isActiveLiberal && !rescued.contains(e));
  Iterable<Creature> nonCitizenLiberals =
      liberals.where((e) => (e.wantedForCrimes[Crime.illegalEntry] ?? 0) > 0);
  Iterable<Creature> citizenLiberals =
      liberals.where((e) => !nonCitizenLiberals.contains(e));

  // Charge everyone with harboring if found harboring illegal immigrants
  if (nonCitizenLiberals.isNotEmpty) {
    criminalizeAll(citizenLiberals, Crime.harboring);
  }

  // Charge everyone with kidnapping if missing persons are found
  if (kidnapped.isNotEmpty) {
    criminalizeAll(liberals, Crime.kidnapping);
    // And murder if any of them are dead
    if (kidnapped.any((e) => !e.alive)) {
      criminalizeAll(liberals, Crime.murder);
    }
  }

  // Enable angry mob sieges if hostage precious to them was found
  if (rescued.any((e) => e.type.preciousToAngryRuralMobs)) {
    offendedAngryRuralMobs = true;
  }

  int y = 1;
  Iterable<Creature> arrested = loc.type == SiteType.homelessEncampment
      ? liberals
      : liberals.where((e) => e.wantedForCrimes.values.any((v) => v > 0));
  if (rescued.length == 1) {
    mvaddstr(y += 2, 1,
        "${rescued.first.name} is taken into custody and rehabilitated.");
  } else if (rescued.length > 1) {
    mvaddstr(y += 2, 1,
        "${rescued.length} people who went missing are taken into custody and rehabilitated.");
  }
  if (arrested.length == 1) {
    mvaddstr(y += 2, 1, arrested.first.properName);
    if (arrested.first.properName != arrested.first.name) {
      addstr(", aka ${arrested.first.name},");
    }
    addstr(" is arrested.");
  } else if (arrested.length > 1) {
    mvaddstr(y += 2, 1, "${arrested.length} Liberals are arrested.");
  }

  if (ledger.funds > 0) {
    if (ledger.funds <= 20000 ||
        loc.siege.activeSiegeType != SiegeType.police) {
      mvaddstr(y += 2, 1, "Fortunately, your funds remain intact.");
    } else {
      int confiscated = lcsRandom(lcsRandom(ledger.funds - 10000)) + 1000;
      if (ledger.funds - confiscated > 50000) {
        confiscated +=
            ledger.funds - confiscated - 30000 - lcsRandom(20000) - confiscated;
      }
      if (confiscated > ledger.funds) confiscated = ledger.funds;
      mvaddstr(y += 2, 1,
          "Law enforcement has confiscated \$$confiscated in LCS funds.");
      ledger.subtractFunds(confiscated, Expense.confiscated);
    }
  }
  if (loc.compound.fortified) {
    mvaddstr(y += 2, 1, "The compound fortifications are dismantled.");
    loc.compound.fortified = false;
  }
  if (loc.compound.boobyTraps) {
    mvaddstr(y += 2, 1, "The booby traps are disarmed and removed.");
    loc.compound.boobyTraps = false;
  }
  if (loc.compound.aaGun) {
    if (laws[Law.gunControl] != DeepAlignment.archConservative) {
      mvaddstr(y += 2, 1, "The anti-aircraft gun is dismantled.");
      loc.compound.aaGun = false;
    }
  }
  if (loc.businessFront) {
    loc.businessFront = false;
    // Check that it took; some locations have permanent, unconfiscatable
    // business fronts
    if (!loc.businessFront) {
      mvaddstr(y += 2, 1, "Materials related to the business front are taken.");
    }
  }
  if (loc.type == SiteType.homelessEncampment &&
      laws[Law.policeReform]! < DeepAlignment.eliteLiberal) {
    loc.init();
    mvaddstr(y += 2, 1,
        "The police also ransack the camp and destroy the makeshift shelters.");
    mvaddstr(++y, 1, "The homeless people here are left with nothing.");
  }
  await pressAnyKey();
  for (Creature p in present) {
    if (kidnapped.contains(p)) {
      for (Creature p2 in pool.where((p2) =>
          p2.alive &&
          p2.activity.type == ActivityType.interrogation &&
          p2.activity.idInt == p.id)) {
        p2.activity = Activity.none();
      }
      p.squad = null;
      pool.remove(p);
    } else {
      p.squad?.loot.clear();
      p.dropWeaponAndAmmo();
      if (p.wantedForCrimes.values.any((v) => v > 0)) {
        p.squad = null;
        p.location = policeStation;
        p.activity = Activity.none();
      }
    }
  }
}
