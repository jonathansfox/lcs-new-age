import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/title_screen/questions.dart';
import 'package:lcs_new_age/title_screen/title_screen.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

// Debug flag to start with the President as a sleeper agent
const bool debugPresidentSleeper = false;

Future<void> setupNewGame() async {
  gameState = GameState();
  bool classicmode = false;
  bool strongccs = false;
  bool nightmarelaws = false;

  void checkBoxOption(int y, bool ticked, String key, String text,
      {bool disabled = false}) {
    addOptionText(y, 0, key, "[${ticked ? "X" : " "}] $key - $text",
        enabledWhen: !disabled);
  }

  erase();
  while (true) {
    mvaddstrc(4, 6, white,
        "New Game of Liberal Crime Squad: Advanced Gameplay Options");
    checkBoxOption(
        7, classicmode, "A", "Classic Mode: No Conservative Crime Squad.");
    checkBoxOption(9, strongccs, "B",
        "We Didn't Start The Fire: The CCS starts active and extremely strong.",
        disabled: classicmode);
    checkBoxOption(11, nightmarelaws, "C",
        "Nightmare Mode: Liberalism is forgotten. Is it too late to fight back?");

    addOptionText(15, 0, "Any Other Key", "Any Other Key - Continue...");

    int c = await getKey();

    if (c == Key.a) {
      classicmode = !classicmode;
      continue;
    }
    if (c == Key.b) {
      strongccs = !strongccs;
      continue;
    }
    if (c == Key.c) {
      nightmarelaws = !nightmarelaws;
      continue;
    }
    break;
  }

  if (nightmarelaws) {
    for (Law l in Law.values) {
      laws[l] = DeepAlignment.archConservative;
    }
    for (View a in View.issues) {
      politics.publicOpinion[a] = lcsRandomDouble(20);
    }
    for (int s = 0; s < senate.length; s++) {
      senate[s] = switch (s) {
        < 55 => DeepAlignment.archConservative,
        < 70 => DeepAlignment.conservative,
        < 80 => DeepAlignment.moderate,
        < 97 => DeepAlignment.liberal,
        _ => DeepAlignment.eliteLiberal,
      };
    }
    for (int h = 0; h < house.length; h++) {
      house[h] = switch (h) {
        < 220 => DeepAlignment.archConservative,
        < 350 => DeepAlignment.conservative,
        < 400 => DeepAlignment.moderate,
        < 425 => DeepAlignment.liberal,
        _ => DeepAlignment.eliteLiberal,
      };
    }
    for (int c = 0; c < court.length; c++) {
      court[c] = switch (c) {
        < 5 => DeepAlignment.archConservative,
        < 7 => DeepAlignment.conservative,
        < 8 => DeepAlignment.moderate,
        < 8 => DeepAlignment.liberal,
        _ => DeepAlignment.eliteLiberal,
      };
      do {
        if (court[c] == DeepAlignment.archConservative) {
          politics.courtName[c] = generateFullName(Gender.whiteMalePatriarch);
        } else {
          politics.courtName[c] = generateFullName();
        }
      } while (politics.courtName[c].firstLast.length > 20);
    }
  }
  if (classicmode) {
    ccsState = CCSStrength.defeated;
  } else if (strongccs) {
    ccsState = CCSStrength.attacks;
  }
}

Future<void> makeCharacter() async {
  Creature founder = Creature.fromId(CreatureTypeIds.politicalActivist);
  founder.align = Alignment.liberal;

  founder.rawAttributes[Attribute.heart] = 8;
  founder.rawAttributes[Attribute.wisdom] = 1;
  founder.rawAttributes[Attribute.intelligence] = 5;
  founder.rawAttributes[Attribute.agility] = 5;
  founder.rawAttributes[Attribute.strength] = 5;
  founder.rawAttributes[Attribute.charisma] = 5;
  for (Skill s in Skill.values) {
    founder.rawSkill[s] = 0;
  }

  if (megaFounderCheat) {
    founder.rawAttributes.forEach((a, i) => founder.rawAttributes[a] = 30 + i);
    founder.rawSkill.forEach((s, i) => founder.rawSkill[s] = 30 + i);
  }

  bool letMeChoose = true;
  City startingCity = cities.first;
  Map<Gender, String> first = {
    Gender.male: firstName(Gender.male),
    Gender.female: firstName(Gender.female),
    Gender.nonbinary: firstName(Gender.nonbinary, false),
  };
  String last = lastName();
  Gender sex = oneIn(2) ? Gender.male : Gender.female;
  const List<Gender> sexOptions = [
    Gender.male,
    Gender.female,
    Gender.nonbinary
  ];
  founder.giveClothingType("CLOTHING_CLOTHES");
  String sexDesc() {
    return switch (sex) {
      Gender.male => "Male",
      Gender.female => "Female",
      _ => "Intersex",
    };
  }

  while (true) {
    erase();
    mvaddstrc(4, 6, white, "The Founder of the Liberal Crime Squad");

    mvaddstrc(7, 2, lightGray, "Given Name: ");
    addstrc(white, first[sex]!);
    mvaddstrx(7, 34, "&m(Press &BA&m to have your parents reconsider)");

    mvaddstrc(9, 2, lightGray, "Family Name: ");
    addstrc(white, last);
    mvaddstrx(9, 34, "&m(Press &BB&m to be born to a different family)");

    mvaddstrc(11, 2, lightGray, "Sex at Birth: ");
    addstrc(white, sexDesc());
    mvaddstrx(11, 34, "&m(Press &BC&m to have the doctor check again)");

    mvaddstrc(13, 2, lightGray, "Tragic Origin: ");
    if (letMeChoose) {
      addstrc(lightGreen, "Let Me Choose");
    } else {
      addstrc(red, "Let Fate Decide");
    }
    mvaddstrx(13, 34, "&m(Press &BD&m to toggle choice or fate)");

    mvaddstrc(15, 2, lightGray, "City: ");
    addstrc(white, startingCity.getName(includeCity: true));
    mvaddstrx(15, 34, "&m(Press &BE&m to move at a young age)");

    addOptionText(
        19, 2, "Any Other Key", "Press any other key when ready to begin...",
        baseColorKey: ColorKey.midGray);

    int c = await getKey();
    if (c == Key.a) {
      first[sex] = firstName(sex, false);
    } else if (c == Key.b) {
      last = lastName();
    } else if (c == Key.c) {
      sex = sexOptions[(sexOptions.indexOf(sex) + 1) % sexOptions.length];
    } else if (c == Key.d) {
      letMeChoose = !letMeChoose;
    } else if (c == Key.e) {
      startingCity = cities[(cities.indexOf(startingCity) + 1) % cities.length];
    } else {
      break;
    }
  }

  ledger.forceSetFunds(7);

  founder.gender = founder.genderAssignedAtBirth = sex;
  founder.properName = "${first[sex]!} $last";
  founder.name = founder.properName;
  squads.add(Squad()..name = "The Liberal Crime Squad");
  founder.squad = squads.first;
  activeSquad = squads.first;
  pool.add(founder);
  founder.location = sites.firstWhere(
      (l) => l.city == startingCity && l.controller == SiteController.lcs);
  founder.base = founder.site;

  await characterCreationQuestions(founder, letMeChoose);

  await aNewConservativeEra();

  erase();
  mvaddstrc(0, 0, white, "What is your name to the people?");
  founder.name = await enterName(2, 0, founder.properName, prefill: true);
}

Future<void> aNewConservativeEra() async {
  FullName oldPresident = generateFullName(Gender.whiteMalePatriarch);

  erase();
  mvaddstrc(2, 2, white, "A NEW CONSERVATIVE ERA");

  mvaddstrc(4, 2, lightGray, "The Year is $year.");

  mvaddstr(6, 2,
      "Following a series of violent protests from the far right, Conservative");
  mvaddstr(7, 2,
      "President ${oldPresident.firstLast} has resigned in disgrace.  His hardcore");
  mvaddstr(8, 2,
      "Arch-Conservative Vice President, ${execName[Exec.president]!.firstLast}, a close ally of the");
  mvaddstr(9, 2,
      "rioters, has been sworn in as the new President of the United States.");

  mvaddstr(11, 2,
      "With Conservatives having swept into power in the recent midterm elections,");
  mvaddstr(12, 2,
      "and a Conservative majority in the Supreme Court of the United States,");
  mvaddstr(13, 2,
      "commentators are hailing it as the beginning of a new Conservative era.");

  move(15, 2);
  setColor(red);
  addstr(
      "President ${execName[Exec.president]!.firstLast} has asked the new Congress to move quickly");
  mvaddstr(16, 2, "to rubber stamp his radical Arch-Conservative agenda. ");
  setColor(lightGray);
  addstr("The left seems");
  mvaddstr(17, 2,
      "powerless to stop this imminent trampling of Liberal Sanity and Justice.");

  mvaddstr(19, 2, "In this dark time, the Liberal Crime Squad is born...");

  await getKey();

  // If debug flag is enabled, make the President a sleeper agent
  if (debugPresidentSleeper) {
    uniqueCreatures.president.sleeperAgent = true;
    uniqueCreatures.president.hireId = pool[0].id;
    liberalize(uniqueCreatures.president);
    uniqueCreatures.president.juice = 1000;
    pool.add(uniqueCreatures.president);
    exec[Exec.president] = DeepAlignment.eliteLiberal;
  }
}
