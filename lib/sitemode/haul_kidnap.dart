import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/sitemode/advance.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* prompt after you've said you want to kidnap someone */
Future<void> kidnapattempt() async {
  Creature? kidnapper;

  activeSquadMemberIndex = -1;

  if (!activeSquad!.livingMembers.any((e) => e.prisoner == null)) {
    await encounterMessage("No one can do the job.");
    return;
  }

  do {
    printParty();

    move(8, 20);
    setColor(white);
    addstr("Choose a Liberal squad member to do the job.");

    int c = await getKey();

    if (isBackKey(c)) return;

    int index = c - '1'.codeUnitAt(0);
    if (index >= 0 && index < squad.length) {
      if (squad[index].prisoner == null) {
        kidnapper = squad[index];
      }
    }
  } while (kidnapper == null);

  List<Creature> viableTargets = [];

  for (Creature e in encounter) {
    if (e.alive &&
        e.align == Alignment.conservative &&
        (!e.type.animal || animalsArePeopleToo) &&
        (!e.weapon.type.protectsAgainstKidnapping ||
            e.blood <= 20 ||
            e.nonCombatant) &&
        !e.type.tank) {
      viableTargets.add(e);
    }
  }

  if (viableTargets.isNotEmpty) {
    Creature target = viableTargets[0];

    if (viableTargets.length > 1) {
      clearSceneAreas();

      setColor(white);
      move(9, 1);
      addstr("Kidnap whom?");

      int x = 1, y = 11;
      for (int t2 = 0; t2 < viableTargets.length; t2++) {
        String letter = letterAPlus(t2);
        addOptionText(y++, x, letter, "$letter - ${viableTargets[t2].name}");

        if (y == 17) {
          y = 11;
          x += 30;
        }
      }

      int c = await getKey();
      int index = c - Key.a;

      if (index >= 0 && index < viableTargets.length) {
        target = viableTargets[index];
      }
      if (isBackKey(c)) return;
    }

    bool yellForHelp = false;
    bool success = false;

    if (!kidnapper.weapon.type.canTakeHostages) {
      yellForHelp = true;

      //BASIC ROLL
      int aroll = kidnapper.skillRoll(Skill.martialArts);
      int droll = target.attributeRoll(Attribute.agility, take10: true);

      kidnapper.train(Skill.martialArts, droll);

      clearMessageArea();

      //HIT!
      if (aroll > droll) {
        setColor(white);
        move(9, 1);
        addstr(kidnapper.name);
        addstr(" snatches ");
        addstr(target.name);
        addstr("!");

        kidnapper.prisoner = target;

        await getKey();

        setColor(red);
        move(10, 1);
        addstr(target.name);
        addstr(" is struggling and screaming!");

        await getKey();

        success = true;
      } else {
        await encounterMessage("${kidnapper.name} grabs at ${target.name}",
            line2: "but ${target.name} writhes away!", color: purple);
        success = false;
      }
    } else {
      clearMessageArea();

      setColor(white);
      move(9, 1);
      addstr(kidnapper.name);
      addstr(" shows ");
      addstr(target.name);
      addstr(" the ");
      addstr(kidnapper.weapon.getName(sidearm: true));
      addstr(" ");
      move(10, 1);
      addstr("and says, ");
      setColor(lightGreen);
      addstr("\"${[
        "Please, be cool.",
        "No sudden moves now.",
        "Nobody needs to get hurt.",
        "Stay cool, now.",
        "You're coming with me.",
        "This is for your own good.",
        "I'll keep you safe.",
        "Walk calmly.",
        "One foot in front of the other.",
        "Yep, you're walking with me.",
        "It's cool, it's cool.",
        "I'm gonna need you to come with me.",
        "Let's go for a walk.",
        "Let's hang out for a bit.",
        "Fancy meeting you here.",
        "Care to step outside?",
        "Why don't you come with me?",
        "Today is your lucky day.",
        "After you.",
        "Let's go.",
        "Let's be friends.",
        "You and me are buddies now.",
        "Time to go.",
        "We're friends now.",
        "You're my friend now.",
        "It's taco night, and you're invited.",
        "I have someone I'd like you to meet.",
        "Don't worry. You've never been safer.",
        "Hello, friend...",
        "You and me are gonna be great friends.",
        "I just know we're gonna get along great.",
        "Ever considered a career in politics?",
        "Ever thought about being an activist?",
        "I think you'd enjoy being a Liberal.",
        "You might like direct action.",
        "I prefer the term 'activist' myself.",
        "Don't worry, I'm not a cop.",
      ].random}\"");

      kidnapper.prisoner = target;

      await getKey();

      success = true;
    }

    if (success) {
      encounter.remove(target);

      int time = 40 + lcsRandom(20);
      if (time < 1) time = 1;
      if (siteAlarmTimer > time || siteAlarmTimer == -1) siteAlarmTimer = time;
    } else {
      siteAlarm = true;
    }

    if (yellForHelp) {
      bool present = encounter.any((e) => e.alive);

      if (present) {
        await alienationCheck(false);
        siteAlarm = true;
        siteCrime += 5;
        addPotentialCrime(squad, Crime.kidnapping,
            reasonKey: target.id.toString());
        if (target.type.preciousToAngryRuralMobs) offendedAngryRuralMobs = true;
      }
    }

    if (siteAlarm) await enemyattack(encounter);
    await creatureadvance();
  } else {
    await encounterMessage("All of the targets are too dangerous.");
  }
}

/* prompt after you've said you want to release someone */
Future<void> releasehostage() async {
  Creature? kidnapper;

  activeSquadMemberIndex = -1;

  if (!activeSquad!.livingMembers.any(
      (e) => e.prisoner != null && e.prisoner!.align != Alignment.liberal)) {
    setColor(white);
    clearMessageArea();
    move(9, 1);
    addstr("No hostages are being held.");

    await getKey();

    return;
  }

  do {
    printParty();

    move(8, 20);
    setColor(white);
    addstr("Choose a Liberal squad member to release their hostage.");

    int c = await getKey();

    if (isBackKey(c)) return;

    int index = c - '1'.codeUnitAt(0);
    if (index >= 0 && index < squad.length) {
      if (squad[index].prisoner != null &&
          squad[index].prisoner!.align != Alignment.liberal) {
        kidnapper = squad[index];
      }
    }
  } while (kidnapper == null);

  kidnapper.prisoner!.noticedParty = true;
  kidnapper.prisoner!.isWillingToTalk = false;
  await freehostage(kidnapper, FreeHostageMessage.none);

  if (!siteAlarm) {
    setColor(white);
    clearMessageArea();
    move(9, 1);
    addstr("The hostage shouts for help!");

    await getKey();

    siteAlarm = true;
    await alienationCheck(false);
  }
}

enum FreeHostageMessage {
  continueLine,
  newLine,
  none,
}

Future<void> freehostage(Creature cr, FreeHostageMessage situation) async {
  Creature? prisoner = cr.prisoner;
  if (prisoner == null) return;

  if (prisoner.alive) {
    if (situation == FreeHostageMessage.continueLine) {
      if (prisoner.hireId == null) {
        addstr(" and a hostage is freed");
      } else {
        addstr(" and ${prisoner.name}");
        if (prisoner.justEscaped) {
          addstr(" is recaptured");
        } else {
          addstr(" is captured");
        }
      }
    } else if (situation == FreeHostageMessage.newLine) {
      clearMessageArea();
      setColor(white);
      move(9, 1);
      if (prisoner.hireId == null) {
        addstr("A hostage escapes!");
      } else {
        addstr(prisoner.name);
        if (prisoner.justEscaped) {
          addstr(" is recaptured.");
        } else {
          addstr(" is captured.");
        }
      }
    }

    if (prisoner.align != Alignment.liberal) {
      encounter.add(prisoner);
      conservatize(prisoner);
    } else {
      await captureCreature(prisoner);
    }
  } else {
    if (prisoner.align == Alignment.liberal) {
      prisoner.squad = null;
      prisoner.die();
      prisoner.location = null;
    }
  }

  cr.prisoner = null;

  if (situation == FreeHostageMessage.newLine) {
    printParty();
    printEncounter();

    await getKey();
  }
}

/* haul dead/paralyzed */
Future<void> squadHaulImmobileAllies(bool dead) async {
  int hostslots = 0; //DRAGGING PEOPLE OUT IF POSSIBLE
  for (Creature p in squad) {
    if (p.alive && (p.canWalk || (p.hasWheelchair)) && p.prisoner == null) {
      hostslots++;
    } else if ((!p.alive || (!p.canWalk && !p.hasWheelchair)) &&
        p.prisoner != null) {
      clearMessageArea();
      setColor(yellow);
      move(9, 1);
      addstr(p.name);
      addstr(" can no longer handle ");
      addstr(p.prisoner!.name);
      addstr(".");

      await getKey();

      await freehostage(p.prisoner!, FreeHostageMessage.newLine);
    }
  }

  while (true) {
    bool removed = false;
    for (Creature p in squad.toList()) {
      if ((!p.alive && dead) ||
          (p.alive && !p.hasWheelchair && !p.canWalk && !dead)) {
        if (hostslots == 0 || p.body.fellApart) {
          if (!p.alive) {
            clearMessageArea();
            setColor(yellow);
            move(9, 1);
            addstr("Nobody can carry Martyr ");
            addstr(p.name);
            addstr(".");

            //DROP LOOT
            makeLoot(p, groundLoot);

            p.die();
            p.location = null;
          } else {
            clearMessageArea();
            setColor(yellow);
            move(9, 1);
            addstr(p.name);
            addstr(" is left to be captured.");

            await captureCreature(p);
          }
        } else {
          for (Creature p2 in squad) {
            if (p2 == p) continue;
            if (p2.alive &&
                (p2.canWalk || (p2.hasWheelchair)) &&
                p2.prisoner == null) {
              p2.prisoner = p;

              clearMessageArea();
              setColor(yellow);
              move(9, 1);
              addstr(p2.name);
              addstr(" hauls ");
              addstr(p.name);
              addstr(".");
              //New line.
              break;
            }
          }

          hostslots--;
        }

        //SHUFFLE SQUAD
        squad.remove(p);
        printParty();

        await getKey();
        removed = true;
        break;
      }
    }
    if (!removed) break;
  }
}

/* names the new hostage and stashes them in your base */
Future<void> kidnaptransfer(Creature cr, {Creature? kidnapper}) async {
  cr.nameCreature();

  Site? base = kidnapper?.base ??
      activeSquad?.members[0].base ??
      findSiteInSameCity(cr.location?.city, SiteType.homelessEncampment);
  cr.location = base;
  cr.base = base;
  cr.missing = true;

  //disarm them and stash their weapon back at the base
  cr.dropWeaponAndAmmo(lootPile: cr.site?.loot);

  //Create interrogation data
  interrogationSessions.add(InterrogationSession(cr.id));

  erase();

  setColor(white);
  move(0, 0);
  addstr("The Education of ");
  addstr(cr.properName);

  move(2, 0);
  setColor(lightGray);
  addstr("What name will you use for this ");
  addstr(cr.type.name);
  addstr(" in ${cr.gender.hisHer} presence?");

  cr.name = await enterName(4, 0, cr.properName, prefill: true);

  pool.add(cr);
  stats.kidnappings++;
}
