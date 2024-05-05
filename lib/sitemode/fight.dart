import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/armor.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/money.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/sitemode/haul_kidnap.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/talk/talk_in_combat.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* attack handling for each side as a whole */
Future<void> youattack() async {
  bool wasalarm = siteAlarm;

  for (Creature p in activeSquad!.livingMembers) {
    List<Creature> superEnemies = [];
    List<Creature> dangerousEnemies = [];
    List<Creature> enemies = [];
    List<Creature> nonEnemies = [];

    for (Creature e in encounter) {
      if (e.alive) {
        if (e.isEnemy && !e.nonCombatant) {
          if (e.type.tank && e.stunned == 0) {
            superEnemies.add(e);
          } else if ((e.attack.socialDamage || e.attack.averageDamage > 20) &&
              e.blood >= e.maxBlood * 0.4 &&
              e.stunned == 0) {
            dangerousEnemies.add(e);
          } else {
            enemies.add(e);
          }
        } else {
          nonEnemies.add(e);
        }
      }
    }

    if (superEnemies.isEmpty && dangerousEnemies.isEmpty && enemies.isEmpty) {
      if (encounter.any((e) => e.isEnemy && e.alive)) {
        await intimidate(p);
      }
      return;
    }

    Creature target;
    if (superEnemies.isNotEmpty && !p.attack.socialDamage) {
      target = superEnemies.random;
    } else if (dangerousEnemies.isNotEmpty) {
      target = dangerousEnemies.random;
    } else if (enemies.isNotEmpty) {
      target = enemies.random;
    } else {
      target = superEnemies.random;
    }

    bool mistake = false;
    // 1% chance to accidentally hit bystanders
    if (nonEnemies.isNotEmpty && oneIn(100)) {
      target = nonEnemies.random;
      mistake = true;
    }

    int beforeblood = target.blood;

    bool attacked = await attack(p, target, mistake);

    if (attacked) {
      if (mistake) {
        await alienationCheck(mistake);
        siteCrime += 10;
      } else {
        siteCrime += 3;
        addjuice(p, 1, 200);
      }
      addDramaToSiteStory(Drama.attacked);
      // Charge with assault if first strike
      if (siteAlarm &&
          (!wasalarm ||
              (beforeblood > target.blood && beforeblood == target.maxBlood)) &&
          activeSite?.siege.underSiege == false) {
        if (p.equippedWeapon == null) {
          criminalize(p, Crime.assault);
        }
      }
    }

    if (!target.alive) {
      if (mode == GameMode.site) makeLoot(target, groundLoot);
      encounter.remove(target);
      if (!mistake) {
        for (Creature p in squad) {
          addjuice(p, 5, 500);
        }
      }
    }
  }

  for (Creature e in encounter) {
    if (e.alive && e.isEnemy) {
      siteAlarm = true;
      break;
    }
  }

  //COVER FIRE
  if (activeSiteUnderSiege) {
    for (Creature p in pool) {
      if (!p.alive) continue;
      if (p.align != Alignment.liberal) continue;
      if (p.squad == activeSquad) continue;
      if (p.location != activeSite) continue;

      Attack? chosenAttack = p.getAttack(true, false, false);
      if (chosenAttack != null) {
        List<Creature> goodtarg = [];
        List<Creature> badtarg = [];

        for (Creature e in encounter) {
          if (e.alive) {
            if (e.isEnemy) {
              goodtarg.add(e);
            } else {
              badtarg.add(e);
            }
          }
        }

        if (goodtarg.isEmpty) return;

        Creature target = goodtarg.random;

        bool mistake = false;

        if (badtarg.isNotEmpty && oneIn(100)) {
          target = badtarg.random;
          mistake = true;
        }

        bool fired = await attack(p, target, mistake);

        if (fired) {
          if (mistake) {
            await alienationCheck(mistake);
            siteCrime += 10;
          }

          criminalize(p, Crime.assault);
        }

        if (!target.alive) {
          if (mode == GameMode.site) makeLoot(target, groundLoot);
          encounter.remove(target);
        }
      }
    }
  }
}

Future<void> enemyattack() async {
  const List<String> escapeCrawling = [
    " crawls off moaning...",
    " crawls off whimpering...",
    " crawls off trailing blood...",
    " crawls off screaming...",
    " crawls off crying...",
    " crawls off sobbing...",
    " crawls off whispering...",
    " crawls off praying...",
    " crawls off cursing..."
  ];

  const List<String> escapeRunning = [
    " makes a break for it!",
    " escapes crying!",
    " runs away!",
    " gets out of there!",
    " runs hollering!",
    " bolts out of there!",
    " runs away screaming!",
  ];

  for (int i = encounter.length - 1; i >= 0; i--) {
    Creature e = encounter[i];
    if (!e.alive) continue;

    if (siteAlarm &&
        e.type.id == CreatureTypeIds.bouncer &&
        e.align != Alignment.liberal) {
      conservatize(e);
    }
    if (e.isEnemy) {
      e.noticedParty = true;
      e.isWillingToTalk = false;
    }

    if (mode != GameMode.carChase) {
      bool runsAway = e.calculateWillRunAway();

      if (runsAway && e.body is HumanoidBody) {
        if (!await incapacitated(e, false)) {
          clearMessageArea();

          mvaddstrc(16, 1, white, e.name);
          if (e.body.legok < 2 || e.blood < e.maxBlood * 0.45) {
            addstr(escapeCrawling.random);
          } else {
            addstr(escapeRunning.random);
          }

          encounter.remove(e);

          printParty();
          printEncounter();

          await getKey();
        }

        continue;
      }
    }

    List<Creature> goodtarg = [];
    List<Creature> badtarg = [];

    if (e.isEnemy) {
      for (Creature p in squad) {
        if (p.alive) goodtarg.add(p);
      }
      for (Creature e2 in encounter) {
        if (e2.alive && e2 != e) {
          if (!activeSiteUnderSiege) {
            badtarg.add(e2);
          } else {
            if (e2.isEnemy) {
              badtarg.add(e2);
            } else {
              goodtarg.add(e2);
            }
          }
        }
      }
    } else {
      for (Creature e2 in encounter) {
        if (e2.alive && e2.isEnemy) {
          goodtarg.add(e2);
        } else if (e2.alive && e2 != e) {
          badtarg.add(e2);
        }
      }
    }

    if (goodtarg.isEmpty) return;

    Creature target = goodtarg.random;

    bool canmistake = true;

    if (e.attack.socialDamage && encounter.length < ENCMAX) canmistake = false;

    if (canmistake) {
      if (e.isEnemy && target.prisoner != null && oneIn(2)) {
        await attack(e, target.prisoner!, true);
        if (!target.prisoner!.alive) {
          if (target.prisoner!.align != Alignment.liberal ||
              target.prisoner!.body.fellApart) {
            CreatureType prisonerType = target.prisoner!.type;

            if (prisonerType.majorEnemy) {
              siteCrime += 30;
            }

            makeLoot(target.prisoner!, groundLoot);

            String bodyDesc = target.prisoner!.body.fellApart
                ? "the bloody mess"
                : "${target.prisoner!.name}'s body";

            await encounterMessage("${target.name} drops $bodyDesc.");
            target.prisoner = null;
          }
        }
        continue;
      }

      if (oneIn(10 * e.weaponSkill + 10) && badtarg.isNotEmpty) {
        target = badtarg.random;
        if (target.justConverted) {
          await attack(e, target, false);
        } else {
          await attack(e, target, true);
        }
        if (!target.alive) {
          if (mode == GameMode.site) makeLoot(target, groundLoot);
          encounter.remove(target);
        }
        continue;
      }
    }

    await attack(e, target, false);
    if (!target.alive && encounter.contains(target)) {
      if (mode == GameMode.site) makeLoot(target, groundLoot);
      encounter.remove(target);
    }
  }
}

/* attack handling for an individual creature and its target */
Future<bool> attack(Creature a, Creature t, bool mistake,
    {bool forceMelee = false}) async {
  bool targetInSquad = t.squad == activeSquad && t.align == Alignment.liberal;
  bool targetIsLeader = targetInSquad && t.boss == null;

  clearMessageArea();
  setColor(a.align.color);

  //INCAPACITATED
  a.incapacitatedThisRound = false;
  if (await incapacitated(a, false)) {
    a.incapacitatedThisRound = true;

    return false;
  }

  //RELOAD
  if ((a.willReload(mode == GameMode.carChase, forceMelee) ||
          a.hasThrownWeapon) &&
      !forceMelee) {
    move(16, 1);
    if (a.hasThrownWeapon) {
      a.readyAnotherThrowingWeapon();
      addstr("${a.name} readies another ${a.weapon.getName()}.");
    } else {
      a.reload(true);
      addstr("${a.name} reloads.");
    }

    printParty();
    printEncounter();

    await getKey();

    return false;
  }
  bool canSocialAttack =
      a.align == Alignment.liberal || encounter.length < ENCMAX;
  bool forceRanged = mode == GameMode.carChase;
  bool forceNoReload = forceMelee || !a.canReload();
  Attack? attackUsed = a.getAttack(forceRanged, forceMelee, forceNoReload,
      allowSocial: canSocialAttack);

  if (attackUsed == null) return false; // No viable attack to use, so don't

  if (attackUsed.socialDamage) {
    if (a.align == Alignment.liberal || encounter.length < ENCMAX) {
      return socialAttack(a, t, attackUsed);
    }
  }

  bool melee = !attackUsed.ranged;
  bool sneakAttack = false;
  bool addNastyOff = false;

  mvaddstr(16, 1, "${a.name} ");
  if (mistake) addstr("MISTAKENLY ");
  if (a.weapon.type.idName == "WEAPON_NONE") {
    if (oneIn(a.skill(Skill.martialArts) + 1)) {
      addstr("punches");
    } else if (oneIn(a.skill(Skill.martialArts))) {
      addstr("swings at");
    } else if (oneIn(a.skill(Skill.martialArts) - 1)) {
      addstr("kicks");
    } else if (oneIn(a.skill(Skill.martialArts) - 2)) {
      addstr("pummels");
    } else if (oneIn(a.skill(Skill.martialArts) - 3)) {
      addstr("strikes");
    } else if (oneIn(a.skill(Skill.martialArts) - 4)) {
      addstr("jump kicks");
    } else {
      addstr("slows time and touches");
      addNastyOff = true;
    }
  } else {
    if (attackUsed.canBackstab && a.align == Alignment.liberal && !mistake) {
      if (!t.noticedParty && !siteAlarm) {
        sneakAttack = true;
        addstr("sneaks up on");
        if (siteAlarmTimer > 10 || siteAlarmTimer < 0) siteAlarmTimer = 10;
        t.noticedParty = true;
        t.isWillingToTalk = false;
      }
    }

    if (!sneakAttack) {
      addstr(attackUsed.attackDescription.random);
      siteAlarm = true;
    }
  }

  addstr(" ${t.name}");

  if (a.equippedWeapon != null && !attackUsed.thrown) {
    addstr(" with a ${a.weapon.getName()}");
  }
  addstr("!");

  await getKey();

  int bonus =
      0; // Accuracy bonus or penalty that does NOT affect damage or counterattack chance

  //SKILL EFFECTS
  Skill wsk = attackUsed.skill;

  // Basic roll
  int aroll = a.skillRoll(wsk);
  int droll = (t.skillRoll(Skill.dodge) / 2).round();
  //Founders are better dodgers
  if (targetIsLeader) droll = t.skillRoll(Skill.dodge);
  if (sneakAttack) {
    droll = (t.attributeRoll(Attribute.wisdom) / 2).round();
    aroll += a.skillRoll(Skill.stealth);
    a.train(Skill.stealth, 10);
    a.train(wsk, 10);
  } else {
    t.train(Skill.dodge, aroll * 2);
    a.train(wsk, droll * 2 + 5);
  }

  // Hostages interfere with attack
  if (t.prisoner != null) bonus -= lcsRandom(10);
  if (a.prisoner != null) aroll -= lcsRandom(10);

  //Injured people suck at attacking, are like fish in a barrel to attackers
  aroll = healthmodroll(aroll, a);
  droll = healthmodroll(droll, t);

  // If in a foot chance, double the debilitating effect of injuries
  if (mode == GameMode.footChase) {
    aroll = healthmodroll(aroll, a);
    droll = healthmodroll(droll, t);
  }

  // Prevent negative rolls
  if (aroll < 0) aroll = 0;
  if (droll < 0) droll = 0;

  // Weapon accuracy bonuses and penalties
  bonus += attackUsed.accuracyBonus;

  //USE BULLETS
  int bursthits = 0; // Tracks number of hits.

  int thrownweapons =
      0; // Used by thrown weapons to remove the weapons at the end of the turn if needed

  if (a.equippedWeapon == null) //Move into WEAPON_NONE -XML
  {
    // Martial arts multi-strikes
    bursthits = 1 + lcsRandom(a.skill(Skill.martialArts) ~/ 3 + 1);
    if (bursthits > 5) bursthits = 5;
    if (!a.human) {
      bursthits = 1; // Whoops, must be human to use martial arts fanciness
    }
  } else {
    if (mode == GameMode.site &&
        lcsRandom(100) < (attackUsed.fire?.chanceCausesDebris ?? 0)) {
      activeSite!.changes
          .add(SiteTileChange(locx, locy, locz, SITEBLOCK_DEBRIS));
    }
    if (mode == GameMode.site &&
        lcsRandom(100) < (attackUsed.fire?.chance ?? 0)) {
      // Fire!
      if (!levelMap[locx][locy][locz].burning ||
          !levelMap[locx][locy][locz].debris) {
        levelMap[locx][locy][locz].setFlag(SITEBLOCK_FIRE_START, true);
        siteCrime += 3;
        addjuice(a, 5, 500);
        if (!activeSiteUnderSiege && squad.contains(a)) {
          criminalizeparty(Crime.arson);
          addDramaToSiteStory(Drama.arson);
        }
      }
    }

    for (int i = 0; i < attackUsed.numberOfAttacks; i++) {
      if (attackUsed.usesAmmo) {
        if (a.weapon.ammo > 0) {
          a.weapon.ammo -= 1;
        } else {
          break;
        }
      } else if (attackUsed.thrown) {
        if (((a.spareAmmo?.stackSize ?? 0) + 1) - thrownweapons > 0) {
          thrownweapons++;
        } else {
          break;
        }
      }

      if (sneakAttack) {
        bursthits = 1; // Backstab only hits once
        break;
      }
      // Each shot in a burst is increasingly less likely to hit
      if (aroll + bonus - i * attackUsed.successiveAttacksDifficulty > droll) {
        bursthits++;
      }
    }
  }

  if (aroll + bonus > droll &&
      attackUsed.averageDamage > t.blood &&
      targetIsLeader &&
      mode != GameMode.carChase) {
    // If the attack has a high chance of killing the target, and the target
    // is the leader, find a liberal to jump in front of the bullet
    for (Creature alternate in squad) {
      if (alternate == t) continue;
      if (alternate.attribute(Attribute.heart) > 8 &&
          alternate.attribute(Attribute.agility) > 4) {
        clearMessageArea();
        mvaddstrc(16, 1, lightGreen, alternate.name);
        if (!t.alive) {
          addstr(" misguidedly");
        } else {
          addstr(" heroically");
        }
        addstr(" shields ${t.name}");
        if (!t.alive) addstr("'s corpse");
        addstr("!");

        //Instant juice!! Way to take the bullet!!
        addjuice(alternate, 10, 1000);
        await getKey();

        t = alternate;
        break;
      }
    }
  }

  move(17, 1);
  debugPrint("${a.name} rolls $aroll + $bonus, ${t.name} rolls $droll");
  Map<BodyPart, int> weights = {};
  for (BodyPart p in t.body.parts) {
    if (p.missing) continue;
    if (p.immuneInCar && mode == GameMode.carChase) {
      continue;
    }
    int size = p.size;
    if (sneakAttack) {
      if (p.weakSpot) size *= 4;
      if (!p.critical) continue;
    }
    if (aroll + bonus > droll + 10) {
      if (p.weakSpot) size *= 2;
      if (p.critical) size *= 2;
    } else if (aroll + bonus > droll + 5) {
      if (p.critical) size *= 2;
    }
    weights[p] = size;
  }
  BodyPart? hitPart;
  if (weights.isNotEmpty) hitPart = lcsRandomWeighted(weights);

  if (hitPart != null && aroll + bonus > droll) {
    //HIT!
    String str = a.name;
    if (sneakAttack) {
      str += " stabs the ";
    } else {
      str += " hits the ";
    }

    if (t.armor.covers(hitPart)) {
      if (hitPart.weakSpot && t.armor.type.headArmor > 4) {
        str += "helmet";
      } else if (hitPart.critical && t.armor.type.bodyArmor > 4) {
        str += "body armor";
      } else if (t.armor.type.limbArmor > 4) {
        str += "${hitPart.name.toLowerCase()} armor";
      } else {
        str += hitPart.name.toLowerCase();
      }
    } else {
      str += hitPart.name.toLowerCase();
    }

    // show multiple hits
    if ((attackUsed.alwaysDescribeHit || bursthits > 1) &&
        a.weapon.type.idName != "WEAPON_NONE") {
      String multiHit = switch (bursthits) {
        1 => "",
        2 => " twice",
        3 => " three times",
        4 => " four times",
        5 => " five times",
        _ => " $bursthits times",
      };
      str += ", ${attackUsed.hitDescription}$multiHit";
    }

    int damamount = 0;
    int strengthmin = attackUsed.ranged ? 0 : attackUsed.strengthMin;
    int strengthmax = attackUsed.ranged ? 0 : attackUsed.strengthMax;
    SeverType severtype = attackUsed.severType;

    bool damagearmor = false;
    int armorpiercing = 0;

    severtype = attackUsed.severType;
    if (addNastyOff) severtype = SeverType.nasty;
    int random = attackUsed.randomDamage + a.skill(wsk);
    int fixed = attackUsed.fixedDamage + a.skill(wsk);
    if (sneakAttack) fixed += 100;
    if (bursthits >= (attackUsed.critical?.hitsRequired ?? 999) &&
        lcsRandom(100) < (attackUsed.critical?.chance ?? 0)) {
      random = attackUsed.critical?.randomDamage ?? random;
      fixed = attackUsed.critical?.fixedDamage ?? fixed;
      severtype = attackUsed.critical?.severType ?? severtype;
      //debugPrint("Critical hit!");
    }
    //debugPrint("Random: $random, fixed: $fixed, hits: $bursthits");
    while (bursthits > 0) {
      damamount += lcsRandom(random) + fixed;
      bursthits--;
    }
    damagearmor = attackUsed.damagesArmor;
    armorpiercing = attackUsed.armorPenetration;
    //debugPrint("Initial damage roll: $damamount");

    int mod = 0;

    if (strengthmax > strengthmin) {
      // Melee attacks: Maximum strength bonus, minimum
      // strength to deliver full damage
      int strength = a.attribute(Attribute.strength);
      if (strength > strengthmax) strength = strengthmax;
      mod += strength - strengthmin;
      armorpiercing += (strength - strengthmin) ~/ 2;
    }

    // DAMAGE BONUS FROM HIGH SKILL
    mod += a.skill(wsk);

    int predamamount = damamount;
    bool bruiseOnly = false;
    damamount =
        damagemod(t, attackUsed, damamount, hitPart, armorpiercing, mod);
    if (damamount < predamamount / 4 &&
        damamount < 20 &&
        damamount > 0 &&
        damamount < t.blood / 4) {
      bruiseOnly = true;
      str += " to little effect";
    }
    //debugPrint("Damage after mod: $damamount");

    if (damamount > 0) {
      Creature target = t;

      if (bruiseOnly) {
        hitPart.bruised = true;
      } else {
        hitPart.bleeding = attackUsed.bleeds;
        hitPart.cut = attackUsed.cuts;
        hitPart.torn = attackUsed.tears;
        hitPart.shot = attackUsed.shoots;
        hitPart.burned = attackUsed.burns;
        hitPart.bruised = attackUsed.bruises;
      }

      int severamount = 200;
      if (hitPart.weakSpot) {
        severamount = (severamount / 2).round();
      } else if (hitPart.critical) {
        severamount *= 4;
      }

      if (severtype != SeverType.none &&
          damamount >= severamount &&
          !bruiseOnly) {
        if (severtype == SeverType.clean) {
          hitPart.cleanOff = true;
          if (hitPart.critical && !hitPart.weakSpot) {
            str += " CUTTING IT IN HALF!";
          } else {
            str += " CUTTING IT OFF!";
          }
        } else if (severtype == SeverType.nasty) {
          hitPart.nastyOff = true;
          str += " BLOWING IT APART!";
        }
      } else {
        str += ".";
      }

      if (!hitPart.critical && target.alive) {
        if (lcsRandom(100) >= attackUsed.noDamageReductionForLimbsChance) {
          damamount = min(damamount, (target.blood / 2).round());
        }
      }

      if (damagearmor && target.equippedArmor != null) {
        armordamage(target.armor, hitPart, damamount);
      }

      //debugPrint("Target blood before hit: ${target.blood}/${target.maxBlood}");
      target.blood -= damamount;
      //debugPrint("Target blood after hit: ${target.blood}/${target.maxBlood}");

      levelMap[locx][locy][locz].bloody = true;

      mvaddstrc(17, 1, a.align.color, str);

      if ((hitPart.critical && hitPart.missing) || target.blood <= 0) {
        bool alreadydead = !target.alive;
        bool alienate = false;

        if (!alreadydead) {
          target.die();

          int killjuice = 5 + (t.juice / 20).round();
          if ((t.align.index - a.align.index).abs() == 2) {
            if (t.type.majorEnemy || t.type.tank) {
              killjuice += 50;
            }
            if (activeSite?.siege.underSiege == false &&
                mode == GameMode.site) {
              if (!t.type.majorEnemy &&
                  !t.type.canPerformArrests &&
                  !t.type.lawEnforcement &&
                  !t.type.edgelord &&
                  !t.type.ccsMember &&
                  !t.type.tank &&
                  t.calculateWillRunAway()) {
                killjuice = 0;
              }
            }
            addjuice(a, killjuice, 1000); // Instant juice
          } else {
            addjuice(a, -killjuice, -50);
          }

          if (target.isEnemy && (!t.type.animal || animalsArePeopleToo)) {
            if (activeSiteUnderSiege) activeSite!.siege.kills++;
            if (activeSiteUnderSiege && t.type.tank) {
              activeSite!.siege.tanks--;
            }
            if (activeSite?.controller == SiteController.ccs) {
              if (target.type.id == CreatureTypeIds.ccsArchConservative) {
                ccsBossKills++;
              }
              ccsSiegeKills++;
            }
          }
          if (target.squadId == null &&
              (!target.type.animal || animalsArePeopleToo) &&
              !sneakAttack) {
            siteCrime += 10;
            if (t.type.majorEnemy) {
              siteCrime += 90;
            }
            if (a.squad == activeSquad) {
              if (mode == GameMode.site && !activeSiteUnderSiege) {
                alienate = true;
              }
              addDramaToSiteStory(Drama.killedSomebody);
              criminalizeparty(Crime.murder);
            }
          }
        }

        await getKey();

        if (severtype == SeverType.nasty) bloodblast(t.armor);

        if (!alreadydead) {
          await severloot(t, groundLoot);
          clearMessageArea();
          addDeathMessage(target);

          printParty();
          printEncounter();

          if (alienate) alienate = await alienationCheck(true);

          if (!alienate) await getKey();

          if (target.prisoner != null) {
            await freehostage(t, FreeHostageMessage.newLine);
          }
        }
      } else {
        printParty();
        printEncounter();

        await getKey();

        if (severtype == SeverType.nasty) bloodblast(t.armor);

        //SPECIAL WOUNDS
        if (!hitPart.missing && target.body is HumanoidBody) {
          bool heavydam = false;
          bool breakdam = false;
          bool pokedam = false;
          HumanoidBody body = target.body as HumanoidBody;
          if (damamount >= 12) {
            if (attackUsed.shoots ||
                attackUsed.burns ||
                attackUsed.tears ||
                attackUsed.cuts) {
              heavydam = true;
            }
          }

          if (damamount >= 10) {
            if (attackUsed.cuts || attackUsed.tears || attackUsed.shoots) {
              pokedam = true;
            }
            if (attackUsed.bruises) {
              breakdam = true;
            }
          }

          if (damamount >= 20) {
            if (attackUsed.cuts || attackUsed.shoots || attackUsed.tears) {
              breakdam = true;
            }
          }

          void maxBlood(double proportion) {
            if (target.blood > target.maxBlood * proportion) {
              target.blood = (target.maxBlood * proportion).round();
            }
          }

          if (hitPart == body.head) {
            clearMessageArea();
            setColor(a.align.color);

            switch (lcsRandom(7)) {
              case 0:
                if ((!body.missingLeftEye ||
                        !body.missingRightEye ||
                        !body.missingNose) &&
                    heavydam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s face is blasted off!");
                  } else if (attackUsed.burns) {
                    addstr("'s face is burned away!");
                  } else if (attackUsed.tears) {
                    addstr("'s face is torn off!");
                  } else if (attackUsed.cuts) {
                    addstr("'s face is cut away!");
                  } else {
                    addstr("'s face is removed!");
                  }

                  await getKey();

                  body.missingLeftEye = true;
                  body.missingRightEye = true;
                  body.missingNose = true;
                  maxBlood(0.2);
                }
              case 1:
                if (body.teeth > 0) {
                  int teethminus = lcsRandom(body.teeth) + 1;

                  move(16, 1);
                  if (teethminus > 1) {
                    if (teethminus == body.teeth) {
                      addstr("All ");
                    }
                    addstr("$teethminus of ${target.name}'s teeth are ");
                  } else if (body.teeth > 1) {
                    addstr("One of ${target.name}'s teeth is ");
                  } else {
                    addstr("${target.name}'s last tooth is ");
                  }

                  if (attackUsed.shoots) {
                    addstr("shot out!");
                  } else if (attackUsed.burns) {
                    addstr("burned away!");
                  } else if (attackUsed.tears) {
                    addstr("gouged out!");
                  } else if (attackUsed.cuts) {
                    addstr("cut out!");
                  } else {
                    addstr("knocked out!");
                  }

                  await getKey();

                  body.teeth -= teethminus;
                }
              case 2:
                if (!body.missingRightEye && heavydam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s right eye is blasted out!");
                  } else if (attackUsed.burns) {
                    addstr("'s right eye is burned away!");
                  } else if (attackUsed.tears) {
                    addstr("'s right eye is torn out!");
                  } else if (attackUsed.cuts) {
                    addstr("'s right eye is poked out!");
                  } else {
                    addstr("'s right eye is removed!");
                  }

                  await getKey();

                  body.missingRightEye = true;
                  maxBlood(0.5);
                }
              case 3:
                if (!body.missingLeftEye && heavydam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s left eye is blasted out!");
                  } else if (attackUsed.burns) {
                    addstr("'s left eye is burned away!");
                  } else if (attackUsed.tears) {
                    addstr("'s left eye is torn out!");
                  } else if (attackUsed.cuts) {
                    addstr("'s left eye is poked out!");
                  } else {
                    addstr("'s left eye is removed!");
                  }

                  await getKey();

                  body.missingLeftEye = true;
                  maxBlood(0.5);
                }
              case 4:
                if (!body.missingTongue && heavydam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s tongue is blasted off!");
                  } else if (attackUsed.burns) {
                    addstr("'s tongue is burned away!");
                  } else if (attackUsed.tears) {
                    addstr("'s tongue is torn out!");
                  } else if (attackUsed.cuts) {
                    addstr("'s tongue is cut off!");
                  } else {
                    addstr("'s tongue is removed!");
                  }

                  await getKey();

                  body.missingTongue = true;
                  maxBlood(0.5);
                }
              case 5:
                if (!body.missingNose && heavydam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s nose is blasted off!");
                  } else if (attackUsed.burns) {
                    addstr("'s nose is burned away!");
                  } else if (attackUsed.tears) {
                    addstr("'s nose is torn off!");
                  } else if (attackUsed.cuts) {
                    addstr("'s nose is cut off!");
                  } else {
                    addstr("'s nose is removed!");
                  }

                  await getKey();

                  body.missingNose = true;
                  maxBlood(0.5);
                }
              case 6:
                if (!body.brokenNeck && breakdam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s neck bones are shattered!");
                  } else {
                    addstr("'s neck is broken!");
                  }

                  await getKey();

                  body.neck = InjuryState.untreated;
                  maxBlood(0.2);
                }
            }
          }
          if (hitPart == body.torso) {
            clearMessageArea();
            setColor(a.align.color);

            switch (lcsRandom(11)) {
              case 0:
                if (!body.brokenUpperSpine && breakdam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s upper spine is shattered!");
                  } else {
                    addstr("'s upper spine is broken!");
                  }

                  await getKey();

                  body.upperSpine = InjuryState.untreated;
                  maxBlood(0.2);
                }
              case 1:
                if (!body.brokenLowerSpine && breakdam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s lower spine is shattered!");
                  } else {
                    addstr("'s lower spine is broken!");
                  }

                  await getKey();

                  body.lowerSpine = InjuryState.untreated;
                  maxBlood(0.2);
                }
              case 2:
                if (body.puncturedRightLung && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s right lung is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s right lung is torn!");
                  } else {
                    addstr("'s right lung is punctured!");
                  }

                  await getKey();

                  body.puncturedRightLung = true;
                  maxBlood(0.2);
                }
              case 3:
                if (body.puncturedLeftLung && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s left lung is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s left lung is torn!");
                  } else {
                    addstr("'s left lung is punctured!");
                  }

                  await getKey();

                  body.puncturedLeftLung = true;
                  maxBlood(0.2);
                }
              case 4:
                if (body.puncturedHeart && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s heart is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s heart is torn!");
                  } else {
                    addstr("'s heart is punctured!");
                  }

                  await getKey();

                  body.puncturedHeart = true;
                  if (target.blood > 3) {
                    target.blood = 3;
                  }
                }
              case 5:
                if (body.puncturedLiver && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s liver is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s liver is torn!");
                  } else {
                    addstr("'s liver is punctured!");
                  }

                  await getKey();

                  body.puncturedLiver = true;
                  maxBlood(0.5);
                }
              case 6:
                if (body.puncturedStomach && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s stomach is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s stomach is torn!");
                  } else {
                    addstr("'s stomach is punctured!");
                  }

                  await getKey();

                  body.puncturedStomach = true;
                  maxBlood(0.5);
                }
              case 7:
                if (body.puncturedRightKidney && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s right kidney is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s right kidney is torn!");
                  } else {
                    addstr("'s right kidney is punctured!");
                  }

                  await getKey();

                  body.puncturedRightKidney = true;
                  maxBlood(0.5);
                }
              case 8:
                if (body.puncturedLeftKidney && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s left kidney is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s left kidney is torn!");
                  } else {
                    addstr("'s left kidney is punctured!");
                  }

                  await getKey();

                  body.puncturedLeftKidney = true;
                  maxBlood(0.5);
                }
              case 9:
                if (body.puncturedSpleen && pokedam) {
                  mvaddstr(16, 1, target.name);
                  if (attackUsed.shoots) {
                    addstr("'s spleen is blasted!");
                  } else if (attackUsed.tears) {
                    addstr("'s spleen is torn!");
                  } else {
                    addstr("'s spleen is punctured!");
                  }

                  await getKey();

                  body.puncturedSpleen = true;
                  maxBlood(0.5);
                }
              case 10:
                if (body.ribs > 0 && breakdam) {
                  int ribminus = lcsRandom(body.ribs) + 1;

                  move(16, 1);
                  if (ribminus > 1) {
                    if (ribminus == body.ribs) {
                      addstr("All ");
                    }
                    addstr("$ribminus  of ${target.name}'s ribs are ");
                  } else if (body.ribs > 1) {
                    addstr("One of ${target.name}'s ribs is ");
                  } else {
                    addstr("${target.name}'s last unbroken rib is ");
                  }

                  if (attackUsed.shoots) {
                    addstr("shot apart!");
                  } else {
                    addstr("broken!");
                  }

                  await getKey();

                  body.ribs -= ribminus;
                }
            }
          }

          await severloot(target, groundLoot);
        }

        //setColor(white);
      }
    } else {
      addstr(" to no effect.");

      printParty();
      printEncounter();

      await getKey();
    }
  } else {
    setColor(white);

    if (melee &&
        aroll < droll - 10 &&
        t.blood > 70 &&
        t.human &&
        t.getAttack(false, true, true) != null) {
      mvaddstr(17, 1, "${t.name} knocks the blow aside and counters!");
      await getKey();
      await attack(t, a, false, forceMelee: true);
    } else {
      move(17, 1);
      if (sneakAttack) {
        addstr(t.name);
        addstr([
          " notices at the last moment!",
          " notices before the attack connects!",
          " spins and blocks the attack!",
          " jumps back and cries out in alarm!",
        ].random);
        siteAlarm = true;
      } else if (t.skillCheck(
          Skill.dodge, Difficulty.average)) //Awesome dodge or regular one?
      {
        addstr(t.name);
        addstr([
          " dodges the attack!",
          " leaps out of the way!",
          " does the Matrix dodge!",
          " sidesteps the attack!",
          " dodges into cover!",
        ].random);
      } else {
        addstr("${a.name} misses.");
      }

      printParty();
      printEncounter();

      await getKey();
    }
  }

  for (; thrownweapons > 0; thrownweapons--) {
    if (a.hasThrownWeapon) a.readyAnotherThrowingWeapon();
    a.dropWeapon();
  }

  return true;
}

/* modifies a combat roll based on the creature's critical injuries */
int healthmodroll(int aroll, Creature a) {
  return aroll - lcsRandom(a.body.combatRollModifier * 2);
}

/* adjusts attack damage based on armor, other factors */
int damagemod(Creature t, Attack attackUsed, int damamount,
    BodyPart hitlocation, int armorpenetration, int mod) {
  int armor = 0;
  if (hitlocation.weakSpot) {
    armor = t.armor.type.headArmor;
  } else if (hitlocation.critical) {
    armor = t.armor.type.bodyArmor;
  } else {
    armor = t.armor.type.limbArmor;
  }
  if (!t.armor.covers(hitlocation)) {
    armor = 0;
  }
  int naturalArmor = hitlocation.naturalArmor;
  if (attackUsed.burns) {
    naturalArmor = (naturalArmor / 2).round();
    if (t.armor.type.fireResistant) {
      if (t.armor.damaged) {
        armorpenetration = (armorpenetration / 2).round();
      } else {
        armorpenetration = 0;
      }
      armor += 2;
    }
  }
  armor += naturalArmor;

  armor -= t.armor.quality - 1;
  if (t.armor.damaged) armor -= 1;
  debugPrint(
      "Armor: $armor, $armorpenetration penetration, pre-armor mod: $mod");

  armor = armor - armorpenetration;
  if (armor > 0) mod = mod - armor * max(2, armor);

  debugPrint(
      "Damage mod: $mod, damage before application: $damamount, final armor $armor");

  if (mod > 10) {
    mod = 10; // Cap damage multiplier (every 5 points adds 1x damage)
  }

  if (mod <= -1) {
    damamount = (damamount / (1.0 - 1.0 * mod)).round();
    debugPrint("Damage reduced to $damamount");
  } else if (mod >= 0) {
    damamount = (damamount * (1.0 + 0.2 * mod)).round();
    debugPrint("Damage increased to $damamount");
  }

  if (damamount < 0) damamount = 0;

  if (hitlocation.weakSpot) damamount = damamount * 2;
  if (!hitlocation.critical) damamount = (damamount / 2).round();
  debugPrint("Final damage after hit location effects: $damamount");

  return damamount;
}

Future<bool> socialAttack(Creature a, Creature t, Attack attackUsed) async {
  int resist = 0;

  clearMessageArea();
  mvaddstrc(16, 1, white,
      "${a.name} ${attackUsed.attackDescription.random} ${t.name}!");

  int attack = a.skillRoll(attackUsed.skill);
  if (t.align == Alignment.liberal) {
    resist = t.attributeRoll(Attribute.heart);
  } else {
    resist = t.attributeRoll(Attribute.wisdom);
  }
  resist += t.skill(Skill.psychology);
  a.train(attackUsed.skill, max(1, resist));

  if ((t.type.tank || (t.type.animal && !animalsArePeopleToo)) ||
      (a.isEnemy && t.brainwashed)) {
    mvaddstr(17, 1, "${t.name} is immune to the attack!");
  } else if (a.align == t.align) {
    mvaddstr(17, 1, "${t.name} already agrees with ${a.name}.");
  } else if (attack > resist) {
    if (attackUsed.stuns) {
      t.stunned += (attack - resist) ~/ 4;
    }
    if (a.isEnemy) {
      if (t.juice > 100) {
        mvaddstr(17, 1, "${t.name} loses juice!");
        addjuice(t, -50, 100);
      } else if (lcsRandom(15) > t.attribute(Attribute.wisdom) ||
          t.attribute(Attribute.wisdom) < t.attribute(Attribute.heart)) {
        mvaddstr(17, 1, "${t.name} is tainted with Wisdom!");
        t.adjustAttribute(Attribute.wisdom, 1);
      } else if (t.align == Alignment.liberal && t.seduced) {
        mvaddstr(17, 1, "${t.name} can't bear to leave!");
      } else {
        if (a.align == Alignment.conservative) {
          mvaddstr(17, 1, "${t.name} is turned Conservative");
          t.stunned = 0;
          if (t.prisoner != null) {
            await freehostage(t, FreeHostageMessage.continueLine);
          }
          addstr("!");
        } else {
          mvaddstr(17, 1, "${t.name} doesn't want to fight anymore");
          t.stunned = 0;
          if (t.prisoner != null) {
            await freehostage(t, FreeHostageMessage.continueLine);
          }
          addstr("!");
        }

        if (!encounter.contains(t)) encounter.add(t);
        pool.remove(t);
        if (a.align == Alignment.conservative) {
          conservatize(t);
          t.isWillingToTalk = false;
        } else if (a.align == Alignment.liberal) {
          liberalize(t);
          t.isWillingToTalk = true;
        } else {
          t.isWillingToTalk = true;
        }
        t.noticedParty = true;
        t.squad = null;
      }
    } else {
      if (t.juice >= 1) {
        mvaddstr(17, 1, "${t.name} seems less badass!");
        addjuice(t, -100, 0);
      } else if (!t.attributeCheck(Attribute.heart, Difficulty.average) ||
          t.attribute(Attribute.heart) < t.attribute(Attribute.wisdom)) {
        mvaddstr(17, 1, "${t.name}'s Heart swells!");
        t.adjustAttribute(Attribute.heart, 1);
      } else {
        mvaddstr(17, 1, "${t.name} has turned Liberal!");
        t.stunned = 0;

        liberalize(t);
        t.infiltration /= 2;
        t.justConverted = true;
        t.isWillingToTalk = true;
      }
    }
  } else {
    mvaddstr(17, 1, "${t.name} remains strong.");
  }

  printParty();
  printEncounter();

  await getKey();

  return true;
}

/* destroys armor, masks, drops weapons based on severe damage */
Future<void> severloot(Creature cr, List<Item> loot) async {
  int armok = cr.body.armok;

  if (cr.equippedWeapon != null && armok == 0) {
    clearMessageArea();
    mvaddstrc(16, 1, yellow, "The ");
    addstr(cr.weapon.getName(sidearm: true));
    addstr(" slips from");
    mvaddstr(17, 1, cr.name);
    addstr("'s grasp.");

    await getKey();

    if (mode == GameMode.site) {
      cr.dropWeaponAndAmmo(lootPile: loot);
    } else {
      cr.dropWeaponAndAmmo();
    }
  }

  HumanoidBody? body;
  if (cr.body is HumanoidBody) {
    body = cr.body as HumanoidBody;
  }

  if (body?.torso.missing == true &&
          cr.equippedArmor?.covers(body!.torso) == true ||
      (body?.head.missing == true && cr.equippedArmor?.type.mask == true)) {
    clearMessageArea();
    mvaddstrc(16, 1, yellow, cr.name);
    addstr("'s ");
    addstr(cr.armor.shortName);
    addstr(" has been destroyed.");

    await getKey();

    cr.strip();
  }
}

/* damages the selected armor if it covers the body part specified */
void armordamage(Armor armor, BodyPart bp, int damamount) {
  int d2 = armor.type.durability ~/ 2;
  if (armor.covers(bp) && lcsRandom(d2) + d2 < damamount) {
    if (armor.damaged) {
      if (lcsRandom(damamount * armor.quality) > lcsRandom(d2 * 2) + d2 * 2) {
        armor.quality += 1;
      }
    } else {
      armor.damaged = true;
    }
  }
}

/* blood explosions */
void bloodblast(Armor armor) {
  //GENERAL
  armor.bloody = true;

  if (mode != GameMode.site) return;

  levelMap[locx][locy][locz].megaBloody = true;

  //HIT EVERYTHING
  for (Creature p in squad) {
    if (oneIn(2)) {
      p.equippedArmor?.bloody = true;
    }
  }

  for (Creature e in encounter) {
    if (oneIn(2)) {
      e.equippedArmor?.bloody = true;
    }
  }

  //REFRESH THE SCREEN
  printSiteMap(locx, locy, locz);
  refresh();
}

void makeLoot(Creature cr, List<Item> lootPile) {
  debugPrint("Making loot for ${cr.name} into $lootPile");
  cr.dropWeaponAndAmmo(lootPile: lootPile);
  cr.strip(lootPile: lootPile);
  if (cr.money > 0 && mode == GameMode.site) {
    lootPile.add(Money(cr.money));
  }
}

/* checks if the creature can fight and prints flavor text if they can't */
Future<bool> incapacitated(Creature a, bool noncombat) async {
  bool incapacitated = false;
  bool printed = false;

  if (a.blood <= a.maxBlood * 0.2 ||
      (a.blood <= a.maxBlood * 0.5 && (oneIn(2) || a.incapacitatedThisRound))) {
    incapacitated = true;
    if (a.type.tank) {
      a.incapacitatedThisRound = false;
      if (noncombat) {
        clearMessageArea();

        mvaddstrc(16, 1, white, "The ");
        addstr(a.name);
        switch (lcsRandom(3)) {
          case 0:
            addstr(" smokes...");
          case 1:
            addstr(" smolders.");
          case 2:
            addstr(" burns...");
        }

        printed = true;
      }
    } else if (a.type.animal) {
      a.incapacitatedThisRound = false;
      if (noncombat) {
        clearMessageArea();
        mvaddstrc(16, 1, white, "The ");
        addstr(a.name);
        switch (lcsRandom(3)) {
          case 0:
            addstr(" yelps in pain...");
          case 1:
            if (noProfanity) {
              addstr(" [makes a stinky].");
            } else {
              addstr(" soils the floor.");
            }
          case 2:
            addstr(" yowls pitifully...");
        }

        printed = true;
      }
    } else {
      a.incapacitatedThisRound = false;
      if (noncombat) {
        clearMessageArea();
        mvaddstrc(16, 1, white, a.name);
        switch (lcsRandom(54)) {
          case 0:
            addstr(" desperately cries out to Jesus.");
          case 1:
            if (noProfanity) {
              addstr(" [makes a stinky].");
            } else {
              addstr(" soils the floor.");
            }
          case 2:
            addstr(" whimpers in a corner.");
          case 3:
            addstr(" begins to weep.");
          case 4:
            addstr(" vomits.");
          case 5:
            addstr(" chortles...");
          case 6:
            addstr(" screams in pain.");
          case 7:
            addstr(" asks for mother.");
          case 8:
            addstr(" prays softly...");
          case 9:
            addstr(" clutches at the wounds.");
          case 10:
            addstr(" reaches out and moans.");
          case 11:
            addstr(" hollers in pain.");
          case 12:
            addstr(" groans in agony.");
          case 13:
            addstr(" begins hyperventilating.");
          case 14:
            addstr(" shouts a prayer.");
          case 15:
            addstr(" coughs up blood.");
          case 16:
            if (mode != GameMode.carChase) {
              addstr(" stumbles against a wall.");
            } else {
              addstr(" leans against the door.");
            }
          case 17:
            addstr(" begs for forgiveness.");
          case 18:
            addstr(" shouts \"Why have you forsaken me?\"");
          case 19:
            addstr(" murmurs \"Why Lord?   Why?\"");
          case 20:
            addstr(" whispers \"Am I dead?\"");
          case 21:
            if (noProfanity) {
              addstr(" [makes a mess], moaning.");
            } else {
              addstr(" pisses on the floor, moaning.");
            }
          case 22:
            addstr(" whispers incoherently.");
          case 23:
            if (a.body.eyeok > 1) {
              addstr(" stares off into space.");
            } else if (a.body.eyeok == 1) {
              addstr(" stares into space with one empty eye.");
            } else {
              addstr(" stares out with hollow sockets.");
            }
          case 24:
            addstr(" cries softly.");
          case 25:
            addstr(" yells until the scream cracks dry.");
          case 26:
            if (a.body.teeth > 1) {
              addstr("'s teeth start chattering.");
            } else if (a.body.teeth == 1) {
              addstr("'s tooth starts chattering.");
            } else {
              addstr("'s gums start chattering.");
            }
          case 27:
            addstr(" starts shaking uncontrollably.");
          case 28:
            addstr(" looks strangely calm.");
          case 29:
            addstr(" nods off for a moment.");
          case 30:
            addstr(" starts drooling.");
          case 31:
            addstr(" seems lost in memories.");
          case 32:
            addstr(" shakes with fear.");
          case 33:
            addstr(" murmurs \"I'm so afraid...\"");
          case 34:
            addstr(" cries \"It can't be like this...\"");
          case 35:
            if (a.age < 20 && !a.type.animal) {
              addstr(" cries \"Mommy!\"");
            } else if (a.type.dog) {
              addstr(" murmurs \"What about my puppies?\"");
            } else {
              addstr(" murmurs \"What about my offspring?\"");
            }
          case 36:
            addstr(" shudders quietly.");
          case 37:
            addstr(" yowls pitifully.");
          case 38:
            addstr(" begins losing faith in God.");
          case 39:
            addstr(" muses quietly about death.");
          case 40:
            addstr(" asks for a blanket.");
          case 41:
            addstr(" shivers softly.");
          case 42:
            if (noProfanity) {
              addstr(" [makes a mess].");
            } else {
              addstr(" vomits up a clot of blood.");
            }
          case 43:
            if (noProfanity) {
              addstr(" [makes a mess].");
            } else {
              addstr(" spits up a cluster of bloody bubbles.");
            }
          case 44:
            addstr(" pleads for mercy.");
          case 45:
            addstr(" quietly asks for coffee.");
          case 46:
            addstr(" looks resigned.");
          case 47:
            addstr(" scratches at the air.");
          case 48:
            addstr(" starts to giggle uncontrollably.");
          case 49:
            addstr(" wears a look of pain.");
          case 50:
            addstr(" questions God.");
          case 51:
            addstr(" whispers \"Mama baby.  Baby loves mama.\"");
          case 52:
            addstr(" asks for childhood toys frantically.");
          case 53:
            addstr(" murmurs \"But I go to church...\"");
        }

        printed = true;
      }
    }
  } else if (a.stunned > 0) {
    if (noncombat) {
      a.stunned--;
      clearMessageArea();
      mvaddstrc(16, 1, white, a.name);
      switch (lcsRandom(11)) {
        case 0:
          addstr(" seems hesitant.");
        case 1:
          addstr(" is caught in self-doubt.");
        case 2:
          addstr(" looks around uneasily.");
        case 3:
          addstr(" begins to weep.");
        case 4:
          addstr(" asks \"Is this right?\"");
        case 5:
          addstr(" asks for guidance.");
        case 6:
          addstr(" is caught in indecision.");
        case 7:
          addstr(" feels numb.");
        case 8:
          addstr(" prays quietly.");
        case 9:
          addstr(" searches for the truth.");
        case 10:
          addstr(" tears up.");
      }

      printed = true;
    }
    incapacitated = true;
  } else if (!incapacitated && a.body.fullParalysis) {
    if (!noncombat) {
      clearMessageArea();
      mvaddstrc(16, 1, white, a.name);
      switch (lcsRandom(5)) {
        case 0:
          addstr(" looks on with authority.");
        case 1:
          addstr(" waits patiently.");
        case 2:
          addstr(" sits in thought.");
        case 3:
          addstr(" breathes slowly.");
        case 4:
          addstr(" considers the situation.");
      }

      printed = true;
    }

    incapacitated = true;
  }

  if (printed) {
    printParty();
    printEncounter();

    await getKey();
  }

  return incapacitated;
}

Future<void> captureCreature(Creature t) async {
  t.activity = Activity.none();
  t.dropWeaponAndAmmo();
  Armor clothes = Armor("ARMOR_CLOTHES");
  t.equippedArmor = clothes;
  t.sleeperAgent = false;

  await freehostage(t, FreeHostageMessage.none);
  if (t.justEscaped) {
    t.location = activeSite;
    if (activeSite!.isPartOfTheJusticeSystem) {
      Armor prisoner = Armor("ARMOR_PRISONER");
      t.equippedArmor = prisoner;
    }
    if (activeSite!.type == SiteType.prison) {
      t.heat = 0;
      t.wantedForCrimes.updateAll((key, value) => 0);
    }
  } else {
    t.location = findSiteInSameCity(
        activeSite?.city ?? t.site?.city, SiteType.policeStation);
  }

  t.squad = null;
}

/* describes a character's death */
void addDeathMessage(Creature cr) {
  setColor(yellow);

  move(16, 1);
  String str = "";

  BodyPart? head = cr.body.parts.firstWhereOrNull((bp) => bp.name == "Head");
  BodyPart? body = cr.body.parts.firstWhereOrNull((bp) => bp.name == "Torso");

  if (head?.missing == true) {
    str = cr.name;
    switch (lcsRandom(4)) {
      case 0:
        str += " reaches once where there ";
        addstr(str);
        move(17, 1);
        if (mode != GameMode.carChase) {
          addstr("is no head, and falls.");
        } else {
          addstr("is no head, and slumps over.");
        }
      case 1:
        if (mode != GameMode.carChase) {
          str += " stands headless for a ";
        } else {
          str += " sits headless for a ";
        }
        addstr(str);
        mvaddstr(17, 1, "moment then crumples over.");
      case 2:
        str += " squirts ";
        if (noProfanity) {
          str += "[red water]";
        } else {
          str += "blood";
        }
        str += " out of the ";
        addstr(str);
        move(17, 1);
        if (mode != GameMode.carChase) {
          addstr("neck and runs down the hall.");
        } else {
          addstr("neck and falls to the side.");
        }
      case 3:
        str += " sucks a last breath through ";
        addstr(str);
        mvaddstr(17, 1, "the neck hole, then is quiet.");
    }
  } else if (body?.missing == true) {
    str = cr.name;
    switch (lcsRandom(2)) {
      case 0:
        str += " breaks into pieces.";
      case 1:
        str += " falls apart and is dead.";
    }
    addstr(str);
  } else {
    str = cr.name;
    switch (lcsRandom(11)) {
      case 0:
        str += " cries out one last time ";
        addstr(str);
        mvaddstr(17, 1, "then is quiet.");
      case 1:
        str += " gasps a last breath and ";
        addstr(str);
        move(17, 1);
        if (noProfanity) {
          addstr("[makes a mess].");
        } else {
          addstr("soils the floor.");
        }
      case 2:
        str += " murmurs quietly, breathing softly. ";
        addstr(str);
        mvaddstr(17, 1, "Then all is silent.");
      case 3:
        str += " shouts \"FATHER!  Why have you ";
        addstr(str);
        mvaddstr(17, 1, "forsaken me?\" and dies in a heap.");
      case 4:
        str += " cries silently for mother, ";
        addstr(str);
        mvaddstr(17, 1, "breathing slowly, then not at all.");
      case 5:
        str += " breathes heavily, coughing up ";
        addstr(str);
        mvaddstr(17, 1, "blood...  then is quiet.");
      case 6:
        str += " silently drifts away, and ";
        addstr(str);
        mvaddstr(17, 1, "is gone.");
      case 7:
        str += " sweats profusely, murmurs ";
        addstr(str);
        move(17, 1);
        if (noProfanity) {
          addstr("something [good] about Jesus, and dies.");
        } else {
          addstr("something about Jesus, and dies.");
        }
      case 8:
        str += " whines loudly, voice crackling, ";
        addstr(str);
        mvaddstr(17, 1, "then curls into a ball, unmoving.");
      case 9:
        str += " shivers silently, whispering ";
        addstr(str);
        mvaddstr(17, 1, "a prayer, then all is still.");
      case 10:
        str += " speaks these final words: ";
        addstr(str);
        move(17, 1);
        switch (cr.align) {
          case Alignment.liberal:
            addstr(slogan);
          case Alignment.moderate:
            addstr("\"A plague on both your houses...\"");
          default:
            addstr("\"Better dead than liberal...\"");
            break;
        }
    }
  }
}

/* pushes people into the current squad (used in a siege) */
void autopromote(Site loc) {
  if (activeSquad == null) return;

  int partysize = squad.length;
  int partyalive = activeSquad!.livingMembers.length;
  int libnum = 0;

  if (partyalive == 6) return;

  for (int pl = 0; pl < pool.length; pl++) {
    if (pool[pl].location != loc) continue;
    if (pool[pl].alive && pool[pl].align == Alignment.liberal) libnum++;
  }

  if (partysize == libnum) return;

  squad.removeWhere((e) => !e.alive);

  for (int i = 0; i < 6 - partyalive; i++) {
    for (int pl = 0; pl < pool.length; pl++) {
      if (pool[pl].location != loc) continue;
      if (pool[pl].alive &&
          pool[pl].squadId == null &&
          pool[pl].align == Alignment.liberal) {
        pool[pl].squad = activeSquad;
        break;
      }
    }
  }
}
