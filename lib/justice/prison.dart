import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/blind_time_log.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/game_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/* monthly - move a liberal to jail */
void imprison(Creature g) {
  g.location = findSiteInSameCity(g.location?.city, SiteType.prison);
}

String _juiceSuffix(int delta) {
  if (delta == 0) return "";
  return delta > 0 ? " (+$delta juice)" : " ($delta juice)";
}

Future<void> _prisonSceneLine(String text) async {
  if (canSeeThings) {
    erase();
    mvaddstrc(8, 1, white, text);
    await getKey();
    erase();
  } else {
    logBlindEvent(text);
  }
}

/* monthly - advances a liberal's prison time or executes them */
Future<void> prison(Creature g) async {
  const List<String> cruelAndUnusualExecutionMethods = [
    "beheading",
    "drawing and quartering",
    "disemboweling",
    "one thousand cuts",
    "feeding the lions",
    "repeated gladiatorial death matches",
    "burning",
    "crucifixion",
    "head-squishing",
    "piranha tank swimming exhibition",
    "vivisection",
    "covering with peanut butter and letting rats eat",
    "burying up to the neck in a fire ant nest",
    "running truck over the head",
    "drowning in a sewage digester vat",
    "chipper-shredder",
    "use in lab research",
    "blood draining",
    "chemical weapons test",
    "sale to a furniture maker",
    "being fed into a meat processing plant",
    "sale to foreign slave traders",
    "exposure to degenerate Bay 12 Curses games",
  ];

  const List<String> historicExecutionMethods = [
    "lethal injection",
    "hanging",
    "firing squad",
    "electrocution",
    "inert gas asphyxiation",
  ];

  const List<String> supposedlyHumaneExecutionMethods = ["lethal injection"];

  // People not on death row or about to be released can have a scene in prison
  if (!g.deathPenalty && g.sentence != 1 && oneIn(5)) {
    switch (laws[Law.prisons]) {
      case DeepAlignment.archConservative:
        await laborCamp(g);
      case DeepAlignment.eliteLiberal:
        await rehabilitation(g);
      default:
        await prisonScene(g);
    }
  }

  if (g.sentence > 0) {
    //COMMUTE DEATH IN RIGHT CLIMATE
    if (g.deathPenalty &&
        laws[Law.deathPenalty] == DeepAlignment.eliteLiberal) {
      erase();
      mvaddstrc(8, 1, lightGray, g.name);
      addstr("'s death sentence has been commuted to life, ");
      mvaddstr(9, 1, "due to the abolition of the death penalty.");

      await getKey();

      g.sentence = -1;
      g.deathPenalty = false;
      return;
    }

    //ADVANCE SENTENCE
    g.sentence--;
    if (g.sentence <= 0) {
      //EXECUTE
      if (g.deathPenalty) {
        erase();
        mvaddstrc(8, 1, red, "FOR SHAME:");

        String method = switch (laws[Law.deathPenalty]) {
          DeepAlignment.archConservative =>
            cruelAndUnusualExecutionMethods.random,
          DeepAlignment.conservative => historicExecutionMethods.random,
          _ => supposedlyHumaneExecutionMethods.random,
        };
        if (laws[Law.deathPenalty] == DeepAlignment.archConservative &&
            gameOptions.lighterTone) {
          method = historicExecutionMethods.random;
        }
        mvaddstr(9, 1, "Today, the Conservative Machine executed ${g.name}");
        mvaddstr(10, 1, "by $method.");

        await getKey();

        //dejuice boss
        Creature? boss = pool.firstWhereOrNull((p) => p.id == g.hireId);
        if (boss != null) {
          mvaddstrc(
            12,
            1,
            lightGray,
            "${boss.name} has failed the Liberal Crime Squad.",
          );

          mvaddstr(
            14,
            1,
            "If you can't protect your own people, who can you protect?",
          );

          await getKey();

          addjuice(boss, -50, -50);
        }

        g.die();
      }
      //SET FREE
      else {
        erase();
        mvaddstrc(8, 1, lightGray, g.name);
        addstr(" has been released from prison.");

        mvaddstr(
          9,
          1,
          "No doubt there are some mental scars, but the Liberal is back.",
        );

        await getKey();

        Clothing clothes = Clothing("CLOTHING_CLOTHES");
        g.giveArmor(clothes, null);
        // If their old base is no longer under LCS control, wander back to the
        // homeless camp instead.
        if (g.base?.controller != SiteController.lcs) {
          g.base = findSiteInSameCity(
            g.location?.city,
            SiteType.homelessEncampment,
          );
        }
        g.location = g.base;
      }
    }
    //NOTIFY OF IMPENDING THINGS
    else if (g.sentence == 1) {
      if (g.deathPenalty) {
        if (canSeeThings) {
          erase();
          mvaddstrc(
            8,
            1,
            yellow,
            "${g.name} is due to be executed next month.",
          );

          await getKey();
        } else {
          logBlindEvent("${g.name} is due to be executed next month.");
        }
      } else {
        if (canSeeThings) {
          erase();
          mvaddstrc(8, 1, white, g.name);
          addstr(" is due to be released next month.");

          await getKey();
        } else {
          logBlindEvent("${g.name} is due to be released next month.");
        }
      }
    } else {
      if (g.deathPenalty) {
        if (canSeeThings) {
          erase();
          mvaddstrc(8, 1, yellow, g.name);
          addstr(" is due to be executed in ${g.sentence} months.");

          await getKey();
        } else {
          logBlindEvent(
            "${g.name} is due to be executed in ${g.sentence} months.",
          );
        }
      }
    }
  }
}

Future<void> rehabilitation(Creature g) async {
  const List<String> reeducationExperiences = [
    " attends rehabilitative therapy in prison.",
    " works on a mural about political diversity.",
    " routinely sees a Liberal therapist in prison.",
    " attends a group therapy session in prison.",
    " enjoys the company of a moderate inmate.",
    " enjoys the company of a Conservative inmate.",
    " puts on an anti-crime performance in prison.",
    " learns about the victims of political crime.",
  ];

  String experience = reeducationExperiences.random;
  int juiceChange = 0;
  int wisdomChange = 0;
  bool renounced = false;

  if (!g.attributeCheck(Attribute.heart, Difficulty.formidable)) {
    if (g.juice > 0 && oneIn(2)) {
      juiceChange = -50;
    } else if (lcsRandom(15) > g.attribute(Attribute.wisdom) ||
        g.attribute(Attribute.wisdom) < g.attribute(Attribute.heart)) {
      wisdomChange = 1;
    } else if (g.align == Alignment.liberal && g.seduced && oneIn(4)) {
      addstr(g.name);
      addstr(" only stays loyal to the LCS for ");
      addstr(g.boss?.name ?? "the cause");
      addstr(".");
    } else {
      //Rat out contact
      Creature? contact = g.boss;
      if (contact != null) {
        criminalize(contact, Crime.racketeering);
        contact.confessions++;
      }

      g.die();
      renounced = true;
    }
  }

  if (wisdomChange != 0) {
    await _prisonSceneLine("${g.name}$experience (+$wisdomChange wisdom)");
  } else {
    await _prisonSceneLine("${g.name}$experience${_juiceSuffix(juiceChange)}");
  }
  if (renounced) {
    await _prisonSceneLine("${g.name} renounces the LCS!");
  }
  return;
}

Future<void> laborCamp(Creature g) async {
  int escaped = 0;
  String? experience;
  String? experience2;
  // Escape attempt!
  if (g.hireId == null && oneIn(3)) {
    escaped = 2;
    experience = " organizes a riot of oppressed prisoners...";
    if (g.body.canWalk) {
      experience2 = " overwhelms the prison guards!";
    } else {
      experience2 = " is carried out by other escapees!";
    }
  } else if (g.skillCheck(Skill.disguise, Difficulty.heroic) && oneIn(5)) {
    escaped = 1;
    experience = " wears an electrician's outfit...";
    if (g.body.canWalk) {
      experience2 = " rides away with some contractors!";
    } else {
      experience2 = " is carried out by some confused contractors!";
    }
    g.giveClothingType("CLOTHING_WORKCLOTHES");
  } else if (g.skillCheck(Skill.security, Difficulty.challenging) &&
      g.skillCheck(Skill.stealth, Difficulty.hard) &&
      oneIn(10)) {
    escaped = 1;
    if (g.body.armok > 0 && g.body.legok > 0) {
      experience = " picks the lock on their leg chains...";
      experience2 = " sneaks away!";
    } else {
      experience = " teaches others how to pick their leg chains...";
      experience2 = " escapes with their help!";
    }
  } else if (g.skillCheck(Skill.science, Difficulty.hard) && oneIn(10)) {
    escaped = 1;
    experience = " consumes drugs that simulate death...";
    experience2 = " is thrown out with the trash!";
  }

  const List<String> laborCampExperiences = [
    " is forced to operate dangerous machinery.",
    " is whipped by sadistic prison guards.",
    " isn't given enough food to eat.",
    " is drugged to oblivion by Educators.",
    " does back-breaking work all month.",
    " has a brutal fight with another inmate.",
    " participates in a failed prison riot.",
    " participates in a failed prison riot.",
  ];

  experience ??= laborCampExperiences.random;

  if (escaped > 0) {
    erase();
    mvaddstrc(8, 1, white, g.name);
    addstr(experience);
    await getKey();

    if (experience2 != null) {
      mvaddstrc(9, 1, white, g.name);
      addstr(experience2);
      await getKey();
    }

    move(10, 1);
    escape(g, escaped == 2);

    await getKey();

    erase();
    return;
  }

  // Routine scenes are a single line; death gets its own callout.
  if (oneIn(4)) {
    if (g.health > 1) {
      int before = g.juice;
      addjuice(g, -40, 0);
      addjuice(g, -10, -50);
      await _prisonSceneLine(
        "${g.name}$experience${_juiceSuffix(g.juice - before)}",
      );
    } else {
      g.die();
      g.location = null;
      await _prisonSceneLine("${g.name} is found dead.");
    }
  } else {
    await _prisonSceneLine("${g.name}$experience");
  }

  return;
}

Future<void> prisonScene(Creature g) async {
  int escaped = 0;
  int effect = 0;
  String? experience;
  if (g.juice + (g.hireId == null ? 300 : 0) > 500) {
    // Escape attempt!
    if (g.hireId == null && oneIn(10)) {
      escaped = 2;
      experience =
          " leads a riot with dozens of prisoners chanting the LCS slogan!";
    } else if (g.skillCheck(Skill.computers, Difficulty.formidable) &&
        oneIn(5)) {
      escaped = 2;
      experience =
          " codes a virus on a smuggled phone that opens the prison doors!";
    } else if (g.skillCheck(Skill.disguise, Difficulty.formidable) &&
        oneIn(5)) {
      escaped = 1;
      if (g.body.canWalk) {
        experience =
            " puts on smuggled street clothes and calmly walks out of prison.";
      } else {
        experience =
            " puts on smuggled street clothes and calmly rolls out the front door!";
      }
      g.giveArmor(Clothing("CLOTHING_CLOTHES"), null);
    } else if (g.skillCheck(Skill.security, Difficulty.hard) &&
        g.skillCheck(Skill.stealth, Difficulty.hard) &&
        oneIn(5)) {
      escaped = 1;
      if (g.body.armok > 0) {
        experience =
            " jimmies the cell door and cuts the fence in the dead of night!";
      } else {
        experience =
            " shows an accomplice how to pick locks, and they escape together!";
      }
    } else if (g.skillCheck(Skill.science, Difficulty.challenging) &&
        g.skillCheck(Skill.martialArts, Difficulty.challenging) &&
        oneIn(5)) {
      escaped = 1;
      experience =
          " ODs on smuggled drugs, then breaks out of the medical ward!";
    }
  }

  const List<String> goodExperiences = [
    " advertises the LCS to other inmates.",
    " organizes a gang to beat up on a serial rapist.",
    " learns little skills from other inmates.",
    " gets a prison tattoo with the letters L-C-S.",
    " comes up with new protest songs while in prison.",
  ];
  const List<String> badExperiences = [
    " gets sick for a few days from nasty prison food.",
    " spends too much time working out at the prison gym.",
    " is sexually assaulted by another prison inmate.",
    " writes to the warden swearing off political activism.",
    " rats out another inmate in exchange for benefits.",
  ];
  const List<String> generalExperiences = [
    " ends up in solitary after mouthing off to a guard.",
    " gets high off drugs smuggled into the prison.",
    " does nothing but read books at the prison library.",
    " gets into a fight and is put on latrine duty.",
    " is constantly thinking of ways to escape from prison.",
  ];

  if (escaped == 0) {
    if (g.attributeCheck(Attribute.heart, Difficulty.hard)) {
      effect = 1;
      if (lcsRandom(2) > 0) {
        experience = goodExperiences.random;
      } else {
        experience = generalExperiences.random;
      }
    } else if (g.attributeCheck(Attribute.heart, Difficulty.challenging)) {
      effect = 0;
      experience = generalExperiences.random;
    } else {
      effect = -1;
      if (lcsRandom(2) > 0) {
        experience = badExperiences.random;
      } else {
        experience = generalExperiences.random;
      }
    }
  }

  if (experience == null) return;

  if (escaped > 0) {
    erase();
    mvaddstrc(8, 1, white, g.name);
    addstr(experience);

    await getKey();

    move(10, 1);
    escape(g, escaped == 2);

    await getKey();

    erase();
    return;
  }

  int before = g.juice;
  if (effect > 0) {
    addjuice(g, 20, 1000);
  } else if (effect < 0) {
    addjuice(g, -20, -30);
  }
  await _prisonSceneLine(
    "${g.name}$experience${_juiceSuffix(g.juice - before)}",
  );
}

void escape(Creature g, bool withFriends) {
  Location? prison = g.location;
  addstr(g.name);
  addstr(" escaped from prison!");
  if (!canSeeThings) logBlindEvent("${g.name} escaped from prison!");

  addjuice(g, 50, 1000);
  criminalize(g, Crime.escapingPrison);
  g.location = findSiteInSameCity(g.site?.city, SiteType.homelessEncampment);

  if (withFriends) {
    int numEscaped = 0;
    for (Creature p in pool) {
      if (p.location == prison && !p.sleeperAgent) {
        criminalize(p, Crime.escapingPrison);
        p.location = g.location;
        numEscaped++;
      }
    }
    if (numEscaped == 1) {
      mvaddstr(11, 1, "Another imprisoned LCS member also gets out!");
      if (!canSeeThings) {
        logBlindEvent("Another imprisoned LCS member also gets out!");
      }
    } else if (numEscaped > 1) {
      mvaddstr(11, 1, "$numEscaped other LCS members escape in the riot!");
      if (!canSeeThings) {
        logBlindEvent("$numEscaped other LCS members escape in the riot!");
      }
    }
  }
}
