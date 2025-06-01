/* everybody reload! */
import 'dart:math';

import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/map_specials.dart';
import 'package:lcs_new_age/sitemode/newencounter.dart';
import 'package:lcs_new_age/sitemode/site_display.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

enum UnlockTypes { door, cage, cageHard, cell, safe, armory, vault }

enum BashTypes { door }

enum UnlockResult { unlocked, failed, noAttempt, bashed }

enum HackTypes { supercomputer, vault }

/* unlock attempt */
Future<UnlockResult> unlock(UnlockTypes type) async {
  int difficulty = switch (type) {
    UnlockTypes.cage => Difficulty.veryEasy,
    UnlockTypes.door => switch (securityable(activeSite!.type)) {
        0 => Difficulty.easy,
        1 => Difficulty.average,
        _ => Difficulty.hard,
      },
    UnlockTypes.cageHard => Difficulty.average,
    UnlockTypes.safe => Difficulty.formidable,
    UnlockTypes.cell => Difficulty.formidable,
    UnlockTypes.armory => Difficulty.heroic,
    UnlockTypes.vault => Difficulty.heroic,
  };

  int maxattack = activeSquad!.livingMembers
      .fold(1, (best, p) => max(best, p.skill(Skill.security)));
  List<Creature> goodp = activeSquad!.livingMembers
      .where((p) => p.skill(Skill.security) == maxattack)
      .toList();

  if (goodp.isNotEmpty) {
    Creature p = goodp.random;

    //lock pick succeeded.
    if (p.skillCheck(Skill.security, difficulty)) {
      //skill goes up in proportion to the chance of you failing.
      if (maxattack <= difficulty) {
        p.train(Skill.security, 6 * difficulty);
      }
      clearMessageArea();
      mvaddstrc(9, 1, white, "${p.name} ");
      switch (type) {
        case UnlockTypes.door:
          addstr("unlocks the door!");
        case UnlockTypes.cageHard:
        case UnlockTypes.cage:
          addstr("unlocks the cage!");
        case UnlockTypes.safe:
          addstr("cracks the safe!");
        case UnlockTypes.armory:
          addstr("opens the armory!");
        case UnlockTypes.cell:
          addstr("unlocks the cell!");
        case UnlockTypes.vault:
          addstr("cracks the combo locks!");
      }

      //If people witness a successful unlock, they learn a little bit.
      for (Creature j in activeSquad!.livingMembers.where((j) => j != p)) {
        if (j.skill(Skill.security) < difficulty) {
          j.train(Skill.security, 3 * difficulty);
        }
      }

      await getKey();

      return UnlockResult.unlocked;
    } else {
      clearMessageArea();
      setColor(white);
      move(9, 1);

      int i;
      //gain some experience for failing only if you could have succeeded.
      for (i = 0; i < 3; i++) {
        if (p.skillCheck(Skill.security, difficulty)) {
          p.train(Skill.security, 50);

          addstr("${p.name} is close, but can't quite get the lock open.");

          break;
        }
      }

      if (i == 3) addstr("${p.name} can't figure the lock out.");

      await getKey();

      return UnlockResult.failed;
    }
  } else {
    clearMessageArea();
    mvaddstrc(9, 1, white, "You can't find anyone to do the job.");

    await getKey();
  }

  return UnlockResult.noAttempt;
}

/* bash attempt */
Future<UnlockResult> bash(BashTypes type) async {
  int difficulty = 0;
  bool crowable = false;

  switch (type) {
    case BashTypes.door:
      if (securityable(activeSite!.type) == 0) {
        difficulty = Difficulty.easy; // Run down dump
        crowable = true;
      } else if (activeSite!.type != SiteType.prison &&
          activeSite!.type != SiteType.intelligenceHQ) {
        difficulty = Difficulty.average; // Respectable place
        crowable = true;
      } else {
        difficulty = Difficulty.formidable; // Very high security
        crowable = false;
      }
  }

  Creature? maxp;
  if (crowable) {
    crowable = false;

    for (Creature p in squad) {
      if (p.weapon.type.autoBreakLock) {
        crowable = true;
        maxp = p;
      }
    }

    if (!crowable) //didn't find in hands of any squad member
    {
      for (int l = 0; l < activeSquad!.loot.length; l++) {
        if (activeSquad!.loot[l].isWeapon) {
          Weapon w = activeSquad!.loot[l] as Weapon;
          if (w.type.autoBreakLock) {
            crowable = true;
            maxp = activeSquad!.livingMembers.first;
          }
        }
      }
    }
  }

  int maxattack = 0;

  if (!crowable) {
    for (Creature p in activeSquad!.livingMembers) {
      if (maxp == null ||
          (p.attribute(Attribute.strength) *
                  p.weapon.type.bashStrengthModifier >
              maxattack)) {
        maxattack = (p.attribute(Attribute.strength) *
                p.weapon.type.bashStrengthModifier)
            .floor();
        maxp = p;
      }
    }
  }

  difficulty = (difficulty / maxp!.weapon.type.bashStrengthModifier).floor();

  if (crowable || maxp.attributeCheck(Attribute.strength, difficulty)) {
    clearMessageArea();
    mvaddstrc(9, 1, white, maxp.name);
    addstr(" ");
    switch (type) {
      case BashTypes.door:
        if (crowable) {
          addstr("uses a crowbar on the door");
        } else if (maxp.weapon.type.bashStrengthModifier > 1) {
          addstr("smashes in the door");
        } else if (maxp.hasWheelchair) {
          addstr("rams open the door");
        } else {
          addstr("kicks in the door");
        }
    }
    addstr("!");

    await getKey();

    int timer = 5;
    if (crowable) timer = 20;

    if (siteAlarmTimer < 0 || siteAlarmTimer > timer) {
      siteAlarmTimer = timer;
    } else {
      siteAlarmTimer = 0;
    }

    //Bashing doors in secure areas sets off alarms
    if ((activeSite!.type == SiteType.prison ||
            activeSite!.type == SiteType.intelligenceHQ) &&
        !siteAlarm) {
      siteAlarm = true;
      move(10, 1);
      setColor(red);
      addstr("Alarms go off!");

      await getKey();
    }

    return UnlockResult.bashed;
  } else {
    clearMessageArea();
    mvaddstrc(9, 1, white, maxp.name);
    switch (type) {
      case BashTypes.door:
        if (maxp.hasWheelchair) {
          addstr(" rams into the door");
        } else {
          addstr(" kicks the door");
        }
    }
    addstr("!");

    await getKey();

    if (siteAlarmTimer < 0) siteAlarmTimer = 25;

    return UnlockResult.failed;
  }
}

/* computer hack attempt */
Future<UnlockResult> hack(HackTypes type) async {
  int difficulty = switch (type) {
    HackTypes.supercomputer => Difficulty.heroic,
    HackTypes.vault => Difficulty.hard,
  };

  int maxattack = -3;
  Creature? hacker;

  for (Creature p in activeSquad!.livingMembers
      .where((p) => p.skill(Skill.computers) > 0)) {
    int roll = p.skillRoll(Skill.computers);
    if (!p.canSee) roll -= 3;
    if (roll > maxattack) {
      maxattack = roll;
      hacker = p; // best hacker so far
    }
  }

  if (hacker != null) {
    bool blind = !hacker.canSee;
    hacker.train(Skill.computers, difficulty);

    if (maxattack > difficulty) {
      clearMessageArea();
      mvaddstrc(9, 1, white, hacker.name);
      if (hacker.skill(Skill.computers) < 2) {
        addstr(" presses buttons randomly...");
        await getKey();
        mvaddstr(10, 1, "...and accidentally");
      }
      switch (type) {
        case HackTypes.supercomputer:
          addstr(" burns a disk of top secret files");
        case HackTypes.vault:
          addstr(" disables the second layer of security");
      }
      if (blind) {
        addstr(" despite being blind");
      }
      addstr("!");

      await getKey();

      return UnlockResult.unlocked;
    } else {
      clearMessageArea();
      mvaddstrc(9, 1, white, hacker.name);
      if (hacker.skill(Skill.computers) < 2) {
        addstr(" presses buttons randomly...");
        await getKey();
        mvaddstr(
            10,
            1,
            [
              "...which doesn't work. Obviously.",
              "...but now the screen is off and won't turn on.",
              "...and manages to install DOOM. Which is cool, but unhelpful.",
              "...and now it's doing a virus scan and locking out input.",
              "...until a thin line of smoke rises from the computer.",
              "...until the computer just freezes up.",
              "...and presses \"enable lockout\" followed by \"confirm\".",
              "...but now the text is in wingdings.",
              "...and now the keyboard layout is in Klingon.",
              "...and now the computer is playing tic-tac-toe against itself.",
            ].random);
      } else {
        addstr(" couldn't");
        if (blind) addstr(" see how to");
        switch (type) {
          case HackTypes.supercomputer:
            addstr(" bypass the supercomputer security.");
          case HackTypes.vault:
            addstr(" bypass the vault's electronic lock.");
        }
      }

      await getKey();

      return UnlockResult.failed;
    }
  } else {
    clearMessageArea();
    mvaddstrc(9, 1, white, "You can't find anyone to do the job.");

    await getKey();
  }

  return UnlockResult.noAttempt;
}

String _mediaIssueDescription(View v) => switch (v) {
      View.lgbtRights => "trans rights",
      View.deathPenalty => "the death penalty",
      View.taxes => "taxes",
      View.nuclearPower => "nuclear power",
      View.animalResearch => "animal research",
      View.policeBehavior => "police violence",
      View.torture => "torture",
      View.prisons => "prison reform",
      View.intelligence => "privacy laws",
      View.freeSpeech => "free speech",
      View.genetics => "genetic research",
      View.justices => "the Supreme Court",
      View.gunControl => "gun violence",
      View.sweatshops => "sweatshops",
      View.pollution => "pollution",
      View.corporateCulture => "corporations",
      View.ceoSalary => "billionaires",
      View.womensRights => "gender equality",
      View.civilRights => "civil rights",
      View.drugs => "drug laws",
      View.immigration => "immigration",
      View.military => "military spending",
      View.amRadio => "AM radio shows",
      View.cableNews => "Conservative media bias",
      View.lcsKnown => "the LCS",
      View.lcsLiked => "the LCS",
      View.ccsHated => "the CCS",
    };

int _mediaSegmentPower() {
  int segmentpower = 0;
  int partysize = activeSquad!.livingMembers.length;

  for (Creature p in activeSquad!.livingMembers) {
    segmentpower += p.attribute(Attribute.intelligence);
    segmentpower += p.attribute(Attribute.heart);
    segmentpower += p.attribute(Attribute.charisma);
    segmentpower += p.skill(Skill.music);
    segmentpower += p.skill(Skill.religion);
    segmentpower += p.skill(Skill.science);
    segmentpower += p.skill(Skill.business);
    segmentpower += p.skill(Skill.persuasion);
    p.train(Skill.persuasion, 50);
  }

  segmentpower = (segmentpower / partysize + segmentpower / 4).round();
  return segmentpower;
}

Future<bool> tvBroadcast() async {
  return await _mediaBroadcast(
      "camera", View.cableNews, "TV", "viewers", CreatureTypeIds.newsAnchor);
}

Future<bool> radioBroadcast() async {
  return await _mediaBroadcast("microphone", View.amRadio, "radio", "listeners",
      CreatureTypeIds.radioPersonality);
}

String _mediaQualityDescription(
    int segmentpower, String medium, String viewername) {
  return switch (segmentpower) {
    < 25 => "The Squad sounds utterly clueless.",
    < 35 => "The segment really sucks.",
    < 45 => "It is a very boring hour.",
    < 55 => "It is mediocre $medium.",
    < 70 => "The show was all right.",
    < 85 => "The Squad put on a good show.",
    < 100 => "It was thought-provoking, even humorous.",
    < 150 => "The regular show isn't half this good.",
    _ => "The Squad leaves $viewername weeping for freedom!",
  };
}

Future<bool> _mediaBroadcast(String takeover, View mediaView, String medium,
    String viewername, String celebrityType) async {
  siteAlarm = true;

  int enemy = 0;
  for (Creature e in encounter) {
    if (e.alive) {
      if (e.align == Alignment.conservative) enemy++;
    }
  }

  if (enemy > 0) {
    await encounterMessage("The Conservatives in the room hurry the Squad, so ",
        line2: "the broadcast never happens.");
    return false;
  }

  addPotentialCrime(squad, Crime.disturbingThePeace);
  addPotentialCrime(squad, Crime.unlawfulSpeech);

  View viewhit = View.issues.random;
  View hostageviewhit = View.issues.random;
  await encounterMessage("The Squad takes control of the $takeover and ",
      line2: "talks about ${_mediaIssueDescription(viewhit)}.");

  int segmentpower = _mediaSegmentPower();

  //PRISONER PARTS
  for (Creature p in activeSquad!.livingMembers) {
    if (p.prisoner != null) {
      if (p.prisoner?.alive == true &&
          p.prisoner?.type.id == celebrityType &&
          p.prisoner?.align == Alignment.conservative) {
        hostageviewhit = View.issues.random;
        await encounterMessage(
            "The hostage ${p.prisoner!.name} is forced on air to ",
            line2: "discuss ${_mediaIssueDescription(hostageviewhit)}.");

        addPotentialCrime(squad, Crime.terrorism);

        int usegmentpower = 10; //FAME BONUS
        usegmentpower += p.prisoner!.attribute(Attribute.intelligence);
        usegmentpower += p.prisoner!.attribute(Attribute.heart);
        usegmentpower += p.prisoner!.attribute(Attribute.charisma);
        usegmentpower += p.prisoner!.skill(Skill.persuasion);

        changePublicOpinion(hostageviewhit, (usegmentpower / 2).round());

        segmentpower += usegmentpower;
      } else {
        await encounterMessage(
            "${p.prisoner!.name}, the hostage, is kept off-air.");
      }
    }
  }

  await encounterMessage(
      _mediaQualityDescription(segmentpower, medium, viewername));

  //CHECK PUBLIC OPINION
  changePublicOpinion(View.lcsKnown, 10);
  changePublicOpinion(
      View.lcsLiked,
      ((segmentpower - 50) * ((100 - publicOpinion[mediaView]!) / 200))
          .round());
  changePublicOpinion(viewhit,
      ((segmentpower - 50) * ((100 - publicOpinion[mediaView]!) / 100)).round(),
      coloredByLcsOpinions: true);
  changePublicOpinion(View.freeSpeech,
      ((segmentpower - 50) * ((100 - publicOpinion[mediaView]!) / 100)).round(),
      coloredByLcsOpinions: true);
  if (squad.any((c) => c.weapon.isAGun && c.weapon.isCurrentlyLegal)) {
    changePublicOpinion(
        View.gunControl,
        ((segmentpower - 50) * ((100 - publicOpinion[mediaView]!) / 100))
            .round(),
        coloredByLcsOpinions: true);
  }

  if (siteAlienated.index >= SiteAlienation.alienatedModerates.index &&
      segmentpower >= 40) {
    siteAlienated = SiteAlienation.none;
    await encounterMessage("Moderates at the station appreciated the show.",
        line2: "They no longer feel alienated.");
  }

  //POST-SECURITY BLITZ IF IT SUCKED
  if (segmentpower < 85 && segmentpower >= 25) {
    await encounterMessage("Security is waiting for the Squad ",
        line2: "after the show!");

    fillEncounter(CreatureTypeIds.securityGuard, lcsRandom(8) + 2);
  } else {
    await encounterMessage(
        "The show was so ${(segmentpower < 50) ? "hilarious" : "entertaining"} that security listened to it ",
        line2: "at their desks.  The Squad might yet escape.");
  }

  return true;
}

/* rescues people held at the activeparty's current location */
Future<void> partyrescue(TileSpecial special) async {
  int freeslots = 6 - squad.length;
  int hostslots =
      activeSquad!.livingMembers.where((e) => e.prisoner == null).length;

  List<Creature> waitingForRescue = pool
      .where((p) =>
          p.alive &&
          p.isLiberal &&
          p.squad != activeSquad &&
          p.location == activeSite &&
          !p.sleeperAgent &&
          !(special == TileSpecial.prisonControlLow &&
              !(p.sentence > 0 && !p.deathPenalty)) &&
          !(special == TileSpecial.prisonControlMedium &&
              !(p.sentence < 0 && !p.deathPenalty)) &&
          !(special == TileSpecial.prisonControlHigh && !p.deathPenalty))
      .toList();

  for (Creature rescue in waitingForRescue.toList()) {
    if (freeslots > 0 && (hostslots == 0 || oneIn(2) && rescue.canWalk)) {
      rescue.squad = activeSquad;
      rescue.location = null;
      rescue.base = squad[0].base;
      rescue.justEscaped = true;
      criminalize(rescue, Crime.escapingPrison);
      hostslots++;
      freeslots--;

      printParty();
      await encounterMessage(
          "You've rescued ${rescue.name} from the Conservatives.");
      waitingForRescue.remove(rescue);
    } else if (hostslots > 0) {
      for (Creature p in activeSquad!.livingMembers) {
        if (p.prisoner == null) {
          p.prisoner = rescue;
          rescue.squadId = activeSquad!.id;
          rescue.location = null;
          rescue.base = p.base;
          rescue.justEscaped = true;
          hostslots--;
          criminalize(rescue, Crime.escapingPrison);
          printParty();
          await encounterMessage(
              "You've rescued ${rescue.name} from the Conservatives.");
          if (rescue.canWalk) {
            await encounterMessage(
                "${rescue.name} ${[
                  "was tortured recently",
                  "was beaten severely yesterday",
                  "was on a hunger strike"
                ].random}",
                line2:
                    "so ${p.name} will have to haul ${rescue.gender.himHer}.");
          } else {
            await encounterMessage("${rescue.name} is unable to walk",
                line2:
                    "so ${p.name} will have to haul ${rescue.gender.himHer}.");
          }
          waitingForRescue.remove(rescue);
          break;
        }
      }
    }
  }

  if (waitingForRescue.length == 1) {
    await encounterMessage(
        "There's nobody left to carry ${waitingForRescue[0].name}.",
        line2: "You'll have to come back later.");
  } else if (waitingForRescue.length > 1) {
    await encounterMessage("There's nobody left to carry the others.",
        line2: "You'll have to come back later.");
  }
}

Future<bool> reloadparty(bool wasteful, {bool showText = false}) async {
  bool didReload = false;
  for (Creature p in activeSquad!.livingMembers) {
    bool pReloaded = false;
    String message = "";
    if (p.hasThrownWeapon) {
      pReloaded = p.readyAnotherThrowingWeapon();
      //message = "${p.name} readies another ${p.weapon.getName()}.";
    } else if (p.canReload()) {
      pReloaded = p.reload(wasteful);
      //message = "${p.name} reloads.";
    }
    if (pReloaded) {
      didReload = true;
      if (showText && message.isNotEmpty) {
        clearMessageArea();
        printParty();
        //mvaddstrc(9, 1, white, message);
        //await getKey();
      }
    }
  }
  return didReload;
}
