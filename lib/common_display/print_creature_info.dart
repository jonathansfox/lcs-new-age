import 'package:format/format.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

void printCreatureInfo(
  Creature cr, {
  ShowCarPrefs? showCarPrefs,
  int knowledge = 255,
}) {
  showCarPrefs ??= mode == GameMode.base
      ? ShowCarPrefs.showPreferences
      : ShowCarPrefs.showActualCar;
  makeDelimiter(y: 1);
  mvaddstrc(1, 2, lightGray, "${cr.name}, ${cr.title}");
  if (cr.isHoldingBody) {
    addstr(", holding ${cr.prisoner?.type.hostageName ?? cr.prisoner?.name}");
  }
  printAttributesAsKnowledgePermits(cr, knowledge);

  mvaddstr(5, 0, "Transp: ");
  printTransportation(cr, showCarPrefs);

  setWeaponColor(cr);
  mvaddstr(6, 0, "Weapon: ");
  printWeapon(cr);

  setColorForArmor(cr);
  mvaddstr(7, 0, "Clothes: ");
  addstr(cr.armor.shortName);

  printTopSkills(2, 31, cr, 5, knowledge: knowledge);

  printHealthStat(1, 49, cr);
  if (cr.body.parts.any((p) => p.wounded)) {
    printWounds(cr);
    setColor(lightGray);
  }
}

void printAttributesAsKnowledgePermits(Creature creature, int knowledge) {
  mvaddstr(2, 0, "Str: ${creature.attribute(Attribute.strength)}");
  mvaddstr(3, 0, "Agi: ${creature.attribute(Attribute.agility)}");
  mvaddstr(4, 0, "Hrt: ${creature.attribute(Attribute.heart)}");
  mvaddstr(2, 11, "Int: ${creature.attribute(Attribute.intelligence)}");
  mvaddstr(3, 11, "Cha: ${creature.attribute(Attribute.charisma)}");
  mvaddstr(4, 11, "Wis: ${creature.attribute(Attribute.wisdom)}");
}

enum ShowCarPrefs {
  onFoot, // "-1" in the old code
  showActualCar, // "0"
  showPreferences, // "1"
}

void printTransportation(Creature cr, ShowCarPrefs showCarPrefs) {
  Vehicle? v;
  if (showCarPrefs == ShowCarPrefs.showActualCar) v = cr.car;
  if (showCarPrefs == ShowCarPrefs.showPreferences) v = cr.preferredCar;
  if (v != null) {
    addstr(v.shortName);
    if (showCarPrefs == ShowCarPrefs.showPreferences
        ? cr.preferredDriver
        : cr.isDriver) {
      addstr("-D");
    }
  } else {
    int legok = cr.body.legs.where((l) => !l.missing).length;
    if (cr.hasWheelchair) {
      addstr("Wheelchair");
    } else {
      addstr(legok >= 1 ? "On Foot" : "On \"Foot\"");
    }
  }
}

void setWeaponColor(Creature cr) {
  if (mode != GameMode.site) {
    setColor(lightGray);
  } else {
    switch (weaponCheck(cr)) {
      case WeaponCheckResult.ok:
        setColor(lightGreen);
      case WeaponCheckResult.inCharacter:
        setColor(yellow);
      case WeaponCheckResult.suspicious:
        setColor(red);
    }
  }
}

void printWeapon(Creature cr) {
  addstr(cr.weapon.type.shortName);
  if (cr.weapon.type.usesAmmo) {
    if (cr.weapon.ammo > 0) {
      addstr(" (${cr.weapon.ammo})");
    } else {
      setColor(darkGray);
      if ((cr.spareAmmo?.stackSize ?? 0) > 0) {
        addstr(" (${cr.spareAmmo!.stackSize})");
      } else {
        addstr(" (XX)");
      }
    }
  } else if (cr.weapon.type.thrown) {
    addstr(" (${cr.weapon.stackSize})");
  }
}

void printTopSkills(int y, int x, Creature cr, int numberToPrint,
    {int knowledge = 255}) {
  // Get skills sorted by level and experience
  List<MapEntry<Skill, int>> skills = List.generate(
    Skill.values.length,
    (i) => MapEntry<Skill, int>(
      Skill.values[i],
      (cr.rawSkill[Skill.values[i]] ?? 0) * 10000 +
          (cr.rawSkillXP[Skill.values[i]] ?? 0),
    ),
  );
  skills.sort((a, b) => b.value.compareTo(a.value));
  skills = skills.where((s) => s.value > 0).take(numberToPrint).toList();
  if (skills.isNotEmpty) {
    mvaddstrc(y, x, lightGray, "Top Skills:");
  }
  for (int i = 0; i < skills.length; i++) {
    Skill s = skills[i].key;
    int level = cr.skill(s);
    int levelXP = (cr.skillXP(s) / skillXpNeeded(level) * 100).floor();
    if (cr.skillCap(s) > 0 && cr.rawSkill[s]! >= cr.skillCap(s)) {
      setColor(lightBlue);
    } else if (cr.rawSkillXP[s]! > 100 + (10 * cr.rawSkill[s]!) &&
        cr.rawSkill[s]! < cr.skillCap(s)) {
      setColor(white);
    } else if (cr.rawSkill[s]! < 1) {
      if (cr.rawSkillXP[s]! > 0) {
        setColor(darkGray);
      }
      setColor(darkGray);
    } else {
      setColor(lightGray);
    }
    move(y + i + 1, x);
    if (knowledge > i) {
      addstr(s.displayName);
    } else {
      addstr("???????");
    }
    addstr(": ");
    if (knowledge > i + 2) {
      addstr("$level.$levelXP");
    } else {
      addstr("?");
    }
  }
}

void printWounds(Creature cr, {int y = 2, int x = 49}) {
  for (int i = 0; i < cr.body.parts.length; i++) {
    BodyPart p = cr.body.parts[i];
    setColor(p.bleeding ? red : lightGray);
    mvaddstr(y + i, x, "${p.name}: ");
    move(y + i, x + 12);
    if (p.nastyOff) {
      addstr("Ripped off");
    } else if (p.cleanOff) {
      addstr("Clean sever");
    }
    if (!p.wounded) {
      setColor(lightGreen);
      addstr(cr.align == Alignment.liberal ? "Liberal" : "Healthy");
    } else {
      List<String> injuries = [];
      if (p.shot) injuries.add("Sht");
      if (p.bruised) injuries.add("Brs");
      if (p.cut) injuries.add("Cut");
      if (p.torn) injuries.add("Trn");
      if (p.burned) injuries.add("Brn");
      addstr(injuries.join(","));
    }
  }
}

void printCreatureAgeAndGender(Creature person) {
  {
    String age;
    if (person.body is! HumanoidBody) {
      // Animals and machines; +-2
      age = "${person.age + person.birthDate.day % 5 - 2}?";
    } else if (person.age < 20) {
      // Children and teens; +-1
      age = "${person.age + person.birthDate.day % 3 - 1}?";
    } else {
      // Adults; just assess a decade
      age = "${person.age - (person.age % 10)}s";
    }

    // Assess their gender Liberally
    addstr(" ($age, ${capitalize(person.gender.name)})");
  }
}

/* full character sheet with surrounding interface */
Future<void> fullCreatureInfoScreen(Creature cr) async {
  if (activeSquad == null) return;

  const int pagenum = 3;
  int page = 0;

  while (true) {
    erase();

    setColor(lightGreen);
    move(0, 0);
    addstr("Profile of a Liberal");

    if (page == 0) printFullCreatureStats(cr);
    if (page == 1) printFullCreatureSkills(cr);
    if (page == 2) printFullCreatureCrimes(cr);

    move(23, 0);
    addstr("N - Change Name           G - Change Gender");
    if ((activeSquad?.members.length ?? 0) > 1) {
      addstr("    LEFT/RIGHT - Other Liberals");
    }
    move(24, 0);
    addstr("Press any other key to continue the Struggle");
    addstr("    UP/DOWN  - More Info");

    int c = await getKey();

    if ((activeSquad?.members.length ?? 0) > 1 &&
        ((c == Key.leftArrow) || (c == Key.rightArrow))) {
      int sx = (c == Key.leftArrow) ? -1 : 1;
      int index = squad.indexOf(cr) + sx;
      cr = squad[index % squad.length];
    } else if (c == Key.downArrow) {
      page++;
      page %= pagenum;
    } else if (c == Key.upArrow) {
      page--;
      if (page < 0) page = pagenum - 1;
      page %= pagenum;
    } else if (c == Key.n) {
      setColor(lightGray);
      mvaddstr(23, 0,
          "What is the new code name?                                                      "); // 80 characters
      mvaddstr(24, 0,
          "                                                                                "); // 80 spaces

      cr.name = await enterName(24, 0, cr.name);
    } else if (c == Key.g) {
      List<Gender> genders = [Gender.male, Gender.female, Gender.nonbinary];
      int index;
      if (genders.contains(cr.gender)) {
        index = genders.indexOf(cr.gender);
      } else {
        index = 0;
      }
      cr.gender = genders[(index + 1) % genders.length];
    } else {
      break;
    }
  }
}

/* Full screen character sheet, skills only edition */
void printFullCreatureSkills(Creature cr) {
  // Add name
  printFullCreatureNameBlock(cr);

  // Add all skills
  for (int s = 0; s < Skill.values.length; s++) {
    Skill skill = Skill.values[s];
    if (s % 3 == 0 && s < 9) {
      setColor(lightGray);
      move(4, 27 * (s ~/ 3));
      addstr("SKILL");
      move(4, 15 + 27 * (s ~/ 3));
      addstr("NOW   MAX");
    }

    highlightColorForSkill(cr, skill);

    move(5 + s ~/ 3, 27 * (s % 3));
    addstr(skill.displayName);
    addstr(": ");
    printSkillValue(cr, skill, 5 + s ~/ 3, 14 + 27 * (s % 3));
  }
  setColor(lightGray);
}

void printSkillValue(Creature cr, Skill skill, int y, int x,
    {bool emphasizePotential = false}) {
  move(y, x);
  addstr("{:2d}.".format(cr.skill(skill)));
  int xpPercent =
      ((cr.skillXP(skill) / skillXpNeeded(cr.skill(skill))) * 100).round();
  if (xpPercent < 100) {
    if (xpPercent != 0) {
      if (xpPercent < 10) {
        addstr("0");
      }
      addstr("$xpPercent");
    } else {
      addstr("00");
    }
  } else {
    addstr("99+");
  }

  if (emphasizePotential) {
    if (cr.skillCap(skill) > cr.skill(skill)) {
      setColor(white);
    }
  } else {
    if (cr.skillCap(skill) == 0 || cr.skill(skill) < cr.skillCap(skill)) {
      setColor(darkGray);
    }
  }
  move(y, x + 6);
  addstr("{:2d}.00".format(cr.skillCap(skill)));
}

/* full screen character sheet */
void printFullCreatureStats(Creature cr,
    {ShowCarPrefs showCarPrefs = ShowCarPrefs.showPreferences}) {
  setColor(lightGray);

  // Add name
  printFullCreatureNameBlock(cr);
  // Add birthdate
  mvaddstr(3, 0, "Born ${getMonth(cr.birthDate.month)} ${cr.birthDate.day}, ");
  addstr("${cr.birthDate.year} (Age ${cr.age}, ");
  if (cr.gender == Gender.male) {
    addstr("Male");
  } else if (cr.gender == Gender.female) {
    addstr("Female");
  } else {
    addstr("Nonbinary");
  }
  addstr(")");

  move(3, 46);
  printWantedFor(cr);
  setColor(lightGray);

  // Add juice
  move(9, 16);
  addstr("Juice: ${cr.juice}");
  if (cr.juice < 1000) {
    move(10, 16);
    addstr("Next:  ");
    if (cr.juice < 0) {
      addstr("0");
    } else if (cr.juice < 10) {
      addstr("10");
    } else if (cr.juice < 50) {
      addstr("50");
    } else if (cr.juice < 100) {
      addstr("100");
    } else if (cr.juice < 200) {
      addstr("200");
    } else if (cr.juice < 500) {
      addstr("500");
    } else {
      addstr("1000");
    }
  }
  // Add attributes
  move(5, 0);
  addstr("Heart: ${cr.attribute(Attribute.heart)}");
  move(6, 0);
  addstr("Intelligence: ${cr.attribute(Attribute.intelligence)}");
  move(7, 0);
  addstr("Wisdom: ${cr.attribute(Attribute.wisdom)}");
  move(8, 0);
  addstr("Agility: ${cr.attribute(Attribute.agility)}");
  move(9, 0);
  addstr("Strength: ${cr.attribute(Attribute.strength)}");
  move(10, 0);
  addstr("Charisma: ${cr.attribute(Attribute.charisma)}");

  // Add highest skills
  Map<Skill, bool> used = {for (Skill s in Skill.values) s: false};

  int skillsMax = 16;
  bool printed = true;

  move(5, 28);
  addstr("SKILL");
  move(5, 43);
  addstr("NOW   MAX");
  for (int skillsShown = 0; skillsShown < skillsMax && printed; skillsShown++) {
    printed = false;

    int max = 0;
    int maxs = -1;
    for (int s = 0; s < Skill.values.length; s++) {
      Skill skill = Skill.values[s];
      if ((cr.skill(skill) * 10000 + cr.skillXP(skill)) > max &&
          !used[skill]!) {
        max = cr.skill(skill) * 10000 + cr.skill(skill);
        maxs = s;
      }
    }

    if (maxs != -1) {
      Skill skill = Skill.values[maxs];
      used[skill] = true;
      printed = true;

      highlightColorForSkill(cr, skill);

      move(6 + skillsShown, 28);
      addstr(skill.displayName);
      addstr(": ");
      move(6 + skillsShown, 42);
      addstr("{:2d}.".format(cr.skill(skill)));
      if (cr.skillXP(skill) < 100 + (10 * cr.skill(skill))) {
        addstr("{:02d}".format(
            (cr.skillXP(skill) * 100) ~/ (100 + (10 * cr.skill(skill)))));
      } else {
        addstr("99+");
      }

      if (cr.skillCap(skill) == 0 || cr.skill(skill) < cr.skillCap(skill)) {
        setColor(darkGray);
      }
      move(6 + skillsShown, 48);
      addstr("{:2d}.00".format(cr.skillCap(skill)));
    }
  }

  setColor(lightGray);

  // Add weapon
  move(13, 0);
  addstr("Weapon: ");
  printWeapon(cr);

  // Add clothing
  move(14, 0);
  addstr("Clothes: ");
  addstr(cr.armor.equipTitle(full: true));

  // Add vehicle
  move(15, 0);
  addstr("Car: ");
  Vehicle? v;
  if (showCarPrefs == ShowCarPrefs.showPreferences) {
    v = cr.preferredCar;
  } else {
    v = cr.car;
  }
  if (v != null && showCarPrefs != ShowCarPrefs.onFoot) {
    addstr(v.fullName());
    bool d;
    if (showCarPrefs == ShowCarPrefs.showPreferences) {
      d = cr.preferredDriver;
    } else {
      d = cr.isDriver;
    }
    if (d) addstr("-D");
  } else {
    int legok = cr.body.legok;
    if (cr.hasWheelchair) {
      addstr("Wheelchair");
    } else if (legok >= 1) {
      addstr("On Foot");
    } else {
      addstr("On \"Foot\"");
    }
  }

  // Add recruit stats
  if (!cr.brainwashed) {
    move(18, 0);
    addstr((cr.maxSubordinates - cr.subordinatesLeft).toString());
    addstr(" Recruits / ");
    addstr(cr.maxSubordinates.toString());
    addstr(" Max");
  } else {
    move(18, 0);
    addstr("Enlightened Can't Recruit");
  }
  // Any meetings with potential recruits scheduled?
  if (cr.scheduledMeetings > 0) {
    move(18, 55);
    addstr("Scheduled Meetings: ");
    addstr(cr.scheduledMeetings.toString());
  }
  // Add seduction stats
  move(19, 0);
  int lovers = cr.relationships.length;
  if (lovers > 0) {
    addstr("$lovers Romantic Interest");
    if (lovers > 1) addstr("s");
  }
  // Any dates with potential love interests scheduled?
  if (cr.scheduldeDates > 0) {
    move(19, 55);
    addstr("Scheduled Dates:    ");
    addstr(cr.scheduldeDates.toString());
  }

  // Add wound status
  for (int w = 0; w < cr.body.parts.length; w++) {
    BodyPart part = cr.body.parts[w];
    if (part.bleeding) {
      setColor(red);
    } else {
      setColor(lightGray);
    }

    move(5 + w, 55);
    addstr("${part.name}:");

    move(5 + w, 66);
    if (part.nastyOff) {
      addstr("Ripped off");
    } else if (part.cleanOff) {
      addstr("Severed");
    } else {
      List<String> wounds = [];

      if (part.shot) wounds.add("Shot");
      if (part.cut) wounds.add("Cut");
      if (part.bruised) wounds.add("Bruised");
      if (part.burned) wounds.add("Burned");
      if (part.torn) wounds.add("Torn");

      if (wounds.isEmpty) {
        setColor(lightGreen);
        if (cr.type.animal) {
          addstr("Animal");
        } else {
          addstr("Liberal");
        }
      } else {
        addstr(wounds.join(","));
      }
    }
  }
  setColor(lightGray);

  //SPECIAL WOUNDS
  setColor(red);

  int y = 12;
  int x = 55;
  List<String> injuries = cr.body.allSpecialInjuries();
  for (String injury in injuries) {
    mvaddstr(y++, x, injury);
  }

  setColor(lightGray);
}

/* Full screen character sheet, crime sheet */
void printFullCreatureCrimes(Creature cr) {
  printFullCreatureNameBlock(cr);
  // Show outstanding convictions in addition to untried crimes
  if (cr.deathPenalty) {
    setColor(red);
    if (cr.site?.type == SiteType.prison) {
      mvaddstr(3, 0, "On DEATH ROW");
    } else {
      mvaddstr(3, 0, "Sentenced to DEATH");
    }
  } else if (cr.sentence < 0) {
    setColor(red);
    if (cr.site?.type == SiteType.prison) {
      mvaddstr(3, 0, "Serving life in prison");
    } else {
      mvaddstr(3, 0, "Sentenced to life in prison");
    }
  } else if (cr.sentence > 0) {
    setColor(yellow);
    if (cr.site?.type == SiteType.prison) {
      mvaddstr(3, 0, "Serving ");
    } else {
      mvaddstr(3, 0, "Sentenced to ");
    }
    addstr("${cr.sentence} months in prison.");
  }

  // Add all crimes
  for (int i = 0; i < Crime.values.length; i++) {
    Crime crime = Crime.values[i];
    if (i % 2 == 0 && i < 4) {
      setColor(lightGray);
      mvaddstr(4, 40 * (i ~/ 2), "CRIME");
      mvaddstr(4, 30 + 40 * (i ~/ 2), "NUM");
    }

    // Commited crimes are yellow
    if (cr.wantedForCrimes[crime]! > 0) {
      setColor(yellow);
    } else {
      setColor(darkGray);
    }

    mvaddstr(5 + i ~/ 2, 40 * (i % 2), "${crime.wantedFor}: ");
    mvaddstr(5 + i ~/ 2, 30 + 40 * (i % 2),
        "{:02d}".format(cr.wantedForCrimes[crime]!));
  }

  setColor(lightGray);
}

void printFullCreatureNameBlock(Creature cr) {
  mvaddstrc(2, 0, lightGray, "Name: ");
  addstrc(white, cr.name);
  addstrc(lightGray, ", ${cr.title} (${cr.type.name})");
}

void highlightColorForSkill(Creature cr, Skill skill) {
  if (cr.skillCap(skill) != 0 && cr.skill(skill) >= cr.skillCap(skill)) {
    // Maxed skills are cyan
    setColor(lightBlue);
  } else if (cr.skillXP(skill) >= 100 + (10 * cr.skill(skill)) &&
      cr.skill(skill) < cr.skillCap(skill)) {
    // Leveling skills are white
    setColor(white);
  } else if (cr.skill(skill) < 1) {
    // <1 skills are dark gray
    setColor(darkGray);
  } else {
    // >=1 skills are light gray
    setColor(lightGray);
  }
}

void printWantedFor(Creature cr) {
  bool kidnapped = cr.kidnapped;
  bool criminal = false;
  Map<Crime, bool> wanted = {};

  for (Crime crime in Crime.values) {
    if ((cr.wantedForCrimes[crime] ?? 0) > 0) {
      wanted[crime] = true;
      criminal = true;
    } else {
      wanted[crime] = false;
    }
  }

  if (!criminal && !kidnapped) return;

  setColor(yellow);
  addstr("WANTED FOR ");

  if (kidnapped) {
    addstr("REHABILITATION");
  } else if (wanted[Crime.treason] == true) {
    addstr("TREASON");
  } else if (wanted[Crime.terrorism] == true) {
    addstr("TERRORISM");
  } else if (wanted[Crime.murder] == true) {
    addstr("MURDER");
  } else if (wanted[Crime.kidnapping] == true) {
    addstr("KIDNAPPING");
  } else if (wanted[Crime.bankRobbery] == true) {
    addstr("BANK ROBBERY");
  } else if (wanted[Crime.arson] == true) {
    addstr("ARSON");
  } else if (wanted[Crime.flagBurning] == true) {
    addstr(laws[Law.freeSpeech] == DeepAlignment.archConservative
        ? "FLAG MURDER"
        : "FLAG BURNING");
  } else if (wanted[Crime.unlawfulSpeech] == true) {
    addstr("HARMFUL SPEECH");
  } else if (wanted[Crime.drugDistribution] == true) {
    addstr("DRUG DEALING");
  } else if (wanted[Crime.escapingPrison] == true) {
    addstr("ESCAPING PRISON");
  } else if (wanted[Crime.aidingEscape] == true) {
    addstr("RELEASING PRISONERS");
  } else if (wanted[Crime.juryTampering] == true) {
    addstr("JURY TAMPERING");
  } else if (wanted[Crime.racketeering] == true) {
    addstr("RACKETEERING");
  } else if (wanted[Crime.extortion] == true) {
    addstr("EXTORTION");
  } else if (wanted[Crime.assault] == true) {
    addstr("ASSAULT");
  } else if (wanted[Crime.grandTheftAuto] == true) {
    addstr("GRAND THEFT AUTO");
  } else if (wanted[Crime.creditCardFraud] == true) {
    addstr("CREDIT CARD FRAUD");
  } else if (wanted[Crime.theft] == true) {
    addstr("LARCENY");
  } else if (wanted[Crime.prostitution] == true) {
    addstr("PROSTITUTION");
  } else if (wanted[Crime.harboring] == true) {
    addstr(laws[Law.immigration]! < DeepAlignment.liberal
        ? "HIRING ILLEGAL ALIENS"
        : "HIRING UNDOCUMENTED WORKERS");
  } else if (wanted[Crime.cyberTerrorism] == true) {
    addstr("CYBER TERRORISM");
  } else if (wanted[Crime.dataTheft] == true) {
    addstr("DATA THEFT");
  } else if (wanted[Crime.unlawfulBurial] == true) {
    addstr("UNLAWFUL BURIAL");
  } else if (wanted[Crime.breakingAndEntering] == true) {
    addstr("BREAKING AND ENTERING");
  } else if (wanted[Crime.cyberVandalism] == true) {
    addstr("CYBER VANDALISM");
  } else if (wanted[Crime.vandalism] == true) {
    addstr("VANDALISM");
  } else if (wanted[Crime.resistingArrest] == true) {
    addstr("RESISTING ARREST");
  } else if (wanted[Crime.disturbingThePeace] == true) {
    addstr("DISTURBING THE PEACE");
  } else if (wanted[Crime.publicNudity] == true) {
    addstr("PUBLIC NUDITY");
  } else if (wanted[Crime.loitering] == true) {
    addstr("LOITERING");
  }
}
