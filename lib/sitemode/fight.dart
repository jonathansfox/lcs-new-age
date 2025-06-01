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
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/clothing.dart';
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
import 'package:lcs_new_age/talk/talk_in_combat.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* attack handling for each side as a whole */
Future<void> youattack(List<Creature> validTargets) async {
  bool wasAlarm = siteAlarm;

  for (Creature p in activeSquad!.livingMembers) {
    await squadMemberAttacks(p, wasAlarm, validTargets);
  }

  // Alarm enemies
  for (Creature e in validTargets) {
    if (e.alive && e.isEnemy) {
      siteAlarm = true;
      break;
    }
  }

  // Cover fire from allies when defending/escaping from a crowded safehouse
  if (activeSiteUnderSiege) {
    for (Creature p in pool) {
      if (!p.alive) continue;
      if (p.align != Alignment.liberal) continue;
      if (p.squad == activeSquad) continue;
      if (p.location != activeSite) continue;

      Attack? chosenAttack = p.getAttack(true, false, false);
      if (chosenAttack != null) {
        await squadMemberAttacks(p, wasAlarm, validTargets);
      }
    }
  }
}

Future<void> squadMemberAttacks(
    Creature p, bool wasAlarm, List<Creature> validTargets) async {
  // Categorize npcs into danger levels
  List<Creature> superEnemies = [];
  List<Creature> dangerousEnemies = [];
  List<Creature> enemies = [];
  List<Creature> nonEnemies = [];
  for (Creature e in validTargets) {
    if (e.alive) {
      if (e.isEnemy &&
          ((!e.nonCombatant && !e.calculateWillRunAway()) ||
              e.type.majorEnemy)) {
        if (e.type.tank && e.stunned == 0) {
          superEnemies.add(e);
        } else if ((e.attack.socialDamage || e.attack.damage > 20) &&
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

  // Intimidate if no enemies present who aren't fleeing
  if (superEnemies.isEmpty &&
      dangerousEnemies.isEmpty &&
      enemies.isEmpty &&
      mode != GameMode.carChase) {
    if (validTargets.any((e) => e.isEnemy && e.alive)) {
      await intimidate(p);
    }
    return;
  }

  // Select one of the most dangerous enemies to attack
  Creature target;
  if (superEnemies.isNotEmpty && !p.attack.socialDamage) {
    target = superEnemies.random;
  } else if (dangerousEnemies.isNotEmpty) {
    target = dangerousEnemies.random;
  } else if (enemies.isNotEmpty) {
    target = enemies.random;
  } else if (superEnemies.isNotEmpty) {
    target = superEnemies.random;
  } else if (validTargets.isNotEmpty) {
    target = validTargets.random;
  } else {
    return; // No valid targets to attack
  }

  // <1% chance for the LCS to accidentally hit bystanders
  bool mistake = false;
  if (nonEnemies.isNotEmpty && oneIn(100 + p.skill(p.attack.skill) * 10)) {
    target = nonEnemies.random;
    mistake = true;
  }

  // Resolve attack on target
  bool attacked = await attack(p, target, mistake);

  if (attacked) {
    // Add juice, drama, size crime
    if (mistake) {
      siteCrime += 10;
    } else {
      siteCrime += 3;
      addjuice(p, 1, 200);
    }
    if (!p.weapon.type.musicalAttack) {
      addDramaToSiteStory(Drama.attacked);
      if (p.weapon.isCurrentlyLegal && p.weapon.isAGun) {
        addDramaToSiteStory(Drama.legalGunUsed);
      } else if (p.weapon.isAGun) {
        addDramaToSiteStory(Drama.illegalGunUsed);
      }
      // Charge with assault if first strike
      addPotentialCrime([p], Crime.assault, reasonKey: target.id.toString());
    } else {
      addPotentialCrime([p], Crime.disturbingThePeace,
          reasonKey: target.id.toString());
    }
  }

  // Dead foes drop loot, removed from encounter, grant bonus juice
  if (!target.alive && target.align == Alignment.conservative) {
    if (mode == GameMode.site) makeLoot(target, groundLoot);
    encounter.remove(target);
    validTargets.remove(target);
    if (!mistake) {
      for (Creature p in squad) {
        addjuice(p, 5, 500);
      }
    }
  }
}

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
const List<String> cowerInCombat = [
  " cowers in fear.",
  " cowers in the corner.",
  " stays in cover.",
  " looks around in panic.",
  " stays low to the ground.",
];

Future<void> enemyattack(List<Creature> possibleEnemies) async {
  for (int i = possibleEnemies.length - 1; i >= 0; i--) {
    Creature e = possibleEnemies[i];
    e.justAttacked = false;
    if (!e.alive) continue;

    // Moderate bouncers are converted to conservatives
    if (siteAlarm &&
        e.type.id == CreatureTypeIds.bouncer &&
        e.align != Alignment.liberal) {
      conservatize(e);
    }
    // Enemies notice you and become unwilling to talk
    if (e.isEnemy) {
      e.noticedParty = true;
      e.isWillingToTalk = false;
    }

    // Fleeing npcs escape
    if (mode != GameMode.carChase) {
      bool runsAway = e.calculateWillRunAway() || e.nonCombatant;
      if (mode == GameMode.carChase) runsAway = false;
      if (e.cantRunAway) runsAway = false;

      if (runsAway && e.body is HumanoidBody) {
        clearMessageArea();

        mvaddstrc(9, 1, white, e.name);
        if (e.body.legok < 2 || e.blood < e.maxBlood * 0.45) {
          addstr(escapeCrawling.random);
        } else {
          addstr(escapeRunning.random);
        }

        encounter.remove(e);
        possibleEnemies.remove(e);
        if (activeSiteUnderSiege) activeSite!.siege.kills++;

        printParty();
        printEncounter();

        await getKey();

        continue;
      } else if (e.nonCombatant && e.cantRunAway) {
        if (await incapacitated(e, false)) {
          e.incapacitatedThisRound = true;
        } else if (e.equippedWeapon != null) {
          clearMessageArea();
          mvaddstrc(9, 1, white, e.name);
          addstr(cowerInCombat.random);
          await getKey();
        }
        continue;
      }
    }

    // Categorize targets into good and bad buckets
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
      for (Creature e2 in possibleEnemies) {
        if (e2.alive && e2.isEnemy && !e2.nonCombatant && e2.stunned <= 0) {
          goodtarg.add(e2);
        } else if (e2.alive && e2 != e) {
          badtarg.add(e2);
        }
      }
    }

    // Take no action if nobody they want to attack is present
    if (goodtarg.isEmpty) return;

    Creature target = goodtarg.random;

    // If the attack will be a social attack, it can't have friendly fire
    bool canmistake = true;
    if (e.attack.socialDamage) canmistake = false;
    if (!e.attack.ranged) canmistake = false;
    if (mode == GameMode.carChase) canmistake = false;

    if (canmistake) {
      // Resolve hits on hostages and hauled liberals
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

      // Resolve friendly fire and neutrals caught in the crossfire
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
          possibleEnemies.remove(target);
        }
        continue;
      }
    }

    // Resolve attack on the intended target
    await attack(e, target, false);
    if (!target.alive && encounter.contains(target)) {
      if (mode == GameMode.site) makeLoot(target, groundLoot);
      encounter.remove(target);
      possibleEnemies.remove(target);
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
    a.justAttacked = false;
    return false;
  } else {
    a.justAttacked = true;
    a.cantRunAway = true;
  }

  //RELOAD
  if ((a.willReload(mode == GameMode.carChase, forceMelee) ||
          a.hasThrownWeapon) &&
      !forceMelee) {
    move(9, 1);
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
  bool forceRanged = mode == GameMode.carChase;
  bool canSocialAttack =
      (a.align == Alignment.liberal || encounter.length < ENCMAX) &&
          !forceRanged;
  bool forceNoReload = forceMelee || !a.canReload();
  Attack? attackUsed = a.getAttack(forceRanged, forceMelee, forceNoReload,
      allowSocial: canSocialAttack);

  if (attackUsed == null) return false; // No viable attack to use, so don't

  if (attackUsed.socialDamage) {
    if (a.align == Alignment.liberal || encounter.length < ENCMAX) {
      return socialAttack(a, t, attackUsed);
    }
  }

  bool melee = !attackUsed.ranged && !attackUsed.socialDamage;
  bool sneakAttack = false;
  bool addNastyOff = false;
  bool addStun = false;
  bool addAutoConvert = false;
  bool torsoOnly = false;
  int maxNumberOfAttacks = attackUsed.numberOfAttacks;
  double damageMultiplier = 1;

  mvaddstr(9, 1, "${a.name} ");
  if (mistake) addstr("MISTAKENLY ");
  if (a.weapon.type.idName == "WEAPON_NONE") {
    int result = a.skillRoll(Skill.martialArts);
    if (a.body is HumanoidBody) {
      if (result < Difficulty.easy) {
        addstr("flails at");
        maxNumberOfAttacks = 1;
        damageMultiplier = 0.5;
      } else if (result < Difficulty.average) {
        addstr("punches");
        maxNumberOfAttacks = 1;
        damageMultiplier = 1;
      } else if (result < Difficulty.hard) {
        addstr("kicks");
        maxNumberOfAttacks = 1;
        damageMultiplier = 1;
      } else if (result < Difficulty.mythic) {
        switch (lcsRandom(3)) {
          case 0:
            addstr("pummels");
            maxNumberOfAttacks = 6;
            damageMultiplier = 1;
          case 1:
            addstr("combos");
            maxNumberOfAttacks = 4;
            damageMultiplier = 2;
          case 2:
            addstr("jump kicks");
            maxNumberOfAttacks = 1;
            damageMultiplier = 5;
        }
      } else {
        switch (lcsRandom(9)) {
          case 0:
            addstr("unleashes ${a.gender.hisHer} Stand on");
            maxNumberOfAttacks = 12;
            damageMultiplier = 1.5;
          case 1:
            addstr("launches a flurry of kicks at");
            maxNumberOfAttacks = 8;
            damageMultiplier = 2;
          case 2:
            addstr("slows time and touches");
            addNastyOff = true;
            maxNumberOfAttacks = 1;
            damageMultiplier = 12;
          case 3:
            addstr("leaps into the air and descends upon");
            maxNumberOfAttacks = 3;
            damageMultiplier = 5;
          case 4:
            addstr("suddenly appears behind");
            maxNumberOfAttacks = 4;
            damageMultiplier = 4;
          case 5:
            addstr("hurls a ball of energy at");
            addNastyOff = true;
            maxNumberOfAttacks = 1;
            damageMultiplier = 12;
          case 6:
            addstr("throws a stunning palm strike at");
            addStun = true;
            maxNumberOfAttacks = 1;
            damageMultiplier = 0.5;
          case 7:
            addstr("leaps into a spinning kick against");
            maxNumberOfAttacks = 2;
            damageMultiplier = 6;
          case 8:
            addstr("delivers the Bleeding Heart punch to");
            addAutoConvert = true;
            torsoOnly = true;
            maxNumberOfAttacks = 1;
            damageMultiplier = 0;
        }
      }
    } else if (a.weapon.typeName == "WEAPON_BITE") {
      addstr("lunges with fangs out at");
      maxNumberOfAttacks = 1;
      damageMultiplier = 1;
    } else {
      addstr("attacks");
      maxNumberOfAttacks = 1;
      damageMultiplier = 1;
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
    addstr(" with a ${a.weapon.getName(primary: true)}");
  }
  addstr("!");

  await getKey();

  int bonus =
      0; // Accuracy bonus or penalty that does NOT affect damage or counterattack chance

  //SKILL EFFECTS
  Skill wsk = attackUsed.skill;

  // Basic roll
  int aroll = a.skillRoll(wsk, dice: Dice.d20);
  int droll = t.skill(Skill.dodge);
  if (attackUsed.ranged) {
    droll += 10;
  } else {
    droll += t.attribute(Attribute.agility);
  }
  if (mode == GameMode.carChase) {
    droll = 0;
    if (t.car != null && a.car != null) {
      int tDistance = chaseSequence?.enemyCarDistance[t.car!] ?? 0;
      int aDistance = chaseSequence?.enemyCarDistance[a.car!] ?? 0;
      int difference = (tDistance - aDistance).abs();
      droll = difference + lcsRandom(difference) + 5;
    }
    a.train(wsk, droll + 5);
  } else {
    if (sneakAttack) {
      droll = t.attribute(Attribute.wisdom);
      if (siteAlarmTimer == 0) {
        droll += DifficultyModifier.aLotHarder;
      }
      // Current tile bloody? People are more on guard
      if (mode == GameMode.site) {
        if (levelMap[locx][locy][locz].megaBloody) {
          droll += DifficultyModifier.aLotHarder;
        } else if (levelMap[locx][locy][locz].bloody) {
          droll += DifficultyModifier.moderatelyHarder;
        }
      }
      aroll += a.skill(Skill.stealth);
      a.train(Skill.stealth, 10);
      a.train(wsk, 10);
    } else {
      t.train(Skill.dodge, aroll * 2);
      a.train(wsk, droll * 2 + 5);
    }
  }

  // Hostages interfere with attack
  if (t.prisoner != null) bonus -= lcsRandom(10);
  if (a.prisoner != null) aroll -= lcsRandom(10);

  //Injured people suck at attacking, are like fish in a barrel to attackers
  aroll = healthmodroll(aroll, a);
  if (mode != GameMode.carChase) {
    droll = healthmodroll(droll, t);
  }

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

  if (a.weapon.typeName == "WEAPON_NONE") //Move into WEAPON_NONE -XML
  {
    // Martial arts multi-strikes
    if (maxNumberOfAttacks == 1) {
      bursthits = 1;
    } else {
      bursthits = maxNumberOfAttacks ~/ 2 +
          lcsRandom((a.skill(Skill.martialArts) - maxNumberOfAttacks) ~/ 3 + 1);
    }
    if (bursthits > maxNumberOfAttacks) bursthits = maxNumberOfAttacks;
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
          addPotentialCrime(squad, Crime.arson, reasonKey: "fire");
          addDramaToSiteStory(Drama.arson);
        }
      }
    }

    for (int i = 0; i < maxNumberOfAttacks; i++) {
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
      int recoil = attackUsed.successiveAttacksDifficulty * i;
      if (attackUsed.usesAmmo) {
        recoil += (a.weapon.loadedAmmoType?.recoil ?? 0) * i;
      }
      if (aroll + bonus - recoil > droll &&
          a.skill(wsk) >= attackUsed.successiveAttacksDifficulty * i) {
        bursthits++;
      }
    }
  }

  if (aroll + bonus > droll &&
      attackUsed.damage > t.blood &&
      targetIsLeader &&
      mode != GameMode.carChase) {
    // If the attack has a high chance of killing the target, and the target
    // is the leader, find a liberal to jump in front of the bullet
    for (Creature alternate in squad) {
      if (alternate == t) continue;
      if (alternate.attribute(Attribute.heart) > 8 &&
          alternate.attribute(Attribute.agility) > 4) {
        clearMessageArea();
        mvaddstrc(9, 1, lightGreen, alternate.name);
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

  move(10, 1);
  debugPrint("${a.name} rolls $aroll + $bonus, ${t.name} rolls $droll");
  BodyPart? hitPart;
  BodyPart? rollHitLocation() {
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
      if (aroll + bonus > droll + 20) {
        if (!p.weakSpot) continue;
      }
      if (aroll + bonus > droll + 15) {
        if (!p.critical) continue;
      }
      if (aroll + bonus > droll + 10) {
        if (p.weakSpot) size *= 2;
        if (p.critical) size *= 2;
      } else if (aroll + bonus > droll + 5) {
        if (p.critical && !p.weakSpot) size *= 2;
      } else {
        if (p.weakSpot) continue;
      }
      weights[p] = size;
    }
    if (weights.isNotEmpty) {
      return lcsRandomWeighted(weights);
    } else if (t.body.parts.isNotEmpty) {
      return t.body.parts.random;
    }
    return null;
  }

  hitPart = rollHitLocation();
  if (torsoOnly) {
    hitPart = t.body.parts.firstWhere((p) => p.critical && !p.weakSpot);
  }

  if (hitPart != null && aroll + bonus > droll) {
    //HIT!
    String str = a.name;
    if (addAutoConvert) {
      str += " punches the ${t.align.ism} out of ${t.name}";
    } else if (sneakAttack) {
      str += " stabs the ";
    } else if (bursthits == 1 || attackUsed.ranged) {
      str += " hits ";
    }

    if (addAutoConvert) {
    } else if (bursthits > 1 && !attackUsed.ranged) {
      str += " strikes true";
    } else if (t.clothing.covers(hitPart)) {
      str += "${t.name}'s ";
      if (hitPart.weakSpot && t.human) {
        if (t.clothing.headArmor > 4) {
          str += "helmet";
        } else {
          str += hitPart.name.toLowerCase();
        }
      } else if (hitPart.critical && t.clothing.bodyArmor > 4 && t.human) {
        str += t.clothing.armor?.name.split(",").first.toLowerCase() ?? "armor";
      } else if (t.clothing.getLimbArmor(hitPart) > 4) {
        str += "${hitPart.name.toLowerCase()} armor";
      } else {
        str += hitPart.name.toLowerCase();
      }
    } else {
      str += hitPart.name.toLowerCase();
    }

    // show multiple hits
    if (attackUsed.alwaysDescribeHit || bursthits > 1) {
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
    if (addAutoConvert) {
      addstr("$str!");
    } else {
      addstr("$str.");
    }
    await getKey();

    bool aliveBefore = t.alive;
    for (int i = 0; i < bursthits; i++) {
      await hit(a, t, attackUsed, hitPart!, sneakAttack, addNastyOff,
          damageMultiplier);
      if (hitPart.critical && addStun) {
        t.stunned = 10;
      } else if (addStun) {
        t.stunned = 1;
      }
      if (addAutoConvert && !t.type.tank) {
        void swapAttributes(Attribute a, Attribute b) {
          int aValue = t.rawAttributes[a]!;
          int bValue = t.rawAttributes[b]!;
          t.rawAttributes[a] = bValue;
          t.rawAttributes[b] = aValue;
        }

        if (a.align == Alignment.conservative) {
          if (t.rawAttributes[Attribute.heart]! >
              t.rawAttributes[Attribute.wisdom]!) {
            swapAttributes(Attribute.heart, Attribute.wisdom);
          }
          if (!encounter.contains(t)) encounter.add(t);
          pool.remove(t);
          conservatize(t);
          t.noticedParty = true;
          t.isWillingToTalk = true;
        } else if (a.align == Alignment.liberal) {
          if (t.rawAttributes[Attribute.wisdom]! >
              t.rawAttributes[Attribute.heart]!) {
            swapAttributes(Attribute.heart, Attribute.wisdom);
          }
          liberalize(t);
          t.isWillingToTalk = true;
        }
        t.justConverted = true;
        printEncounter();
      }
      if (!attackUsed.ranged) hitPart = rollHitLocation();
      if (torsoOnly) {
        hitPart = t.body.parts.firstWhere((p) => p.critical && !p.weakSpot);
      }
      if (hitPart == null) break;
    }

    if (aliveBefore && !t.alive && t.squad == null) {
      printParty();
      printEncounter();
      addDeathMessage(t);
      await getKey();
    }
  } else {
    setColor(white);

    if (melee &&
        aroll < droll - 10 &&
        t.blood > 70 &&
        t.human &&
        t.getAttack(false, true, true) != null) {
      mvaddstr(10, 1, "${t.name} knocks the blow aside and counters!");
      await getKey();
      await attack(t, a, false, forceMelee: true);
    } else {
      move(10, 1);
      if (sneakAttack) {
        addstr(t.name);
        addstr([
          " notices at the last moment!",
          " notices before the attack connects!",
          " spins and blocks the attack!",
          " jumps back and cries out in alarm!",
        ].random);
        siteAlarm = true;
      } else if (mode == GameMode.carChase) {
        addstr("${a.name}'s shot ${[
          "misses!",
          "goes wide!",
          "hits the car!",
          "hits the road!",
          "hits the sidewalk!",
          "hits a building!",
          "hits a tree!",
          "hits a parked car!",
          "ricochets off the car!",
          "ricochets off the road!",
          "is too high!",
        ].random}");
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
    BodyPart hitlocation, double mod) {
  debugPrint("Damage mod: $mod, damage before application: $damamount");

  if (mod < 0) {
    damamount = (damamount / (1.0 - 1.0 * mod)).round();
    debugPrint("Damage reduced to $damamount");
  } else if (mod >= 0) {
    damamount = (damamount * (1.0 + 0.2 * mod)).round();
    debugPrint("Damage increased to $damamount");
  }

  if (damamount < 0) damamount = 0;

  return damamount;
}

Future<void> hit(Creature a, Creature t, Attack attackUsed, BodyPart hitPart,
    bool sneakAttack, bool addNastyOff, double damageMultiplier) async {
  if (hitPart.missing) return;
  String str = "";
  int damamount = 0;
  SeverType severtype = attackUsed.severType;

  severtype = attackUsed.severType;
  if (addNastyOff) severtype = SeverType.nasty;
  int random = (attackUsed.damage * 0.8).round();
  int fixed = (attackUsed.damage * 0.2).round();
  if (sneakAttack) fixed += 100;
  //debugPrint("Random: $random, fixed: $fixed, hits: $bursthits");
  //debugPrint("Initial damage roll: $damamount");

  // Damage bonus from high skill, strength
  double mod = 0;
  if (!attackUsed.ranged) {
    double strength = a.attribute(Attribute.strength).toDouble();
    mod += strength;
  }

  int bursthits = a.weapon.loadedAmmoType?.multihit ?? 1;
  if (attackUsed.cartridge != a.weapon.loadedAmmoType?.cartridge) bursthits = 1;
  bool bruiseOnly = true;
  for (int i = 0; i < bursthits; i++) {
    int hitDamage = lcsRandom(random) + fixed;
    hitDamage = (hitDamage * damageMultiplier).round();
    hitDamage = damagemod(t, attackUsed, hitDamage, hitPart, mod);

    // Armor
    int externalArmor = t.clothing.getArmorForLocation(hitPart);
    int internalArmor = hitPart.naturalArmor;
    int totalArmor = internalArmor + externalArmor;
    if (totalArmor > 0) {
      int armorDamage = max((hitDamage * 0.3).round(), 1);
      int blocked = min(totalArmor, hitDamage);
      if (totalArmor < hitDamage) {
        bruiseOnly = false;
      }
      if (attackUsed.bruises && !attackUsed.bleeds) {
        hitDamage -= (blocked * 0.5).floor();
      } else {
        hitDamage -= (blocked * 0.8).floor();
      }
      if (armorDamage > 0) {
        int externalDamage = min(armorDamage, externalArmor);
        int internalDamage = min(armorDamage - externalDamage, internalArmor);
        t.clothing.damageArmorInLocation(hitPart, externalDamage);
        hitPart.naturalArmor -= internalDamage;
      }
    } else {
      bruiseOnly = false;
    }
    damamount += hitDamage;
  }

  if (damamount > 0) {
    Creature target = t;

    if (bruiseOnly) {
      hitPart.bruised = true;
    } else {
      if (attackUsed.bleeds) {
        hitPart.bleeding += 1;
      }
      hitPart.cut = attackUsed.cuts;
      hitPart.torn = attackUsed.tears;
      hitPart.shot = attackUsed.shoots;
      hitPart.burned = attackUsed.burns;
      hitPart.bruised = attackUsed.bruises;
    }

    int severamount =
        (hitPart.relativeHealth * t.maxBlood + t.maxBlood).round();
    if (hitPart.critical) {
      severamount += t.maxBlood * 2;
    }

    if (severtype != SeverType.none &&
        damamount >= severamount &&
        !bruiseOnly) {
      String NAME = // ignore: non_constant_identifier_names
          t.name.toUpperCase();
      String PART = // ignore: non_constant_identifier_names
          hitPart.name.toUpperCase();
      if (severtype == SeverType.clean) {
        hitPart.cleanOff = true;
        if (hitPart.critical && !hitPart.weakSpot) {
          str += "$NAME'S $PART IS SLICED IN HALF!";
        } else {
          str += "$NAME'S $PART IS SLICED OFF!";
        }
      } else if (severtype == SeverType.nasty) {
        hitPart.nastyOff = true;
        str += "$NAME'S $PART IS BLOWN APART!";
      }
    }

    hitPart.relativeHealth -= damamount / target.maxBlood;

    if (hitPart.weakSpot) damamount = damamount * 2;
    if (!hitPart.critical) damamount = (damamount / 2).round();
    debugPrint("Final damage after hit location effects: $damamount");

    if (!hitPart.critical && target.alive) {
      if (lcsRandom(100) >= attackUsed.noDamageReductionForLimbsChance) {
        damamount = min(damamount, (target.blood / 2).round());
      }
    }

    //debugPrint("Target blood before hit: ${target.blood}/${target.maxBlood}");
    target.blood -= damamount;
    //debugPrint("Target blood after hit: ${target.blood}/${target.maxBlood}");

    levelMap[locx][locy][locz].bloody = true;

    if (severtype == SeverType.nasty) bloodblast(t.clothing);

    if (str != "") {
      clearMessageArea();
      mvaddstrc(9, 1, a.align.color, str);
      printParty();
      printEncounter();
      await getKey();
    }

    if ((hitPart.critical && hitPart.missing) || target.blood <= 0) {
      bool alreadydead = !target.alive;

      if (!alreadydead) {
        target.die();

        int killjuice = 5 + (t.juice / 20).round();
        if ((t.align.index - a.align.index).abs() == 2) {
          if (t.type.majorEnemy || t.type.tank) {
            killjuice += 50;
          }
          addjuice(a, killjuice, 1000); // Instant juice
        } else {
          addjuice(a, -25, -50);
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
            (!target.type.animal || animalsArePeopleToo)) {
          siteCrime += 10;
          if (t.type.majorEnemy) {
            siteCrime += 90;
          }
          if (a.squad == activeSquad) {
            addDramaToSiteStory(Drama.killedSomebody);
            addPotentialCrime(squad, Crime.murder);
          }
        }
      }

      if (!alreadydead) {
        await severloot(t, groundLoot);
        printParty();
        printEncounter();
        clearMessageArea();

        if (target.prisoner != null) {
          await freehostage(t, FreeHostageMessage.newLine);
        }
      }
    }

    printParty();
    printEncounter();

    //SPECIAL WOUNDS
    if (!hitPart.missing && target.body is HumanoidBody) {
      bool heavydam = false;
      bool breakdam = false;
      bool pokedam = false;
      HumanoidBody body = target.body as HumanoidBody;
      if (damamount >= 12) {
        if ((attackUsed.shoots ||
                attackUsed.burns ||
                attackUsed.tears ||
                attackUsed.cuts) &&
            !bruiseOnly) {
          heavydam = true;
        }
      }

      if (damamount >= 10) {
        if ((attackUsed.cuts || attackUsed.tears || attackUsed.shoots) &&
            !bruiseOnly) {
          pokedam = true;
        }
      }

      if (damamount >= 40 || (damamount >= 20 && attackUsed.bruises)) {
        if (attackUsed.cuts ||
            attackUsed.shoots ||
            attackUsed.tears ||
            attackUsed.bruises) {
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

        int roll = lcsRandom(7);

        switch (roll) {
          case 0:
            if ((!body.missingLeftEye ||
                    !body.missingRightEye ||
                    !body.missingNose) &&
                heavydam) {
              mvaddstr(9, 1, target.name);
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

              move(9, 1);
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
              mvaddstr(9, 1, target.name);
              if (attackUsed.shoots) {
                addstr("'s right eye is shot out!");
              } else if (attackUsed.burns) {
                addstr("'s right eye is burned away!");
              } else if (attackUsed.tears) {
                addstr("'s right eye is torn out!");
              } else if (attackUsed.cuts) {
                addstr("'s right eye is cut open!");
              } else {
                addstr("'s right eye is removed!");
              }

              await getKey();

              body.missingRightEye = true;
              maxBlood(0.5);
            }
          case 3:
            if (!body.missingLeftEye && heavydam) {
              mvaddstr(9, 1, target.name);
              if (attackUsed.shoots) {
                addstr("'s left eye is shot out!");
              } else if (attackUsed.burns) {
                addstr("'s left eye is burned away!");
              } else if (attackUsed.tears) {
                addstr("'s left eye is torn out!");
              } else if (attackUsed.cuts) {
                addstr("'s left eye is cut open!");
              } else {
                addstr("'s left eye is removed!");
              }

              await getKey();

              body.missingLeftEye = true;
              maxBlood(0.5);
            }
          case 4:
            if (!body.missingTongue && heavydam) {
              mvaddstr(9, 1, target.name);
              if (attackUsed.shoots) {
                addstr("'s tongue is blown off!");
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
              mvaddstr(9, 1, target.name);
              if (attackUsed.shoots) {
                addstr("'s nose is blown off!");
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
              mvaddstr(9, 1, target.name);
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

        int roll = lcsRandom(10 + body.ribs > 0 ? 4 : 0);
        if (bruiseOnly) roll = 11;

        switch (roll) {
          case 0:
            if (!body.brokenUpperSpine && breakdam) {
              mvaddstr(9, 1, target.name);
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
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedRightLung && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedLeftLung && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedHeart && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedLiver && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedStomach && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedRightKidney && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedLeftKidney && pokedam) {
              mvaddstr(9, 1, target.name);
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
            if (!body.puncturedSpleen && pokedam) {
              mvaddstr(9, 1, target.name);
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
          case 11:
          case 12:
          case 13:
            if (body.ribs > 0 && breakdam) {
              int ribminus = lcsRandom(min(body.ribs, damamount ~/ 20)) + 1;

              move(9, 1);
              if (ribminus > 1) {
                if (ribminus == body.ribs) {
                  addstr("All ");
                }
                addstr("$ribminus of ${target.name}'s ribs are ");
              } else if (body.ribs > 1) {
                addstr("One of ${target.name}'s ribs is ");
              } else {
                addstr("${target.name}'s last unbroken rib is ");
              }

              if (attackUsed.shoots) {
                addstr("shattered!");
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
}

Future<bool> socialAttack(Creature a, Creature t, Attack attackUsed) async {
  int resist = 0;

  clearMessageArea();
  mvaddstrc(9, 1, white,
      "${a.name} ${attackUsed.attackDescription.random} ${t.name}!");

  int attack = a.skillRoll(attackUsed.skill);
  if (t.align == Alignment.liberal) {
    resist = t.attributeRoll(Attribute.heart, take10: true);
  } else {
    resist = t.attributeRoll(Attribute.wisdom, take10: true);
  }
  resist += t.skill(Skill.psychology);
  a.train(attackUsed.skill, max(1, resist));

  if (t.type.animal && !animalsArePeopleToo) {
    resist += 10;
  }

  if (t.type.tank || (a.isEnemy && t.brainwashed)) {
    mvaddstr(10, 1, "${t.name} is immune to the attack!");
  } else if (a.align == t.align) {
    mvaddstr(10, 1, "${t.name} already agrees with ${a.name}.");
  } else if (attack > resist) {
    if (attackUsed.stuns) {
      t.stunned += (attack - resist) ~/ 4;
    }
    if (a.isEnemy) {
      if (t.juice > 100) {
        mvaddstr(10, 1, "${t.name} loses juice!");
        addjuice(t, -50, 100);
      } else if (lcsRandom(15) > t.attribute(Attribute.wisdom) ||
          t.attribute(Attribute.wisdom) < t.attribute(Attribute.heart)) {
        mvaddstr(10, 1, "${t.name} is tainted with Wisdom!");
        t.adjustAttribute(Attribute.wisdom, 1);
      } else if (t.align == Alignment.liberal && t.seduced) {
        mvaddstr(10, 1, "${t.name} can't bear to leave!");
      } else {
        if (a.align == Alignment.conservative) {
          mvaddstr(10, 1, "${t.name} is turned Conservative");
          if (t.prisoner != null) {
            await freehostage(t, FreeHostageMessage.continueLine);
          }
          addstr("!");
        } else {
          mvaddstr(10, 1, "${t.name} doesn't want to fight anymore");
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
          if (t.align == Alignment.conservative) {
            if (activeSite?.controller == SiteController.ccs) {
              if (t.type.id == CreatureTypeIds.ccsArchConservative) {
                ccsBossConverts++;
              }
              ccsSiegeConverts++;
            }
          }
          liberalize(t);
          if (activeSiteUnderSiege) activeSite!.siege.kills++;
          t.isWillingToTalk = true;
        } else {
          t.isWillingToTalk = true;
        }
        t.noticedParty = true;
        t.squad = null;
      }
    } else {
      if (t.juice >= 1) {
        mvaddstr(10, 1, "${t.name} seems less badass!");
        addjuice(t, -100, 0);
        t.stunned += lcsRandom(2);
      } else if (!t.attributeCheck(Attribute.heart, Difficulty.average) ||
          t.attribute(Attribute.heart) < t.attribute(Attribute.wisdom)) {
        mvaddstr(10, 1, "${t.name}'s Heart swells!");
        t.adjustAttribute(Attribute.heart, 1);
        t.stunned += lcsRandom(2);
      } else {
        if (t.align == Alignment.conservative) {
          if (activeSite?.controller == SiteController.ccs) {
            if (t.type.id == CreatureTypeIds.ccsArchConservative) {
              ccsBossConverts++;
            }
            ccsSiegeConverts++;
          }
        }

        mvaddstr(10, 1, "${t.name} has turned Liberal!");
        t.stunned = 0;

        liberalize(t);
        if (activeSiteUnderSiege) activeSite!.siege.kills++;
        sitestory?.drama.add(Drama.musicalRampage);
        t.justConverted = true;
        t.isWillingToTalk = true;
      }
    }
  } else {
    mvaddstr(10, 1, "${t.name} remains strong.");
  }

  printParty();
  printEncounter();

  await getKey();

  siteCrime += 3;
  addjuice(a, 1, 200);

  return false;
}

/* destroys armor, masks, drops weapons based on severe damage */
Future<void> severloot(Creature cr, List<Item> loot) async {
  int armok = cr.body.armok;

  if (cr.equippedWeapon != null && armok == 0) {
    clearMessageArea();
    mvaddstrc(9, 1, yellow, "The ");
    addstr(cr.weapon.getName());
    addstr(" slips from");
    mvaddstr(10, 1, cr.name);
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
          cr.equippedClothing?.covers(body!.torso) == true ||
      (body?.head.missing == true && cr.equippedClothing?.type.mask == true)) {
    clearMessageArea();
    mvaddstrc(9, 1, yellow, cr.name);
    addstr("'s ");
    addstr(cr.clothing.shortName);
    addstr(" has been destroyed.");

    await getKey();

    cr.strip();
  }
}

/* blood explosions */
void bloodblast(Clothing armor) {
  //GENERAL
  if (armor.type.canGetBloody) armor.bloody = true;

  if (mode != GameMode.site) return;

  levelMap[locx][locy][locz].megaBloody = true;

  //HIT EVERYTHING
  for (Creature p in squad) {
    if (oneIn(2)) {
      p.equippedClothing?.bloody = true;
    }
  }

  for (Creature e in encounter) {
    if (oneIn(2)) {
      e.equippedClothing?.bloody = true;
    }
  }

  //REFRESH THE SCREEN
  printSiteMapSmall(locx, locy, locz);
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

        mvaddstrc(9, 1, white, "The ");
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
        mvaddstrc(9, 1, white, "The ");
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
        mvaddstrc(9, 1, white, a.name);
        if (a.squad == null && !a.type.majorEnemy) a.nonCombatant = true;
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
      mvaddstrc(9, 1, white, a.name);
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
      mvaddstrc(9, 1, white, a.name);
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
  Clothing clothes = Clothing("CLOTHING_CLOTHES");
  t.equippedClothing = clothes;
  t.sleeperAgent = false;

  await freehostage(t, FreeHostageMessage.none);
  if (t.justEscaped) {
    t.location = activeSite;
    if (activeSite!.isPartOfTheJusticeSystem) {
      Clothing prisoner = Clothing("CLOTHING_PRISONER");
      t.equippedClothing = prisoner;
    }
    if (activeSite!.type == SiteType.prison) {
      t.heat = 0;
      t.wantedForCrimes.updateAll((key, value) => 0);
    }
  } else {
    t.location = findSiteInSameCity(
        activeSite?.city ?? t.location?.city, SiteType.policeStation);
  }

  t.squad = null;
}

/* describes a character's death */
void addDeathMessage(Creature cr) {
  clearMessageArea();
  setColor(yellow);

  move(9, 1);
  String str = "";

  BodyPart? head = cr.body.parts.firstWhereOrNull((bp) => bp.name == "Head");
  BodyPart? body = cr.body.parts.firstWhereOrNull((bp) => bp.name == "Torso");

  if (head?.missing == true) {
    str = cr.name;
    switch (lcsRandom(4)) {
      case 0:
        str += " reaches once where there ";
        addstr(str);
        move(10, 1);
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
        mvaddstr(10, 1, "moment then crumples over.");
      case 2:
        str += " squirts ";
        if (noProfanity) {
          str += "[red water]";
        } else {
          str += "blood";
        }
        str += " out of the ";
        addstr(str);
        move(10, 1);
        if (mode != GameMode.carChase) {
          addstr("neck and runs down the hall.");
        } else {
          addstr("neck and falls to the side.");
        }
      case 3:
        str += " sucks a last breath through ";
        addstr(str);
        mvaddstr(10, 1, "the neck hole, then is quiet.");
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
  } else if (cr.blood < cr.maxBlood * -2) {
    str = cr.name;
    switch (lcsRandom(2)) {
      case 0:
        str += " is dead before ${cr.gender.hisHer} body hits the ground.";
        addstr(str);
      case 1:
        str += " collapses lifelessly.";
        addstr(str);
      case 2:
        str += " doesn't even make sound.";
        addstr(str);
      case 3:
        str += " is very much dead.";
        addstr(str);
      case 4:
        str += " didn't even know what hit ${cr.gender.himHer}.";
        addstr(str);
      case 5:
        str += " dies instantly.";
        addstr(str);
      case 6:
        str += "'s body slumps to the floor.";
        addstr(str);
      case 7:
        str += "'s body hits the ground with a dull thump.";
        addstr(str);
    }
  } else {
    str = cr.name;
    switch (lcsRandom(11)) {
      case 0:
        str += " cries out one last time ";
        addstr(str);
        mvaddstr(10, 1, "then is quiet.");
      case 1:
        str += " gasps a last breath and ";
        addstr(str);
        move(10, 1);
        if (noProfanity) {
          addstr("[makes a mess].");
        } else {
          addstr("soils the floor.");
        }
      case 2:
        str += " murmurs quietly, breathing softly.";
        addstr(str);
        mvaddstr(10, 1, "Then all is silent.");
      case 3:
        str += " shouts \"FATHER!  Why have you ";
        addstr(str);
        mvaddstr(10, 1, "forsaken me?\" and dies in a heap.");
      case 4:
        str += " cries silently for mother, ";
        addstr(str);
        mvaddstr(10, 1, "breathing slowly, then not at all.");
      case 5:
        str += " breathes heavily, coughing up ";
        addstr(str);
        mvaddstr(10, 1, "blood...  then is quiet.");
      case 6:
        str += " silently drifts away, and ";
        addstr(str);
        mvaddstr(10, 1, "is gone.");
      case 7:
        str += " sweats profusely, murmurs ";
        addstr(str);
        move(10, 1);
        if (noProfanity) {
          addstr("something [good] about Jesus, and dies.");
        } else {
          addstr("something about Jesus, and dies.");
        }
      case 8:
        str += " whines loudly, voice crackling, ";
        addstr(str);
        mvaddstr(10, 1, "then curls into a ball, unmoving.");
      case 9:
        str += " shivers silently, whispering ";
        addstr(str);
        mvaddstr(10, 1, "a prayer, then all is still.");
      case 10:
        str += " speaks these final words: ";
        addstr(str);
        move(10, 1);
        switch (cr.align) {
          case Alignment.liberal:
            addstr(slogan);
          case Alignment.moderate:
            addstr("\"A plague on both your houses...\"");
          default:
            addstr("\"Better dead than liberal...\"");
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
