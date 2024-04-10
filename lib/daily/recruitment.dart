import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'recruitment.g.dart';

@JsonSerializable()
class RecruitmentSession {
  RecruitmentSession(this.recruit, [Creature? recruiter]) {
    if (recruiter != null) {
      this.recruiter = recruiter;
    }
    if (lcsRandom(100) < publicOpinion[View.lcsKnown]!) {
      double bonus = politics.publicMood();
      double rollSize = 100 - bonus;
      if (recruit.align != Alignment.liberal) {
        rollSize = bonus;
        bonus = 0;
      }
      if (100 - (lcsRandom(rollSize.round()) + bonus) <
          publicOpinion[View.lcsLiked]!) {
        rawEagerness = 3;
      } else {
        rawEagerness = 0;
      }
    } else {
      rawEagerness = 2;
    }
  }
  factory RecruitmentSession.fromJson(Map<String, dynamic> json) =>
      _$RecruitmentSessionFromJson(json);
  Map<String, dynamic> toJson() => _$RecruitmentSessionToJson(this);

  Creature recruit;
  int? _recruiterId;
  @JsonKey(name: "recruiter")
  int get recruiterId => _recruiterId ?? recruiter.id;
  set recruiterId(int id) => _recruiterId = id;
  @JsonKey(includeToJson: false, includeFromJson: false)
  late Creature recruiter;

  int rawEagerness = 0;
  @JsonKey(includeToJson: false, includeFromJson: false)
  int get eagerness {
    if (recruit.align == Alignment.liberal) return rawEagerness;
    if (recruit.align == Alignment.moderate) return rawEagerness - 2;
    if (recruit.align == Alignment.conservative) return rawEagerness - 4;
    return rawEagerness;
  }

  void addEagerness(int amount) => rawEagerness += amount;
}

List<String> _issueEventStrings = [
  "a documentary on the struggle for trans rights",
  "a research paper on abuses of the death penalty",
  "an economic paper on the flaws of trickle-down",
  "a video tour of the Chernobyl dead zone",
  "a documentary about factory farming",
  "a hand-recorded video of police brutality",
  "a government inquiry into military interrogations",
  "a documentary on privacy rights",
  "a collection of banned books",
  "a video about genetic engineering accidents",
  "a Liberal policy paper inquiring into judicial decisions",
  "a book profiling school shootings",
  "a hand-recorded video of unregulated sweatshops",
  "call for stricter environmental regulations",
  "are disgusted by corporate malfeasance",
  "a Liberal think-tank survey of top CEO salaries",
  "a documentary about modern feminism",
  "a documentary on the civil rights struggle",
  "a collection of studies on the health effects of marijuana",
  "a reality TV episode on the lives of immigrants",
  "a book on the history of military atrocities",
  "a documentary on the prisoners' suffering",
  "a leaked government paper on environmental conditions",
  "a documentary on life under corporate culture"
];

Future<void> meetWithPotentialRecruits() async {
  for (int i = pool.length - 1; i >= 0; i--) {
    pool[i].meetings = 0;
  }
  if (!disbanding) {
    for (int r = recruitmentSessions.length - 1; r >= 0; r--) {
      RecruitmentSession session = recruitmentSessions[r];
      Creature p = session.recruiter;
      // Stand up recruits if 1) recruiter does not exist,
      // 2) recruiter was not able to return to a safehouse today,
      // or 3) recruiter is dead.
      if (p.site?.controller == SiteController.lcs &&
          p.alive &&
          p.location?.city == recruitmentSessions[r].recruit.location?.city) {
        //MEET WITH RECRUIT
        //TERMINATE NULL RECRUIT MEETINGS
        if (p.site?.siege.underSiege == true) {
          recruitmentSessions.remove(session);
          continue;
        }
        //DO MEETING
        else {
          if (await completeRecruitMeeting(recruitmentSessions[r], p)) {
            recruitmentSessions.remove(session);
            continue;
          }
        }
      } else {
        recruitmentSessions.remove(session);
        continue;
      }
    }
  }
}

/* daily - recruit - recruit meeting */
Future<bool> completeRecruitMeeting(RecruitmentSession r, Creature p) async {
  erase();
  setColor(white);
  move(0, 0);
  if (p.meetings++ > 5 && lcsRandom(p.meetings - 5) > 0) {
    addstr(p.name);
    addstr(" accidentally missed the meeting with ");
    addstr(r.recruit.name);
    move(1, 0);
    addstr("due to multiple booking of recruitment sessions.");

    move(3, 0);
    addstr("Get it together, ");
    addstr(p.name);
    addstr("!");

    await getKey();

    return true;
  }
  addstr("Meeting with ");
  addstr(r.recruit.name);
  addstr(", ");
  addstr(r.recruit.type.name);
  addstr(", ");
  addstr(r.recruit.location!.name);

  setColor(lightGray);
  printFunds();

  printCreatureInfo(r.recruit, showCarPrefs: ShowCarPrefs.onFoot);
  makeDelimiter();

  move(10, 0);
  addstr(r.recruit.name);
  switch (r.eagerness) {
    case 1:
      addstr(" will take a lot of persuading.");
    case 2:
      addstr(" is interested in learning more.");
    case 3:
      addstr(" feels something needs to be done.");
    default:
      if (r.eagerness >= 4) {
        addstr(" is ready to fight for the Liberal Cause.");
      } else {
        addstr(" kind of regrets agreeing to this.");
      }
  }
  move(11, 0);
  addstr("How should ");
  addstr(p.name);
  addstr(" approach the situation?");

  move(13, 0);
  if (ledger.funds < 50) setColor(darkGray);
  addstr("A - Spend \$50 on props and a book for them to keep afterward.");
  setColor(lightGray);
  move(14, 0);
  addstr("B - Just casually chat with them and discuss politics.");

  move(15, 0);
  if (p.subordinatesLeft > 0 && r.eagerness >= 4) {
    addstr("C - Offer to let ");
    addstr(r.recruit.name);
    addstr(" join the LCS as a full member.");
  } else if (p.subordinatesLeft <= 0) {
    setColor(darkGray);
    addstr("C - ");
    addstr(p.name);
    addstr(" needs more Juice to recruit.");
    setColor(lightGray);
  } else {
    setColor(darkGray);
    addstr("C - ");
    addstr(r.recruit.name);
    addstr(" isn't ready to join the LCS.");
    setColor(lightGray);
  }

  move(16, 0);
  addstr("D - Break off the meetings.");

  int y = 18;

  while (true) {
    int c = await getKey();

    if (c == Key.c && p.subordinatesLeft >= 0 && r.eagerness >= 4) {
      move(y, 0);
      addstr(p.name);
      addstr(" offers to let ");
      addstr(r.recruit.name);
      addstr(" join the Liberal Crime Squad.");

      await getKey();

      setColor(lightGreen);
      move(y += 2, 0);

      addstr(r.recruit.name);
      addstr(" accepts, and is eager to get started.");

      liberalize(r.recruit);

      await getKey();

      pool.add(r.recruit);

      erase();
      await sleeperizePrompt(r.recruit, p, 6);

      r.recruit.hireId = p.id;

      p.train(Skill.persuasion, 25);
      recruitmentSessions.remove(r);
      stats.recruits++;

      return true;
    }
    if (c == Key.b || (c == Key.a && ledger.funds >= 50)) {
      if (c == Key.a) ledger.subtractFunds(50, Expense.recruitment);

      p.train(Skill.persuasion, 25);
      p.train(Skill.science, r.recruit.skill(Skill.science));
      p.train(Skill.religion, r.recruit.skill(Skill.religion));
      p.train(Skill.law, r.recruit.skill(Skill.law));
      p.train(Skill.business, r.recruit.skill(Skill.business));

      int libPersuasiveness = p.skill(Skill.business) +
          p.skill(Skill.science) +
          p.skill(Skill.religion) +
          p.skill(Skill.law) +
          p.attribute(Attribute.intelligence);

      int recruitReluctance = 5 +
          r.recruit.skill(Skill.business) +
          r.recruit.skill(Skill.science) +
          r.recruit.skill(Skill.religion) +
          r.recruit.skill(Skill.law) +
          r.recruit.attribute(Attribute.wisdom) +
          r.recruit.attribute(Attribute.intelligence);

      if (libPersuasiveness > recruitReluctance) {
        recruitReluctance = 0;
      } else {
        recruitReluctance -= libPersuasiveness;
      }

      int difficulty = recruitReluctance;

      if (c == Key.a) {
        difficulty -= 5;

        mvaddstr(y++, 0, "${p.name} shares ${_issueEventStrings.random}.");

        await getKey();
      } else {
        move(y++, 0);
        addstr(p.name);
        addstr(" explains ");
        addstr(p.gender.hisHer);
        addstr(" views on ");
        addstr(Law.values.random.label);
        addstr(".");

        await getKey();
      }

      difficulty += r.recruit.level - 1;

      if (p.skillCheck(Skill.persuasion, difficulty)) {
        setColor(lightBlue);
        if (r.rawEagerness < 127) r.rawEagerness++;
        move(y++, 0);
        addstr(r.recruit.name);
        addstr(" found ");
        addstr(p.name);
        addstr("'s views to be insightful.");

        move(y++, 0);
        addstr("They'll definitely meet again tomorrow.");
      } else if (p.skillCheck(
          Skill.persuasion, difficulty)) // Second chance to not fail horribly
      {
        if (r.rawEagerness > -128) r.rawEagerness--;
        move(y++, 0);
        addstr(r.recruit.name);
        addstr(" is skeptical about some of ");
        addstr(p.name);
        addstr("'s arguments.");

        move(y++, 0);
        addstr("They'll meet again tomorrow.");
      } else {
        setColor(purple);
        move(y++, 0);
        if (r.recruit.type.talkReceptive &&
            r.recruit.align == Alignment.liberal) {
          addstr(r.recruit.name);
          addstr(" isn't convinced ");
          addstr(p.name);
          addstr(" really understands the problem.");

          move(y++, 0);
          addstr("Maybe ");
          addstr(p.name);
          addstr(" needs more experience.");
        } else {
          addstr(p.name);
          addstr(" comes off as slightly insane.");

          move(y++, 0);
          addstr(
              "This whole thing was a mistake. There won't be another meeting.");
        }

        await getKey();

        return true;
      }

      await getKey();

      return false;
    }
    if (c == Key.d) return true;
  }
}

// Prompt to turn new recruit into a sleeper
Future<void> sleeperizePrompt(
    Creature converted, Creature recruiter, int y) async {
  bool selection = false;
  while (true) {
    move(y, 0);
    setColor(lightGray);
    addstr("In what capacity will ");
    addstr(converted.name);
    addstr(" best serve the Liberal cause?");
    move(y + 2, 0);
    setColor(selection ? lightGray : white);
    addstr(selection ? "   " : "-> ");
    addstr(
        "Come to ${recruiter.location!.getName(short: false, includeCity: true)} as a ");
    setColor(selection ? green : lightGreen);
    addstr("regular member");
    setColor(selection ? lightGray : white);
    addstr(".");
    move(y + 3, 0);
    setColor(selection ? white : lightGray);
    addstr(selection ? "-> " : "   ");
    addstr(
        "Stay at ${converted.workLocation.getName(short: false, includeCity: true)} as a ");
    setColor(selection ? lightBlue : blue);
    addstr("sleeper agent");
    setColor(selection ? white : lightGray);
    addstr(".");

    int c = await getKey();
    if ((isBackKey(c)) && selection) {
      converted.sleeperAgent = true;
      converted.location = converted.workLocation;
      converted.site?.mapped = true;
      converted.site?.hidden = false;
      converted.base = converted.site;
      liberalize(converted);
      if (converted == uniqueCreatures.president) {
        politics.exec[Exec.president] = DeepAlignment.eliteLiberal;
      }
      break;
    } else if ((isBackKey(c)) && !selection) {
      converted.location = recruiter.location;
      converted.base = recruiter.base;
      liberalize(converted);
      if (converted == uniqueCreatures.ceo) uniqueCreatures.newCEO();
      if (converted == uniqueCreatures.president) {
        politics.promoteVP();
      }
      break;
    } else if (isPageUp(c) ||
        c == Key.upArrow ||
        c == Key.leftArrow ||
        isPageDown(c) ||
        c == Key.downArrow ||
        c == Key.rightArrow) {
      selection = !selection;
    }
  }
}
