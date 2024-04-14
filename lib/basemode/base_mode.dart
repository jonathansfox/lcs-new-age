import 'package:lcs_new_age/basemode/activate_regulars.dart';
import 'package:lcs_new_age/basemode/activate_sleepers.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/basemode/base_actions.dart';
import 'package:lcs_new_age/basemode/disbanding.dart';
import 'package:lcs_new_age/basemode/flag.dart';
import 'package:lcs_new_age/basemode/invest_in_location.dart';
import 'package:lcs_new_age/basemode/liberal_agenda.dart';
import 'package:lcs_new_age/basemode/plan_site_visit.dart';
import 'package:lcs_new_age/basemode/review_mode.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/advance_day.dart';
import 'package:lcs_new_age/daily/siege.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/monthly/advance_month.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';

Future<bool> baseMode() async {
  int daysWithoutVision = 0;
  disbanding = false;

  while (true) {
    bool forceWait = false;
    cantSeeReason = CantSeeReason.other;
    forceWait = await checkForVision();

    if (!forceWait) {
      await howTimesHaveChanged(daysWithoutVision);
      daysWithoutVision = 0;
    }

    int partySize = activeSquad?.members.length ?? 0;
    if (activeSquad != null && partySize == 0) {
      squads.remove(activeSquad);
      activeSquad = null;
    }

    Site? loc = activeSquad?.site ?? activeSafehouse;
    Siege? siege = loc?.siege;
    if (!forceWait) {
      erase();
      baseModeSquadSafehouseDisplay(loc);
      baseModeOptionsDisplay(loc);
    }
    int c = forceWait ? Key.w : await getKey();
    switch (c) {
      case Key.v:
        // manage vehicles
        if (vehiclePool.isNotEmpty &&
            (activeSquad?.members.isNotEmpty ?? false)) {
          await setVehicles();
        }
      case Key.g:
        // give up
        if (siege?.underSiege ?? false) {
          await giveUp(loc);
          cleanGoneSquads();
        }
      case Key.f:
        // go forth / fight siege
        if (!(siege?.underSiege ?? false) && partySize > 0) {
          await planSiteVisit();
        } else if (siege?.underSiege == true &&
            siege?.activeSiegeType == SiegeType.police &&
            (activeSafehouse ?? activeSquad?.site)?.type ==
                SiteType.homelessEncampment) {
          await fightHomelessCampSiege();
          cleanGoneSquads();
        } else if (siege?.underAttack ?? false) {
          await escapeOrEngage();
          cleanGoneSquads();
        } else if (siege?.underSiege ?? false) {
          await sallyForth();
          cleanGoneSquads();
        }
      case Key.z:
        // select next safehouse
        List<Site> safehouses = sites.where((l) => l.isSafehouse).toList();
        if (safehouses.isNotEmpty) {
          int index = safehouses.indexOf(activeSafehouse ?? safehouses[0]);
          activeSquad = null;
          activeSafehouse = safehouses[(index + 1) % safehouses.length];
        }
      case Key.e:
        // equip loot
        if (partySize > 0 &&
            !(siege?.underAttack ?? false) &&
            activeSquad?.site != null) {
          Creature? oldASM = activeSquadMember;
          activeSquadMember = null;
          await equip(activeSquad?.site?.loot);
          activeSquadMember = oldASM;
        }
      case Key.o:
        // reorder squad
        if (partySize > 1) {
          await orderparty();
        }
      case Key.c:
        // cancel the squad's departure
        if (partySize > 0) {
          activeSquad?.activity = Activity.none();
        }
      case Key.p:
        if (loc != null) await prideOrProtest(loc);
      case Key.w:
        // wait
        if (forceWait || !pool.any((p) => p.site?.siege.underAttack ?? false)) {
          clearScreenOnNextMessage = forceWait;
          if (cantSeeReason != CantSeeReason.none) daysWithoutVision++;
          await advanceDay();
          if (day == 1) await advanceMonth();
          await advanceLocations();
          if (forceWait && day == 1) {
            erase();
            mvaddstrc(7, 5, lightGray, "Time passes...");
            mvaddstr(9, 12, "${getMonth(month)} $day, $year");
            refresh();
            await Future.delayed(const Duration(milliseconds: 100));
          }
        }
      case Key.i:
        Site? safehouse = activeSafehouse;
        if (safehouse != null &&
            safehouse.upgradable &&
            (siege?.underSiege == false)) {
          await investInLocation(safehouse);
        }
      case Key.l:
        disbanding = await liberalAgenda();
      case Key.a:
        await activateRegulars();
      case Key.b:
        await activateSleepers();
      case Key.n:
        if (squads.isNotEmpty) {
          int index = squads.indexOf(activeSquad ?? squads.last) + 1;
          if (index >= squads.length) index = 0;
          activeSquad = squads[index];
        }
      case Key.r:
        await reviewAssetsAndFormSquads();
      case Key.s:
        await updateTheSlogan();
      case Key.num0:
        activeSquadMember = null;
      case Key.x:
        await autoSaveGame();
        endGame();
      default:
        if (activeSquad != null) {
          int squadIndex = c - Key.num1;
          if (squadIndex >= 0 && squadIndex < squad.length) {
            Creature? squadMember = activeSquadMember;
            if (activeSquadMemberIndex == squadIndex && squadMember != null) {
              await fullCreatureInfoScreen(squadMember);
            } else {
              activeSquadMemberIndex = squadIndex;
            }
          }
        }
    }
  }
}

void baseModeSquadSafehouseDisplay(Site? loc) {
  if (activeSquad != null) activeSafehouse = null;
  locHeader();

  Site? aSafehouse = activeSafehouse;
  if (aSafehouse != null) {
    printLocation(aSafehouse);
    if ((aSafehouse.upgradable) && !aSafehouse.siege.underSiege) {
      mvaddstrc(8, 1, lightGray, "I - Invest in this location");
    }
  } else if (activeSquad != null) {
    printParty();
  } else {
    makeDelimiter();
  }

  if (loc == null) return;
  if (loc.siege.underSiege) {
    if (loc.siege.underAttack) {
      mvaddstrc(8, 1, red, "Under Attack");
    } else {
      mvaddstrc(8, 1, yellow, "Under Siege");
      if (loc.compound.rations <= 0) {
        addstr(" (No Food)");
      }
    }
  }

  if (loc.hasFlag) {
    printFlag();
  }
}

void printLocation(Site loc) {
  if (loc.siege.underSiege) {
    if (!loc.siege.underAttack) {
      mvaddstrc(2, 1, yellow, "The police have surrounded this location.");
    } else {
      setColor(red);
      switch (loc.siege.activeSiegeType) {
        case SiegeType.police:
          mvaddstr(2, 1, "The police are raiding");
        case SiegeType.cia:
          mvaddstr(2, 1, "The CIA is raiding");
        case SiegeType.hicks:
          mvaddstr(2, 1, "An angry mob is storming");
        case SiegeType.corporateMercs:
          mvaddstr(2, 1, "Corporate mercs are attacking");
        case SiegeType.ccs:
          mvaddstr(2, 1, "The CCS is attacking");
        default:
          mvaddstr(2, 1, "Software bugs are attacking");
      }
      addstr(" this location!");
    }
  } else {
    mvaddstrc(2, 1, lightGray, "You are not under siege... yet.");
  }
  if (loc.upgradable) {
    if (numberEating(loc) > 0) {
      int daysLeft = foodDaysLeft(loc);
      if (daysLeft > 0) {
        if (daysLeft < 4) {
          setColor(loc.siege.underSiege ? yellow : lightGray);
          mvaddstr(3, 1, "This location has food for only a few days.");
        }
      } else {
        setColor(loc.siege.underSiege ? red : lightGray);
        mvaddstr(3, 1, "This location has insufficient food stores.");
      }
    }
    if (loc.compound.fortified) {
      mvaddstrc(4, 1, white, "FORTIFIED COMPOUND");
    }
    if (loc.compound.videoRoom) {
      mvaddstrc(4, 24, lightBlue, "VIDEO STUDIO");
    }
    if (loc.compound.hackerDen) {
      mvaddstrc(4, 41, blue, "HACKER DEN");
    }
    if (loc.businessFront) {
      mvaddstrc(4, 56, pink, "BUSINESS FRONT");
    } else if (loc.discreet) {
      mvaddstrc(4, 56, darkGray, "HIDDEN LOCATION");
    }
    if (loc.compound.cameras) {
      if (loc.siege.underSiege && loc.siege.camerasOff) {
        mvaddstrc(5, 1, red, "CAMERAS OFF");
      } else {
        mvaddstrc(5, 1, lightGreen, "CAMERAS ON");
      }
    }
    if (loc.compound.boobyTraps) {
      mvaddstrc(5, 17, red, "BOOBY TRAPS");
    }
    if (loc.compound.aaGun) {
      mvaddstrc(5, 33, orange, "AA GUN");
    }
    if (loc.compound.bollards) {
      mvaddstrc(5, 45, yellow, "BOLLARDS");
    }
    if (loc.siege.underSiege && loc.siege.lightsOff) {
      mvaddstrc(5, 58, lightGray, "LIGHTS OUT");
    } else if (loc.compound.solarPanels) {
      mvaddstrc(5, 58, lightGreen, "SOLAR POWER");
    } else if (loc.compound.generator) {
      mvaddstrc(5, 59, white, "GENERATOR");
    }
    int eaters = numberEating(loc), days = foodDaysLeft(loc);
    if (eaters > 0) {
      if (days >= 1) {
        mvaddstrc(
            6, 50, lightGray, "$days day${days > 1 ? "s" : ""} of Food Left.");
      } else if (days == 0) {
        mvaddstrc(6, 50, red, "Not Enough Food");
      }
    }
    mvaddstrc(6, 1, lightGray,
        "${loc.compound.rations} Daily Ration${loc.compound.rations > 1 ? "s" : ""}");
    mvaddstr(6, 30, "$eaters Eating");
  }
}

void locHeader([Site? loc]) {
  loc = loc ?? activeSquad?.site ?? activeSafehouse;
  move(0, 0);
  setColor(lightGray);
  if (loc != null) {
    if (loc.siege.underAttack) {
      setColor(red);
    } else if (loc.siege.underSiege) {
      setColor(yellow);
    }
    if (activeSquad == null) addstr("No Squad Selected, ");
    addstr("${loc.getName(includeCity: true)}, ");
  }
  addstr("${getMonth(month)} $day, $year");
  if (loc == null) {
    mvaddstrc(3, 6, darkGray, "To form a new squad:");
    mvaddstr(4, 6, "1) R - Review Assets and Form Squads");
    mvaddstr(5, 6, "2) Press Z to Assemble a New Squad");
  }
  printFunds();
  if (activeSquad != null) {
    printSquadActivityDescription(0, 41, activeSquad!);
  }
}

void baseModeOptionsDisplay(Site? loc) {
  int squadSize = activeSquad?.members.length ?? 0;
  bool sieged = loc?.siege.underSiege ?? false;
  int safehouseCount = sites.where((l) => l.isSafehouse).length;
  bool cannotWait = pool.any((p) => p.site?.siege.underAttack ?? false);

  mvaddstrc(18, 10, lightGray, "=== ACTIVISM ===");
  mvaddstr(18, 51, "=== PLANNING ===");
  setColorConditional(squadSize > 0 && !(loc?.siege.underAttack ?? false));
  mvaddstr(19, 40, "E - Equip Squad");
  setColorConditional(vehiclePool.isNotEmpty && squadSize > 0);
  mvaddstr(19, 60, "V - Vehicles");
  setColorConditional(pool.isNotEmpty);
  mvaddstr(20, 40, "R - Review Assets and Form Squads");
  setColorConditional(squadSize > 1);
  if (squadSize > 1 && !sieged) mvaddstr(8, 31, "O - Reorder");
  if (squadSize > 0 && !sieged) {
    // don't cover up info about siege with irrelevant squad name of a squad
    // that will be disbanded during the siege anyway
    mvaddstrc(8, 1, lightGray, activeSquad?.name ?? "");
  }

  setColorConditional(
      squads.length > 1 || (activeSquad == null && squads.isNotEmpty));
  mvaddstr(8, 45, "N - Next Squad");
  setColorConditional(safehouseCount > 0);
  mvaddstr(8, 62, "Z - Next Location");
  mvaddstrc(21, 40, lightGray, "L - The Status of the Liberal Agenda");
  setColorConditional(pool.where((p) => p.isActiveLiberal).any(
      (p) => p.squad == null || p.squad?.activity.type == ActivityType.none));
  mvaddstr(21, 1, "A - Activate Liberals");
  setColorConditional(pool.any((p) => p.sleeperAgent));
  mvaddstr(21, 25, "B - Sleepers");
  setColorConditional(
      squadSize > 0 && activeSquad?.activity.type != ActivityType.none);
  mvaddstr(20, 1, "C - Cancel Departure");

  if (sieged) {
    setColorConditional(
        squadSize > 0 || pool.any((p) => p.site?.siege.underAttack ?? false));
    mvaddstr(19, 1, "F - Escape/Engage");
    mvaddstrc(19, 23, lightGray, "G - Give Up");
  } else {
    setColorConditional(squadSize > 0);
    mvaddstr(19, 1, "F - Go Forth to Stop Evil");
  }

  setColor(lightGray);
  if (cannotWait) {
    mvaddstr(23, 1, "Cannot Wait until Siege Resolved");
  } else {
    if (sieged) {
      mvaddstr(23, 1, "W - Wait out the siege");
    } else if (squads.any((s) => s.activity.type == ActivityType.visit)) {
      mvaddstrc(23, 1, lightGreen, "W - Carry out your plans");
    } else {
      mvaddstr(23, 1, "W - Wait a day");
    }
    if (date.add(const Duration(days: 1)).month != month) {
      addstr(" (next month)");
    }
  }
  mvaddstrc(22, 40, lightGray, "S - Free Speech: the Liberal Slogan");
  mvaddstrc(23, 40, lightGray, "X - Live to fight evil another day");

  if (loc?.hasFlag ?? false) {
    setColorConditional(sieged, ifTrue: lightGreen, ifFalse: lightGray);
    mvaddstr(22, 1, "P - Protest: Burn the flag");
  } else {
    setColorConditional(ledger.funds >= 20 &&
        !sieged &&
        (activeSafehouse != null || activeSquad != null));
    mvaddstr(22, 1, "P - Pride: fly a flag here (\$20)");
  }

  setColor(lightGray);
  if (loc?.hasFlag ?? false) {
    mvaddstrCenter(17, slogan);
  } else {
    mvaddstrCenter(13, slogan);
  }
}

Future<bool> checkForVision() async {
  bool forceWait = true;
  cantSeeReason = CantSeeReason.other;
  if (disbanding) {
    cantSeeReason = CantSeeReason.disbanded;
    disbanding = await showDisbandingScreen();
  } else {
    for (Creature c in pool) {
      if (c.isActiveLiberal) {
        cantSeeReason = CantSeeReason.none;
        if (c.clinicMonthsLeft == 0) {
          forceWait = false;
          break;
        }
      } else {
        if (c.clinicMonthsLeft > 0 &&
            cantSeeReason.index > CantSeeReason.hospital.index) {
          cantSeeReason = CantSeeReason.hospital;
        } else if (c.vacationDaysLeft > 0 &&
            cantSeeReason.index > CantSeeReason.dating.index) {
          cantSeeReason = CantSeeReason.dating;
        } else if (c.hidingDaysLeft > 0 &&
            cantSeeReason.index > CantSeeReason.hiding.index) {
          cantSeeReason = CantSeeReason.hiding;
        }
      }
    }
  }
  return forceWait;
}

Future<void> howTimesHaveChanged(int daysWithoutVision) async {
  String? str;
  if (daysWithoutVision >= 365 * 16) {
    str = "How long since you've heard these sounds...  times have changed.";
  } else if (daysWithoutVision >= 365 * 8) {
    str = "It has been a long time.  A lot must have changed...";
  } else if (daysWithoutVision >= 365 * 4) {
    str = "It sure has been a while.  Things might have changed a bit.";
  }
  if (str != null) {
    erase();
    setColor(white);
    mvaddstrCenter(12, str);
    await pressAnyKey();
  }
}

enum CantSeeReason { hospital, dating, hiding, other, prison, disbanded, none }

Future<void> updateTheSlogan() async {
  mvaddstrc(16, 0, lightGray, "What is your new slogan?");
  eraseLine(17);
  slogan = await enterName(17, 0, "We need a slogan!");
}
