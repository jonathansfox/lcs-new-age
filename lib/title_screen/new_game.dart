import 'package:flutter/material.dart' show Color;
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/title_screen/questions.dart';
import 'package:lcs_new_age/title_screen/title_screen.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/debug_flags.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> setupNewGame() async {
  gameState = GameState();

  int gameWorld = 0;
  int ccsOption = 1;
  int initiative = 0;

  final List<(String, String, Color)> gameWorldChoices = [
    (
      "The Times They Are a-Changin'",
      "The country is beginning to slide into far-right authoritarianism.",
      yellow,
    ),
    (
      "The End of the World as We Know It",
      "Liberalism is already forgotten.  Is it too late to fight back?",
      red,
    ),
  ];
  final List<(String, String, Color)> ccsChoices = [
    ("Clear Blue Skies", "The CCS will never appear.", lightGreen),
    (
      "Bad Blood",
      "A rival CCS will form eventually and grow stronger over time.",
      yellow,
    ),
    (
      "We Didn't Start The Fire",
      "The CCS starts active and extremely strong.",
      red,
    ),
  ];
  final List<(String, String, Color)> initiativeChoices = [
    (
      "Power to the People",
      "Team initiative: Your squad attacks first in each round.",
      yellow,
    ),
    (
      "Welcome to the Jungle",
      "Zipper initiative: Teams take turns attacking one at a time.",
      red,
    ),
  ];

  void cyclingOption(
    int y,
    String key,
    String category,
    List<(String, String, Color)> choices,
    int index,
  ) {
    var (name, description, color) = choices[index];
    var colorKey = ColorKey.fromColor(color);
    addOptionText(y, 2, key, "$key - $category:");
    mvaddstrx(y, 35, "&$colorKey$name");
    setColor(midGray);
    mvaddstr(y + 1, 6, description);
  }

  while (true) {
    erase();
    mvaddstrc(4, 6, white, "New Game of Liberal Crime Squad: Gameplay Options");
    cyclingOption(
      7,
      "A",
      "Starting Political Climate",
      gameWorldChoices,
      gameWorld,
    );
    cyclingOption(10, "B", "Conservative Crime Squad", ccsChoices, ccsOption);
    cyclingOption(13, "C", "Combat Difficulty", initiativeChoices, initiative);

    mvaddstrx(
      16,
      2,
      "Option difficulty ratings: &GEasier &w- &YStandard &w- &RHarder",
    );

    addOptionText(18, 2, "Any Other Key", "Any Other Key - Continue...");

    int c = await getKey();

    if (c == Key.a) {
      gameWorld = (gameWorld + 1) % gameWorldChoices.length;
      continue;
    }
    if (c == Key.b) {
      ccsOption = (ccsOption + 1) % ccsChoices.length;
      continue;
    }
    if (c == Key.c) {
      initiative = (initiative + 1) % initiativeChoices.length;
      continue;
    }
    break;
  }

  bool nightmarelaws = gameWorld == 1;
  gameState.alternatingInitiative = initiative == 1;

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
  switch (ccsOption) {
    case 0: // Clear Blue Skies: the CCS never appears.
      ccsState = CCSStrength.defeated;
    case 2: // We Didn't Start The Fire: start active and at full strength.
      ccsState = CCSStrength.sieges;
      gameState.ccsAggressive = true;
    default: // A Hard Rain's A-Gonna Fall: the CCS forms over time, as normal.
      break;
  }
  if (debugEliteLiberalPublicOpinion) {
    for (int v = 0; v < View.values.length; v++) {
      politics.publicOpinion[View.values[v]] = 100;
    }
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
    Gender.nonbinary,
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
    addOptionText(
      7,
      34,
      "A",
      "(A to have your parents reconsider)",
      baseColorKey: ColorKey.midGray,
    );

    mvaddstrc(9, 2, lightGray, "Family Name: ");
    addstrc(white, last);
    addOptionText(
      9,
      34,
      "B",
      "(B to be born to a different family)",
      baseColorKey: ColorKey.midGray,
    );

    mvaddstrc(11, 2, lightGray, "Sex at Birth: ");
    addstrc(white, sexDesc());
    addOptionText(
      11,
      34,
      "C",
      "(C to have the doctor check again)",
      baseColorKey: ColorKey.midGray,
    );

    mvaddstrc(13, 2, lightGray, "Tragic Origin: ");
    if (letMeChoose) {
      addstrc(lightGreen, "Let Me Choose");
    } else {
      addstrc(red, "Let Fate Decide");
    }
    addOptionText(
      13,
      34,
      "D",
      "(D to toggle choice or fate)",
      baseColorKey: ColorKey.midGray,
    );

    mvaddstrc(15, 2, lightGray, "City: ");
    addstrc(white, startingCity.getName(includeCity: true));
    addOptionText(
      15,
      34,
      "E",
      "(E to move at a young age)",
      baseColorKey: ColorKey.midGray,
    );

    addOptionText(
      19,
      2,
      "Any Other Key",
      "Press any other key when ready to begin...",
      baseColorKey: ColorKey.midGray,
    );

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
  if (debugAMilli) ledger.forceSetFunds(1000000);
  if (debugFounderMedicalDebt) founder.medicalBills = 50000;

  founder.gender = founder.genderAssignedAtBirth = sex;
  founder.properName = "${first[sex]!} $last";
  founder.name = founder.properName;
  squads.add(Squad()..name = "The Liberal Crime Squad");
  founder.squad = squads.first;
  activeSquad = squads.first;
  pool.add(founder);
  founder.location = sites.firstWhere(
    (l) => l.city == startingCity && l.controller == SiteController.lcs,
  );
  founder.base = founder.site;

  if (debugSiege) {
    founder.base = findSiteInSameCity(
      founder.location!.city,
      SiteType.warehouse,
    );
    founder.base?.siege.timeUntilCops = 0;
    founder.base?.compound.fortified = true;
    founder.base?.compound.rations = 1000;
    founder.base?.compound.aaGun = true;
    founder.base?.compound.bollards = true;
    founder.base?.compound.boobyTraps = true;
    founder.base?.compound.cameras = true;
    founder.base?.compound.generator = true;
    founder.base?.compound.diesel = 1000;
    founder.base?.compound.hackerDen = true;
    founder.base?.compound.videoRoom = true;
    founder.base?.heat = 9000;
    founder.juice = 1000;
    founder.rawSkill[Skill.firearms] = founder.skillCap(Skill.firearms);
    founder.rawSkill[Skill.dodge] = founder.skillCap(Skill.dodge);
    founder.giveWeaponAndAmmo("WEAPON_M7", 9);

    for (int i = 0; i < 10; i++) {
      Creature c = Creature.fromId(CreatureTypeIds.agent);
      liberalize(c);
      c.nameCreature();
      c.juice = 1000;
      c.rawSkill[Skill.firearms] = c.skillCap(Skill.firearms);
      c.rawSkill[Skill.dodge] = c.skillCap(Skill.dodge);
      c.hireId = founder.id;
      c.base = founder.base;
      c.location = founder.location;
      c.giveWeaponAndAmmo("WEAPON_M7", 9);
      pool.add(c);
      if (founder.squad!.members.length < 6) {
        c.squad = founder.squad;
      }
    }
  }

  await characterCreationQuestions(founder, letMeChoose);

  if (debugMartialArtsMaster) {
    founder.rawAttributes[Attribute.heart] = 15;
    founder.rawAttributes[Attribute.agility] = 15;
    founder.rawAttributes[Attribute.strength] = 15;
    founder.juice = 1000;
    founder.rawSkill[Skill.martialArts] = founder.skillCap(Skill.martialArts);
    founder.rawSkill[Skill.dodge] = founder.skillCap(Skill.dodge);
  }

  if (debugBadlyInjured) {
    for (var part in founder.body.parts) {
      part.cut = true;
      part.bleeding = 10;
      part.torn = true;
      part.relativeHealth = 0.5;
      part.shot = true;
      part.burned = true;
      part.bruised = true;
    }
    if (founder.body is HumanoidBody) {
      (founder.body as HumanoidBody).teeth = 5;
      (founder.body as HumanoidBody).ribs = 5;
      (founder.body as HumanoidBody).neck = InjuryState.untreated;
      (founder.body as HumanoidBody).upperSpine = InjuryState.untreated;
      (founder.body as HumanoidBody).lowerSpine = InjuryState.untreated;
      (founder.body as HumanoidBody).missingRightEye = true;
      (founder.body as HumanoidBody).missingLeftEye = true;
      (founder.body as HumanoidBody).missingNose = true;
      (founder.body as HumanoidBody).missingTongue = true;
      (founder.body as HumanoidBody).puncturedRightLung = true;
      (founder.body as HumanoidBody).puncturedLeftLung = true;
      (founder.body as HumanoidBody).puncturedHeart = true;
      (founder.body as HumanoidBody).puncturedLiver = true;
      (founder.body as HumanoidBody).puncturedStomach = true;
      (founder.body as HumanoidBody).puncturedRightKidney = true;
      (founder.body as HumanoidBody).puncturedLeftKidney = true;
      (founder.body as HumanoidBody).puncturedSpleen = true;
    }
    founder.blood = 1;
  }

  if (debugPartyRescue) {
    for (int i = 0; i < 20; i++) {
      Creature c = Creature.fromId(CreatureTypeIds.collegeStudent);
      liberalize(c);
      c.nameCreature();
      c.location = findSiteInSameCity(
        founder.location?.city,
        SiteType.policeStation,
      );
      pool.add(c);
    }

    founder.rawAttributes[Attribute.agility] = 15;
    founder.rawAttributes[Attribute.intelligence] = 15;
    founder.juice = 1000;
    founder.rawSkill[Skill.security] = founder.skillCap(Skill.security);
    founder.rawSkill[Skill.stealth] = founder.skillCap(Skill.stealth);
  }

  if (debugAllItems) {
    founder.base?.loot.addAll(itemTypes.values.map((e) => Item(e.idName)));
  }

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

  mvaddstr(
    6,
    2,
    "Following a series of violent protests from the far right, Conservative",
  );
  mvaddstr(
    7,
    2,
    "President ${oldPresident.firstLast} has resigned in disgrace.  His hardcore",
  );
  mvaddstr(
    8,
    2,
    "Arch-Conservative Vice President, ${execName[Exec.president]!.firstLast}, a close ally of the",
  );
  mvaddstr(
    9,
    2,
    "rioters, has been sworn in as the new President of the United States.",
  );

  mvaddstr(
    11,
    2,
    "With Conservatives having swept into power in the recent midterm elections,",
  );
  mvaddstr(
    12,
    2,
    "and a Conservative majority in the Supreme Court of the United States,",
  );
  mvaddstr(
    13,
    2,
    "commentators are hailing it as the beginning of a new Conservative era.",
  );

  move(15, 2);
  setColor(red);
  addstr(
    "President ${execName[Exec.president]!.firstLast} has asked the new Congress to move quickly",
  );
  mvaddstr(16, 2, "to rubber stamp his radical Arch-Conservative agenda. ");
  setColor(lightGray);
  addstr("The left seems");
  mvaddstr(
    17,
    2,
    "powerless to stop this imminent trampling of Liberal Sanity and Justice.",
  );

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
