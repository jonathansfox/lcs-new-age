import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/hostages/execute.dart';
import 'package:lcs_new_age/daily/hostages/interrogate.dart';
import 'package:lcs_new_age/daily/hostages/lovebomb.dart';
import 'package:lcs_new_age/daily/hostages/ransom.dart';
import 'package:lcs_new_age/daily/hostages/release.dart';
import 'package:lcs_new_age/daily/hostages/traumatize.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'tend_hostage.g.dart';

@JsonSerializable()
class InterrogationSession {
  InterrogationSession(this.hostageId);
  factory InterrogationSession.fromJson(Map<String, dynamic> json) =>
      _$InterrogationSessionFromJson(json);
  Map<String, dynamic> toJson() => _$InterrogationSessionToJson(this);

  @JsonKey(name: 'creatureId')
  int hostageId;
  @JsonKey(includeToJson: false)
  Creature get hostage => pool.firstWhere((e) => e.id == hostageId);
  Map<Technique, bool> techniques = {};
  Map<int, double> rapport = {};
  int daysOfDrugUse = 0;

  // Ransom tracking
  @JsonKey(defaultValue: false)
  bool ransomDemanded = false;
  @JsonKey(defaultValue: 0)
  int ransomAmount = 0;
  @JsonKey(defaultValue: 0)
  int daysUntilRansomResponse = 0;
  @JsonKey(defaultValue: false)
  bool ransomPaid = false;
}

enum Technique {
  talk,
  restrain,
  beat,
  props,
  drugs,
  kill,
  ransom,
  free,
  question,
  recruit,
}

Future<void> tendHostage(InterrogationSession intr) async {
  Creature cr = intr.hostage;
  var rapport = intr.rapport;
  var techniques = intr.techniques;
  List<Creature> tenders = [];

  //Find all tenders who are set to this hostage
  for (Creature p in pool) {
    if (!p.alive) continue;
    if (p.activity.type == ActivityType.interrogation &&
        p.activity.idInt == cr.id) {
      //If they're in the same location as the hostage,
      //include them in the interrogation
      if (p.location == cr.location && p.location != null) {
        tenders.add(p);
      } else {
        //If they're someplace else, take them off the job
        p.activity = Activity.none();
      }
    }
  }

  if (cr.location == null) {
    pool.remove(cr);
    return;
  }

  //possible hostage escape attempt if unattended or unrestrained
  if (tenders.isEmpty || techniques[Technique.restrain] == false) {
    //CHECK FOR HOSTAGE ESCAPE
    int liberalsAtSafehouse = pool
        .where((e) => e.location == cr.location && e.isActiveLiberal)
        .length;
    int guardsAtSafehouse = tenders.length;
    int nonGuardsAtSafehouse = liberalsAtSafehouse - guardsAtSafehouse;
    if (lcsRandom(200) + 50 * guardsAtSafehouse + 10 * nonGuardsAtSafehouse <
        cr.attribute(Attribute.intelligence) / 2 +
            cr.attribute(Attribute.agility) / 2 +
            cr.attribute(Attribute.strength) / 2 +
            cr.daysSinceJoined * 2) {
      await showMessage("${cr.name} has escaped!");

      for (Creature p in pool) {
        if (rapport[p.id] != null) {
          p.criminalize(Crime.kidnapping);
        }
      }

      cr.site?.siege.timeUntilCops = 3;

      //clear activities for tenders
      for (int i = 0; i < pool.length; i++) {
        if (!pool[i].alive) continue;
        if (pool[i].activity.type == ActivityType.interrogation &&
            pool[i].activity.idInt == cr.id) {
          pool[i].activity = Activity.none();
        }
      }

      pool.remove(cr);
      return;
    }

    if (tenders.isEmpty) return;
  }

  setColor(lightGray);

  int y = 3;

  int business = 0, religion = 0, science = 0, attack = -1;

  List<int> tenderAttack = [for (Creature _ in tenders) 0];

  for (int p = 0; p < tenders.length; p++) {
    Creature tempp = tenders[p];
    business = max(tempp.skill(Skill.business), business);
    religion = max(tempp.skill(Skill.religion), religion);
    science = max(tempp.skill(Skill.science), science);

    tenderAttack[p] = tempp.skill(Skill.psychology) * 2;

    tenderAttack[p] += tempp.clothing.type.interrogationBasePower;

    if (tenderAttack[p] < 0) tenderAttack[p] = 0;
    if (tenderAttack[p] > attack) attack = tenderAttack[p];
  }

  List<int> goodp = [];

  for (int p = 0; p < tenders.length; p++) {
    Creature tempp = tenders[p];
    if (tempp.alive && tenderAttack[p] == attack) {
      goodp.add(p);
    }
  }

  attack += Dice.r2d6.roll();
  Creature lead = tenders[goodp.first];

  attack += cr.daysSinceJoined;

  attack += business - cr.skill(Skill.business);
  attack += religion - cr.skill(Skill.religion);
  attack += science - cr.skill(Skill.science);
  attack -= cr.skill(Skill.psychology);

  attack += cr.attribute(Attribute.heart);
  attack -= cr.attribute(Attribute.wisdom);

  while (true) {
    erase();
    mvaddstrc(
        0, 0, white, "The Education of ${cr.name}: Day ${cr.daysSinceJoined}");
    y = 2;
    if (techniques[Technique.kill] == true) {
      setColor(red);
      eraseLine(y);
      move(y, 0);
      y += 2;
      addstr("The Execution of ${cr.name}   ");
    } else {
      setColor(yellow);
      move(y, 0);
      y += 2;
      addstr("Select a Liberal Education Plan");
    }

    void planItem(Technique technique, String letter, String ifActive,
        {int cost = 0, String colorKey = ColorKey.white, bool enabled = true}) {
      move(y++, 0);
      bool active = techniques[technique] ?? false;
      String text = ifActive;
      if (cost > 0) {
        String costStr = "(\$$cost)";
        text = text.padRight(30 - costStr.length, ' ') + costStr;
      }
      addInlineOptionText(
        letter,
        "$letter - $text",
        enabledWhen: ledger.funds >= cost && enabled,
        baseColorKey: active ? colorKey : ColorKey.midGray,
      );
    }

    planItem(Technique.talk, "A", "Casual Conversation");
    planItem(Technique.props, "B", "Enlightening Activities", cost: 250);
    planItem(Technique.recruit, "C", "Attempt Recruitment");
    planItem(Technique.question, "D", "Demand Information");
    planItem(Technique.ransom, "E", "Draft a Ransom Note",
        enabled: !intr.ransomDemanded);
    planItem(Technique.free, "F", "Set ${cr.name} Free");
    planItem(Technique.kill, "K", "Kill the Hostage", colorKey: ColorKey.red);
    y += 2;
    addOptionText(y++, 0, "Enter", "Enter - Confirm the Plan");

    showInterrogationSidebar(intr, lead);

    int c = await getKey();
    if (c >= Key.a && c <= Key.f || c == Key.k) {
      techniques[Technique.talk] = false;
      techniques[Technique.drugs] = false;
      techniques[Technique.restrain] = false;
      techniques[Technique.question] = false;
      techniques[Technique.props] = false;
      techniques[Technique.ransom] = false;
      techniques[Technique.kill] = false;
      techniques[Technique.free] = false;
      techniques[Technique.recruit] = false;
      techniques[switch (c) {
        Key.a => Technique.talk,
        Key.b => Technique.props,
        Key.c => Technique.recruit,
        Key.d => Technique.question,
        Key.e => Technique.ransom,
        Key.f => Technique.free,
        Key.k => Technique.kill,
        _ => Technique.talk,
      }] = true;
    }
    if (isBackKey(c)) break;
  }

  if (techniques[Technique.props] == true && ledger.funds >= 250) {
    ledger.subtractFunds(250, Expense.hostageTending);
  } else {
    techniques[Technique.props] = false;
  }

  if (techniques[Technique.kill] == true) // Kill the Hostage
  {
    y = await handleExecution(intr, lead, tenders, y);
    if (!cr.alive) {
      for (Creature p in pool) {
        if (!p.alive) continue;
        if (p.activity.type == ActivityType.interrogation &&
            p.activity.idInt == cr.id) {
          p.activity = Activity.none();
        }
      }
      return;
    }
  }

  if (techniques[Technique.free] == true) {
    await handleRelease(intr, lead, y);
    // Clear activities for tenders
    for (Creature p in tenders) {
      p.activity = Activity.none();
    }
    return;
  }

  // Recruitment attempt
  if (techniques[Technique.recruit] == true && cr.alive) {
    erase();
    mvaddstrc(0, 0, white,
        "The Recruitment of ${cr.name}: Day ${cr.daysSinceJoined}");
    y = 2;
    setColor(lightGray);

    // Base chance of success is 0%
    int successChance = 0;

    // Add psychology skill bonus
    successChance += lead.skill(Skill.psychology) * 5;

    // Add rapport bonus
    successChance += ((rapport[lead.id] ?? 0) * 10).round();
    if ((rapport[lead.id] ?? 0) < 0) {
      successChance -= 100;
    }

    // Reduce by 30% for each point of wisdom
    successChance -= cr.attribute(Attribute.wisdom) * 30;

    // Reduce by 2% for each point of juice
    successChance -= cr.juice * 2;

    String reaction;
    if (successChance >= 100) {
      reaction = [
        "accepts the offer immediately.",
        "seems to have been waiting for this ${cr.gender.hisHer} whole life.",
        "looks like ${cr.gender.heShe} is about to say yes.",
        "says yes without hesitation.",
        "says yes right away.",
        "jumps up and down in excitement.",
        "mutters \"fuck yes\" under ${cr.gender.hisHer} breath.",
      ].random;
    } else if (successChance < 0) {
      reaction = [
        "doesn't seem impressed by the offer.",
        "doesn't seem interested in joining.",
        "looks baffled by the suggestion.",
        "seems indignant at the suggestion.",
        "looks like ${cr.gender.heShe} is about to say no.",
      ].random;
    } else if (successChance < 25) {
      reaction = [
        "doesn't react as ${lead.name} makes the pitch.",
        "doesn't seem to know what to make of it.",
        "looks confused by the suggestion.",
        "looks like ${cr.gender.heShe} is trying to figure out what to say.",
      ].random;
    } else {
      reaction = [
        "leans in to listen with careful attention.",
        "seems receptive to the idea.",
        "asks some probing questions.",
        "appears to be considering the offer.",
        "looks like ${cr.gender.heShe} might be convinced.",
        "asks a lot of questions and seems to be taking it seriously.",
      ].random;
    }

    addparagraph(
        y,
        0,
        "${lead.name} attempts to recruit ${cr.name} to the Liberal Crime Squad. "
        "As the pitch goes on, ${cr.gender.heShe} $reaction");
    y = console.y + 1;

    await getKey();

    if (lcsRandom(100) < successChance) {
      String reaction = [
        "says getting kidnapped by the LCS is the best thing that ever happened "
            "to ${cr.gender.himHer}, and laughs in a sort of shocked "
            "and giddy way at how much ${cr.gender.hisHer} view of the "
            "world has been changed by the experience.",
        "says ${cr.gender.heShe} has been waiting for this moment "
            "${cr.gender.hisHer} whole life without knowing it, and "
            "this is the first chance ${cr.gender.heShe} has to really "
            "become the person ${cr.gender.heShe} was meant to be.",
        "places ${cr.gender.hisHer} hand on ${cr.gender.hisHer} chest "
            "and says ${cr.gender.heShe} has changed a lot since "
            "coming here, and ${cr.gender.heShe} is grateful to have a chance "
            "to prove it and make up for ${cr.gender.hisHer} past mistakes.",
        "says ${cr.gender.heShe} will do anything ${lead.name} asks of "
            "${cr.gender.himHer}. ${cr.gender.heSheCap} just hopes "
            "${cr.gender.heShe} has the skills to do something useful.",
      ].random;

      setColor(lightGreen);
      addparagraph(y, 0,
          "${cr.name} agrees to join the Liberal Crime Squad! ${cr.gender.heSheCap} $reaction");
      cr.hireId = lead.id;
      cr.juice = 0;
      cr.brainwashed = true;
      cr.base = cr.site;
      liberalize(cr);
      stats.recruits++;

      // Clear activities for tenders
      for (Creature p in tenders) {
        p.activity = Activity.none();
      }
    } else {
      String reaction;
      if (successChance < 0) {
        reaction = [
          "bites ${cr.gender.hisHer} tongue and just looks furious that "
              "${lead.name} would even suggest such a thing.",
          "accuses ${cr.name} of being a terrorist kidnapper who "
              "should be shot on sight.",
          "declares that the LCS is a cult. A political cult, but still a "
              "${noProfanity ? "[politically incorrect]" : "God damn"} cult. And "
              "${cr.name} can take that joining bullshit and shove it where the "
              "sun don't shine.",
          "accuses ${lead.name} of being absolutely out of "
              "${lead.gender.hisHer} mind if ${lead.gender.heShe} thinks "
              "${cr.name} would ever join a left-wing terrorist organization.",
          "rants about how the LCS are a bunch of LIBERALS and that's the "
              "absolute worst thing you can be.",
          "stands up and starts yelling about how ${cr.gender.heShe} "
              "was KIDNAPPED and is a PRISONER and if ${lead.name} has "
              "ANY DECENCY left at all, ${lead.gender.heShe} will let "
              "${cr.gender.himHer} go RIGHT NOW.",
        ].random;
        rapport[lead.id] = (rapport[lead.id] ?? 0) - 2;
      } else {
        reaction = [
          "says ${cr.gender.heShe} needs more time to think.",
          "says it's worth considering, but ${cr.gender.heShe} isn't ready for "
              "this kind of commitment.",
          "says ${cr.gender.heShe} just wants to go back to ${cr.gender.hisHer} "
              "normal life once ${lead.name} lets ${cr.gender.himHer} go.",
          "seems to have second thoughts about the whole thing.",
        ].random;
      }
      setColor(red);
      addparagraph(y, 0,
          "${cr.name} rejects the offer to join. ${cr.gender.heSheCap} $reaction");

      // Failed recruitment attempt increases wisdom slightly
      if (cr.attribute(Attribute.heart) > 1) {
        cr.adjustAttribute(Attribute.heart, -1);
        cr.adjustAttribute(Attribute.wisdom, 1);
      }
    }

    await getKey();
    return;
  }

  if (techniques[Technique.ransom] == true) {
    if (!intr.ransomDemanded) {
      // First time demanding ransom
      erase();
      mvaddstrc(
          0, 0, white, "The Ransom of ${cr.name}: Day ${cr.daysSinceJoined}");
      y = 2;
      setColor(lightGray);

      await handleRansomNote(intr, lead, cr, y);
      return;
    }
  }

  erase();
  mvaddstrc(
      0, 0, white, "The Education of ${cr.name}: Day ${cr.daysSinceJoined}");
  y = 2;

  if (intr.ransomDemanded &&
      !intr.ransomPaid &&
      intr.daysUntilRansomResponse <= 0 &&
      cr.site?.siege.underSiege == false) {
    // Time for ransom response
    bool ransomSuccess = await handleRansomResponse(intr, cr);
    if (ransomSuccess) {
      // Ransom was successful, set them free
      await handleRelease(intr, lead, y);
      // Clear activities for tenders
      for (Creature p in tenders) {
        p.activity = Activity.none();
      }
      return;
    }
  } else {
    setColor(lightGray);
    addparagraph(y, 0,
        "${cr.name} is locked in a back room converted into a makeshift cell.");
    y = console.y + 1;
    if (intr.ransomDemanded &&
        !intr.ransomPaid &&
        cr.site?.siege.underSiege == false) {
      // Waiting for response
      intr.daysUntilRansomResponse--;
    }
  }

  if (techniques[Technique.question] == true && cr.alive) // Firm Interrogation
  {
    await handleFirmInterrogation(lead, cr, rapport, y);
  }

  // Verbal Interrogation
  else if ((techniques[Technique.talk] == true ||
          techniques[Technique.props] == true) &&
      cr.alive) {
    await handleLoveBombing(intr, lead, cr, y);
  }

  //Lead interrogator gets bonus experience
  if (techniques[Technique.kill] != true) {
    lead.train(Skill.psychology, 20);
    //Others also get experience
    for (int i = 0; i < tenders.length; i++) {
      tenders[i].train(Skill.psychology, 10);
    }
  }

  //Death
  if (!cr.alive || cr.blood < 1) {
    cr.die();

    stats.kills++;
    move(++y, 0);
    setColor(red);
    addstr(cr.name);
    addstr(" suddenly drops dead.");
    setColor(lightGray);
    y++;
    //show_interrogation_sidebar(cr,a);

    await getKey();

    y = await traumatize(lead, "death", y);
  }

  if (cr.align == Alignment.liberal || !cr.alive) {
    for (Creature p in tenders) {
      p.activity = Activity.none();
    }
  }

  mvaddstrc(24, 0, lightGray, "Press any key to reflect on this.");
  await getKey();
}

Future<int> maybeRevealSecrets(Creature cr, Creature lead, int y) async {
  Site? workSite = cr.workLocation is Site ? cr.workLocation as Site : null;
  if (workSite?.mapped == false &&
      (oneIn(5) || cr.align == Alignment.liberal)) {
    y++;
    mvaddstr(y++, 0, "${cr.name} reveals details about the ${workSite!.name}.");
    mvaddstr(y++, 0,
        "${lead.name} was able to create a map of the site with this information.");

    workSite.mapped = true;
    workSite.hidden = false;
    await getKey();
  }
  return y;
}

// Clear sidebar
void cleanInterrogationSidebar() {
  eraseArea(startY: 4, startX: 40, endY: 23, endX: 74);
}

// Shows the interrogation data at the right side of the screen
void showInterrogationSidebar(InterrogationSession intr, Creature a) {
  cleanInterrogationSidebar();

  if (!pool.any((e) => e.id == intr.hostageId)) return;

  Creature cr = intr.hostage;
  var rapport = intr.rapport;
  int y = 4;
  move(y, 40);
  setColor(lightGray);
  addstr("Prisoner: ");
  setColor(red);
  addstr(cr.name);
  move(y += 2, 40);
  setColor(lightGray);
  addstr("Health: ");
  printHealthStat(y, 48, cr);
  mvaddstrc(++y, 40, lightGray, "Heart: ${cr.attribute(Attribute.heart)}");
  mvaddstr(++y, 40, "Wisdom: ${cr.attribute(Attribute.wisdom)}");
  mvaddstr(++y, 40, "Health: ${cr.health}");

  move(y = 13, 40);
  setColor(lightGray);
  addstr("Lead Interrogator: ");
  setColor(lightGreen);
  addstr(a.name);
  move(y += 2, 40);
  setColor(lightGray);
  addstr("Health: ");
  printHealthStat(y, 48, a);
  mvaddstrc(
      ++y, 40, lightGray, "Psychology Skill: ${a.skill(Skill.psychology)}");
  move(++y, 40);
  setColor(lightGray);
  addstr("Heart: ${a.attribute(Attribute.heart)}");
  mvaddstr(++y, 40, "Wisdom: ${a.attribute(Attribute.wisdom)}");
  mvaddstr(++y, 40, "Outfit: ${a.clothing.longName}");

  //mvaddstr(++y, 40, "Rapport: ${rapport[a.id]?.toStringAsFixed(1) ?? 0}");
  move(y += 2, 40);

  if ((rapport[a.id] ?? 0) > 7) {
    addstr("${cr.name} chats warmly with");
    mvaddstr(++y, 40, "${cr.gender.hisHer} friend ${a.name}.");
  } else if ((rapport[a.id] ?? 0) > 5) {
    addstr("${cr.name} looks forward to");
    mvaddstr(++y, 40, "these little chats.");
  } else if ((rapport[a.id] ?? 0) > 3) {
    addstr("${cr.name} has mutual respect");
    mvaddstr(++y, 40, "for ${a.name}.");
  } else if ((rapport[a.id] ?? 0) > 1) {
    addstr("${cr.name} lets ${cr.gender.hisHer}");
    mvaddstr(++y, 40, "guard down a little.");
  } else if ((rapport[a.id] ?? 0) > -1) {
    addstr("${cr.name} is uncooperative");
    mvaddstr(++y, 40, "toward ${a.name}.");
  } else if ((rapport[a.id] ?? 0) > -4) {
    addstr("${a.name} is losing");
    mvaddstr(++y, 40, "patience with ${cr.name}.");
  } else {
    addstr("${a.name} is out of fucks");
    mvaddstr(++y, 40, "to give about ${cr.name}.");
  }
}
