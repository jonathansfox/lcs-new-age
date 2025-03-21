/* siege - gives up on sieges with empty locations */
/* Work in progress. It works, but needs to be called in more places. */
/* Currently, it only works when you confront a siege and then fail. */
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/chase_sequence.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/miscactions.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemode.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* siege - updates upcoming sieges */
Future<void> siegeCheck() async {
  if (disbanding) return;

  // Upkeep - even base-less should be considered.
  // XXX - candidate to create nice function?
  // Cleanse record on things that aren't illegal right now
  for (Creature p in pool) {
    if (laws[Law.flagBurning]! > DeepAlignment.moderate) {
      p.wantedForCrimes[Crime.flagBurning] = 0;
    }
    if (laws[Law.drugs]! > DeepAlignment.moderate) {
      p.wantedForCrimes[Crime.drugDistribution] = 0;
    }
    if (laws[Law.immigration] == DeepAlignment.eliteLiberal) {
      p.wantedForCrimes[Crime.illegalEntry] = 0;
    }
    if (laws[Law.freeSpeech]! > DeepAlignment.archConservative) {
      p.wantedForCrimes[Crime.unlawfulSpeech] = 0;
    }
  }

  Creature? ceoSleeper = pool.firstWhereOrNull(
      (p) => p.sleeperAgent && p.type.id == CreatureTypeIds.corporateCEO);
  //FIRST, THE COPS
  int numpres;
  for (City c in cities) {
    List<Site> sites = c.sites.toList();
    Site? policeStation =
        sites.firstWhereOrNull((s) => s.type == SiteType.policeStation);
    if (policeStation == null) continue;
    bool policeChiefCompromised = pool.any((p) =>
        p.sleeperAgent &&
        p.locationId == policeStation.idString &&
        p.type.id == CreatureTypeIds.policeChief);
    List<Site> safehouses =
        sites.where((s) => s.controller == SiteController.lcs).toList();
    for (Site l in safehouses) {
      if (policeStation.isClosed) {
        l.heat = (l.heat * 0.95).floor();
        continue;
      }
      if (l.siege.underSiege) continue;
      if (policeChiefCompromised) {
        l.heat = (l.heat * 0.95).floor();
      }
      numpres = 0;
      // CHECK FOR CRIMINALS AT THIS BASE
      int crimes = 0;
      for (Creature p in l.creaturesPresent) {
        // Sleepers and people not at this base don't count
        if (p.sleeperAgent || p.inHiding) continue;

        // Corpses attract attention
        if (!p.alive) {
          crimes += 5;
          continue;
        }

        // Kidnapped persons increase heat
        if (p.kidnapped && p.align != Alignment.liberal) {
          crimes += 5 * p.daysSinceJoined;
          continue;
        }

        // Non-liberals don't count other than that
        if (p.align != Alignment.liberal) continue;

        numpres++;

        // Accumulate heat from liberals who have it,
        // but let them bleed it off in the process
        if (p.heat > 0) {
          crimes += (p.heat / 10).ceil();
          p.heat -= min(max(4, p.heat ~/ 200), p.heat);
        }
      }

      // Update location heat
      l.heat += ((crimes - l.heat - l.heatProtection) / 10).ceil();
      if (l.heat < 0) l.heat = 0;

      int huntingSpeed = 0;
      if (l.heat > l.heatProtection) {
        if (l.heatProtection == 0) {
          huntingSpeed = 5;
        } else {
          huntingSpeed = max(1, min(l.heat ~/ l.heatProtection, 5));
        }
        if (policeChiefCompromised) {
          huntingSpeed = 1;
        }
      }
      if (l.siege.timeUntilCops > 0) {
        l.siege.timeUntilCops = l.siege.timeUntilCops - 1;
      } else if (l.siege.timeUntilCops < -1) {
        // Reduce the cooldown between raids
        l.siege.timeUntilCops = l.siege.timeUntilCops + 1;
      } else if (l.siege.timeUntilCops == -1) {
        // Begin planning siege if high heat on location
        if (huntingSpeed > 0 && (oneIn(60 ~/ huntingSpeed))) {
          // Set time until siege is carried out
          l.siege.timeUntilCops += 2 + lcsRandom(6);

          bool policeSleeperWarning = pool.any(
              (p) => p.sleeperAgent && p.locationId == policeStation.idString);

          if (policeSleeperWarning) {
            erase();
            mvaddstrc(8, 1, white,
                "You have received advance warning from one of your agents regarding ");
            mvaddstr(9, 1,
                "a government raid on the ${l.getName(includeCity: true)}.");

            int y = 11;
            if (l.siege.escalationState == SiegeEscalation.police) {
              if (deathSquadsActive) {
                mvaddstr(y++, 1,
                    "The police are planning to deploy heavily armed Death Squad units.");
                mvaddstr(y++, 1,
                    "They are ready to use lethal force if there is any hint of resistance.");
              } else {
                mvaddstr(y++, 1,
                    "The police are planning to deploy heavily armed SWAT units.");
                mvaddstr(y++, 1,
                    "Anyone present not suspected of a crime will be processed and released.");
                mvaddstr(y++, 1,
                    "Resistance will be met with lethal force if necessary.");
              }
            } else if (l.siege.escalationState ==
                SiegeEscalation.nationalGuard) {
              mvaddstr(y++, 1,
                  "The police have handed over planning to the National Guard.");
              mvaddstr(y++, 1,
                  "They are planning to surround the compound with soldiers.");
            } else {
              mvaddstr(y++, 1,
                  "The National Guard is mustering additional resources.");
            }
            if (l.siege.escalationState.index >= SiegeEscalation.tanks.index) {
              mvaddstr(y++, 1,
                  "An M1 Abrams Tank will be deployed to enforce the siege.");
            }
            if (l.siege.escalationState.index >=
                SiegeEscalation.bombers.index) {
              mvaddstr(y++, 1,
                  "Aircraft will bomb the compound to weaken the defenses.");
              mvaddstr(y++, 1,
                  "Special forces will be brought in handle the final assault.");
            }

            y++;
            mvaddstr(y++, 1,
                "The operation is scheduled to take place some time in the next week.");
            mvaddstr(y++, 1, "Press Esc to ponder the situation...");
            int c;
            do {
              c = await getKey();
            } while (c != Key.x && c != Key.escape);
          }
        }
      }

      //COPS RAID THIS LOCATION
      if (l.siege.timeUntilCops == 0) {
        l.siege.timeUntilCops = -5;
        l.heat = 0;

        if (numpres > 0) {
          erase();
          if (l.type == SiteType.homelessEncampment) {
            mvaddstrc(
                8, 1, white, "The police are sweeping the ${l.getName()}!");
            l.siege.underAttack = true;
          } else {
            mvaddstrc(
                8, 1, white, "The police have surrounded the ${l.getName()}!");
            l.siege.underAttack = false;
          }

          await getKey();

          //MENTION ESCALATION STATE
          if (l.siege.escalationState.index >=
              SiegeEscalation.nationalGuard.index) {
            mvaddstr(
                9, 1, "National Guard troops are replacing normal SWAT units.");
            await getKey();
          }
          if (l.siege.escalationState.index >= SiegeEscalation.tanks.index) {
            move(10, 1);
            if (l.compound.bollards) {
              addstr("An M1 Abrams Tank is stopped by the tank traps.");
            } else {
              addstr(
                  "An M1 Abrams Tank takes up position outside the compound.");
            }
            await getKey();
          }
          if (l.siege.escalationState.index >= SiegeEscalation.bombers.index) {
            mvaddstr(11, 1, "You hear jet bombers streak overhead.");
            await getKey();
          }

          // "You are wanted for blahblah and other crimes."
          await stateBrokenLaws(l);
          l.siege.activeSiegeType = SiegeType.police;
          l.siege.lightsOff = false;
          l.siege.camerasOff = false;
        } else {
          erase();
          if (l.type == SiteType.homelessEncampment) {
            mvaddstrc(8, 1, white,
                "The cops have raided the ${l.getName()}.  No LCS members were present.");
          } else {
            mvaddstrc(8, 1, white,
                "The cops have raided the ${l.getName()}, an unoccupied safehouse.");
          }
          await getKey();

          int y = 9;
          for (Creature p in l.creaturesPresent.toList()) {
            if (!p.alive) {
              move(y++, 1);
              addstr("${p.name}'s corpse has been recovered.");
              await getKey();
              pool.remove(p);
              continue;
            }
            if (p.align != Alignment.liberal) {
              move(y++, 1);
              addstr("${p.name} has been rescued.");
              await getKey();
              pool.remove(p);
              p.location = p.workLocation;
              continue;
            }
          }
          l.loot.clear();
          vehiclePool.removeWhere((v) => v.location == l);
        }
      }

      //OTHER OFFENDABLE ENTITIES
      //CORPS
      if (l.heat > l.heatProtection &&
          l.siege.timeuntilcorps == -1 &&
          !l.siege.underSiege &&
          offendedCorps &&
          oneIn(60) &&
          numpres > 0) {
        l.siege.timeuntilcorps = lcsRandom(3) + 1;

        // CEO sleepers may give a warning before corp raids
        if (ceoSleeper != null || oneIn(5)) {
          erase();
          mvaddstrc(8, 1, white, "You have received ");
          if (ceoSleeper != null) {
            addstr("a warning from ${ceoSleeper.name} ");
          } else {
            addstr("an anonymous tip");
          }
          addstr(" that several Corporations ");
          mvaddstr(9, 1, "are hiring mercenaries to attack ");
          if (ceoSleeper != null) {
            addstr(l.getName(includeCity: true));
          } else {
            addstr("the LCS.");
          }
          await getKey();
        }
      } else if ((l.siege.timeuntilcorps > 0) && !l.siege.underSiege) {
        // Corp raid countdown!
        l.siege.timeuntilcorps--;
      } else if (l.siege.timeuntilcorps == 0 &&
          !l.siege.underSiege &&
          offendedCorps &&
          numpres > 0) {
        // Corps raid!
        erase();
        mvaddstrc(8, 1, white,
            "Corporate mercenaries are raiding the ${l.getName()}!");
        await getKey();

        l.siege.activeSiegeType = SiegeType.corporateMercs;
        l.siege.underAttack = true;
        l.siege.lightsOff = false;
        l.siege.camerasOff = false;
        offendedCorps = false;
        l.siege.timeuntilcorps = -1;
      } else if (l.siege.timeuntilcorps == 0) {
        // Silently call off foiled corp raids
        l.siege.timeuntilcorps = -1;
      }

      //CONSERVATIVE CRIME SQUAD
      if (ccsActive && ccsState.index >= CCSStrength.sieges.index) {
        if (l.heat > l.heatProtection &&
            l.siege.timeuntilccs == -1 &&
            !l.siege.underSiege &&
            oneIn(60) &&
            numpres > 0) {
          l.siege.timeuntilccs = lcsRandom(3) + 1;
          // CCS sleepers may give a warning before raids
          Creature? ccsSleeper =
              pool.firstWhereOrNull((p) => p.sleeperAgent && p.type.ccsMember);
          if (ccsSleeper != null) {
            erase();
            mvaddstrc(8, 1, white,
                "You have received warning from ${ccsSleeper.name} that the CCS ");
            mvaddstr(9, 1, "is gearing up to attack ${l.name}.");
            await getKey();
          }
        } else if (l.siege.timeuntilccs > 0) {
          // CCS raid countdown!
          l.siege.timeuntilccs--;
        } else if (l.siege.timeuntilccs == 0 &&
            !l.siege.underSiege &&
            numpres > 0) {
          l.siege.timeuntilccs = -1;
          // CCS raid!
          erase();
          mvaddstrc(
              8, 1, white, "A screeching truck pulls up to ${l.getName()}!");
          await getKey();

          if (!l.compound.bollards && oneIn(5)) {
            // CCS Carbombs safehouse!!
            erase();
            mvaddstrc(
                8, 1, red, "The truck plows into the building and explodes!");
            await getKey();

            erase();
            mvaddstrc(0, 1, white, "CCS CAR BOMBING CASUALTY REPORT");

            mvaddstr(2, 1, "KILLED: ");
            int killedY = 2;
            int killedX = 9;

            mvaddstr(6, 1, "INJURED: ");
            int injuredY = 6;
            int injuredX = 10;

            for (int i = 0; i < pool.length; i++) {
              if (pool[i].location == l) {
                if (oneIn(2)) {
                  int namelength = pool[i].name.length;
                  pool[i].blood -=
                      lcsRandom(max(1, 101 - pool[i].juice ~/ 10)) + 10;
                  if (pool[i].blood < 0) {
                    if (killedX + namelength > 78) {
                      killedY++;
                      killedX = 1;
                      //Add limit for killed_y.
                    }
                    move(killedY, killedX);
                    pool[i].die();
                    setColor(pool[i].align.color);
                    addstr("${pool[i].name}, ");
                    killedX += namelength + 2;
                  } else {
                    if (injuredX + namelength > 78) {
                      injuredY++;
                      injuredX = 1;
                      //Add limit for injured_y.
                    }
                    move(injuredY, injuredX);
                    setColor(pool[i].align.color);
                    addstr("${pool[i].name}, ");
                    injuredX += namelength + 2;
                  }
                }
              }
            }

            await getKey();
          } else {
            // CCS Raids safehouse
            erase();
            mvaddstrc(8, 1, red,
                "CCS members pour out of the truck and shoot in the front doors!");
            await getKey();

            l.siege.activeSiegeType = SiegeType.ccs;
            l.siege.underAttack = true;
            l.siege.lightsOff = false;
            l.siege.camerasOff = false;
          }
        } else if (l.siege.timeuntilccs == 0) {
          l.siege.timeuntilccs = -1; // Silently call off foiled ccs raids
        }
      }

      //CIA
      if (l.heat > l.heatProtection / 2 &&
          l.siege.timeuntilcia == -1 &&
          !l.siege.underSiege &&
          offendedCia &&
          oneIn(60) &&
          numpres > 0) {
        l.siege.timeuntilcia = lcsRandom(3) + 1;
        Creature? agentsleeper = pool.firstWhereOrNull(
            (p) => p.sleeperAgent && p.type.id == CreatureTypeIds.agent);
        if (agentsleeper != null) {
          erase();
          mvaddstrc(8, 1, white,
              "${agentsleeper.name} has sent word that the CIA is planning ");
          mvaddstr(9, 1, "to launch an attack on ${l.getName()}!");
          await getKey();
        }
      } else if (l.siege.timeuntilcia > 0) {
        l.siege.timeuntilcia--; // CIA raid countdown!
      } else if (l.siege.timeuntilcia == 0 &&
          !l.siege.underSiege &&
          offendedCia &&
          numpres > 0) {
        l.siege.timeuntilcia = -1;
        // CIA raids!
        erase();
        mvaddstrc(8, 1, white,
            "In the dead of the night, a column of unmarked black vans surround the ${l.getName()}.");
        int y = 10;
        await getKey();
        mvaddstr(y++, 1,
            "Hair stands on end... the air is charged with the sound of silence.");
        if (l.compound.cameras) {
          mvaddstr(y++, 1, "The camera feeds are dead.");
        }
        if (l.compound.generator) {
          mvaddstr(y++, 1, "The generator won't start.");
        }
        if (l.compound.solarPanels) {
          mvaddstr(
              y++, 1, "The solar batteries are suddenly reporting no charge.");
        }
        mvaddstr(y++, 1,
            "The compound is plunged into darkness as the doors spontaneously unlock.");
        y++;
        mvaddstr(y++, 1, "The CIA has arrived.");
        await getKey();

        l.siege.activeSiegeType = SiegeType.cia;
        l.siege.underAttack = true;
        l.siege.lightsOff = true;
        l.siege.camerasOff = true;
      } else if (l.siege.timeuntilcia == 0) {
        l.siege.timeuntilcia = -1; // Silently call off foiled cia raids
      }

      //HICKS
      if (l.heat > l.heatProtection &&
          !l.siege.underSiege &&
          offendedHicks &&
          oneIn(120) &&
          numpres > 0) {
        erase();
        mvaddstrc(8, 1, white,
            "Masses dissatisfied with your lack of respect for right-wing media");
        mvaddstr(9, 1, "are storming the ${l.getName()}!");
        await getKey();

        l.siege.activeSiegeType = SiegeType.hicks;
        l.siege.underAttack = true;
        l.siege.lightsOff = false;
        l.siege.camerasOff = false;
        offendedHicks = false;
      }
    }
  }
}

/* siege - updates sieges in progress */
Future<void> siegeTurn() async {
  if (disbanding) return;

  for (Site l in sites.where((l) => l.siege.underSiege)) {
    int liberalcount = pool
        .where(
            (p) => p.location == l && p.align == Alignment.liberal && p.alive)
        .length;

    //resolve sieges with no people
    if (liberalcount == 0) {
      erase();
      setColor(white);

      mvaddstr(8, 1,
          "Conservatives have raided the ${l.getName()}, an unoccupied safehouse.");

      if (l.siege.activeSiegeType == SiegeType.ccs &&
          l.type == SiteType.warehouse) {
        l.controller = SiteController.ccs; // CCS Captures warehouse
      }

      await getKey();

      int y = 9;

      for (int i = pool.length - 1; i >= 0; i--) {
        Creature p = pool[i];
        if (p.location != l) continue;
        if (!p.alive) {
          mvaddstr(y++, 1, p.name);
          addstr("'s corpse has been recovered.");
          await getKey();
          pool.remove(p);
          continue;
        }
        if (p.align != Alignment.liberal) {
          mvaddstr(y++, 1, "${p.name} has been rescued.");
          await getKey();
          pool.remove(p);
          continue;
        }
      }

      for (int v = vehiclePool.length - 1; v >= 0; v--) {
        if (vehiclePool[v].locationId == l.id) vehiclePool.removeAt(v);
      }

      l.siege.activeSiegeType = SiegeType.none;
    }

    if (!l.siege.underAttack) {
      //EAT
      bool starving = false;
      int eaters = l.numberEating;
      if (l.compound.rations == 0 && eaters > 0) {
        starving = true;
        await showMessage("Your Liberals are starving!");
      }
      if (l.compound.rations >= eaters) {
        l.compound.rations -= eaters;
      } else {
        l.compound.rations = 0;
      }

      for (Creature p in pool) {
        if (!p.alive || p.location != l) continue;

        if (starving) p.blood -= lcsRandom(8) + 4;

        // Check if liberal starved to death.
        if (p.blood <= 0) {
          p.die();
          await showMessage("${p.name} has starved to death.");
        }
      }

      String cops =
          l.siege.escalationState == SiegeEscalation.police ? "cops" : "troops";

      //ATTACK!
      bool attack = false;
      if (oneIn(12)) attack = true;

      if (attack) {
        await showMessage(
            "The $cops are moving in! They're about to breach the front door!");
        l.siege.underAttack = true;
      } else {
        bool nothingBadHappened = true;

        //CUT LIGHTS
        if (!l.siege.lightsOff &&
            !(l.compound.generator || l.compound.solarPanels) &&
            oneIn(10)) {
          nothingBadHappened = false;
          await showMessage("The $cops have cut the lights!");
          l.siege.lightsOff = true;
        }

        //SNIPER
        if (!l.compound.fortified && oneIn(2)) {
          nothingBadHappened = false;

          Creature? target = pool
              .where((p) =>
                  p.location == l && p.alive && p.align == Alignment.liberal)
              .randomOrNull;
          if (target != null) {
            if (lcsRandom(100) > target.juice) {
              await showMessage("A sniper takes out ${target.name}!");
              if (target.align == Alignment.liberal) {
                liberalcount--;
              }
              target.squad = null;
              target.die();
            } else {
              await showMessage("A sniper nearly hits ${target.name}!");
            }
          }
        }

        if (l.siege.escalationState.index >= SiegeEscalation.bombers.index) {
          nothingBadHappened = false;
          //AIR STRIKE!
          bool hit = true;
          await showMessage("Planes streak overhead!");

          bool hasAAGun = l.compound.aaGun;
          bool hasGenerator = l.compound.generator;
          bool hasSolarPanels = l.compound.solarPanels;

          if (hasAAGun) {
            await showMessage(
                "The thunder of the anti-aircraft gun shakes the compound!");
            if (!oneIn(5)) {
              hit = false;
              if (oneIn(2)) {
                await showMessage(
                    "You didn't shoot any down, but you did hold them off.");
              } else {
                await showMessage(
                    "Hit! One of the bombers slams into to the ground.");
                await showMessage(
                    "It's all over the TV. Everyone in the Liberal Crime Squad gains 20 juice!");
                for (Creature p in pool) {
                  addjuice(p, 20, 1000);
                }
              }
            } else {
              await showMessage("A skilled pilot gets through!");
            }
          }

          if (hit) {
            await showMessage("Explosions rock the compound!");

            if (hasAAGun && oneIn(3)) {
              await showMessage("The anti-aircraft gun takes a direct hit!");
              await showMessage("There's nothing left but smoking wreckage...");
              l.compound.aaGun = false;
            } else if (hasSolarPanels) {
              await showMessage("The solar panels take a direct hit!");
              if (!hasGenerator) {
                await showMessage("The lights fade and all goes dark...");
                l.siege.lightsOff = true;
              }
              l.compound.solarPanels = false;
            } else if (hasGenerator && oneIn(3)) {
              await showMessage("The generator takes a direct hit!");
              if (!hasSolarPanels) {
                await showMessage("The lights fade and all goes dark...");
                l.siege.lightsOff = true;
              }
              l.compound.generator = false;
            }
            if (oneIn(2)) {
              Creature? victim =
                  pool.where((p) => p.location == l && p.alive).randomOrNull;
              if (victim != null) {
                if (lcsRandom(100) > victim.juice) {
                  await showMessage("The blast kills ${victim.name}!");
                  if (victim.align == Alignment.liberal) {
                    liberalcount--;
                  }
                  victim.squad = null;
                  victim.die();
                } else {
                  await showMessage("${victim.name} narrowly avoids death!");
                }
              }
            } else {
              await showMessage("Fortunately, no one was hurt.");
            }
          }
        }

        if (l.compound.bollards &&
            l.siege.escalationState.index >= SiegeEscalation.tanks.index &&
            oneIn(15)) {
          nothingBadHappened = false;

          //ENGINEERS
          await showMessage(
              "Army engineers detonate explosives and destroy the bollards!");
          await showMessage(
              "The tank moves forward to your compound entrance.");
          l.compound.bollards = false;
        }

        //NEED GOOD THINGS TO BALANCE THE BAD

        // ELITE REPORTER SNEAKS IN
        if (oneIn(20) && nothingBadHappened && liberalcount > 0) {
          FullName repname = generateFullName();
          String newsType = [
            "news program",
            "news magazine",
            "website",
            "scandal rag",
            "newspaper"
          ].random;
          String newsNameA = [
            "Daily", "Nightly", "Current", "Pressing", //
            "Socialist", "American", "National", "Union",
            "Foreign", "Associated", "International", "County",
          ].random;
          String newsNameB = [
            "Reporter", "Issue", "Take", "Constitution", //
            "Times", "Post", "News", "Affair",
            "Statesman", "Star", "Inquirer",
          ].random;

          erase();
          setColor(lightGray);
          mvaddstr(
              1, 1, "Elite Journalist ${repname.firstLast} from the $newsType");
          mvaddstr(
              2, 1, "$newsNameA $newsNameB got into the compound somehow!");
          await getKey();

          int best = 0;
          for (int i = 0, bestvalue = -1000; i < pool.length; i++) {
            Creature p = pool[i];
            if (!p.alive || p.align != Alignment.liberal || p.location != l) {
              continue;
            }

            int sum = p.attribute(Attribute.intelligence) +
                p.attribute(Attribute.heart) +
                p.skill(Skill.persuasion) +
                p.juice;

            if (sum > bestvalue) {
              best = i;
              bestvalue = sum;
            }
          }

          mvaddstr(4, 1, "${pool[best].name} decides to give an interview.");
          await getKey();

          mvaddstr(6, 1,
              "The interview is wide-ranging, covering a variety of topics.");
          await getKey();

          int segmentpower = pool[best].attributeRoll(Attribute.intelligence) +
              pool[best].attributeRoll(Attribute.heart) +
              pool[best].skillRoll(Skill.business, take10: true) +
              pool[best].skillRoll(Skill.religion, take10: true) +
              pool[best].skillRoll(Skill.law, take10: true) +
              pool[best].skillRoll(Skill.science, take10: true) +
              pool[best].skillRoll(Skill.persuasion) +
              pool[best].skillRoll(Skill.persuasion);

          move(8, 1);
          if (segmentpower < 35) {
            String playName = "${[
              "Flaming",
              "Dumb",
              "Retarded",
              "Insane",
              "Crazy",
              "Loopy",
              "Idiot",
              "Empty-Headed",
              "Nutty",
              "Half-Baked",
              "Pot-Smoking",
              "Stoner",
            ].random} ${[
              "Liberal",
              "Socialist",
              "Anarchist",
              "Communist",
              "Marxist",
              "Green",
              "Elite",
              "Guerrilla",
              "Commando",
              "Soldier",
            ].random}";
            addstr(repname.firstLast);
            addstr(" canceled the interview halfway through");
            mvaddstr(
                9, 1, "and later used the material for a Broadway play called");
            mvaddstr(10, 1, "$playName.");
          } else if (segmentpower < 40) {
            addstr(
                "But the interview is so boring that ${repname.firstLast} falls asleep.");
          } else if (segmentpower < 45) {
            addstr("But ${pool[best].name} stutters nervously the whole time.");
          } else if (segmentpower < 50) {
            addstr(
                "${pool[best].name}'s verbal finesse leaves something to be desired.");
          } else if (segmentpower < 65) {
            addstr("${pool[best].name} represents the LCS well.");
          } else if (segmentpower < 80) {
            addstr("The discussion was exciting and dynamic.");
            mvaddstr(9, 1,
                "Even the Cable News and AM Radio spend days talking about it.");
          } else {
            addstr(
                "${repname.firstLast} later went on to win a Pulitzer for it.");
            mvaddstr(9, 1,
                "Virtually everyone in America was moved by ${pool[best].name}'s words.");
          }

          await getKey();

          //CHECK PUBLIC OPINION
          changePublicOpinion(View.lcsKnown, 20);
          changePublicOpinion(View.lcsLiked, (segmentpower - 45) ~/ 2);
          for (int v = 0; v < 5; v++) {
            changePublicOpinion(View.issues.random, (segmentpower - 45) ~/ 2);
          }
        }
      }
      // single blank line after every siege day
    } // end if(!l.siege.underAttack)
  } // end for(l=0;l<location.length;l++) if(l.siege.underSiege)
}

/* siege - handles giving up */
Future<void> siegeDefeat() async {
  Site? loc = activeSafehouse ?? activeSquad?.members.firstOrNull?.base;
  if (loc == null) return;

  if (loc.controller == SiteController.lcs && loc.rent > 1) {
    loc.controller = SiteController.unaligned;
  }

  //IF POLICE, END SIEGE
  if (loc.siege.activeSiegeType == SiegeType.police) {
    Site? policeStation = findSiteInSameCity(loc.city, SiteType.policeStation);

    //END SIEGE
    erase();
    setColor(white);
    move(1, 1);
    if (loc.siege.escalationState == SiegeEscalation.police) {
      addstr("The police");
    } else {
      addstr("The soldiers");
    }
    addstr(" confiscate everything, including Squad weapons.");

    int kcount = 0, pcount = 0, icount = 0;
    String? kname, pname, pcname;
    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (p.location != loc || !p.alive) continue;

      if ((p.wantedForCrimes[Crime.illegalEntry] ?? 0) > 0) icount++;

      if (p.missing && p.align == Alignment.conservative) {
        kcount++;
        kname = p.properName;
        if (p.type.preciousToHicks) {
          offendedHicks = true;
        }
        p.activity = Activity.none();
      }
    }

    //CRIMINALIZE POOL IF FOUND WITH KIDNAP VICTIM OR ALIEN
    if (kcount > 0) {
      criminalizeAll(pool.where((p) => p.isActiveLiberal && p.location == loc),
          Crime.kidnapping);
    }
    if (icount > 0) {
      criminalizeAll(pool.where((p) => p.isActiveLiberal && p.location == loc),
          Crime.harboring);
    }

    //LOOK FOR PRISONERS (MUST BE AFTER CRIMINALIZATION ABOVE)
    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (p.location != loc || !p.alive) continue;

      if (p.isCriminal && !(p.missing && p.align == Alignment.conservative)) {
        pcount++;
        pname = p.properName;
        pcname = p.name;
      }
    }

    if (kcount == 1) {
      mvaddstr(3, 1, "$kname is rehabilitated and freed.");
    }
    if (kcount > 1) {
      mvaddstr(3, 1, "The kidnap victims are rehabilitated and freed.");
    }
    if (pcount == 1) {
      mvaddstr(5, 1, pname!);
      if (pname != pcname) {
        addstr(", aka $pcname,");
        move(6, 1);
      } else {
        addstr(" ");
      }
      addstr("is taken to the police station.");
    }
    if (pcount > 1) {
      mvaddstr(5, 1, "$pcount Liberals are taken to the police station.");
    }
    if (ledger.funds > 0) {
      if (ledger.funds <= 2000) {
        mvaddstr(8, 1, "Fortunately, your funds remain intact.");
      } else {
        int confiscated = lcsRandom(lcsRandom(ledger.funds - 2000) + 1) + 1000;
        if (ledger.funds - confiscated > 50000) {
          confiscated += ledger.funds - 30000 - lcsRandom(20000) - confiscated;
        }
        mvaddstr(8, 1,
            "Law enforcement has confiscated \$$confiscated in LCS funds.");
        ledger.subtractFunds(confiscated, Expense.confiscated);
      }
    }
    if (loc.compound.fortified) {
      mvaddstr(10, 1, "The compound fortifications are dismantled.");

      loc.compound.fortified = false;
    }
    if (loc.businessFront) {
      loc.businessFront = false;
      if (!loc.businessFront) {
        mvaddstr(
            12, 1, "Materials relating to the business front have been taken.");
      }
    }

    await getKey();

    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (p.site != loc) continue;

      //ALL KIDNAP VICTIMS FREED REGARDLESS OF CRIMES
      if (p.missing || !p.alive) {
        // Clear actions for anybody who was tending to this person
        for (int i = 0; i < pool.length; i++) {
          if (pool[i].alive &&
              pool[i].activity.type == ActivityType.interrogation &&
              pool[i].activity.idInt == p.id) {
            pool[i].activity.type = ActivityType.none;
          }
        }
        p.squad = null;
        pool.remove(p);
        continue;
      }

      p.dropWeaponAndAmmo();

      if (p.isCriminal) {
        p.squad = null;
        p.location = policeStation;
        p.activity.type = ActivityType.none;
      }
    }

    loc.siege.activeSiegeType = SiegeType.none;
  } else {
    //OTHERWISE IT IS SUICIDE
    int killnumber = 0;
    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (p.location != loc) continue;

      killnumber++;
      p.squad = null;
      p.die();
      p.location = null;
    }

    erase();
    mvaddstrc(1, 1, white, "Everyone in the ${loc.getName()} is slain.");
    await getKey();

    NewsStory.prepare(NewsStories.massacre)
      ..loc = loc
      ..siegetype = loc.siege.activeSiegeType
      ..siegebodycount = killnumber;

    //MUST SET activeSite TO SATISFY checkForDefeat() CODE
    Site? tmp = activeSite;
    activeSite = loc;
    await checkForDefeat();
    activeSite = tmp;

    loc.siege.activeSiegeType = SiegeType.none;
  }

  //CONFISCATE MATERIAL
  loc.loot.clear();
  for (int v = vehiclePool.length - 1; v >= 0; v--) {
    if (vehiclePool[v].location == loc) {
      vehiclePool.removeAt(v);
    }
  }
}

enum SallyForthResult {
  defeated,
  escaped,
  brokeSiege,
}

// Siege -- Mass combat outside safehouse
Future<SallyForthResult> sallyForthPart3(Site loc) async {
  await reloadparty(false);
  Siege siege = loc.siege;
  activeSite = loc;

  encounter.clear();

  if (siege.escalationState == SiegeEscalation.police) {
    if (loc.type == SiteType.homelessEncampment) {
      // Regular cops sweeping the homeless camp
      for (int e = 0; e < ENCMAX - 9; e++) {
        if (deathSquadsActive) {
          encounter.add(Creature.fromId(CreatureTypeIds.deathSquad));
        } else if (gangUnitsActive) {
          encounter.add(Creature.fromId(CreatureTypeIds.gangUnit));
        } else {
          encounter.add(Creature.fromId(CreatureTypeIds.cop));
        }
      }
      // Bystanders that might help out
      prepareEncounter(loc.type, false, addToExisting: true);
      prepareEncounter(loc.type, false, addToExisting: true);
      for (int e = ENCMAX - 9; e < encounter.length; e++) {
        encounter[e].align = Alignment.liberal;
      }
    } else {
      // SWAT teams
      for (int e = 0; e < ENCMAX - 9; e++) {
        encounter.add(Creature.fromId(CreatureTypeIds.swat));
      }
    }
  } else if (siege.escalationState.index >=
      SiegeEscalation.nationalGuard.index) {
    // Military
    for (int e = 0; e < ENCMAX - 9; e++) {
      encounter.add(Creature.fromId(CreatureTypeIds.soldier));
    }
  }
  // M1 Tank
  if (siege.escalationState.index >= SiegeEscalation.tanks.index &&
      !loc.compound.bollards) {
    encounter.add(Creature.fromId(CreatureTypeIds.tank));
  }

  chaseSequence = ChaseSequence(loc);
  ChaseOutcome outcome = await footChaseSequence(
      showStandardText: false, autoPromoteFromSitePool: loc);
  mode = GameMode.base;

  switch (outcome) {
    case ChaseOutcome.escape:
      setColor(white);
      clearMessageArea();
      mvaddstr(16, 1, "You're free!");
      await getKey();
      await escapeSiege(false);
      return SallyForthResult.escaped;
    case ChaseOutcome.capture:
      await siegeDefeat();
      return SallyForthResult.defeated;
    case ChaseOutcome.death:
      await checkForDefeat();
      return SallyForthResult.defeated;
    case ChaseOutcome.victory:
      setColor(white);
      clearMessageArea();
      if (loc.type == SiteType.homelessEncampment) {
        mvaddstr(16, 1, "The camp is saved!");
      } else {
        mvaddstr(16, 1, "The siege is broken!");
      }
      await getKey();
      await conquerText();
      await squadCleanup();
      await escapeSiege(true);
      return SallyForthResult.brokeSiege;
  }
}

Future<void> fightHomelessCampSiege() async {
  Site? loc = activeSafehouse ?? activeSquad?.members.firstOrNull?.site;
  if (loc == null) return;

  //GIVE INFO SCREEN
  erase();
  mvaddstrc(1, 26, red, "UNDER ATTACK: HOMELESS CAMP");

  mvaddstrc(3, 16, lightGray,
      "You are about to mount a defense of the homeless camp.");
  mvaddstr(4, 11, "The enemy is expecting resistance, and you will have to");
  mvaddstr(5, 11, "defeat them all or run away to survive this encounter.");
  mvaddstr(6, 11, "Some agitators are also turning out to resist with you.");

  mvaddstr(8, 11, "Your Squad has filled out to six members if any were ");
  mvaddstr(9, 11, "available.  If you have a larger pool of Liberals, they");
  mvaddstr(10, 11, "will provide cover fire and hang back until needed.");

  mvaddstrc(
      23, 11, red, "Press any key to Confront the Conservative Aggressors");

  await getKey();

  return sallyForthPart2(loc);
}

/* siege - prepares for exiting the siege to fight the attackers head on */
Future<void> sallyForth() async {
  Site? loc = activeSafehouse ?? activeSquad?.members.firstOrNull?.site;
  if (loc == null) return;

  //GIVE INFO SCREEN
  erase();
  mvaddstrc(1, 26, red, "UNDER SIEGE: ESCAPE OR ENGAGE");

  mvaddstrc(3, 16, lightGray,
      "You are about to exit the compound to lift the Conservative");
  mvaddstr(4, 11, "siege on your safehouse.  The enemy is ready for you, and");
  mvaddstr(
      5, 11, "you will have to defeat them all or run away to survive this");
  mvaddstr(6, 11, "encounter.");

  mvaddstr(8, 11, "Your Squad has filled out to six members if any were ");
  mvaddstr(9, 11, "available.  If you have a larger pool of Liberals, they");
  mvaddstr(10, 11, "will provide cover fire from the compound until needed.");

  mvaddstrc(
      23, 11, red, "Press any key to Confront the Conservative Aggressors");

  await getKey();

  return sallyForthPart2(loc);
}

Future<void> sallyForthPart2(Site loc) async {
  //CRIMINALIZE
  if (loc.siege.activeSiegeType == SiegeType.police) {
    criminalizeAll(pool.where((p) => p.isActiveLiberal && p.location == loc),
        Crime.resistingArrest);
  }

  //DELETE ALL SQUADS IN THIS AREA UNLESS THEY ARE THE activeSquad
  for (Squad s in squads
      .where((s) => s != activeSquad && s.members.any((p) => p.location == loc))
      .toList()) {
    for (Creature c in s.members.toList()) {
      c.squad = null;
    }
    squads.remove(s);
  }

  // No squads at the location? Form a new one.
  if (activeSquad == null) {
    squads.add(Squad());
    squads.last.name = "${activeSafehouse!.getName(short: true)} Defense";
    int i = 0;
    for (Creature p in pool) {
      if (p.location == activeSafehouse &&
          p.alive &&
          p.align == Alignment.liberal) {
        squads.last.members.add(p);
        p.squadId = squads.last.id;
        if (++i >= 6) break;
      }
    }
    activeSquad = squads.last;
  }

  //MAKE SURE PARTY IS ORGANIZED
  autopromote(loc);

  //START FIGHTING
  sitestory = NewsStory.prepare(NewsStories.squadEscapedSiege)
    ..positive = 1
    ..loc = loc
    ..siegetype = loc.siege.activeSiegeType;
  SallyForthResult result = await sallyForthPart3(loc);
  if (result == SallyForthResult.brokeSiege) {
    sitestory!.type = NewsStories.squadBrokeSiege;
  }
  // If you fail, make sure the safehouse isn't under siege anymore by
  // forcing you to "give up".
  if (result == SallyForthResult.defeated) {
    cleanGoneSquads();
    activeSafehouse = loc;
    await siegeDefeat();
  }
}

/* siege - prepares for entering site mode to fight the siege */
Future<void> escapeOrEngage() async {
  Site? loc = activeSafehouse ?? activeSquad?.members.firstOrNull?.site;
  if (loc == null) return;

  //GIVE INFO SCREEN
  erase();
  mvaddstrc(1, 26, red, "UNDER ATTACK: ESCAPE OR ENGAGE");

  mvaddstrc(3, 16, lightGray,
      "You are about to engage Conservative forces in battle.");
  mvaddstr(
      4, 11, "You will find yourself in the Liberal safehouse, and it will");
  mvaddstr(5, 11, "be swarming with Conservative units.  The Liberal Crime");
  mvaddstr(
      6, 11, "Squad will be located far from the entrance to the safehouse.");
  mvaddstr(
      7, 11, "It is your task to bring your squad out to safety, or fight");
  mvaddstr(
      8, 11, "off the Conservatives within the perimeter.  Either way you");
  mvaddstr(
      9, 11, "choose, any equipment from the safehouse which isn't held by a");
  mvaddstr(10, 11, "Liberal will be scattered about the compound.  Save what");
  mvaddstr(11, 11, "you can.  You might notice your Squad has filled out to");
  mvaddstr(
      12, 11, "six members if any were available.  If you have a larger pool");
  mvaddstr(13, 11, "of Liberals, they will be traveling behind the Squad.");
  mvaddstr(14, 11, "There is a new button, (R)eorganize, which reflects this.");
  mvaddstr(15, 11, "Squad members in the back with firearms can provide cover");
  mvaddstr(
      16, 11, "fire.  If you have at least six people total, then six must");
  mvaddstr(17, 11, "be in the Squad.  If less than six, then they all must.");

  int y = 19;
  if (loc.compound.cameras) {
    mvaddstr(y++, 16, "Your security cameras let you see units on the (M)ap.");
  }
  if (loc.compound.boobyTraps) {
    mvaddstr(y++, 16, "Your traps will harass the enemy, but not the Squad.");
  }

  mvaddstrc(
      23, 11, red, "Press any key to Confront the Conservative Aggressors");

  await getKey();

  //CRIMINALIZE
  if (loc.siege.activeSiegeType == SiegeType.police) {
    criminalizeAll(loc.creaturesPresent.where((p) => p.isActiveLiberal),
        Crime.resistingArrest);
  }

  //DELETE ALL SQUADS IN THIS AREA UNLESS THEY ARE THE activeSquad
  for (int sq = squads.length - 1; sq >= 0; sq--) {
    if (squads[sq] != activeSquad && squads[sq].members.isNotEmpty) {
      if (squads[sq].members.first.location == loc) {
        if (activeSquad != null) {
          for (Creature p in activeSquad!.members.toList()) {
            p.squad = null;
          }
          squads.removeAt(sq);
        } else {
          activeSquad = squads[sq];
        }
      }
    }
  }

  // No squads at the location? Form a new one.
  if (activeSquad == null) {
    squads.add(Squad());
    squads.last.name = "${activeSafehouse!.getName(short: true)} Defense";
    for (Creature p
        in activeSafehouse!.creaturesPresent.where((p) => p.isActiveLiberal)) {
      if (squads.last.members.length < 6) {
        p.squad = squads.last;
      } else {
        break;
      }
    }
    activeSquad = squads.last;
  }

  //MAKE SURE PARTY IS ORGANIZED
  autopromote(loc);

  //START FIGHTING
  sitestory = NewsStory.prepare(loc.siege.underAttack
      ? NewsStories.squadFledAttack
      : NewsStories.squadEscapedSiege)
    ..positive = 1
    ..loc = loc
    ..siegetype = loc.siege.activeSiegeType;
  await siteMode(loc);
}

/* siege - what happens when you escaped the siege */
Future<void> escapeSiege(bool won) async {
  //TEXT IF DIDN'T WIN
  if (!won) {
    //GIVE INFO SCREEN
    erase();
    mvaddstrc(1, 32, yellow, "You have escaped!");

    mvaddstrc(3, 16, lightGray,
        "The Conservatives thought that the Liberal Crime Squad was");
    mvaddstr(
        4, 11, "finished, but once again, Conservative Thinking has proven");
    mvaddstr(5, 11, "itself to be based on Unsound Notions.");
    mvaddstr(
        6, 16, "However, all is not well.  In your haste to escape you have");
    mvaddstr(7, 11, "lost everything that you've left behind.  You'll have");
    mvaddstr(8, 11, "to start from scratch in a new safe house.  Your");
    mvaddstr(9, 11,
        "funds remain under your control, fortunately.  Your flight has");
    mvaddstr(
        10, 11, "given you some time to regroup, but the Conservatives will");
    mvaddstr(11, 11, "doubtless be preparing another assault.");

    Site? homes;
    if (activeSquad != null) {
      if (activeSquad?.members.isNotEmpty == true) {
        homes = findSiteInSameCity(
            activeSquad!.members.first.site!.city, SiteType.homelessEncampment);
      }
    }

    mvaddstrc(
        13, 11, yellow, "Press any key to split up and lay low for a few days");

    await getKey();

    //dump retrieved loot in homeless camp - is there anywhere better to put it?
    if (activeSquad != null) homes?.addLootAndProcessMoney(activeSquad!.loot);

    activeSquad = null; //active squad cannot be disbanded in removesquadinfo,
    //but we need to disband current squad as the people are going to be 'away'.

    //GET RID OF DEAD, etc.
    if (activeSite!.rent > 1) activeSite!.controller = SiteController.unaligned;

    for (int i = pool.length - 1; i >= 0; i--) {
      Creature p = pool[i];
      if (p.site != activeSite) continue;
      if (!p.alive) {
        pool.removeAt(i);
        continue;
      }
      p.prisoner = null;

      //BASE EVERYONE LEFT AT HOMELESS CAMP
      p.squad = null;
      p.hidingDaysLeft = lcsRandom(3) + 2;
      if (p.align == Alignment.liberal) {
        // not a hostage
        p.location = null;
      } else {
        // hostages don't go into hiding, just shove em into the homeless camp
        p.location = homes;
      }
      p.base = homes;
    }
    activeSite!.loot.clear();

    for (int v = vehiclePool.length - 1; v >= 0; v--) {
      if (vehiclePool[v].location == activeSite) {
        vehiclePool.removeAt(v);
      }
    }

    activeSite!.compound.fortified = false;
    activeSite!.compound.rations = 0;
    activeSite!.businessFront = false;
    await initsite(activeSite!);
  }

  //SET UP NEW SIEGE CHARACTERISTICS, INCLUDING TIMING
  if (won && activeSite!.siege.activeSiegeType == SiegeType.police) {
    activeSite!.siege.timeUntilCops = lcsRandom(4) + 4;
    activeSite!.siege.escalationState =
        activeSite!.siege.escalationState.escalate();
  }
  activeSite!.siege.activeSiegeType = SiegeType.none;
}

/* siege - flavor text when you fought off the raid */
Future<void> conquerText() async {
  //GIVE INFO SCREEN

  erase();
  mvaddstrc(1, 26, lightGreen, "* * * * *   VICTORY   * * * * *");

  if (activeSite!.siege.activeSiegeType == SiegeType.police) {
    mvaddstrc(3, 16, lightGray,
        "The Conservative automatons have been driven back —— for ");
    mvaddstr(4, 11,
        "the time being.  While they are regrouping, you might consider ");
    mvaddstr(5, 11, "abandoning this safe house for a safer location.");
  } else {
    mvaddstrc(3, 16, lightGray,
        "The Conservative automatons have been driven back.  ");
    mvaddstr(4, 11, "Unfortunately, you will never truly be safe from ");
    mvaddstr(5, 11, "this filth until the Liberal Agenda is realized.");
  }

  mvaddstr(7, 19, "Press C to Continue Liberally.");

  while (await getKey() != Key.c) {}
}

/* siege - flavor text when you crush a CCS safe house */
Future<void> conquerTextCCS() async {
  //GIVE INFO SCREEN
  erase();
  mvaddstrc(1, 26, lightGreen, "* * * * *   VICTORY   * * * * *");

  if (ccsBaseKills < 3) {
    setColor(lightGray);
    move(3, 16);
    if (ccsSiegeConverts > 10) {
      addstr("Music still ringing in their ears, the squad revels in ");
      mvaddstr(4, 11, "their victory.  ");
    } else if (ccsBossConverts > 0) {
      addstr("The CCS Lieutenant lost in self-realization, the squad ");
      mvaddstr(4, 11, "slips away.  ");
    } else if (ccsSiegeKills > 10) {
      addstr("Gunfire still ringing in their ears, the squad revels in ");
      mvaddstr(4, 11, "their victory.  ");
    } else {
      addstr("The CCS Lieutenant lying dead at their feet, the squad ");
      mvaddstr(4, 11, "slips away.  ");
    }
    addstr("The CCS Founder wasn't here, but for now, their ");
    mvaddstr(5, 11,
        "power has been severely weakened.  Once the safehouse cools off, ");
    mvaddstr(
        6, 11, "this will make a fine base for future Liberal operations.");
  } else {
    move(3, 16);
    bool pacifist = false;
    if (ccsSiegeConverts > 10) {
      addstr("Music still ringing in their ears, the squad revels in ");
      mvaddstr(4, 11, "their final victory.  ");

      mvaddstr(6, 16,
          "As your Liberals speak to the former CCS members, it is increasingly ");
      mvaddstr(7, 11, "clear that this was the CCS's last safehouse.");
      pacifist = true;
    } else if (ccsBossConverts > 0) {
      addstr("The CCS Founder lost in self-realization, the squad ");
      mvaddstr(4, 11, "slips away.");

      mvaddstr(6, 16,
          "With even its Founder swearing off Conservatism forever, the last ");
      mvaddstr(4, 11, "of the CCS's morale and confidence is shattered.");
      pacifist = true;
    } else if (ccsSiegeKills > 10) {
      addstr("Gunfire still ringing in their ears, the squad revels in ");
      mvaddstr(4, 11, "their final victory.");

      mvaddstr(6, 16,
          "As your Liberals pick through the remains of the safehouse, ");
      mvaddstr(7, 11,
          "it is increasingly clear that this was the CCS's last safehouse.");
    } else {
      addstr("The CCS Founder lying dead at their feet, the squad ");
      mvaddstr(4, 11, "slips away.");

      mvaddstr(
          6, 16, "With its Founder killed in the heart of their own base, ");
      mvaddstr(
          7, 11, "the last of the enemy's morale and confidence is shattered.");
    }

    mvaddstr(9, 16,
        "The CCS has been completely ${pacifist ? "neutralized" : "destroyed"}.  Now wasn't there a ");
    mvaddstr(10, 16, "revolution to attend to?");

    mvaddstr(12, 5,
        "+200 JUICE TO EVERYONE FOR ${pacifist ? "CONVERTING" : "ERADICATING"} THE CONSERVATIVE CRIME SQUAD");

    for (Creature p in pool) {
      addjuice(p, 200, 1000);
    }
  }

  mvaddstr(15, 19, "Press C to Continue Liberally.");

  while (await getKey() != Key.c) {}
}

/* siege - "you are wanted for _______ and other crimes..." */
Future<void> stateBrokenLaws(Site loc) async {
  Set<Crime> brokenLaws = {};
  int kidnapped = 0;
  String? kname;

  for (Creature p in pool) {
    if (!p.alive || p.location != loc) continue;
    if (p.kidnapped) {
      kname = p.properName;
      kidnapped++;
    }
    for (Crime c in Crime.values) {
      if (p.wantedForCrimes[c]! > 0) {
        brokenLaws.add(c);
      }
    }
  }
  int typenum = brokenLaws.length;

  erase();

  setColor(white);
  move(1, 1);
  if (loc.siege.underAttack && loc.siege.activeSiegeType != SiegeType.police) {
    addstr("You hear shouts:");
  } else {
    addstr("You hear a blaring voice on a loudspeaker:");
  }

  move(3, 1);
  if (loc.siege.escalationState.index >= SiegeEscalation.tanks.index &&
      politics.publicMood() < 20) {
    addstr("In the name of God, your campaign of terror ends here!");
  } else if (loc.type == SiteType.homelessEncampment) {
    addstr("Everyone in the camp is under arrest!");
  } else {
    addstr("Surrender yourselves!");
  }

  move(4, 1);

  //KIDNAP VICTIM
  if (kidnapped > 0) {
    addstr("Release $kname");
    if (kidnapped > 1) addstr(" and the others");
    addstr(" unharmed!");
  } else {
    String crimeName = Crime.values
            .firstWhereOrNull((c) => brokenLaws.contains(c))
            ?.wantedFor ??
        "harboring a fugitive from justice";
    addstr("You are wanted for $crimeName");
    if (typenum > 1) addstr(" and other crimes");
    addstr("!");
  }

  await getKey();
}
