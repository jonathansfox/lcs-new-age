import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/base_actions.dart';
import 'package:lcs_new_age/basemode/help_system.dart';
import 'package:lcs_new_age/basemode/review_mode.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/siege.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/advance.dart';
import 'package:lcs_new_age/sitemode/chase_sequence.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/haul_kidnap.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/miscactions.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/talk/talk.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/game_options.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> siteMode(Site loc) async {
  activeSite = loc;
  siteAlarm = false;
  siteAlarmTimer = -1;
  postAlarmTimer = 0;
  siteOnFire = false;
  siteAlienated = SiteAlienation.none;
  siteCrime = 0;
  encounter.clear();
  await initsite(loc);
  mode = GameMode.site;

  if (!loc.siege.underSiege) {
    ccsSiegeKills = 0;
    ccsBossKills = 0;

    //Start at entrance to map
    locx = MAPX >> 1;
    locy = 1;
    locz = 0;
    // Second floor start of White House
    if (loc.type == SiteType.whiteHouse && currentTile.wall) locz++;

    // Visit everything that can be found from the starting location without
    // going through a wall or door
    floodVisitAllTiles(locx, locy, locz);

    //check for sleeper infiltration or map knowledge
    for (int p = 0; p < pool.length; p++) {
      if (pool[p].base == loc || loc.mapped) {
        //make entire site known
        for (SiteTile t in levelMap.all) {
          t.known = true;
        }
        break;
      }
    }
  } else {
    siteAlarm = true;

    loc.siege.attackTime = 0;
    loc.siege.kills = 0;
    loc.siege.tanks = 0;

    //PLACE YOU
    for (SiteTile t in levelMap.all) {
      if (!loc.siege.lightsOff) t.known = true;
      t.locked = false;
      t.loot = false;
    }

    int exhaustlocation = 0;

    do {
      // Some bugs with degenerate spawn outside the map are occurring
      // Unknown why, but hard-coding limits to spawn location should help
      //locx=lcsRandom(MAPX);
      //locy=maxy-lcsRandom(3);
      locx = (MAPX / 2 + lcsRandom(25) - 12).floor();
      locy = 15 - lcsRandom(3);

      if (exhaustlocation > 10000) {
        for (SiteTile t in levelMap.allOnFloor(locz)) {
          t.flag = 0;
          if (t.y == 0) t.exit = true;
        }

        locx = 1 + lcsRandom(MAPX - 1);
        locy = 1 + lcsRandom(18 - 1);
      }
      if (exhaustlocation > 1000) {
        locx = lcsRandom(MAPX);
        locy = lcsRandom(18);
        exhaustlocation++;
      } else {
        exhaustlocation++;
      }

      //if(locy<3) locy=3;
      locz = 0;
    } while (currentTile.wall || currentTile.door || currentTile.burning);

    //PLACE LOOT
    int lootnum = loc.loot.length;
    if (lootnum > 10) lootnum = 10;

    SiteTile tile;
    for (int l = 0; l < lootnum; l++) {
      Iterable<SiteTile> options = levelMap
          .allOnFloor(0)
          .where((t) => !t.wall && !t.door && !t.exit && !t.loot);
      if (options.isEmpty) break;
      tile = options.where((t) => !t.outdoor).randomOrNull ?? options.random;
      tile.loot = true;
    }

    //PLACE TRAPS
    if (loc.compound.boobyTraps) {
      int trapnum = 30;
      for (int t = 0; t < trapnum; t++) {
        tile = levelMap.allOnFloor(0).randomWhere(
            (tile) => !tile.wall && !tile.door && !tile.exit && !tile.loot);
        tile.siegeTrap = true;
      }
    }

    //PLACE UNITS
    int unitnum = 6;
    int count = 50000;
    for (int t = 0; t < unitnum; t++) {
      do {
        tile = levelMap[lcsRandom(11) + MAPX ~/ 2 - 5][lcsRandom(8)][0];
        count--;
        if (count == 0) break;
      } while (tile.wall ||
          tile.door ||
          tile.exit ||
          tile.siegeUnit ||
          tile.siegeHeavyUnit ||
          tile.siegeTrap);

      tile.siegeUnit = true;
    }

    if (!loc.compound.bollards &&
        loc.siege.activeSiegeType == SiegeType.police &&
        loc.siege.escalationState.index >= 2) {
      levelMap[MAPX ~/ 2][1][0].siegeHeavyUnit = true;
      loc.siege.tanks = 1;
    }
  }

  await _siteModeAux();

  encounter.clear();
}

Future<void> _siteModeAux() async {
  int u, x;
  if (activeSquad == null) return;

  for (Creature c in squad) {
    c.location = activeSite;
  }

  await reloadparty(false);

  bool bailOnBase = true;
  if (activeSite == squad.first.base) bailOnBase = false;

  knowmap(locx, locy, locz);

  bool hostcheck = false;

  int encounterTimer = 0;

  while (true) {
    int partysize = squad.length;
    bool partyalive = activeSquad!.livingMembers.isNotEmpty;
    int hostages = 0, encsize = 0, freeable = 0, talkers = 0;
    bool enemy = false;
    for (Creature p in squad) {
      if (p.prisoner != null && p.prisoner!.align != Alignment.liberal) {
        hostages++;
      }
    }
    for (Creature e in encounter) {
      encsize++;
      if (e.isEnemy) enemy = true;
      if (e.type.freeable ||
          ((e.name == "Prisoner") && e.align == Alignment.liberal)) {
        freeable++;
      } else if ((e.isWillingToTalk || (e.isEnemy && siteAlarm)) &&
          !(!e.isEnemy && siteAlarm && enemy)) {
        talkers++;
      }
    }

    //If in combat, do a second check
    if (talkers > 0 && siteAlarm && enemy) {
      talkers = 0;
      for (Creature e in encounter) {
        if (e.isEnemy && (e.isWillingToTalk || e.type.animal)) talkers++;
      }
    }
    int libnum = 0;
    for (Creature p in pool) {
      if (p.align == Alignment.liberal &&
          p.alive &&
          p.location == activeSite &&
          !p.sleeperAgent) {
        libnum++;
      }
    }

    // Let the squad stop stressing out over the encounter if there are no enemies this round
    if (!enemy) encounterTimer = 0;

    erase();

    if (activeSiteUnderSiege) {
      mvaddstrc(0, 0, red, activeSite!.getName(includeCity: true));
      addstr(", Level ${locz + 1}: Escape or Engage");
    } else {
      if (postAlarmTimer > 80) {
        setColor(red);
      } else if (postAlarmTimer > 60) {
        setColor(yellow);
      } else {
        setColor(lightGray);
      }
      mvaddstr(0, 0, activeSite!.getName(includeCity: true));
      addstr(", Level ${locz + 1}");

      if (postAlarmTimer > 80) {
        switch (activeSite!.type) {
          case SiteType.armyBase:
            addstr(": MILITARY RESPONDING");
          case SiteType.whiteHouse:
            addstr(": SECRET SERVICE RESPONDING");
          case SiteType.intelligenceHQ:
            addstr(": AGENTS RESPONDING");
          case SiteType.corporateHQ:
          case SiteType.ceoHouse:
            addstr(": MERCENARIES RESPONDING");
          case SiteType.amRadioStation:
            addstr(": LISTENERS RESPONDING");
          case SiteType.cableNewsStation:
            addstr(": VIEWERS RESPONDING");
          case SiteType.drugHouse:
            addstr(": GANG RESPONDING");
          default:
            if (activeSite!.controller == SiteController.ccs) {
              addstr(": CCS RESPONDING");
            } else if (laws[Law.deathPenalty] ==
                    DeepAlignment.archConservative &&
                laws[Law.policeReform] == DeepAlignment.archConservative) {
              addstr(": DEATH SQUADS RESPONDING");
            } else {
              addstr(": POLICE RESPONDING");
            }
        }
      } else if (postAlarmTimer > 60) {
        addstr(": CONSERVATIVE REINFORCEMENTS INCOMING");
      } else if (siteAlienated == SiteAlienation.alienatedModerates) {
        addstr(": ALIENATED MASSES");
      } else if (siteAlienated == SiteAlienation.alienatedEveryone) {
        addstr(": ALIENATED EVERYONE");
      } else if (siteAlarm) {
        addstr(": CONSERVATIVES ALARMED");
      } else if (siteAlarmTimer == 0) {
        addstr(": CONSERVATIVES SUSPICIOUS");
      }
    }

    //PRINT PARTY
    if (!partyalive) activeSquadMember = null;
    printParty();

    //PRINT SITE INSTRUCTIONS
    if (partyalive) {
      if (!enemy || !siteAlarm) {
        setColor(lightGray);
      } else {
        setColor(darkGray);
      }
      mvaddstrc(23, 1, blue, "W");
      addstrc(lightGray, ",");
      addstrc(blue, "A");
      addstrc(lightGray, ",");
      addstrc(blue, "D");
      addstrc(lightGray, ",");
      addstrc(blue, "X");
      addstrc(lightGray, "-Move, ");
      addstrc(groundLoot.isNotEmpty || currentTile.loot ? blue : darkGray, "G");
      addstrc(groundLoot.isNotEmpty || currentTile.loot ? lightGray : darkGray,
          "et, ");
      addstrc(blue, "M");
      addstrc(lightGray, "ap, ");
      addstrc(blue, "E");
      addstrc(lightGray, "quip, ");
      addstrc(blue, "S");
      addstrc(lightGray, "tall, ");
      addstrc(!enemy || !siteAlarm ? lightGray : darkGray, "re");
      addstrc(!enemy || !siteAlarm ? blue : darkGray, "L");
      addstrc(!enemy || !siteAlarm ? lightGray : darkGray, "oad, ");
      addstrc(partysize > 1 ? blue : darkGray, "O");
      addstrc(partysize > 1 ? lightGray : darkGray, "rder,");
      bool graffiti = false;
      bool useColor;
      if (currentTile.special != TileSpecial.none &&
          currentTile.special != TileSpecial.clubBouncerSecondVisit) {
        useColor = true;
      } else if (!(currentTile.graffitiLCS || currentTile.megaBloody)) {
        if (currentTile.right?.wall == true ||
            currentTile.left?.wall == true ||
            currentTile.down?.wall == true ||
            currentTile.up?.wall == true) {
          if (squad.any((c) => c.weapon.type.canGraffiti)) {
            useColor = true;
            graffiti = true;
          } else {
            useColor = false;
          }
        } else {
          useColor = false;
        }
      } else {
        useColor = false;
      }
      mvaddstrc(24, 1, useColor ? blue : darkGray, "U");
      addstrc(
          useColor ? lightGray : darkGray, graffiti ? "-graffiti, " : "se, ");
      if (enemy && siteAlarm) {
        bool canSneak = false;
        for (Creature e in encounter) {
          if (e.alive && e.noticedParty) {
            // You can't sneak past this person; they already know you're there
            canSneak = true;
            break;
          }
        }
        addstrc(blue, "V");
        if (!canSneak) {
          addstrc(lightGray, "-Sneak, ");
        } else {
          addstrc(lightGray, "-Flee, ");
        }
      } else {
        setColor(darkGray);
        addstr("V-Flee, ");
      }
      addstrc(enemy ? blue : darkGray, "F");
      addstrc(enemy ? lightGray : darkGray, "ight, ");
      addstrc(enemy ? blue : darkGray, "K");
      addstrc(enemy ? lightGray : darkGray, "idnap, ");
      addstrc(talkers > 0 ? blue : darkGray, "T");
      addstrc(talkers > 0 ? lightGray : darkGray, "alk, ");
      if (!activeSiteUnderSiege) {
        if (freeable > 0 && (!enemy || !siteAlarm)) {
          addstrc(blue, "R");
          addstrc(lightGray, "escue, ");
        } else {
          if (hostages > 0) {
            addstrc(blue, "R");
            addstrc(lightGray, "elease, ");
          } else {
            addstrc(darkGray, "Release, ");
          }
        }
      } else {
        if (libnum > 6) {
          addstrc(blue, "R");
          addstrc(lightGray, "eorganize, ");
        } else {
          addstrc(darkGray, "Reorganize, ");
        }
      }
      addstrc(blue, "?");
    } else {
      //DESTROY ALL CARS BROUGHT ALONG WITH PARTY
      if (!activeSiteUnderSiege) {
        for (Creature p in squad) {
          if (p.carId != -1) {
            vehiclePool.removeWhere((v) => v.id == p.carId);
          }
        }
      }

      for (Creature p in squad) {
        p.die();
        p.location = null;
      }
      squad.clear();

      addOptionText(9, 1, "C", "C - Reflect on your Conservative ineptitude");
    }

    //PRINT SITE MAP
    printSiteMapSmall(locx, locy, locz);

    //CHECK IF YOU HAVE A SQUIRMING AMATEUR HOSTAGE
    //hostcheck SHOULD ONLY BE 1 WHEN A NEWENC IS CREATED
    if (hostcheck) {
      bool havehostage = false;
      //Check your whole squad
      for (Creature p in squad) {
        //If they're unarmed and dragging someone
        if (p.prisoner != null && !p.weapon.type.canTakeHostages) {
          //And that someone is not an LCS member
          if (p.prisoner!.squadId == null) {
            //They scream for help -- flag them kidnapped, cause alarm
            p.prisoner!.kidnapped = true;
            if (p.type.preciousToAngryRuralMobs) offendedAngryRuralMobs = true;
            havehostage = true;
            for (Creature p in squad) {
              p.offendedAngryRuralMobs++;
            }
            addPotentialCrime(activeSquad!.livingMembers, Crime.kidnapping,
                reasonKey: p.prisoner!.id.toString());
          }
        }
      }

      if (havehostage) {
        await alienationCheck(false);
        siteCrime += 5;
      }
      hostcheck = false;

      clearMessageArea();
    }

    int c;
    if (currentTile.special == TileSpecial.clubBouncer) {
      if (activeSite!.controller == SiteController.lcs) {
        currentTile.special = TileSpecial.none;
        c = await getKey();
      } else {
        c = Key.s;
      }
    } else {
      c = await getKey();
    }

    if (!partyalive && c == Key.c) {
      //END OF GAME CHECK
      if (!await checkForDefeat()) {
        if (activeSiteUnderSiege) {
          if (activeSite!.siege.underAttack) {
            sitestory!.type = NewsStories.squadKilledInSiegeAttack;
          } else {
            sitestory!.type = NewsStories.squadKilledInSiegeEscape;
          }
        } else if (!activeSiteUnderSiege) {
          sitestory!.type = NewsStories.squadKilledInSiteAction;

          await _resolveSite();
        }

        mode = GameMode.base;

        return;
      }
    }

    if (partyalive) {
      int olocx = locx, olocy = locy, olocz = locz;

      bool override = false;

      if (enemy && siteAlarm) {
        if (encounter
            .where((e) =>
                e.isEnemy &&
                (e.weapon.type.protectsAgainstKidnapping ||
                    e.type.canPerformArrests ||
                    e.type.edgelord ||
                    e.type.ccsMember ||
                    e.type.majorEnemy ||
                    e.type.intimidationResistant))
            .isEmpty) {
          override = true;
        }
      }

      if (c == "?".codePoint) {
        await helpOnSitemode();
      }

      if (c == Key.v && enemy && siteAlarm) {
        clearMessageArea();
        mvaddstrc(
            9, 1, white, "Which way?  (W,A,D, and X to move, ENTER to abort)");

        while (true) {
          int c2 = await getKey();

          if (c2 == Key.w ||
              c2 == Key.a ||
              c2 == Key.d ||
              c2 == Key.x ||
              c2 == Key.leftArrow ||
              c2 == Key.rightArrow ||
              c2 == Key.upArrow ||
              c2 == Key.downArrow) {
            c = c2;
            override = true;
            break;
          }

          if (c2 == Key.enter || c2 == Key.escape || c2 == Key.space) break;
        }
      }

      if ((c == Key.w || c == Key.upArrow) &&
          locy > 0 &&
          (!enemy || !siteAlarm || override)) {
        if (currentTile.up?.wall != true) {
          locy--;
        }
      }
      if ((c == Key.a || c == Key.leftArrow) &&
          locx > 0 &&
          (!enemy || !siteAlarm || override)) {
        if (currentTile.left?.wall != true) {
          locx--;
        }
      }
      if ((c == Key.d || c == Key.rightArrow) &&
          locx < MAPX - 1 &&
          (!enemy || !siteAlarm || override)) {
        if (currentTile.right?.wall != true) {
          locx++;
        }
      }
      if ((c == Key.x || c == Key.downArrow) &&
          locy < MAPY - 1 &&
          (!enemy || !siteAlarm || override)) {
        if (currentTile.down?.wall != true) {
          locy++;
        }
      }

      if (c == Key.k && enemy) {
        await kidnapattempt();
      }

      if (c == Key.u) {
        if (currentTile.special != TileSpecial.none) {
          await useTileSpecial();
        } else if (!(currentTile.graffitiLCS || currentTile.megaBloody) &&
            currentTile.neighbors().any((t) => t.wall)) {
          if (activeSquad!.livingMembers
              .any((c) => c.weapon.type.canGraffiti)) {
            await specialGraffiti();
            if (enemy && siteAlarm) {
              await enemyattack(encounter);
            }
          }
        }
      }

      if (c == Key.t && talkers > 0) {
        int forcesp = -1;
        int forcetk = -1;

        for (Creature p in activeSquad!.livingMembers) {
          if (forcesp == -1) {
            forcesp = squad.indexOf(p);
          } else {
            forcesp = -2;
          }
        }

        for (Creature e in encounter) {
          if (e.alive &&
              !(e.type.id == CreatureTypeIds.servant ||
                  e.type.id == CreatureTypeIds.sweatshopWorker)) {
            if (e.isWillingToTalk || siteAlarm) {
              if (forcetk == -1) {
                forcetk = encounter.indexOf(e);
              } else {
                forcetk = -2;
              }
            }
          }
        }

        if (forcetk != -1 && forcesp != -1) {
          int tk = -1, sp = -1;
          if (forcesp == -2) {
            clearSceneAreas();

            mvaddstrc(9, 1, white, "Which Liberal will speak?");
            mvaddstr(9, 35, "Persuasion");
            mvaddstr(10, 35, "(Recruits/Max)");
            mvaddstr(9, 52, "Seduction");
            mvaddstr(10, 52, "(Lovers/Max)");
            mvaddstr(9, 67, "Disguise");

            setColor(lightGray);
            int y = 11;
            for (Creature p in activeSquad!.livingMembers) {
              int i = squad.indexOf(p);
              if (p.alive) {
                addOptionText(y, 1, "${i + 1}", "${i + 1} - ${p.name}");
                printSkillValue(p, Skill.persuasion, y, 34, showCap: false);
                addstr(
                    " (${p.maxSubordinates - p.subordinatesLeft}/${p.maxSubordinates})");
                printSkillValue(p, Skill.seduction, y, 51, showCap: false);
                addstr(
                    " (${p.maxRelationships - p.relationshipsLeft}/${p.maxRelationships})");
                printSkillValue(p, Skill.disguise, y, 66, showCap: false);
                y++;
              }
            }

            while (true) {
              int c = await getKey();

              if (c >= '1'.codePoint && c <= '6'.codePoint) {
                sp = c - '1'.codePoint;
                if (sp < squad.length) {
                  if (squad[sp].alive) {
                    break;
                  }
                }
              }
              if (isBackKey(c)) {
                sp = -1;
                break;
              }
            }
          } else {
            sp = forcesp;
          }

          if (sp != -1) {
            if (forcetk == -2) {
              while (true) {
                clearSceneAreas();

                mvaddstrc(9, 1, white, "To whom?");

                int x = 0, y = 12;
                for (Creature t in encounter) {
                  int i = encounter.indexOf(t);
                  move(y, x);
                  String letter = letterAPlus(i);
                  addInlineOptionText(
                      letter, "$letter - ${t.name} ${creatureAgeAndGender(t)}",
                      baseColorKey: ColorKey.fromColor(t.align.color),
                      enabledWhen: t.alive && t.isWillingToTalk);

                  y++;
                }

                int c = await getKey();

                if (c >= Key.a && c <= Key.z) {
                  tk = c - Key.a;
                  if (tk < encounter.length) {
                    if (encounter[tk].alive &&
                        !(encounter[tk].type.id == CreatureTypeIds.servant ||
                            encounter[tk].type.id ==
                                CreatureTypeIds.sweatshopWorker)) {
                      if (!encounter[tk].isWillingToTalk &&
                          (!siteAlarm || encounter[tk].type.animal)) {
                        clearSceneAreas();

                        mvaddstrc(9, 1, white, encounter[tk].name);
                        addstr(" won't talk to you.");

                        await getKey();
                      } else if (!encounter[tk].isEnemy && siteAlarm && enemy) {
                        clearSceneAreas();

                        mvaddstrc(9, 1, white,
                            "You have to deal with the enemies first.");

                        await getKey();
                      } else {
                        break;
                      }
                    }
                  }
                }
                if (isBackKey(c)) {
                  tk = -1;
                  break;
                }
              }
            } else {
              tk = forcetk;
            }

            if (tk != -1) {
              if (await talk(squad[sp], encounter[tk])) {
                if (enemy && siteAlarm) {
                  await enemyattack(encounter);
                } else if (enemy) {
                  await disguisecheck(encounterTimer);
                }
                await creatureadvance();
                encounterTimer++;
              }
            }
          }
        }
      }

      if (c == Key.l && (!enemy || !siteAlarm)) {
        await reloadparty(true);
        printParty();
        refresh();
        await creatureadvance();
        encounterTimer++;
      }

      if (c == Key.o && partysize > 1) {
        await orderparty();
      }

      if (c == '0'.codePoint) activeSquadMemberIndex = -1;

      if (c == Key.m) {
        for (SiteTile tile in levelMap.allOnFloor(locz)) {
          move(tile.y + 1, tile.x + 5);
          drawTileContent(tile);
        }

        await getKey();
      }

      if (enemy && (c == Key.f)) {
        // Cops can subdue and arrest the squad.
        bool subdue = false;
        for (int i = 0; i < encounter.length; i++) {
          if (encounter[i].blood > 60 &&
              (encounter[i].type.id == CreatureTypeIds.cop ||
                  encounter[i].type.id == CreatureTypeIds.policeChief ||
                  encounter[i].type.id == CreatureTypeIds.swat)) {
            subdue = true;
            // Don't subdue squad if someone is still in good condition.
            for (int j = 0; j < activeSquad!.livingMembers.length; j++) {
              if (squad[j].blood > 40) {
                subdue = false;
                break;
              }
            }
            break;
          }
        }

        if (subdue) {
          await _fightSubdued();
        } else {
          await youattack(encounter);
          await enemyattack(encounter);
          await creatureadvance();
          encounterTimer++;
        }
      }

      if (c == Key.r && activeSiteUnderSiege && libnum > 6) {
        await assembleSquad(activeSquad);
        autopromote(activeSite!);
      } else if (freeable > 0 &&
          (!enemy || !siteAlarm) &&
          c == Key.r &&
          !activeSiteUnderSiege) {
        int followers = 0;
        int actgot = 0;

        if (enemy) siteAlarm = true;
        bool freed;
        do {
          freed = false;
          List<Creature> free = encounter
              .where((e) =>
                  e.type.freeable ||
                  ((e.name == "Prisoner") && e.align == Alignment.liberal))
              .toList();
          for (Creature e in free) {
            if (e.name == "Prisoner") {
              siteAlarm = true; /* alarm for prisoner escape */
              criminalize(e, Crime.escapingPrison);
            }
            followers++;
            freed = true;

            if (partysize < 6) {
              Creature? recruiter;
              // Check for people who can recruit followers
              for (Creature p in squad) {
                if (p.subordinatesLeft > 0) {
                  recruiter = p;
                  break;
                }
              }
              // If someone can, add this person as a newly recruited Liberal!
              if (recruiter != null) {
                Creature newcr = e;
                newcr.nameCreature();

                newcr.location = recruiter.location;
                newcr.base = recruiter.base;
                newcr.hireId = recruiter.id;

                pool.add(newcr);
                stats.recruits++;

                newcr.squad = activeSquad;

                actgot++;
                partysize++;
              }
            }
            encounter.remove(e);
          }

          if (freed) {
            delayedSuspicion(20 + lcsRandom(10));
          }
        } while (freed);

        if (followers > 0) {
          clearMessageArea();

          mvaddstrc(9, 1, white, "You free ");
          if (followers > 1) {
            addstr("some Oppressed Liberals");
          } else {
            addstr("an Oppressed Liberal");
          }
          addstr(" from the Conservatives.");

          if (actgot < followers) {
            await getKey();

            clearMessageArea();

            setColor(white);
            move(9, 1);
            if (actgot == 0 && followers > 1) {
              addstr("They all leave");
            } else if (followers - actgot > 1) {
              addstr("Some leave");
            } else if (actgot == 0) {
              addstr("The Liberal leaves");
            } else {
              addstr("One Liberal leaves");
            }
            addstr(" you, feeling safer getting out alone.");
            // 3 juice for every person you free who doesn't join up
            // This might need to be nerfed in the future because it's so easy,
            // but it's thematically appropriate, so the nerf should probably
            // come in making it less easy rather than less rewarding.
            juiceparty((followers - actgot) * 3, 200);
          }

          await getKey();
        }
      } else if (c == Key.r && hostages > 00) {
        await releasehostage();
      }

      if (c >= '1'.codePoint && c <= '6'.codePoint) {
        int index = c - '1'.codePoint;
        if (index < squad.length) {
          if (activeSquadMemberIndex == index) {
            await fullCreatureInfoScreen(activeSquadMember!);
          } else {
            activeSquadMemberIndex = index;
          }
        }
      }

      if (c == Key.e) {
        await equip(activeSquad!.loot);

        if (enemy && siteAlarm) {
          await enemyattack(encounter);
        } else if (enemy) {
          await disguisecheck(encounterTimer);
        }

        await creatureadvance();
        encounterTimer++;
      }

      if (c == Key.g && (groundLoot.isNotEmpty || currentTile.loot)) {
        bool tookground = false;

        if (currentTile.loot) {
          currentTile.loot = false;

          await lootGround();
          tookground = true;
        }

        //MAKE GROUND LOOT INTO MISSION LOOT
        for (int l = 0; l < groundLoot.length; l++) {
          addLootToSquad(groundLoot[l]);
        }

        groundLoot.clear();

        if (enemy && siteAlarm) {
          await enemyattack(encounter);
        } else if (enemy) {
          await disguisecheck(encounterTimer);
        }

        if (tookground) {
          juiceparty(1, 50);
          await noticeCheck(includeModerates: false);
          siteCrime++;
          addDramaToSiteStory(Drama.stoleSomething);
          addPotentialCrime(squad, Crime.theft);
        }

        await creatureadvance();
        encounterTimer++;
      }

      Site? cbase;
      if (squad.isNotEmpty) {
        cbase = squad[0].base;
      }

      if (locx != olocx || locy != olocy || locz != olocz || c == Key.s) {
        //NEED TO GO BACK TO OLD LOCATION IN CASE COMBAT
        //REFRESHES THE SCREEN
        int nlocx = locx, nlocy = locy, nlocz = locz;
        locx = olocx;
        locy = olocy;
        locz = olocz;

        //ENEMIES SHOULD GET FREE SHOTS NOW
        if (enemy && siteAlarm) {
          bool failed = false;

          // If you can sneak past all enemies
          if (encounter.any((e) => e.alive && e.noticedParty)) failed = true;
          if (!failed) {
            int difficulty = Difficulty.hard +
                encounter
                    .where((e) => e.align == Alignment.conservative)
                    .length;
            for (Creature p in squad) {
              int roll = p.skillRoll(Skill.stealth);
              if (roll < difficulty) {
                p.train(Skill.stealth, 40);
                failed = true;
              } else {
                p.train(Skill.stealth, 10);
              }
            }
          }

          // If snuck past everyone
          if (!failed) {
            clearMessageArea();
            mvaddstrc(
                9, 1, lightBlue, "The squad sneaks past the conservatives!");

            await getKey();
          } else {
            await enemyattack(encounter);
          }
        } else if (enemy) {
          await disguisecheck(encounterTimer);
        } else {
          await reloadparty(false, showText: true);
        }

        await creatureadvance();
        encounterTimer++;

        partyalive = activeSquad!.livingMembers.isNotEmpty;

        if (!partyalive) continue;

        //AFTER DEATH CHECK CAN MOVE BACK TO NEW LOCATION
        locx = nlocx;
        locy = nlocy;
        locz = nlocz;

        //CHECK FOR EXIT
        if (currentTile.exit ||
            (cbase == activeSite && !activeSiteUnderSiege && bailOnBase)) {
          //CHASE SEQUENCE OR FOOT CHASE
          chaseSequence = ChaseSequence(activeSite!);
          int level = siteCrime;
          if (!siteAlarm) level = 0;
          if (!oneIn(3) && level < 4) level = 0;
          if (oneIn(2) && level < 8) level = 0;
          if (postAlarmTimer < 10 + lcsRandom(20)) {
            level = 0;
          } else if (postAlarmTimer < 20 + lcsRandom(20) && !oneIn(3)) {
            level = 0;
          } else if (postAlarmTimer < 40 + lcsRandom(20) && oneIn(3)) {
            level = 0;
          }
          if (activeSiteUnderSiege) level = 1000;

          //MAKE SURE YOU ARE GUILTY OF SOMETHING
          bool guilty = squad.any((p) => p.isCriminal);
          if (!guilty) level = 0;

          makeChasers(siteType, level);

          bool havecar = false;
          for (Creature p in squad) {
            if (p.carId != null) {
              havecar = true;
              for (Creature i in squad) {
                i.carId ??= p.carId;
              }
              break;
            }
          }
          bool gotout = true;
          if (havecar) {
            gotout = (await carChaseSequence()).won;
          } else {
            gotout = (await footChaseSequence()).won;
          }

          //If you survived
          if (gotout) {
            await squadCleanup();

            //END SITE MODE
            if (activeSiteUnderSiege) {
              //Special handling for escaping siege
              await escapeSiege(false);
            } else {
              await _resolveSite();
            }
          } else if (!await checkForDefeat()) {
            //You didn't survive -- handle squad death (unless that ended the game)
            if (activeSiteUnderSiege) {
              //Report on squad killed during siege
              if (activeSite!.siege.underAttack) {
                sitestory!.type = NewsStories.squadKilledInSiegeAttack;
              } else {
                sitestory!.type = NewsStories.squadKilledInSiegeEscape;
              }

              activeSite!.siege.activeSiegeType = SiegeType.none;
            } else {
              //Or report on your failed raid
              sitestory!.type = NewsStories.squadKilledInSiteAction;
              //Would juice the party here, but you're all dead, so...
              await _resolveSite();
            }
          }
          siteAlarm = false;
          mode = GameMode.base;
          return;
        }

        //SEE IF THERE IS AN ENCOUNTER
        bool newenc = false;

        // 10% chance of encounter normally (100% if waiting)
        // 20% chance of encounter after massive response
        // 0% chance of encounter during sieges
        if (!activeSiteUnderSiege) {
          if (postAlarmTimer > 80) {
            if (oneIn(5)) newenc = true;
          } else if (oneIn(10) || c == Key.s) {
            newenc = true;
          }
        }

        if (encounter.isNotEmpty) newenc = false;

        // Handle special tiles that activate when you step on them
        // (rather than those that must be manually activated)
        TileSpecial? makespecial;
        switch (currentTile.special) {
          case TileSpecial.securityCheckpoint:
          case TileSpecial.securityMetalDetectors:
          case TileSpecial.securitySecondVisit:
          case TileSpecial.clubBouncer:
          case TileSpecial.clubBouncerSecondVisit:
          case TileSpecial.apartmentLandlord:
          case TileSpecial.ceoOffice:
          case TileSpecial.table:
          case TileSpecial.tent:
          case TileSpecial.computer:
          case TileSpecial.parkBench:
          case TileSpecial.bankTeller:
          case TileSpecial.ccsBoss:
          case TileSpecial.ovalOfficeNW:
          case TileSpecial.ovalOfficeNE:
          case TileSpecial.ovalOfficeSW:
          case TileSpecial.ovalOfficeSE:
            makespecial = currentTile.special;
            newenc = true;
          default:
            break;
        }

        //DO DOORS
        if (currentTile.door) {
          await _openDoor(
              levelMap[olocx][olocy][olocz].flag & SITEBLOCK_RESTRICTED > 0);
          locx = olocx;
          locy = olocy;
          locz = olocz;
          if (encsize > 0) newenc = false;
        }

        //BAIL UPON VICTORY (version 2 -- defeated CCS safehouse)
        if ((ccsBossKills >= 1 || ccsBossConverts >= 1) &&
            !activeSiteUnderSiege &&
            activeSite!.controller == SiteController.ccs) {
          await squadCleanup();

          //INFORM
          clearMessageArea();

          mvaddstrc(9, 1, lightGreen, "The CCS has been broken!");

          await getKey();

          activeSite!.controller = SiteController.lcs;
          activeSite!.closed = 0;
          activeSite!.heat = 100;
          initSiteName(activeSite!);

          // CCS Safehouse killed?
          if (activeSite!.type == SiteType.bombShelter ||
              activeSite!.type == SiteType.barAndGrill ||
              activeSite!.type == SiteType.bunker) {
            ccsBaseKills++;
            if (ccsBaseKills < 3) {
              ccsState = CCSStrength.values[max(0, ccsState.index - 1)];
            } else {
              ccsState = CCSStrength.defeated;
            }
          }

          await conquerTextCCS();

          //RESET MODE
          mode = GameMode.base;
          return;
        }

        if (activeSiteUnderSiege) // *JDS* police response added
        {
          if (locx != olocx || locy != olocy || locz != olocz) {
            encounter.clear();
          }

          //MOVE SIEGE UNITS AROUND
          //MOVE UNITS
          List<int> unitx = [], unity = [], unitz = [];

          for (x = 0; x < MAPX; x++) {
            for (int y = 0; y < MAPY; y++) {
              for (int z = 0; z < MAPZ; z++) {
                if (levelMap[x][y][z].siegeUnit ||
                    levelMap[x][y][z].siegeUnitDamaged) {
                  unitx.add(x);
                  unity.add(y);
                  unitz.add(z);
                }
              }
            }
          }

          int sx = 0, sy = 0, sz = 0;
          for (u = 0; u < unitx.length; u++) {
            bool damaged =
                levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnitDamaged;
            // don't leave tile if player is here
            if (unitx[u] == locx && unity[u] == locy && unitz[u] == locz) {
              continue;
            }
            // move into player's tile if possible
            if ((((unitx[u] == locx - 1 || unitx[u] == locx + 1) &&
                        unity[u] == locy) ||
                    ((unity[u] == locy - 1 || unity[u] == locy + 1) &&
                        unitx[u] == locx)) &&
                unitz[u] == locz) {
              if (damaged) {
                levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnitDamaged = false;
              } else {
                levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnit = false;
              }

              //Get torched
              if (currentTile.firePeak) {
                currentTile.siegeUnitDamaged = true;
              }

              //BLOW TRAPS
              if (currentTile.siegeTrap) {
                currentTile.siegeTrap = false;
                currentTile.megaBloody = true;
                if (!damaged) {
                  currentTile.siegeUnitDamaged = true;
                }
              } else {
                if (damaged) {
                  currentTile.siegeUnitDamaged = true;
                  currentTile.bloody = true;
                } else {
                  currentTile.siegeUnit = true;
                }
              }
              continue;
            }
            sz = 0;
            switch (lcsRandom(4)) {
              case 0:
                sx = -1;
                sy = 0;
              case 1:
                sx = 1;
                sy = 0;
              case 2:
                sx = 0;
                sy = 1;
              case 3:
                sx = 0;
                sy = -1;
            }
            sx += unitx[u];
            sy += unity[u];
            sz += unitz[u];

            if (sx >= 0 &&
                sx < MAPX &&
                sy >= 0 &&
                sy < MAPY &&
                sz >= 0 &&
                sz < MAPZ) {
              SiteTile tile = levelMap[sx][sy][sz];
              if (!tile.wall) {
                if (tile.door) {
                  tile.door = false;
                  tile.locked = false;
                  tile.knownLock = false;
                  tile.cantUnlock = false;
                } else {
                  //BLOCK PASSAGE
                  if (!(tile.siegeUnit ||
                      tile.siegeHeavyUnit ||
                      tile.siegeUnitDamaged)) {
                    bool damaged =
                        levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnitDamaged;
                    if (damaged) {
                      levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnitDamaged =
                          false;
                    } else {
                      levelMap[unitx[u]][unity[u]][unitz[u]].siegeUnit = false;
                    }

                    //BLOW TRAPS
                    if (tile.siegeTrap) {
                      tile.siegeTrap = false;
                      tile.megaBloody = true;
                      if (!damaged) {
                        tile.siegeUnitDamaged = true;
                      }
                    } else {
                      if (damaged) {
                        tile.siegeUnitDamaged = true;
                        tile.bloody = true;
                      } else {
                        tile.siegeUnit = true;
                      }
                    }
                  }
                }
              }
            }
          }

          unitx.clear();
          unity.clear();
          unitz.clear();

          for (u = 0; u < unitx.length; u++) {
            sz = 0;
            switch (lcsRandom(4)) {
              case 0:
                sx = -1;
                sy = 0;
              case 1:
                sx = 1;
                sy = 0;
              case 2:
                sx = 0;
                sy = 1;
              case 3:
                sx = 0;
                sy = -1;
            }
            sx += unitx[u];
            sy += unity[u];
            sz += unitz[u];

            if (sx >= 0 &&
                sx < MAPX &&
                sy >= 0 &&
                sy < MAPY &&
                sz >= 0 &&
                sz < MAPZ) {
              SiteTile tile = levelMap[sx][sy][sz];
              if (!tile.wall && tile.door) {
                tile.door = false;
                tile.locked = false;
                tile.cantUnlock = false;
                tile.knownLock = false;
              }
            }
          }

          unitx.clear();
          unity.clear();
          unitz.clear();

          //NEW WAVES
          //IF THERE AREN'T ENOUGH UNITS AROUND
          //AND THEY HAVEN'T BEEN SCARED OFF
          //MORE WAVES WILL ATTACK
          //AND IT GETS WORSE AND WORSE
          //but not as bad as it used to get,
          //since the extra waves are small
          activeSite!.siege.attackTime++;
          if (activeSite!.siege.attackTime >= 30 + lcsRandom(10) &&
              (locz != 0 ||
                  locx < (MAPX / 2 - 3) ||
                  locx > (MAPX / 2 + 3) ||
                  locy > 5)) {
            activeSite!.siege.attackTime = 0;

            int existingUnits = 0;
            for (int x = 0; x < MAPX; x++) {
              for (int y = 0; y < MAPY; y++) {
                for (int z = 0; z < MAPZ; z++) {
                  if (levelMap[x][y][z].siegeflag &
                          (SIEGEFLAG_UNIT | SIEGEFLAG_HEAVYUNIT) >
                      0) {
                    existingUnits++;
                  }
                }
              }
            }

            //PLACE UNITS
            int lx, ly, lz, unitnum = 7 - existingUnits, count = 10000;
            if (unitnum < 0) unitnum = 0;

            for (int t = 0; t < unitnum; t++) {
              count = 10000;
              do {
                lx = lcsRandom(7) + (MAPX ~/ 2) - 3;
                ly = lcsRandom(5);
                lz = 0;
                count--;
                if (count == 0) break;
              } while ((levelMap[lx][ly][lz].flag &
                          (SITEBLOCK_BLOCK | SITEBLOCK_DOOR | SITEBLOCK_EXIT) >
                      0) ||
                  (levelMap[lx][ly][lz].siegeflag &
                          (SIEGEFLAG_UNIT |
                              SIEGEFLAG_HEAVYUNIT |
                              SIEGEFLAG_TRAP) >
                      0));
              levelMap[lx][ly][lz].siegeflag |= SIEGEFLAG_UNIT;
            }

            if (!activeSite!.compound.bollards &&
                activeSite!.siege.activeSiegeType == SiegeType.police &&
                activeSite!.siege.escalationState.index >=
                    SiegeEscalation.tanks.index) {
              count = 10000;
              int hunitnum = 1;
              for (int t = 0; t < hunitnum; t++) {
                do {
                  lx = lcsRandom(7) + (MAPX ~/ 2) - 3;
                  ly = lcsRandom(5);
                  lz = 0;
                  count--;
                  if (count == 0) break;
                } while ((levelMap[lx][ly][lz].flag &
                            (SITEBLOCK_BLOCK |
                                SITEBLOCK_DOOR |
                                SITEBLOCK_EXIT) >
                        0) ||
                    (levelMap[lx][ly][lz].siegeflag &
                            (SIEGEFLAG_UNIT |
                                SIEGEFLAG_HEAVYUNIT |
                                SIEGEFLAG_TRAP) >
                        0));
                levelMap[lx][ly][lz].siegeflag |= SIEGEFLAG_HEAVYUNIT;
              }
            }
          }

          //CHECK FOR SIEGE UNITS
          //INCLUDING DAMAGED ONES
          if (currentTile.siegeflag & SIEGEFLAG_UNIT > 0) {
            if (await addsiegeencounter(SIEGEFLAG_UNIT)) {
              currentTile.siegeflag &= ~SIEGEFLAG_UNIT;
            }
          }
          if (currentTile.siegeflag & SIEGEFLAG_HEAVYUNIT > 0) {
            if (await addsiegeencounter(SIEGEFLAG_HEAVYUNIT)) {
              currentTile.siegeflag &= ~SIEGEFLAG_HEAVYUNIT;
            }
          }
          if (currentTile.siegeflag & SIEGEFLAG_UNIT_DAMAGED > 0) {
            if (await addsiegeencounter(SIEGEFLAG_UNIT_DAMAGED)) {
              currentTile.siegeflag &= ~SIEGEFLAG_UNIT_DAMAGED;
            }
          }

          //BAIL UPON VICTORY
          if (activeSite!.siege.kills >= 10 &&
              activeSite!.siege.tanks <= 0 &&
              activeSiteUnderSiege) {
            if (activeSite!.siege.underAttack) {
              sitestory!.type = NewsStories.squadDefended;
            } else {
              sitestory!.type = NewsStories.squadBrokeSiege;
            }

            if (activeSite!.siege.activeSiegeType == SiegeType.ccs) {
              // CCS DOES NOT capture the warehouse -- reverse earlier assumption of your defeat!
              if (activeSite!.type == SiteType.warehouse ||
                  activeSite!.type == SiteType.drugHouse) {
                activeSite!.controller = SiteController.lcs;
              }
            }

            await squadCleanup();

            //INFORM
            clearMessageArea();

            mvaddstrc(
                9, 1, lightGreen, "The Conservatives have shrunk back under ");
            mvaddstr(10, 1, "the power of your Liberal Convictions!");

            await getKey();

            await conquerText();
            await escapeSiege(true);

            //RESET MODE
            mode = GameMode.base;
            return;
          }
        }

        if (!activeSiteUnderSiege && newenc) {
          switch (makespecial) {
            case TileSpecial.computer:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if (siteAlarm || siteAlienated.alienated) {
                addstr("The computer has been unplugged.");

                await getKey();
              } else {
                addstr("The computer is occupied.");

                await getKey();

                prepareEncounter(siteType, false);
                if (encounter.length > 1) {
                  encounter.removeRange(1, encounter.length - 1);
                }
              }
            case TileSpecial.table:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if (siteAlarm || siteAlienated.alienated) {
                addstr("Some people are hiding under the table.");
              } else {
                addstr("The table is occupied.");
              }
              await getKey();

              prepareEncounter(siteType, false);
            case TileSpecial.tent:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if (siteAlarm || siteAlienated.alienated) {
                addstr("Somebody is hiding in the tent.");
              } else {
                addstr("Someone is in the tent.");
              }
              await getKey();

              prepareEncounter(siteType, false, num: 1);
            case TileSpecial.parkBench:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if (siteAlarm || siteAlienated.alienated) {
                addstr("The bench is empty.");

                await getKey();
              } else {
                addstr("There are people sitting here.");

                await getKey();

                prepareEncounter(siteType, false);
              }
            case TileSpecial.securityCheckpoint:
              await specialSecurityCheckpoint();
            case TileSpecial.securityMetalDetectors:
              await specialSecurityMetaldetectors();
            case TileSpecial.securitySecondVisit:
              specialSecuritySecondvisit();
            case TileSpecial.clubBouncer:
              await specialBouncerAssessSquad();
            case TileSpecial.clubBouncerSecondVisit:
              specialBouncerGreetSquad();
            case TileSpecial.ceoOffice:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if ((siteAlarm ||
                      siteAlienated.alienated ||
                      activeSiteUnderSiege) &&
                  uniqueCreatures.ceo.alive) {
                if (!noProfanity) {
                  addstr("Damn! ");
                } else {
                  addstr("[Rats!] ");
                }
                addstr("The CEO must have fled to a panic room.");

                await getKey();
              } else {
                if (uniqueCreatures.ceo.alive &&
                    uniqueCreatures.ceo.location == activeSite) {
                  addstr("The CEO is in his study.");

                  await getKey();

                  encounter.clear();
                  if (uniqueCreatures.ceo.formerHostage &&
                      uniqueCreatures.ceo.align == Alignment.conservative) {
                    encounter.add(Creature.fromId(CreatureTypeIds.guardDog));
                    encounter.add(Creature.fromId(CreatureTypeIds.guardDog));
                    encounter.add(Creature.fromId(CreatureTypeIds.merc));
                    encounter.add(Creature.fromId(CreatureTypeIds.merc));
                    encounter.add(Creature.fromId(CreatureTypeIds.merc));
                    encounter.add(uniqueCreatures.ceo);
                    printEncounter();
                    await encounterMessage("The CEO snarls, ",
                        line2: "\"Fool me twice... can't get fooled again!\"");
                    siteAlarm = true;

                    await enemyattack(encounter);
                    await creatureadvance();
                  } else {
                    encounter.add(uniqueCreatures.ceo);
                  }
                } else {
                  addstr("The CEO's study lies empty.");

                  await getKey();
                }
              }
            case TileSpecial.apartmentLandlord:
              clearMessageArea();
              setColor(white);
              move(9, 1);
              currentTile.special = TileSpecial.none;
              if (siteAlarm ||
                  siteAlienated.alienated ||
                  activeSiteUnderSiege) {
                addstr("The landlord is out of the office.");

                await getKey();
              } else {
                addstr("The landlord is in.");

                await getKey();

                encounter.clear();
                encounter.add(Creature.fromId(CreatureTypeIds.landlord));
              }
            case TileSpecial.bankTeller:
              await specialBankTeller();
            case TileSpecial.ccsBoss:
              await specialCCSBoss();
            case TileSpecial.ovalOfficeNW:
            case TileSpecial.ovalOfficeNE:
            case TileSpecial.ovalOfficeSW:
            case TileSpecial.ovalOfficeSE:
              await specialOvalOffice();
            default:
              bool squadmoved = olocx != locx || olocy != locy || olocz != locz;
              bool isApartment = activeSite!.type == SiteType.apartment ||
                  activeSite!.type == SiteType.tenement ||
                  activeSite!.type == SiteType.upscaleApartment;

              if (squadmoved && isApartment) {
                // Rarely encounter someone in apartments
                if (!oneIn(3)) break;
              }

              prepareEncounter(siteType, activeSite!.highSecurity > 0);

              if (isApartment && currentTile.restricted) {
                // Nobody likes you if you're breaking into their home
                for (var e in encounter) {
                  conservatize(e);
                }
              }

              if (currentTile.bloody && !siteAlarm) {
                Creature? conservative = encounter
                    .firstWhereOrNull((e) => e.align == Alignment.conservative);
                if (conservative != null) {
                  printEncounter();
                  if (currentTile.megaBloody) {
                    await encounterMessage("${conservative.type.name} ${[
                      "looks around wildly, shocked by the gore.",
                      "is looking around with great fear.",
                      "is searching for the source of the blood.",
                      "gasps in horror at the carnage.",
                      "is looking around near the bloody mess.",
                      "is trying to figure out who did this.",
                      "is inspecting the crime scene.",
                      "looks very on edge about the bloody mess.",
                    ].random}");
                  } else {
                    await encounterMessage("${conservative.type.name} ${[
                      "looks at the blood nervously.",
                      "glances at the blood anxiously.",
                      "seems agitated by the blood.",
                      "is investigating the blood.",
                      "glances around nervously.",
                      "seems more on guard than usual.",
                      "is looking around for threats.",
                      "looks confused and upset.",
                    ].random}");
                  }
                }
              } else if (gameOptions.encounterWarnings &&
                  encounter.isNotEmpty) {
                // Show an encounter warning based on whether the squad moved or not and the size of the encounter
                clearMessageArea();
                printEncounter();

                String message;
                if (squadmoved) {
                  switch (encounter.length) {
                    case 1:
                      message = "There is someone up ahead.";
                    case <= 3:
                      message = "There are a few people up ahead.";
                    case <= 6:
                      message = "There is a group of people up ahead.";
                    default:
                      message = "There is a crowd of people up ahead.";
                  }
                } else {
                  switch (encounter.length) {
                    case 1:
                      message = "There is someone passing by.";
                    case <= 3:
                      message = "There are a few people passing by.";
                    case <= 6:
                      message = "There is a group of people passing by.";
                    default:
                      message = "There is a crowd of people passing by.";
                  }
                }
                await encounterMessage(message);
              }
          }
          hostcheck = true;
        }

        if (!activeSiteUnderSiege) {
          if ((locx != olocx || locy != olocy || locz != olocz) && !newenc)
          //PUT BACK SPECIALS
          {
            for (Creature e in encounter) {
              if (e.isWillingToTalk && e.type.id == CreatureTypeIds.landlord) {
                levelMap[olocx][olocy][olocz].special =
                    TileSpecial.apartmentLandlord;
              }
              if (e.isWillingToTalk &&
                  e.type.id == CreatureTypeIds.bankTeller) {
                levelMap[olocx][olocy][olocz].special = TileSpecial.bankTeller;
              }
            }
            encounter.clear();
          }
        }

        if (locx != olocx || locy != olocy || locz != olocz) {
          //NUKE GROUND LOOT
          groundLoot.clear();

          //MOVE BLOOD
          if (levelMap[olocx][olocy][olocz].megaBloody) {
            currentTile.bloody = true;
          }
        }

        knowmap(locx, locy, locz);
      }
    }
  }
}

/* site - determines spin on site news story, "too hot" timer */
Future<void> _resolveSite() async {
  bool doesNotReportCrimes = activeSite!.type == SiteType.bombShelter ||
      activeSite!.type == SiteType.barAndGrill ||
      activeSite!.type == SiteType.bunker ||
      activeSite!.type == SiteType.warehouse ||
      activeSite!.type == SiteType.drugHouse ||
      activeSite!.type == SiteType.homelessEncampment;
  if ((siteAlarm ||
          sitestory!.drama.any((d) => d == Drama.bankTellerRobbery)) &&
      !doesNotReportCrimes) {
    commitPotentialCrimes();
  } else {
    clearPotentialCrimes();
  }
  if (!newsStories.contains(sitestory!)) newsStories.add(sitestory!);

  // Reset isWillingToTalk for unique creatures
  uniqueCreatures.ceo.isWillingToTalk = true;
  uniqueCreatures.president.isWillingToTalk = true;

  if (siteCrime > 50 + lcsRandom(50)) {
    if (activeSite!.controller == SiteController.unaligned) {
      // Capture a warehouse or crack den?
      if (activeSite!.type == SiteType.warehouse ||
          activeSite!.type == SiteType.drugHouse) {
        // Capture safehouse for the glory of the LCS!
        activeSite!.controller = SiteController.lcs;
        initSiteName(activeSite!);
        activeSite!.closed = 0;
        activeSite!.heat = siteCrime;
      } else {
        activeSite!.closed = siteCrime ~/ 10; // Close down site
      }
    } else if (activeSite!.controller == SiteController.lcs &&
        !activeSite!.siege.underAttack) {
      activeSite!.heat += siteCrime; // Increase heat
    }

    // Out sleepers
    if (activeSite!.controller == SiteController.ccs) {
      for (Creature p in pool) {
        if (p.sleeperAgent && p.location == activeSite) {
          p.sleeperAgent = false;
          erase();
          setColor(lightGray);
          mvaddstr(8, 1, "Sleeper ");
          addstr(p.name);
          addstr(" has been outed by your bold attack!");

          mvaddstr(10, 1,
              "The Liberal is now at your command as a normal squad member.");

          p.base = squad[0].base;
          p.location = p.base;

          await getKey();
        }
      }
    }
  } else if (siteCrime > 10 &&
      (activeSite!.controller == SiteController.unaligned ||
          activeSite!.rent > 500)) {
    if (activeSite!.type != SiteType.bombShelter &&
        activeSite!.type != SiteType.barAndGrill &&
        activeSite!.type != SiteType.bunker &&
        activeSite!.type != SiteType.warehouse &&
        activeSite!.type != SiteType.drugHouse) {
      if (securityable(activeSite!.type) > 0) {
        activeSite!.highSecurity = siteCrime;
      } else {
        activeSite!.closed = 7;
      }
    }
  }
}

Future<void> _fightSubdued() async {
  int p;
  //int ps=find_police_station(chaseseq.location);

  chaseSequence?.friendcar.removeWhere((e) => vehiclePool.contains(e));
  int hostagefreed = 0;
  int stolen = 0;
  // Police assess stolen goods in inventory
  for (int l = 0; l < activeSquad!.loot.length; l++) {
    if (activeSquad!.loot[l].isLoot) {
      stolen++;
    }
  }
  for (Creature c in squad.toList()) {
    c.wantedForCrimes.update(Crime.theft, (value) => value + stolen);
    await captureCreature(c);
  }
  squad.clear();
  for (p = 0; p < pool.length; p++) {
    for (var w in pool[p].body.parts) {
      w.bleeding = 0;
    }
  }

  clearMessageArea();
  clearCommandArea();
  mvaddstrc(9, 1, purple, "The police subdue and arrest the squad.");

  if (hostagefreed > 0) {
    mvaddstr(10, 1, "Your hostage");
    if (hostagefreed > 1) {
      addstr("s are free.");
    } else {
      addstr(" is free.");
    }
  }

  await getKey();
}

/* behavior when the player bumps into a door in sitemode */
Future<void> _openDoor(bool restricted) async {
  bool locked = currentTile.flag & SITEBLOCK_LOCKED > 0,
      alarmed = currentTile.flag & SITEBLOCK_ALARMED > 0,
      vaultDoor = currentTile.flag & SITEBLOCK_METAL > 0,
      //   known_locked=currentTile.flag&SITEBLOCK_KLOCK>0,
      cantUnlock = currentTile.flag & SITEBLOCK_CLOCK > 0;

  if (vaultDoor) {
    // Vault door, not usable by bumping
    clearMessageArea();

    mvaddstrc(9, 1, white, "The vault door is impenetrable.");

    await getKey();

    return;
  }

  bool hasSecurity = false;
  for (Creature p in squad) {
    if (p.skill(Skill.security) != 0) {
      hasSecurity = true;
      break;
    }
  }

  if (alarmed) {
    // Unlocked but alarmed door, clearly marked as such
    clearMessageArea();

    setColor(white);
    move(9, 1);
    if (locked) {
      addstr("This door appears to be wired to an alarm.");

      mvaddstr(10, 1, "Try the door anyway? (Yes or No)");
    } else {
      addstr("EMERGENCY EXIT ONLY. ALARM WILL SOUND.");

      mvaddstr(10, 1, "Open the door anyway? (Yes or No)");
    }

    while (true) {
      int c = await getKey();

      if (c == Key.y) {
        break;
      } else if (c == Key.n) {
        return;
      }
    }
  }

  if (locked && !cantUnlock && hasSecurity) {
    currentTile.flag |= SITEBLOCK_KLOCK;

    while (true) {
      clearMessageArea();

      mvaddstrc(9, 1, white, "You try the door, but it is locked.");

      move(10, 1);
      if (alarmed) {
        addstr("Try to disable the alarm and lock? (Yes or No)");
      } else {
        addstr("Try to pick the lock? (Yes or No)");
      }

      int c = await getKey();

      clearMessageArea();

      if (c == Key.y) {
        UnlockResult result = await unlock(UnlockTypes.door);
        // If the unlock was successful

        if (result == UnlockResult.unlocked || result == UnlockResult.bashed) {
          // Unlock the door
          currentTile.flag &= ~(SITEBLOCK_LOCKED | SITEBLOCK_ALARMED);
          addDramaToSiteStory(Drama.unlockedDoor);
          if (siteAlarmTimer < 0 || siteAlarmTimer > 50) siteAlarmTimer = 50;

          if ([SiteType.apartment, SiteType.tenement, SiteType.upscaleApartment]
              .contains(activeSite?.type)) {
            // If you're at an apartment building, charge with breaking
            // and entering every time you break into another apartment
            addPotentialCrime(squad, Crime.breakingAndEntering);
          } else {
            // Otherwise, charge with breaking and entering only once per
            // building by supplying a reasonKey
            addPotentialCrime(squad, Crime.breakingAndEntering,
                reasonKey: "door");
          }
        }
        // Else perma-lock it if an attempt was made
        else if (result == UnlockResult.failed) {
          currentTile.flag |= SITEBLOCK_CLOCK;
          if (currentTile.flag & SITEBLOCK_ALARMED > 0) {
            mvaddstrc(10, 1, white, "Your tampering sets off the alarm!");

            siteAlarm = true;
            await getKey();
          }
        }

        // Check for people noticing you fiddling with the lock
        if (result == UnlockResult.bashed) {
          await noticeCheck();
        }
        return;
      } else if (c == Key.n) {
        return;
      }
    }
  } else if (locked || (!restricted && alarmed)) {
    while (true) {
      clearMessageArea();

      setColor(white);
      move(9, 1);
      if (locked) {
        addstr("You shake the handle but it is ");
        if (hasSecurity) addstr("still ");
        addstr("locked.");
      } else {
        addstr("It's locked from the other side.");
      }

      mvaddstr(10, 1, "Force it open? (Yes or No)");

      int c = await getKey();

      if (c == Key.y) {
        UnlockResult result = await bash(BashTypes.door);

        if (result == UnlockResult.unlocked || result == UnlockResult.bashed) {
          currentTile.flag &= ~SITEBLOCK_DOOR;
          int time = 0;
          if (siteAlarmTimer > time || siteAlarmTimer == -1) {
            siteAlarmTimer = time;
          }
          if (currentTile.flag & SITEBLOCK_ALARMED > 0) {
            clearMessageArea();
            mvaddstrc(9, 1, white, "The alarm goes off!");

            siteAlarm = true;

            await getKey();
          }
          siteCrime++;
          addDramaToSiteStory(Drama.brokeDownDoor);
          if ([SiteType.apartment, SiteType.tenement, SiteType.upscaleApartment]
              .contains(activeSite?.type)) {
            // If you're at an apartment building, charge with breaking
            // and entering every time you break into another apartment
            addPotentialCrime(squad, Crime.breakingAndEntering);
          } else {
            // Otherwise, charge with breaking and entering only once per
            // building by supplying a reasonKey
            addPotentialCrime(squad, Crime.breakingAndEntering,
                reasonKey: "door");
          }
        }

        if (result != UnlockResult.noAttempt) {
          await noticeCheck(difficulty: Difficulty.heroic);
        }

        break;
      } else if (c == Key.n) {
        break;
      }
    }
  } else {
    currentTile.flag &= ~SITEBLOCK_DOOR;
    if (alarmed) {
      // Opened an unlocked but clearly marked emergency exit door
      clearMessageArea();
      mvaddstrc(9, 1, white, "It opens easily. The alarm goes off!");

      siteAlarm = true;

      await getKey();
    }
  }
}

Future<void> squadCleanup() async {
  //Check for hauled prisoners/corpses
  for (Creature p in squad.toList()) {
    p.location = p.base;
    if (p.prisoner != null) {
      //If this is an LCS member or corpse being hauled
      if (pool.contains(p.prisoner)) {
        //Take them out of the squad
        p.prisoner!.squad = null;
        //Set base and current location to squad's safehouse
        p.prisoner!.location = p.base;
        p.prisoner!.base = p.base;
      } else {
        //A kidnapped conservative
        //Convert them into a prisoner
        await kidnaptransfer(p.prisoner!);
      }
      p.prisoner = null;
    }
  }
  //Clear all bleeding and prison escape flags
  for (Creature p in pool) {
    p.justEscaped = false;
    for (var bp in p.body.parts) {
      bp.bleeding = 0;
    }
  }
}

void addLootToSquad(Item item) => activeSquad!.loot.add(item);
