import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/solo_activities.dart';
import 'package:lcs_new_age/daily/dating.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/daily/recruitment.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/daily/siege.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/location/compound.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/monthly/advance_month.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/newspaper/run_news_cycle.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemode.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

Future<void> advanceDay() async {
  if (!disbanding) {
    await autoSaveGame();
  }
  ledger.resetDailyAmounts();
  for (Creature p in pool) {
    p.carId = null;
  }
  if (!disbanding) {
    _moveSquadlessToBases();
    await _tendHostages();
    await _advanceSquads();
  }
  await soloActivities(disbanding);
  if (!disbanding) await _dailyHealing();
  await dispersalCheck();
  await _doRent();
  await meetWithPotentialRecruits();
  if (!disbanding) await doDates();
  await _ageThings();
  await runNewsCycle();
  cleanGoneSquads();
  await siegeTurn();
  await siegeCheck();
  cleanGoneSquads();
  await winCheck();
}

Future<void> _tendHostages() async {
  // Make a copy to allow sessions to be removed during the loop
  for (InterrogationSession intr in interrogationSessions.toList()) {
    if (pool.any((c) => c.id == intr.hostageId)) {
      await tendHostage(intr);
    } else {
      interrogationSessions.remove(intr);
    }
  }
}

void _moveSquadlessToBases() {
  for (Creature c in pool) {
    if (c.squad != null || !c.isActiveLiberal) continue;
    if (c.location != c.base &&
        (c.base?.siege.underSiege == true || c.base == null)) {
      if (c.location == null && c.base == null) {
        c.base = sites.firstWhere((l) => l.type == SiteType.homelessEncampment);
      } else {
        c.base = sites.firstWhere((l) =>
            l.city == c.location?.city &&
            l.type == SiteType.homelessEncampment);
      }
    }
    if (c.base != null && !c.imprisoned) c.location = c.base;
  }
}

Future<void> _advanceSquads() async {
  List<Vehicle> vehiclesInUse = [];
  for (Squad s in squads) {
    if (s.activity.type != ActivityType.none) {
      for (Creature c in s.members) {
        if (c.activity.type != ActivityType.none &&
            c.activity.type != s.activity.type) {
          await showMessage(
              "${c.name} acted with ${s.name} instead of ${c.activity.description}.");
        }
        c.activity = s.activity;
      }
    }
    if (s.activity.type == ActivityType.visit) {
      Site site = s.activity.location!;
      if (site.isClosed || site.siege.underSiege) {
        await showMessage(
            "${s.name} decided ${site.name} was too hot to risk.");
        s.activity = Activity(ActivityType.none);
        continue;
      }
      await _carUpSquad(s, vehiclesInUse);
      if (site.area != s.site?.area && s.members.first.car == null) {
        await showMessage(
            "${s.name} didn't have a car to get to ${site.name}.");
        s.activity = Activity(ActivityType.none);
        continue;
      }
      if (site != s.members.first.base) {
        for (Creature driver
            in s.members.where((m) => m.car != null && m.isDriver)) {
          driver.train(Skill.driving, 10);
        }
      }
      //GO PLACES
      // Verify travellers can afford the cost, and charge them
      bool canDepart = true;
      if (site.cityId != s.members.first.base?.cityId) {
        debugPrint("site.cityId: ${site.cityId}");
        debugPrint(
            "s.members.first.base?.cityId: ${s.members.first.base?.cityId}");
        int price = s.members.length * 100;
        if (ledger.funds < price) {
          await showMessage(
              "${s.name} couldn't afford to travel to ${site.name}.");
          canDepart = false;
        } else {
          ledger.subtractFunds(price, Expense.travel);
          await showMessage("${s.name} paid $price to travel to ${site.name}.");
        }
      }
      if (canDepart) {
        await _squadDepart(s);
      }
      s.activity = Activity(ActivityType.none);
      for (Creature c in s.members) {
        c.activity = Activity(ActivityType.visit);
      }
    }
  }
}

Future<void> _carUpSquad(Squad squad, List<Vehicle> vehiclesInUse) async {
  List<Vehicle> desiredVehicles =
      squad.members.map((c) => c.preferredCar).nonNulls.toSet().toList();
  for (Vehicle v in desiredVehicles) {
    if (vehiclesInUse.contains(v)) {
      await showMessage("${squad.name} couldn't use the ${v.fullName()}.");
    }
  }
  desiredVehicles.removeWhere((v) => vehiclesInUse.contains(v));
  if (desiredVehicles.isEmpty) return;

  // Assign available cars
  for (Vehicle v in desiredVehicles) {
    List<Creature> driver = [], passenger = [];
    vehiclesInUse.add(v);
    // Fill car with designated drivers and passengers
    for (Creature c in squad.members.where((m) => m.preferredCar == v)) {
      c.carId = v.id;
      bool isDriver = c.preferredDriver && c.canWalk;
      if (isDriver) {
        driver.add(c);
      } else {
        passenger.add(c);
      }
    }
    if (driver.isEmpty) {
      // No driver designated; all passengers become candidates
      driver = passenger;
      passenger = [];
    }
    if (driver.length > 1) {
      // Too many drivers; identify the best one and toss the rest
      Creature bestDriver = driver.reduce((value, element) {
        int vDrive =
            value.skillRoll(Skill.driving, take10: true, healthMod: true);
        int eDrive =
            element.skillRoll(Skill.driving, take10: true, healthMod: true);
        return vDrive >= eDrive ? value : element;
      });
      passenger.addAll(driver.where((element) => element != bestDriver));
      driver = [bestDriver];
    }
    driver.first.isDriver = true;
    for (Creature c in passenger) {
      c.isDriver = false;
    }
  }

  // Put people without assigned cars into random cars as passengers
  for (Creature c in squad.members.where((m) => m.carId == null)) {
    c.carId = desiredVehicles.random.id;
  }
}

Future<void> _ageThings() async {
  gameState.date = gameState.date.add(const Duration(days: 1));
  for (Creature c in pool) {
    c.stunned = 0;
    c.daysSinceJoined++;
    if (!c.alive) c.daysSinceDeath++;
    for (int i = 60; i < c.age; i += 5) {
      if (oneIn(365 * 5)) {
        if (c.health > 1) {
          c.permanentHealthDamage = c.permanentHealthDamage + 1;
        } else {
          c.die();
          await showMessage(
              "${c.name} has passed away at the age of ${c.age}.");
          await showMessage(
              "Their Heart finally gave out.  The Liberal will be missed.");
        }
      }
    }
    if (month == c.birthDate.month && day == c.birthDate.day) {
      if (!disbanding && canSeeThings) {
        await showMessage("${c.name} is now ${c.age} years old.");
      }
      if (c.age == 13) {
        c.type = creatureTypes[CreatureTypeIds.teenager]!;
      } else if (c.age == 18) {
        c.type = creatureTypes[CreatureTypeIds.politicalActivist]!;
      }
    }
    if (c.blood < c.maxBlood) c.blood++;
    if (c.hidingDaysLeft > 0) {
      if (--c.hidingDaysLeft == 0) {
        if (c.base?.siege.underSiege == true) {
          c.hidingDaysLeft = 1;
        } else {
          if (!c.imprisoned) {
            c.location = c.base;
          }
          await showMessage("${c.name} regains contact with the LCS.");
        }
      }
    }
    if (c.missing && !c.kidnapped) {
      if (lcsRandom(14) + 5 < c.daysSinceJoined) {
        c.kidnapped = true;
        NewsStory.prepare(NewsStories.kidnapReport).cr = c;
      }
    }
    c.skillUp();
  }
}

Future<void> _squadDepart(Squad s) async {
  if (s.members.isEmpty) return;
  Site site = s.activity.location!;
  Site? base = s.members.first.base ??
      s.site ??
      findSiteInSameCity(site.city, SiteType.homelessEncampment);
  if (base == null) {
    debugPrint(
        "Squad has no base to return to and no homeless camp found. Canceling departure.");
    return;
  }
  if (s.members.first.base == site) {
    await showMessage("${s.name} looks around ${site.name}.");
  } else {
    await showMessage("${s.name} has arrived at ${site.name}.");
  }
  int c = Key.t;

  if (site.controller == SiteController.lcs && s.members.first.base != site) {
    List<SiteType> raidableSafehouses = [
      SiteType.tenement,
      SiteType.apartment,
      SiteType.upscaleApartment,
    ];
    if (!raidableSafehouses.contains(site.type)) {
      c = Key.s;
    } else {
      mvaddstrc(8, 1, white,
          "Why is the squad here?   (S)afe House, to cause (T)rouble, or (B)oth?");
      do {
        c = await getKey();
      } while (c != Key.s && c != Key.b && c != Key.t);
    }
  }
  activeSquad = s;
  switch (site.type) {
    case SiteType.departmentStore:
      await deptstore(site);
    case SiteType.oubliette:
      await oubliette(site);
    case SiteType.pawnShop:
      await pawnshop(site);
    case SiteType.carDealership:
      await dealership(site);
    case SiteType.armsDealer:
      await armsdealer(site);
    case SiteType.universityHospital:
    case SiteType.clinic:
      activeSquad = s;
      await hospital(site);
      locatesquad(s, base);
    default:
      if (c == Key.s || c == Key.b) {
        for (var c in s.members) {
          c.base = site;
        }
        base = site;
      }
      if (c == Key.t || c == Key.b) {
        sitestory = NewsStory.unpublished(NewsStories.squadSiteAction)
          ..loc = site;
        await siteMode(site);
      }
  }
  s.activity.type = ActivityType.none;

  for (Creature c in s.members) {
    c.location = c.base;
    c.car?.locationId = c.site?.id;
  }
}

enum DispersalTypes {
  safe,
  bossSafe,
  noContact,
  bossInPrison,
  hiding,
  bossInHiding,
  abandonLCS,
}

/* squad members with no chain of command lose contact */
Future<void> dispersalCheck() async {
  //NUKE DISPERSED SQUAD MEMBERS WHOSE MASTERS ARE NOT AVAILABLE
  if (pool.isNotEmpty) {
    // *JDS* I'm documenting this algorithm carefully because it
    // took me awhile to figure out what exactly was going on here.
    //
    // dispersal_status tracks whether each person has a secure chain of command.
    //
    // if dispersal_status == NOCONTACT, no confirmation of contact has been made
    // if dispersal_status == BOSSSAFE, confirmation that THEY are safe is given,
    //    but it is still needed to check whether their subordinates
    //    can reach them.
    // if dispersal_status == SAFE, confirmation has been made that this squad
    //    member is safe, and their immediate subordinates have also
    //    checked.
    //
    // The way the algorithm works, everyone starts at dispersal_status = NOCONTACT.
    // Then we start at the top of the chain of command and walk
    // down it slowly, marking people BOSSSAFE and then SAFE as we sweep
    // down the chain. If someone is dead or in an unreachable state,
    // they block progression down the chain to their subordinates,
    // preventing everyone who requires contact with that person
    // from being marked safe. After everyone reachable has been
    // reached and marked safe, all remaining squad members are nuked.
    Map<Creature, DispersalTypes> dispersalStatus =
        Map.fromEntries(pool.map((e) => MapEntry(e, DispersalTypes.noContact)));

    bool promotion;
    do {
      promotion = false;
      for (int i = pool.length - 1; i >= 0; i--) {
        Creature p = pool[i];
        // If member has no boss (founder level), mark
        // them dispersal_status = BOSSSAFE, using them as a starting point
        // at the top of the chain.
        if (p.hireId == null) {
          if (!disbanding) {
            dispersalStatus[p] = DispersalTypes.bossSafe;
            if (p.hidingDaysLeft < 0) {
              p.hidingDaysLeft = 0;
            }
          } else {
            dispersalStatus[p] = DispersalTypes.bossInHiding;
          }
        }
        // If they're dead, mark them dispersal_status = SAFE, so they
        // don't ever have their subordinates checked
        // and aren't lost themselves (they're a corpse,
        // corpses don't lose contact)
        if (!p.alive && !disbanding) {
          dispersalStatus[p] = DispersalTypes.safe;
          //Attempt to promote their subordinates
          if (await _promoteSubordinates(p) != null) promotion = true;

          if (p.site?.controller != SiteController.lcs) {
            pool.remove(p);
          }
        }
      }
    } while (promotion);

    bool changed;

    do // while(changed)
        {
      changed = false;

      bool inprison;

      // Go through the entire pool to locate people at dispersal_status = BOSSSAFE,
      // so we can verify that their subordinates can reach them.
      for (int i = pool.length - 1; i >= 0; i--) {
        Creature p = pool[i];
        if (!p.alive) continue;
        if (p.site?.type == SiteType.prison && !p.sleeperAgent) {
          inprison = true;
        } else {
          inprison = false;
        }

        // If your boss is in hiding
        if (dispersalStatus[p] == DispersalTypes.bossInHiding) {
          dispersalStatus[p] = DispersalTypes.hiding;
          for (int p2 = pool.length - 1; p2 >= 0; p2--) {
            if (pool[p2].hireId == p.id && pool[p2].alive) {
              dispersalStatus[pool[p2]] =
                  DispersalTypes.bossInHiding; // Mark them as unreachable
              changed = true; // Need another iteration
            }
          }
        }

        // If in prison or unreachable due to a member of the command structure
        // above being in prison
        else if ((dispersalStatus[p] == DispersalTypes.bossSafe && inprison) ||
            dispersalStatus[p] == DispersalTypes.bossInPrison) {
          DispersalTypes dispersalval = DispersalTypes.safe;
          if (p.seduced &&
              (p.location != p.boss?.location) &&
              (p.typeId != CreatureTypeIds.lawyer || !p.sleeperAgent)) {
            // Recruited by seduction loses juice when not in prison
            // with their lover
            p.juice--;
            if (p.juice < -50) dispersalval = DispersalTypes.abandonLCS;
          }
          dispersalStatus[p] = dispersalval; // Guaranteed contactable in prison

          // Find all subordinates
          for (int p2 = pool.length - 1; p2 >= 0; p2--) {
            if (pool[p2].hireId == p.id && pool[p2].alive) {
              if (inprison) {
                dispersalStatus[pool[p2]] = DispersalTypes.bossInPrison;
              } else {
                dispersalStatus[pool[p2]] = DispersalTypes.bossSafe;
              }
              changed = true; // Need another iteration
            }
          }
        }
        // Otherwise, if they're reachable
        else if (dispersalStatus[p] == DispersalTypes.bossSafe && !inprison) {
          // Start looking through the pool again.
          // Locate each of this person's subordinates.
          for (Creature p2 in pool.where((p2) => p2.hireId == p.id)) {
            // Protect them from being dispersed -- their boss is
            // safe. Their own subordinates will then be considered
            // in the next loop iteration.
            dispersalStatus[p2] = DispersalTypes.bossSafe;
            // If they're hiding indefinitely and their boss isn't
            // hiding at all, then have them discreetly return in a
            // couple of weeks
            if (p2.hidingDaysLeft < 0 && p.hidingDaysLeft == 0) {
              p2.hidingDaysLeft = lcsRandom(10) + 3;
            }
            changed = true; // Take note that another iteration is needed.
          }
          // Now that we've dealt with this person's subordinates, mark
          // them so that we don't look at them again in this loop.
          dispersalStatus[p] = DispersalTypes.safe;
        }
      }
    } while (changed); // If another iteration is needed, continue the loop.

    // After checking through the entire command structure, proceed
    // to nuke all squad members who are unable to make contact with
    // the LCS.
    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (dispersalStatus[p] == DispersalTypes.noContact ||
          dispersalStatus[p] == DispersalTypes.hiding ||
          dispersalStatus[p] == DispersalTypes.abandonLCS) {
        erase();

        if (!disbanding) {
          if (p.hidingDaysLeft == 0 &&
              dispersalStatus[p] == DispersalTypes.hiding) {
            mvaddstrc(8, 1, white,
                "${p.name} has lost touch with the Liberal Crime Squad.");
            await getKey();
            mvaddstrc(9, 1, lightGreen, "The Liberal has gone into hiding...");
            await getKey();
          } else if (dispersalStatus[p] == DispersalTypes.abandonLCS) {
            mvaddstrc(8, 1, white, "${p.name} has abandoned the LCS.");
            await getKey();
          } else if (dispersalStatus[p] == DispersalTypes.noContact) {
            mvaddstrc(8, 1, white,
                "${p.name} has lost touch with the Liberal Crime Squad.");
            await getKey();
          }
        }

        p.squad = null;
        if (dispersalStatus[p] == DispersalTypes.noContact ||
            dispersalStatus[p] == DispersalTypes.abandonLCS) {
          pool.remove(p);
        } else {
          p.location = null;
          if (!p.sleeperAgent) {
            //Sleepers end up in camp otherwise.
            p.base =
                findSiteInSameCity(p.base!.city, SiteType.homelessEncampment);
          }
          p.activity.type = ActivityType.none;
          p.hidingDaysLeft = -1; // Hide indefinitely
        }
      }
    }
  }

  //MUST DO AN END OF GAME CHECK HERE BECAUSE OF DISPERSAL
  await checkForDefeat(Ending.dispersed);

  cleanGoneSquads();
}

/* promote a subordinate to maintain chain of command when boss is lost */
Future<Creature?> _promoteSubordinates(Creature cr) async {
  Creature? newboss;
  Creature? bigboss = pool.firstWhereOrNull((p) => p.id == cr.hireId);
  int requiredJuice = 1; //Need at least 1 juice to get promoted
  bool promoteToFounder = false;
  Iterable<Creature> subordinates = pool.where((p) => p.hireId == cr.id);
  //Need REVOLUTIONARY (100+) juice to take over founder role
  if (cr.hireId == null) {
    requiredJuice = 100;
    promoteToFounder = true;
  }
  Iterable<Creature> eligibleSubordinates = subordinates.where((p) =>
      p.alive &&
      p.align == Alignment.liberal &&
      !p.brainwashed &&
      (!p.seduced || p.juice >= 100));
  for (Creature candidate in eligibleSubordinates) {
    if (candidate.juice > requiredJuice) {
      requiredJuice = candidate.juice;
      newboss = candidate;
    }
  }

  //No subordinates or none with sufficient juice to carry on
  if (subordinates.isEmpty || newboss == null) {
    if (promoteToFounder &&
        subordinates.isNotEmpty) // Disintegration of the LCS
    {
      erase();
      mvaddstrc(8, 1, white, "${cr.name} has died.");
      await getKey();
      mvaddstr(10, 1,
          "There are none left with the courage and conviction to lead....");
      await getKey();
    }
    return null;
  }

  //Chain of command totally destroyed if dead person's boss also dead
  if (bigboss?.alive != true && !promoteToFounder) return null;

  //Promote the new boss
  newboss.hireId = cr.hireId;

  //Order secondary subordinates to follow the new boss
  for (Creature p in subordinates) {
    if (p != newboss && !p.seduced) {
      p.hireId = newboss.id;
    }
  }

  erase();

  if (bigboss != null) {
    // Normal promotion
    mvaddstrc(8, 1, white, "${bigboss.name} has promoted ${newboss.name}");
    mvaddstr(9, 1, "due to the death of ${cr.name}.");
    if (subordinates.isNotEmpty) {
      mvaddstr(11, 1, "${newboss.name} will take over for ");
      addstr("${cr.name} in the command chain.");
    }
    await getKey();
  } else {
    // Founder level promotion
    mvaddstrc(8, 1, white, "${cr.name} has died.");
    await getKey();

    mvaddstr(
        10,
        1,
        "${newboss.name} is the new leader "
        "of the Liberal Crime Squad!");
    await getKey();

    cr.hireId = newboss.id; // Make dead founder not founder.
  }
  return newboss;
}

Future<void> _dailyHealing() async {
  // Healing - determine medical support at each location
  Map<Site, int> medical = {}, injuries = {};
  for (Site site in sites) {
    medical[site] = 0;
    injuries[site] = 0;
    // Clinic and lockups are equal to a skill 6 liberal
    if (site.type == SiteType.clinic) medical[site] = 6;
    if (site.type == SiteType.policeStation) medical[site] = 6;
    if (site.type == SiteType.courthouse) medical[site] = 6;
    if (site.type == SiteType.prison) medical[site] = 6;
    // Hospital is equal to a skill 12 liberal
    if (site.type == SiteType.universityHospital) medical[site] = 12;
  }
  for (Creature p in pool) {
    // First pass is to identify medics
    if (!p.alive) continue;
    if (p.inHiding) continue;
    if (p.sleeperAgent) continue;
    if (p.site != null) {
      // Don't let starving locations heal
      if (p.site!.foodDaysLeft < 1 && p.site!.siege.underSiege) continue;
      // Anyone present can help heal, but only the highest skill matters
      if ((medical[p.site] ?? 0) < p.skill(Skill.firstAid)) {
        medical[p.site!] = p.skill(Skill.firstAid);
      }
    }
  }

  //HEAL NON-CLINIC PEOPLE AND TRAIN
  for (Creature p in pool) {
    if (!p.alive) continue;
    if (clinictime(p) > 0 && p.clinicMonthsLeft == 0) {
      // For people in LCS home treatment
      int damage = 0; // Amount health degrades
      //int release=1;
      bool transfer = false;
      // Give experience to caretakers
      if (p.site != null) {
        injuries[p.site!] = injuries[p.site]! + p.maxBlood - p.blood;
      }
      // Cap blood at 100-injurylevel*20
      double maxHealingProportion = 1 - (clinictime(p) - 1) * 0.2;
      int maxBlood = (p.maxBlood * maxHealingProportion).round();
      if (p.blood < maxBlood) {
        // Add health
        if (p.site != null) {
          p.blood += 1 + medical[p.site]! ~/ 3;
        }
        if (p.blood > maxBlood) {
          p.blood = maxBlood;
        }
        if (p.blood > p.maxBlood) {
          p.blood = p.maxBlood;
        }
      }
      if (p.alive && p.blood < 0) {
        p.die();
        await showMessage("${p.name} has died of injuries.");
      }
      for (BodyPart w in p.body.parts) {
        // Limbs blown off
        if (w.nastyOff) {
          // Chance to stabilize/amputate wound
          // Difficulty 12 (Will die if not treated)
          if (p.site != null && medical[p.site]! + lcsRandom(10) > 12) {
            w.cleanOff = true;
            w.nastyOff = false;
          } else {
            // Else take bleed damage (4)
            damage += 4;
            if (p.site != null && medical[p.site]! + 9 <= 12) {
              transfer = true; // Impossible to stabilize
            }
          }
        } else if (w.bleeding > 0) {
          // Bleeding wounds
          // Chance to stabilize wound
          // Difficulty 8 (1 in 10 of happening naturally)
          if (p.site != null && (medical[p.site] ?? 0) + lcsRandom(10) > 8) {
            w.bleeding = 0;
          } else {
            // Else take bleed damage (1)
            damage += 1;
            w.bleeding = max(0, w.bleeding - 1);
          }
        }
        // Non-bleeding wounds
        else {
          // Erase wound if almost fully healed, but preserve loss of limbs.
          if (p.blood >= p.maxBlood - 5) {
            w.heal();
          }
        }
      }
      if (p.body is HumanoidBody) {
        // Handle major injuries
        HumanoidBody body = p.body as HumanoidBody;
        bool handleInjury(
            {bool possiblePermanentDamage = true,
            int extraDifficulty = 0,
            int extraBleed = 0}) {
          Site? site = p.site;
          int medicalValue = medical[site] ?? 0;
          if (site != null) {
            injuries[p.site!] = injuries[p.site]! + 25;
          }
          // Notably, return false if the injury is stabilized, true
          // if it remains untreated.
          if (p.site != null &&
              medicalValue + lcsRandom(10) > (14 + extraDifficulty)) {
            return false; // stabilized
          } else {
            if (possiblePermanentDamage) {
              if (p.site != null && lcsRandom(20) > medicalValue) {
                p.permanentHealthDamage++;
              }
            }
            damage += 1 + extraBleed;
            if (medicalValue + 9 <= 14 + extraDifficulty) {
              transfer = true;
            }
            return true;
          }
        }

        // Critical hit wounds
        if (body.puncturedHeart) {
          body.puncturedHeart = handleInjury(
              extraDifficulty: 2, extraBleed: 8, possiblePermanentDamage: true);
        }
        if (body.puncturedRightLung) {
          body.puncturedRightLung = handleInjury(possiblePermanentDamage: true);
        }
        if (body.puncturedLeftLung) {
          body.puncturedLeftLung = handleInjury(possiblePermanentDamage: true);
        }
        if (body.puncturedLiver) {
          body.puncturedLiver = handleInjury();
        }
        if (body.puncturedStomach) {
          body.puncturedStomach = handleInjury();
        }
        if (body.puncturedRightKidney) {
          body.puncturedRightKidney = handleInjury();
        }
        if (body.puncturedLeftKidney) {
          body.puncturedLeftKidney = handleInjury();
        }
        if (body.puncturedSpleen) {
          body.puncturedSpleen = handleInjury();
        }
        if (body.ribs < body.maxRibs) {
          if (!handleInjury()) {
            body.ribs = body.maxRibs;
          }
        }
        if (body.neck == InjuryState.untreated) {
          body.neck =
              handleInjury() ? InjuryState.untreated : InjuryState.treated;
        }
        if (body.upperSpine == InjuryState.untreated) {
          body.upperSpine =
              handleInjury() ? InjuryState.untreated : InjuryState.treated;
        }
        if (body.lowerSpine == InjuryState.untreated) {
          body.lowerSpine =
              handleInjury() ? InjuryState.untreated : InjuryState.treated;
        }
      }

      // Apply damage
      p.blood -= damage;
      if (p.blood < damage) {
        transfer = true; // Imminent risk of death; force hospital visit
      }
      if (transfer &&
          p.site != null &&
          p.alive &&
          p.align == Alignment.liberal &&
          p.site!.controller == SiteController.lcs &&
          p.site!.type != SiteType.universityHospital) {
        setColor(white);
        mvaddstr(8, 1, "${p.name}'s injuries require professional treatment.");
        p.activity = Activity(ActivityType.clinic);
        await getKey();
      }
    }
  }
  //Give experience to medics
  for (Creature p in pool) {
    //If present, qualified to heal, and doing so
    if (p.site != null) {
      //Clear activity if their location doesn't have healing work to do
      if ((injuries[p.site] ?? 0) > 0) {
        //Give experience based on work done and current skill
        p.train(Skill.firstAid, min(50, max(injuries[p.site]! ~/ 5, 1)));
      }
    }
  }
}

/* daily - manages too hot timer and when a site map should be re-seeded and renamed */
Future<void> advanceLocations() async {
  //ADVANCE LOCATIONS
  for (Site l in sites) {
    if (l.closed > 0) {
      l.closed--;
      if (l.closed == 0) {
        //Clean up graffiti, patch up walls, restore fire damage
        l.changes.clear();

        //If high security is supported, chance to throw guards everywhere
        if (securityable(l.type) > 0 && oneIn(2)) {
          l.highSecurity = 60;
        }
        //Else remodel the location, invalidate maps
        else {
          await initsite(l);
        }
      }
    } else if (l.highSecurity > 0) {
      // Bank will remain on high security much longer
      if (l.type != SiteType.bank || oneIn(5)) {
        l.highSecurity--;
      }
    }
  }
}

Future<void> _doRent() async {
  if (day == 3 && !disbanding) {
    for (Site l in sites) {
      if (l.controller == SiteController.lcs && !l.newRental) {
        // if rent >= 1000000 this means you get should kicked out automatically
        if (ledger.funds >= l.rent && l.rent < 1000000) {
          ledger.subtractFunds(l.rent, Expense.rent);
        } else {
          //EVICTED!!!!!!!!!
          await showMessage(
              "EVICTION NOTICE: ${l.name}.  Possessions dumped on the street.");

          l.controller = SiteController.unaligned;

          Site hs = findSiteInSameCity(l.city, SiteType.homelessEncampment)!;
          //MOVE ALL ITEMS AND SQUAD MEMBERS
          for (Creature p in pool) {
            if (p.location == l) p.location = hs;
            if (p.base == l) p.base = hs;
          }
          hs.addLootAndProcessMoney(l.loot);

          l.compound = Compound();
          l.compound.rations = 0;
          l.businessFront = false;
        }
      }
    }
  }
}
