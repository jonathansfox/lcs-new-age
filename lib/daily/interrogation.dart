import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/advance_day.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'interrogation.g.dart';

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
  bool ransomDemanded = false;
  int ransomAmount = 0;
  int daysUntilRansomResponse = 0;
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

  void addRapport(Creature c, double value) {
    rapport.update(c.id, (v) => v + value, ifAbsent: () => value);
  }

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
    if (lcsRandom(200) + 25 * tenders.length <
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
  void selectNewLead() {
    tenders.removeWhere((e) => e.activity.type != ActivityType.interrogation);
    if (tenders.isNotEmpty) {
      lead = tenders.random;
    }
  }

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
    erase();
    mvaddstrc(0, 0, white,
        "The Final Education of ${cr.name}: Day ${cr.daysSinceJoined}");
    Creature? killer;

    for (int i = 0; i < tenders.length; i++) {
      if (lcsRandom(50) < tenders[i].juice ||
          lcsRandom(9) + 1 >=
              (tenders[i].rawAttributes[Attribute.heart] ?? 0) +
                  (rapport[tenders[i].id] ?? 0)) {
        killer = tenders[i];
        break;
      }
    }

    if (killer != null) {
      //delete interrogation information
      setColor(purple);
      cr.die();
      stats.kills++;
      mvaddstr(y++, 0, "${lead.name} executes ${cr.name} by ");
      addstr([
        "burning photos of Ronald Reagan in front of ${cr.gender.himHer}.",
        "telling ${cr.gender.himHer} that taxes have been increased.",
        "forcing ${cr.gender.himHer} to listen to right-wing radio for 24 hours straight.",
        "showing ${cr.gender.himHer} a graph of rising global temperatures.",
        "forcing ${cr.gender.himHer} to actually read a book.",
      ].random);

      await getKey();

      y = await traumatize(lead, "execution", y);
      if (lead.activity.type == ActivityType.none) {
        selectNewLead();
      }
    } else {
      setColor(brown);
      mvaddstr(y++, 0, "There is no one able to get up the nerve to ");
      mvaddstr(y++, 0, "execute ${cr.name} in cold blood.");

      await getKey();
    }
    //show_interrogation_sidebar(cr,a);

    mvaddstrc(24, 0, lightGray, "Press any key to reflect on this.");

    await getKey();

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
    erase();
    mvaddstrc(
        0, 0, white, "The Release of ${cr.name}: Day ${cr.daysSinceJoined}");
    y = 2;
    setColor(lightGray);

    if (cr.site?.siege.underSiege == true) {
      String typeOfSiegers = switch (cr.site?.siege.activeSiegeType) {
        SiegeType.police => switch (cr.site?.siege.escalationState) {
            SiegeEscalation.police => "police",
            _ => "soldiers",
          },
        SiegeType.cia => "CIA agents",
        SiegeType.angryRuralMob => "people outside",
        SiegeType.corporateMercs => "corporate mercenaries",
        SiegeType.ccs => "CCS vigilantes",
        _ => "giant bugs",
      };
      addparagraph(
          y,
          0,
          y + 4,
          79,
          "${lead.name} leads ${cr.name} to the front door and lets "
          "${cr.gender.himHer} run into the arms of the waiting $typeOfSiegers. "
          "There is a brief commotion as ${cr.name} is led to safety, but "
          "aside from that, there's no change in the situation.");
      await getKey();
      return;
    }

    // Calculate recruitment chance similar to recruitment attempt, with an
    // additional -50% penalty since you're actually letting them go and they
    // can easily just go back to their old life
    int successChance = -50;
    successChance += lead.skill(Skill.persuasion) * 5;
    successChance += ((rapport[lead.id] ?? 0) * 10).round();
    successChance -= cr.attribute(Attribute.wisdom) * 30;
    successChance -= cr.juice * 2;

    String reaction;
    if (successChance >= 100) {
      reaction = [
        "looks at ${lead.name} for a long time, and actually seems sad to go.",
        "seems to have been profoundly changed by the experience.",
        "appears to have found a new purpose in life.",
        "looks like ${cr.gender.heShe} has made an important decision.",
        "exchanges a meaningful look with ${lead.name}.",
        "tells ${lead.name} that ${cr.gender.heShe} will be in touch.",
        "appears to be thinking deeply about the future.",
        "looks like ${cr.gender.heShe} has found something ${cr.gender.heShe} was missing.",
      ].random;
    } else if (successChance < 0) {
      reaction = [
        "glances back at ${lead.name} with barely concealed contempt.",
        "seems eager to get away as quickly as possible.",
        "breaks out into a dead run as soon as ${lead.name} lets ${cr.gender.himHer} go.",
        "can't wait to get back to ${cr.gender.hisHer} old life.",
        "can barely believe ${lead.name} is actually letting ${cr.gender.himHer} go.",
        "hesitates only to make sure it isn't a trick, then bolts.",
        "looks ready to put this nonsense behind ${cr.gender.himHer}.",
      ].random;
    } else if (successChance < 25) {
      reaction = [
        "looks around cautiously, unsure what to make of this.",
        "seems confused by the sudden change in circumstances.",
        "appears to be processing what just happened.",
        "looks like ${cr.gender.heShe} is trying to figure out what to do next.",
        "runs off without a word.",
        "glances back at ${lead.name} and looks a bit confused.",
        "looks like ${cr.gender.heShe} is trying to make sense of everything.",
      ].random;
    } else {
      reaction = [
        "looks at ${lead.name} with a mix of emotions.",
        "seems to have been affected by the experience.",
        "appears to be thinking about what ${cr.gender.heShe} has learned.",
        "looks like ${cr.gender.heShe} might have changed ${cr.gender.hisHer} mind about some things.",
        "seems to be considering new possibilities.",
        "appears to be reflecting on what ${cr.gender.heShe} has been through.",
        "looks like ${cr.gender.heShe} has gained some perspective.",
      ].random;
    }

    addparagraph(
        y,
        0,
        y + 4,
        79,
        "${lead.name} takes ${cr.name} to a secure location and releases "
        "${cr.gender.himHer} from captivity. ${cr.name} $reaction");
    y = console.y + 1;

    await getKey();

    // Clear activities for tenders
    for (Creature p in tenders) {
      p.activity = Activity.none();
    }

    // If the hostage is liberal (heart > wisdom) and has rapport with the lead,
    // they might become a sleeper agent
    if (lcsRandom(100) < successChance) {
      addparagraph(
          y,
          0,
          y + 4,
          79,
          "${cr.name} gets in touch with ${lead.name} later, expressing "
          "a desire to continue their conversations and offering "
          "${cr.gender.hisHer} services as a sleeper agent for the "
          "Liberal Crime Squad.");
      cr.hireId = lead.id;
      cr.brainwashed = true;
      cr.base = cr.workLocation is Site ? cr.workLocation as Site : null;
      cr.sleeperAgent = true;
      liberalize(cr);
      stats.recruits++;
      await getKey();
    } else {
      // Otherwise they'll be released
      pool.remove(cr);
      if (cr.missing) {
        cr.missing = false;
        cr.kidnapped = false;
      }
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
        y + 4,
        79,
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
      addparagraph(y, 0, y + 4, 79,
          "${cr.name} agrees to join the Liberal Crime Squad! ${cr.gender.heSheCap} $reaction");
      cr.hireId = lead.id;
      cr.juice = 0;
      cr.brainwashed = true;
      cr.base = cr.workLocation is Site ? cr.workLocation as Site : null;
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
      addparagraph(y, 0, y + 4, 79,
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

      // Calculate ransom amount based on hostage's importance and days in captivity
      switch (cr.type.id) {
        // Very rich or very famous people
        case CreatureTypeIds.corporateCEO:
        case CreatureTypeIds.president:
        case CreatureTypeIds.actor:
        case CreatureTypeIds.athlete:
        case CreatureTypeIds.eminentScientist:
        case CreatureTypeIds.radioPersonality:
        case CreatureTypeIds.policeChief:
        case CreatureTypeIds.socialite:
        case CreatureTypeIds.landlord:
          intr.ransomAmount = 100000;
        // Pretty well off or pretty well known
        case CreatureTypeIds.newsAnchor:
        case CreatureTypeIds.engineer:
        case CreatureTypeIds.mathematician:
        case CreatureTypeIds.liberalJudge:
        case CreatureTypeIds.conservativeJudge:
        case CreatureTypeIds.bankManager:
        case CreatureTypeIds.lawyer:
        case CreatureTypeIds.doctor:
        case CreatureTypeIds.corporateManager:
        case CreatureTypeIds.psychologist:
        case CreatureTypeIds.author:
        case CreatureTypeIds.fashionDesigner:
        case CreatureTypeIds.artCritic:
        case CreatureTypeIds.musicCritic:
        case CreatureTypeIds.programmer:
        case CreatureTypeIds.chef:
        case CreatureTypeIds.musician:
        case CreatureTypeIds.footballCoach:
        case CreatureTypeIds.carSalesman:
        case CreatureTypeIds.prisonGuard:
        case CreatureTypeIds.swat:
        case CreatureTypeIds.deathSquad:
        case CreatureTypeIds.gangUnit:
        case CreatureTypeIds.merc:
        case CreatureTypeIds.cop:
          intr.ransomAmount = 10000;
        // Everybody else
        default:
          intr.ransomAmount = 1000;
      }

      addparagraph(
          y,
          0,
          y + 4,
          79,
          "${lead.name} prepares a ransom demand for ${cr.name} by ${[
            "attaching a photo of ${cr.gender.himHer} to a note made from "
                "magazine clippings",
            "recording a video of ${cr.gender.himHer} in captivity",
            "attaching a personal letter from ${cr.gender.himHer} spelling "
                "out the LCS's demands",
          ].random}. The amount "
          "is set at \$${intr.ransomAmount}. It may take some time "
          "for a response...");
      y = console.y + 1;

      await getKey();

      intr.ransomDemanded = true;
      intr.daysUntilRansomResponse = 3 + lcsRandom(4); // Response in 3-6 days
      if (!cr.kidnapped) {
        cr.kidnapped = true;
        NewsStory.prepare(NewsStories.kidnapReport).cr = cr;
      }
      cr.missing = true;
      cr.heat += 100;

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
    setColor(lightGray);

    // Determine if ransom is paid based on various factors
    bool willPay = false;
    int paymentChance = 50;

    // Increase chance if hostage is valuable
    if (cr.type.preciousToAngryRuralMobs) paymentChance += 20;
    if (cr.attribute(Attribute.charisma) > 5) paymentChance += 10;
    if (cr.attribute(Attribute.intelligence) > 5) paymentChance += 10;

    // Decrease chance if LCS is well known
    if (publicOpinion[View.lcsKnown]! > 50) paymentChance -= 20;

    willPay = lcsRandom(100) < paymentChance;
    addparagraph(y, 0, y + 4, 79,
        "A response has been received from ${cr.name}'s relatives:");
    y = console.y + 1;
    await getKey();

    if (willPay) {
      setColor(lightGreen);
      addparagraph(
          y,
          0,
          y + 4,
          79,
          [
            "\$${intr.ransomAmount} has been deposited in a secure account "
                "according to the instructions provided. Please return "
                "${cr.properName} to us unharmed.",
            "We have sent you the money in the manner you requested. "
                "Just give us our dear ${cr.properName} back.",
            "We will do anything to get ${cr.properName} back. The money is "
                "yours. We are trusting you. Please keep your word.",
          ].random);
      y = console.y + 1;

      ledger.addFunds(intr.ransomAmount, Income.ransom);
      intr.ransomPaid = true;

      for (var key in techniques.keys) {
        techniques[key] = false;
      }
      techniques[Technique.free] = true;

      await getKey();
    } else {
      setColor(red);
      addparagraph(
          y,
          0,
          y + 4,
          79,
          [
            "The friends and relatives of ${cr.name} will not negotiate with kidnappers and terrorists.",
            "Go to hell.",
            "The family of ${cr.name} will not, under any circumstances, finance a terrorist campaign.",
            "The family of ${cr.name} will not, under any circumstances, pay a ransom for that miserable piece of shit.",
          ].random);
      y = console.y + 1;
      setColor(lightGray);

      await getKey();
      intr.ransomPaid = true;
    }
  } else {
    setColor(lightGray);
    addparagraph(y, 0, y + 4, 79,
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
    move(y, 0);

    // Base forceroll on lead interrogator's psychology skill and rapport
    int forceroll = lead.skillRoll(Skill.psychology) +
        ((rapport[lead.id] ?? 0) * 5).round();
    // Reduce rapport with lead
    addRapport(lead, -1);

    String message = "${lead.name} interrogates ${cr.name}, ${[
      "asking",
      "demanding",
      "saying",
      "pressing ${cr.gender.himHer} by saying",
      "probing ${cr.gender.himHer} by saying",
    ].random} \"${[
      "What do you know?",
      "Where do you work?",
      if (ccsActive) "What do you know about the CCS?",
      "Give up your secrets!",
      "Tell us what you know!",
      "We need information!",
      "What are you hiding?",
      "What's really going on?",
    ].random}\"";
    addparagraph(y, 0, y + 4, 79, message);
    y = console.y + 1;

    await getKey();

    if (!cr.attributeCheck(Attribute.wisdom, forceroll)) {
      if (cr.skillCheck(Skill.religion, forceroll)) {
        mvaddstr(
            y++,
            0,
            "${cr.name} ${[
              "prays silently...",
              "seeks strength in faith.",
              "tries to find inner peace.",
              "looks to God for guidance.",
              "whispers a prayer.",
              "asks for divine help.",
            ].random}");
      } else {
        Site? workSite =
            cr.workLocation is Site ? cr.workLocation as Site : null;
        if (workSite?.mapped == false && oneIn(5)) {
          addparagraph(y, 0, y + 4, 79,
              "${cr.name} reveals everything ${cr.gender.heShe} knows about the ${workSite!.name}.");
          y = console.y + 1;

          await getKey();

          workSite.mapped = true;
          workSite.hidden = false;
        } else {
          String the = cr.workLocation is Site ? "the " : "";
          addparagraph(y, 0, y + 4, 79,
              "${cr.name} shares information about $the${cr.workLocation.name}, though ${cr.gender.heShe} doesn't know much of interest to the LCS.");
          y = console.y + 1;

          await getKey();
        }
      }
    } else {
      mvaddstr(y++, 0, "${cr.name} holds firm.");
      await getKey();
    }
  }

  // Verbal Interrogation
  else if ((techniques[Technique.talk] == true ||
          techniques[Technique.props] == true) &&
      cr.alive) {
    double rapportTemp = rapport[lead.id] ?? 0;

    if (techniques[Technique.props] == true) attack += 10;
    attack += (rapportTemp * 5).round();

    String message;
    if (techniques[Technique.props] == true) {
      List<String> miniOptions = [
        "protest sign workshop",
        "drag show",
        "puppet show",
        "movie showing",
        "yoga session",
        "speech",
        "poetry slam",
        "chill session",
        "fashion show",
        "big hug",
        "miniature concert",
        "book reading",
        "feast",
        "mock protest",
        "board game",
        "live chicken",
      ];
      message = "${lead.name} ${[
        "serves ${cr.name} an incredible vegan feast, complete with quinoa "
            "casserole and an oat milk latte, insisting that ${cr.gender.heShe} "
            "try it all while ${lead.name} explains the comparative carbon "
            "footprint of the ingredients and contrasts this against the "
            "carbon footprint of a traditional meat-based meal.",
        "holds an in-depth microaggression workshop with ${cr.name}, engaging "
            "${cr.gender.himHer} in a series of elaborate role-playing scenarios "
            "where they dissect even the most innocuous phrases for hidden biases "
            "and discuss how this impacts ${cr.name} and others around them.",
        "puts together a poetry slam for ${cr.name}, where at first ${lead.name} "
            "reads some of ${lead.gender.hisHer} own poetry before ${cr.name} "
            "is given the stage to join in with several verses of ${cr.gender.hisHer} own, "
            "leading into a long discussion about the poetic form and the "
            "lived experiences that feed into their respective verses.",
        "holds a mock protest to bring ${cr.name} into the movement in spirit, "
            "starting with an extended planning session where they pick out "
            "phrases and put together protest signs about issues that really "
            "matter to ${cr.gender.himHer}.",
        "holds a movie night with ${cr.name}, with a marathon of documentaries "
            "on topics like renewable energy and intersectionality, pausing "
            "frequently for collaborative discussions on \"what it all means\".",
        "has ${cr.name} brainstorm protest sign ideas on issues that matter to "
            "${cr.gender.himHer}, then helps ${cr.gender.himHer} to "
            "put together a sign ${cr.gender.heShe} can take out into the street "
            "once ${cr.name} is released.",
        "puts on a drag brunch for ${cr.name}, encouraging ${cr.gender.himHer} to "
            "embrace self-expression and self-love through glitter, pancakes, "
            "and RuPaul quotes.",
        "sets up a supervised drug experimentation day for ${cr.name}, with a "
            "variety of substances to try, including Cannabis, LSD, MDMA, "
            "and psilocybin, making sure that ${cr.gender.heShe} is "
            "comfortable with the process and has a safe space to explore "
            "altered states of consciousness while minimizing risk to "
            "${cr.gender.hisHer} health.",
        "assigns ${cr.name} a stack of progressive literature, focused on readings "
            "from bell hooks, Audre Lorde, and other feminist icons, so ${cr.gender.heShe} "
            "can break through the barriers of ${cr.gender.hisHer} old mindset "
            "and start to understand the importance of intersectional feminism.",
        "assigns ${cr.name} a stack of progressive literature, focused on readings "
            "from Ngũgĩ wa Thiong'o, Edward Said, and other postcolonial theorists, "
            "so ${cr.gender.heShe} can start to understand the importance of "
            "decolonizing ${cr.gender.hisHer} mind.",
        "assigns ${cr.name} a stack of progressive literature, focused on readings "
            "from Angela Davis, Frantz Fanon, and other revolutionary thinkers, "
            "so ${cr.gender.heShe} can start to understand some of the ideas "
            "that underpin revolutionary left-wing politics.",
        "assigns ${cr.name} a stack of progressive literature, focused on readings "
            "from Peter Kropotkin, Emma Goldman, and other anarchist thinkers, "
            "so ${cr.gender.heShe} can start to question the absolute authority "
            "of the state and the need for a more just and equitable society.",
        "assigns ${cr.name} a stack of progressive literature, focused on readings "
            "from Judith Butler, Michel Foucault, and other queer theorists, "
            "so ${cr.gender.heShe} can start to understand the politics of "
            "queer liberation and the fight against gender-based oppression.",
        "holds a mandatory self-care bootcamp for ${cr.name}, complete with yoga "
            "sessions, aromatherapy, and journaling prompts like \"What does "
            "your political inner child look like?\"",
        "hosts a \"paint your feelings\" session for ${cr.name}, where ${cr.gender.heShe} "
            "is encouraged to express the flaws in ${cr.gender.hisHer} ideology "
            "through abstract art, with no judgment or critique, but a deep "
            "compassion.",
        "organizes a personalized concert of protest-inspired music, inviting "
            "${cr.name} to join in on the harmonies, with a focus on uplifting "
            "songs about love and unity early in the session, and then moving "
            "into more complex and forceful pieces as the session progresses.",
        "holds an inclusive fashion show for ${cr.name}, where ${cr.gender.heShe} "
            "can try on a variety of outfits that challenge traditional gender "
            "norms and incorporate elements of niche subcultures, each item "
            "linked to a discussion about the history and significance of the "
            "style and the subculture it comes from.",
        "brings in gardening supplies and teaches ${cr.name} how to grow ${cr.gender.hisHer} own "
            "food, narrating how sowing literal seeds of change mirrors the "
            "LCS's mission to uproot harmful ideologies.",
        "builds an intricate escape room for ${cr.name}, full of puzzles about "
            "systemic inequality, where ${cr.gender.heShe} can only solve each "
            "puzzle by first escaping ${cr.gender.hisHer} old mindset.",
        "stages a puppet show for ${cr.name}, featuring characters like "
            "Karl Marx and Rosa Luxemburg in a series of skits about the "
            "history of the LCS and the importance of revolutionary "
            "politics.",
        "throws a holiday party for ${cr.name} celebrating ${[
          "Intersectional Justice Jubilee",
          "Hug-Your-Haters Day",
          "Intersectionality Awareness Day",
          "Queer Liberation Day",
          "Decolonization Day",
          "Anarchist Abolitionist Day",
          "Feminist Resistance Day",
          "Trans Unity Day",
          "Rainbow Butterfly Day",
          "Incredible Inclusivity Day",
          "Black Power Day",
          "African Roots Day",
          "Black And Proud Day",
          "Black Lives Do In Fact Matter Day",
          "Love Wins Day",
          "Liberalism Day",
          "Leftist Pride Day",
          "Social Justice Day",
          "Adopt-A-Conservative Day",
          "Fuck The Police Day",
          "Radical Self-Care Day",
          "Resistance Day",
          "Even Prouder Pride Day",
          "I'm A Liberal Day",
          "Damn It's Good To Be A Liberal Day",
          "Liberalism Is The New Black Day",
          "Join The LCS Day",
          "Stop Being A Conservative Day",
        ].random}, complete with a ${miniOptions.randomPop()}, a ${miniOptions.randomPop()}, and a ${miniOptions.randomPop()}.",
        "gives ${cr.name} a live chicken to hold while ${lead.name} plays "
            "a series of undercover videos of factory farms and slaughterhouses "
            "for ${cr.gender.himHer}, then encourages ${cr.gender.himHer} to "
            "get in touch with ${cr.gender.hisHer} true feelings.",
      ].random}";
    } else {
      message = "${lead.name} ${[
        "raves about how good vegan food is to ${cr.name}.",
        "explains microaggressions to ${cr.name}.",
        "recites some spoken word poetry for ${cr.name}.",
        "quizzes ${cr.name} about correct recycling habits.",
        "enthuses about the benefits of regular meditation to ${cr.name} "
            "and offers to teach ${cr.gender.himHer} how to do it.",
        "shows ${cr.name} pictures of people having fun at a protest and "
            "suggests ${cr.gender.heShe} would get a lot out of it.",
        "describes a progressive film to ${cr.name} and tells ${cr.gender.himHer} "
            "about what it means.",
        "tells ${cr.name} about some clever protest signs people have come up "
            "with in the past.",
        "tells ${cr.name} how much fun drag shows are and offers to answer "
            "any questions ${cr.gender.himHer} has about them.",
        "recommends ${cr.name} read some theory when ${cr.gender.heShe} gets "
            "a chance, and tries to explain some of the complex ideas "
            "from memory.",
        "asks ${cr.name} \"What does your political inner child look like?\"",
        "tries to do a guided meditation with ${cr.name}, and asks "
            "${cr.gender.himHer} to visualize ${cr.gender.hisHer} feelings "
            "like a painting.",
        "plays a selection of protest songs on ${lead.gender.hisHer} cell "
            "phone and asks ${cr.gender.himHer} what ${cr.gender.heShe} thinks "
            "they mean.",
        "challenges ${cr.name} to imagine a world without posessions, and "
            "wonders if ${cr.gender.heShe} can.",
        "suggests ${cr.name} would look good in a hemp tunic.",
        "says ${cr.name} would could be a totally epic left-wing punk rebel "
            "if ${cr.gender.heShe} is interested in that sort of thing.",
        "tells ${cr.name} about the importance of intersectionality.",
        "explains to ${cr.name} that fair trade coffee actually tastes better "
            "and is better for the world.",
        "works with ${cr.name} to imagine the best possible world.",
        "asks ${cr.name} to imagine a world without prisons, and tries to "
            "engage ${cr.gender.himHer} in a discussion about how "
            "conflicts would be resolved if locking people away wasn't "
            "an option.",
        "asks ${cr.name} to imagine a world without borders, where moving "
            "between countries is as easy as moving between cities.",
        "tries to help ${cr.name} escape ${cr.gender.hisHer} old mindset.",
        "encourages ${cr.name} to admit ${cr.gender.hisHer} past mistakes, "
            "everything ${cr.gender.heShe} feels guilty or ashamed of, "
            "so ${lead.gender.heShe} can show unconditional acceptance and "
            "understanding of them instead of the rejection ${cr.name} was "
            "expecting.",
      ].random}";
    }
    addparagraph(y, 0, y + 6, 79, message);
    y = console.y + 1;

    await getKey();

    //Target is swayed by Liberal Reason -- skilled interrogators, time held,
    //and rapport contribute to the likelihood of this
    int marginOfSuccess = cr.attribute(Attribute.wisdom) * 2 +
        cr.skill(Skill.business) +
        cr.skill(Skill.religion) +
        cr.skill(Skill.science) +
        cr.skill(Skill.psychology) * 2;
    if (marginOfSuccess < attack) {
      // Reduce juice if any is there
      if (cr.juice > 0) {
        cr.juice -= marginOfSuccess;
        if (cr.juice < 0) cr.juice = 0;
      } else if (cr.juice == 0) {
        // Otherwise, modify heart and wisdom when juice is 0
        if (cr.attribute(Attribute.wisdom) > 1) {
          cr.adjustAttribute(Attribute.wisdom, -1);
        }
        if (cr.attribute(Attribute.heart) < 10) {
          cr.adjustAttribute(Attribute.heart, 1);
        }
      }

      //Improve rapport with interrogator
      addRapport(lead, 1 + lcsRandom(5) * 0.2);

      mvaddstr(y++, 0, cr.name);
      addstr([
        "'s Conservative beliefs are shaken.",
        " quietly considers these ideas.",
        " is beginning to see Liberal reason.",
        " has a revelation of understanding.",
        " grudgingly admits sympathy for LCS ideals.",
        " is beginning to see the error of ${cr.gender.hisHer} ways.",
        " is beginning to understand where the LCS is coming from.",
        " never really thought about things this way before.",
      ].random);

      await getKey();
    }
    //Target is not sold on the LCS arguments and holds firm
    //This is the worst possible outcome if you use props
    else if (!cr.skillCheck(Skill.persuasion,
            lead.attribute(Attribute.heart) + 5 - cr.skill(Skill.psychology)) ||
        techniques[Technique.props] == true) {
      //Loses rapport
      addRapport(lead, -0.2 - lcsRandom(5) * 0.1);

      String description;
      if (rapportTemp > lcsRandom(3) ||
          cr.skill(Skill.psychology) > lead.skill(Skill.psychology)) {
        if (cr.skill(Skill.psychology) > lead.skill(Skill.psychology)) {
          description = [
            "${cr.name} plays along but somehow makes everything seem so "
                "silly and trivial.",
            "${lead.name} somehow ends up on the defensive as ${cr.name} calls "
                "out every manipulative comment ${lead.gender.heShe} makes "
                "in the effort to get ${cr.gender.himHer} to change "
                "${cr.gender.hisHer} views.",
            "${cr.name} sardonically critiques this \"recruitment strategy\" "
                "of love bombing hostages until they think this miserable "
                "existence as a criminal on the fringes of society is somehow "
                "better than the alternative.",
            "${cr.name} suggets ${lead.name} should see a therapist to deal "
                "${cr.gender.hisHer} issues instead of kidnapping and "
                "brainwashing people.",
            "${cr.name} offers some sardonically deadpan advice on how "
                "${lead.name} could make this more coercive and convincing.",
            "${cr.name} keeps asking ${lead.name} the same questions for "
                "some reason and it's just pissing ${lead.gender.himHer} off.",
            "${cr.name} dismisses the activities and asks some rather "
                "rather uncomfortable questions about ${lead.name}'s past.",
          ].random;
          lead.train(Skill.psychology, cr.skill(Skill.psychology) * 4);
          rapport[lead.id] = (rapport[lead.id] ?? 0) - lcsRandom(10) * 0.1;
        } else if (cr.skill(Skill.religion) > lead.skill(Skill.religion)) {
          description = [
            "${lead.name} is unable to shake ${cr.name}'s religious conviction.",
            "${cr.name} draws strength from God.",
            "${lead.name}'s efforts to shake ${cr.name}'s faith seem futile.",
            "${cr.name} explains the Conservative tenets of ${cr.gender.hisHer} faith.",
            "${cr.name} praises the Lord for this moment to converse.",
            "${cr.name} prays that health finds them both.",
            "${cr.name} asks ${lead.name} if ${lead.gender.heShe} ever think${lead.gender.s} about Jesus.",
          ].random;
          lead.train(Skill.religion, cr.skill(Skill.religion) * 4);
        } else if (cr.skill(Skill.business) > lead.skill(Skill.business)) {
          description = [
            "${cr.name} offers to make a deal.",
            "${cr.name} asks if there's a ransom.",
            "${cr.name} asks if the LCS plans to make money from kidnapping.",
            "${cr.name} suggests the interrogation room could be better decorated.",
            "${cr.name} explains the basics of supply and demand.",
            "${cr.name} talks about economic theory.",
            "${cr.name} mounts a defense of Reaganomics.",
            "${cr.name} talks about the importance of the free market.",
            "${cr.name} explains the importance of capitalism.",
            "${cr.name} professes faith in the invisible hand.",
          ].random;
          lead.train(Skill.business, cr.skill(Skill.business) * 4);
        } else {
          description = [
            "The conversation is polite.",
            "${cr.name} engages but is not swayed.",
            "${cr.name} is not convinced.",
            "${cr.name} asks questions, but seems unmoved.",
            "${cr.name} teases ${lead.name} a bit.",
            "${cr.name} asks for ${[
              "coffee",
              "tea",
              "water",
              "a burger",
            ].random}.",
            "${cr.name} explains why ${cr.gender.heShe} disagrees.",
            "${cr.name} debates the points raised.",
          ].random;
        }
      } else {
        description = [
          "${cr.name} just stares.",
          "${cr.name} demands to be released.",
          "${cr.name} refuses to speak.",
          "${cr.name} yells at ${lead.name}.",
          "${cr.name} huffs indignantly.",
          "${cr.name} insults ${lead.name}.",
          "${cr.name} looks at the walls.",
          "${cr.name} ignores ${lead.name}.",
        ].random;
      }
      addparagraph(y, 0, y + 4, 79, description);
      y = console.y + 1;
      await getKey();
    }
    //Target actually wins the argument so successfully that the Liberal
    //interrogator's convictions are the ones that are shaken
    else {
      //Consolation prize is that they end up liking the
      //liberal more
      addRapport(lead, 1.5);

      lead.adjustAttribute(Attribute.wisdom, 1);

      addparagraph(
          y,
          0,
          y + 4,
          79,
          "${cr.name} makes some fascinating points that ${lead.name} has "
          "never considered before... ${lead.name} is completely thrown "
          "off guard.");
      y = console.y + 1;

      mvaddstrc(y++, 0, red, "${lead.name} has been tainted with wisdom!");
      await getKey();
    }
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

Future<int> traumatize(Creature lead, String action, int y) async {
  if (lcsRandom(lead.attribute(Attribute.heart)) > lcsRandom(3)) {
    mvaddstrc(y++, 0, lightGreen,
        "${lead.name} feels sick to ${lead.gender.hisHer} stomach afterward and ");
    lead.heartDamage += 1;
    move(y++, 0);
    addstr([
      "throws up in a trash can.",
      "gets drunk, eventually falling asleep.",
      "curls up in a ball, crying softly.",
      "shoots up and collapses in a heap on the floor.",
      "has a panic attack.",
      "doesn't want to talk to anyone.",
      "can't sleep for days.",
      "is haunted by the memory of the $action.",
      "has nightmares afterwards."
    ].random);
    lead.activity = Activity.none();
  } else if (oneIn(3) && lead.attribute(Attribute.wisdom) < 10) {
    mvaddstrc(y++, 0, lightBlue, "${lead.name} grows colder.");
    lead.adjustAttribute(Attribute.wisdom, 1);
  } else if (oneIn(3) &&
      lead.attribute(Attribute.wisdom) > lead.attribute(Attribute.heart)) {
    String name = lead.name;
    mvaddstrc(y++, 0, lightGray, "$name leaves the safehouse in a daze.");
    await getKey();
    mvaddstrc(
        y++,
        2,
        midGray,
        [
          "$name wanders the streets all night, lost in thought.",
          "$name gets drunk while out and rethinks this life.",
          "$name runs naked through the park at night.",
          "$name wanders aimlessly through the city, unable to think.",
          "$name finds a quiet diner and watches people exist.",
          "$name lies on a park bench, wracked by regret.",
          "$name walks until exhaustion forces ${lead.gender.himHer} to collapse.",
          "$name goes to a bar and meets some new people.",
          "$name lies down in a dumpster, where ${lead.gender.heShe} belongs.",
          "$name knocks on people's doors, turned away every time.",
          "$name sits in a bar, drinking and staring at the wall.",
          "$name stares at a church for hours, before going in.",
          "$name follows flickering streetlights into the darkness.",
          "$name sits in a park, watching people with regular lives.",
          "$name walks until the city dissolves into fog.",
          "$name stares up at the moon as it draws impossibly close.",
          "$name catches a bus, not knowing where it leads.",
          "$name catches a bus and rides it to the end of the line.",
          "$name catches a bus to the next city.",
          "\"I don't want to do this anymore...\"",
          "\"I need to get out of here!\"",
          "\"I can't do this anymore.\"",
          "\"I hate who I've become...\"",
          "\"I don't want to be a part of this...\"",
          "\"I hate this place!\"",
          "\"Fuck all of this!\"",
          "\"Fucking LCS bullshit...\"",
          "\"Who gives a shit about this anyway...\"",
          "\"What am I fucking doing?\"",
          "\"I hate this, I hate myself.\"",
          "\"I used to think I was a good person...\"",
        ].random);
    await getKey();
    if (oneIn(2)) {
      if (oneIn(2)) {
        mvaddstrc(y++, 4, darkGray, "${lead.name} never comes back.");
        lead.location = null;
        lead.die(); // they might be alive, but it doesn't matter to the LCS
        lead.boss?.juice -= 25;
        if (oneIn(2)) {
          lead.base?.siege.timeUntilCops = 2;
        }
      } else {
        lead.location = null;
        lead.hidingDaysLeft = lcsRandom(3) + 2;
        mvaddstrc(y++, 4, darkGray,
            "${lead.name} doesn't come back for several days...");
      }
    } else {
      mvaddstrc(y++, 4, lightGray,
          "${lead.name} returns to the safehouse after a few hours.");
    }
  } else {
    mvaddstrx(y++, 0, "&w${lead.name} &mdoesn't really &Kfeel anything...");
  }
  await getKey();
  if (!lead.alive) {
    await dispersalCheck();
  }
  return y;
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
