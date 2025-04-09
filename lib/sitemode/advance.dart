/* handles end of round stuff for everyone */
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/haul_kidnap.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> creatureadvance() async {
  for (Creature p in squad) {
    if (!p.alive) continue;

    await advancecreature(p);
    if (p.prisoner != null) {
      await advancecreature(p.prisoner!);
      if (!p.prisoner!.alive && mode != GameMode.carChase) {
        if (p.prisoner!.align != Alignment.liberal) {
          clearMessageArea();
          setColor(white);
          move(9, 1);
          addstr(p.name);
          addstr(" drops ");
          addstr(p.prisoner!.name);
          addstr("'s body.");

          makeLoot(p.prisoner!, groundLoot);

          if (p.prisoner!.type.majorEnemy) siteCrime += 30;
          p.prisoner = null;

          await getKey();
        }
      }
    }
  }

  if (activeSiteUnderSiege) {
    for (Creature p in pool) {
      if (!p.alive) continue;
      if (p.squadId != null) continue;
      if (p.location != activeSite) continue;

      await advancecreature(p);
      autopromote(activeSite!);
    }
  }

  for (Creature e in encounter) {
    if (!e.alive) continue;

    await advancecreature(e);
  }

  if (mode != GameMode.carChase) {
    //TAKE THE INJURED WITH YOU
    await squadHaulImmobileAllies(false);

    //TAKE THE DEAD WITH YOU
    await squadHaulImmobileAllies(true);
  }

  for (int i = encounter.length - 1; i >= 0; i--) {
    Creature e = encounter[i];
    if (e.alive) continue;
    if (mode == GameMode.site) makeLoot(e, groundLoot);
    encounter.remove(e);
  }

  if (mode == GameMode.site) {
    if (siteAlarm && siteCrime > 10) postAlarmTimer++;

    if (siteAlarmTimer > 0 && !siteAlarm && siteCrime > 5) {
      siteAlarmTimer--;
      if (siteAlarmTimer <= 0) {
        siteAlarmTimer = 0;

        clearMessageArea();

        setColor(yellow);
        move(9, 1);
        addstr("The Squad smells Conservative panic.");

        printEncounter();

        await getKey();
      }
    }

    for (int z = 0; z < MAPZ; z++) {
      bool stairs = false; // Will check if higher levels are accessible

      for (int y = 0; y < MAPY; y++) {
        for (int x = 0; x < MAPX; x++) {
          if (levelMap[x][y][z].exit) continue;

          if (levelMap[x][y][z].special != TileSpecial.none) {
            if (levelMap[x][y][z].special == TileSpecial.stairsUp) {
              stairs = true;
            }
          }

          // Extinguish ending fires
          if (levelMap[x][y][z].fireEnd) {
            if (oneIn(15)) {
              levelMap[x][y][z].fireEnd = false;
              levelMap[x][y][z].debris = true;
            }
          }

          // Cool/spread peak fires
          if (levelMap[x][y][z].firePeak) {
            siteOnFire = true;
            if (oneIn(10)) {
              levelMap[x][y][z].firePeak = false;
              levelMap[x][y][z].fireEnd = true;
            } else if (oneIn(4)) // Spread fire
            {
              int dir = lcsRandom(4); // Random initial direction
              int tries = 0; // Will try all four directions before giving up

              while (tries < 4) {
                int xmod = 0, ymod = 0;
                switch (dir) {
                  case 0:
                    xmod = -1;
                  case 1:
                    xmod = 1;
                  case 2:
                    ymod = -1;
                  case 3:
                    ymod = 1;
                }
                // Check if the tile is a valid place to spread fire to
                if (x + xmod < MAPX &&
                    x + xmod >= 0 &&
                    y + ymod < MAPY &&
                    y + ymod >= 0 &&
                    !levelMap[x + xmod][y + ymod][z].burning &&
                    !levelMap[x + xmod][y + ymod][z].debris &&
                    !levelMap[x + xmod][y + ymod][z].exit &&
                    !levelMap[x + xmod][y + ymod][z].metal &&
                    !levelMap[x + xmod][y + ymod][z].outdoor) {
                  // Spread it
                  levelMap[x + xmod][y + ymod][z].fireStart = true;
                  break;
                }
                // Else try another direction
                tries++;
                dir++;
                dir %= 4;
              }
              if (tries ==
                  5) // If all four directions unacceptable, spread upward
              {
                // Check if up is valid
                if (z < MAPZ &&
                    !levelMap[x][y][z + 1].burning &&
                    !levelMap[x][y][z + 1].debris &&
                    !levelMap[x][y][z + 1].metal) {
                  // Spread it
                  levelMap[x][y][z + 1].fireStart = true;
                }
                // Else give up
              }
            }
          }

          // Aggrivate starting fires
          if (levelMap[x][y][z].fireStart) {
            if (oneIn(5)) {
              SiteTileChange change = SiteTileChange(x, y, z, SITEBLOCK_DEBRIS);
              activeSite!.changes.add(change);
              levelMap[x][y][z].wall = false;
              levelMap[x][y][z].door = false;
              levelMap[x][y][z].fireStart = false;
              levelMap[x][y][z].firePeak = true;
              siteCrime += 5;
            }
          }
        }
      }

      // If no stairs to the next level were found, don't continue to that level
      if (!stairs) break;
    }
  }
}

/* handles end of round stuff for one creature */
Future<void> advancecreature(Creature cr) async {
  if (!cr.alive) return;

  await incapacitated(cr, true);

  int bleed = 0, topmedicalskill = 0;
  Creature? topmedical;
  for (Creature c in activeSquad!.livingMembers) {
    if (c.stunned > 0 &&
        c.blood > 40 &&
        c.id != cr.id &&
        c.skill(Skill.firstAid) > topmedicalskill) {
      topmedicalskill = (topmedical = c).skill(Skill.firstAid);
    }
  }

  for (BodyPart w in cr.body.parts) {
    if (w.bleeding > 0) {
      if (lcsRandom(300) < cr.attribute(Attribute.heart)) {
        w.bleeding -= 1;
      } else if (cr.squadId != null &&
          topmedical != null &&
          topmedical.skillCheck(Skill.firstAid, Difficulty.hard)) {
        clearMessageArea();
        setColor(lightGreen);
        move(9, 1);
        addstr(topmedical.name);
        addstr(" was able to slow the bleeding of");
        move(10, 1);
        addstr(cr.name);
        addstr("'s wounds.");

        topmedical.train(Skill.firstAid, 50);
        w.bleeding = 0;

        await getKey();
      } else {
        bleed += w.bleeding;
        w.relativeHealth -= w.bleeding / cr.maxBlood;
      }
    }
  }

  if (mode == GameMode.site &&
      !oneIn(3) &&
      (levelMap[locx][locy][locz].firePeak ||
          levelMap[locx][locy][locz].fireEnd)) {
    int burndamage =
        (levelMap[locx][locy][locz].firePeak) ? lcsRandom(10) : lcsRandom(5);
    clearMessageArea();

    // Firefighter's bunker gear reduces burn damage
    if (cr.clothing.fireResistant) {
      // Base effect is 3/3 damage reduction, the denominator
      // increases with low quality or damaged gear
      int denom = 3;

      // Damaged gear
      if (cr.clothing.damaged) denom += 1;
      // Shoddy quality gear
      denom += cr.clothing.quality - 1;

      // Apply damage reduction
      burndamage = (burndamage * (1 - (3.0 / denom))).floor();
    }

    cr.blood -= burndamage;

    if (cr.blood <= 0) {
      // Blame LCS for fire deaths
      await creatureDie(cr, true);
    } else if (burndamage > 0) {
      setColor(darkRed);
      move(9, 1);
      addstr(cr.name);
      addstr(" is burned!");

      await getKey();
    }
  }

  if (bleed > 0) {
    clearMessageArea();

    cr.blood -= bleed;

    levelMap[locx][locy][locz].bloody = true;

    cr.equippedClothing?.bloody = true;

    if (cr.blood <= 0) {
      // Blame LCS for bleeding deaths unless they're liberal or moderate
      await creatureDie(cr, cr.align == Alignment.conservative);
    }
  }
}

Future<void> creatureDie(Creature cr, bool blameParty) async {
  cr.die();

  if (cr.align == Alignment.conservative) {
    if (activeSiteUnderSiege) activeSite!.siege.kills++;
    if (activeSiteUnderSiege && cr.type.tank) {
      activeSite!.siege.tanks--;
    }
    if (activeSite?.controller == SiteController.ccs) {
      if (cr.type.id == CreatureTypeIds.ccsArchConservative) ccsBossKills++;
      ccsSiegeKills++;
    }
  }

  if (cr.squadId == null) {
    siteCrime += 10;
    if (blameParty) {
      addDramaToSiteStory(Drama.killedSomebody);
      addPotentialCrime(squad, Crime.murder);
    }
  }
  addDeathMessage(cr);

  await getKey();

  if (cr.prisoner != null) {
    await freehostage(cr, FreeHostageMessage.newLine);
  }
}
