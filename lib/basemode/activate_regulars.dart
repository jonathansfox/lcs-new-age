import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/basemode/help_system.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/creature/sort_creatures.dart';
import 'package:lcs_new_age/daily/activities/recruiting.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

Future<void> activateRegulars() async {
  List<Creature> tempPool = pool
      .where((p) =>
          p.isActiveLiberal &&
          (p.squad == null || p.squad?.activity.type == ActivityType.none))
      .toList();
  if (tempPool.isEmpty) return;

  sortLiberals(tempPool, SortingScreens.activateRegulars);

  int page = 0;
  while (true) {
    erase();
    printFunds();
    mvaddstr(0, 0, "Activate Uninvolved Liberals");
    makeDelimiter(y: 1);
    mvaddstr(1, 4, "CODE NAME");
    mvaddstr(1, 24, "SKILL");
    mvaddstr(1, 32, "HEALTH");
    mvaddstr(1, 41, "LOCATION");
    mvaddstr(1, 57, "ACTIVITY");
    int y = 2;
    for (int p = page * 19; p < tempPool.length && p < (page + 1) * 19; p++) {
      Creature c = tempPool[p];
      mvaddstrc(y, 0, lightGray, "${letterAPlus(y - 2)} - ${c.name}");
      printSkillSummary(y, 24, c, showWeaponSkill: false);
      printHealthStat(y, 32, c, small: true);
      mvaddstrc(
          y,
          41,
          c.site?.isPartOfTheJusticeSystem == true ? yellow : lightGray,
          c.location?.getName(short: true) ?? "In Hiding");
      mvaddstrc(y, 57, c.activity.color, c.activity.description);
      y++;
    }
    mvaddstrc(22, 0, lightGray, "Press a Letter to Assign an Activity.");
    mvaddstr(23, 0, "$pageStr. T to sort people.");
    mvaddstr(24, 0, "Press Z to assign simple tasks in bulk.");
    int c = await getKey();
    if (isPageUp(c) && page > 0) page--;
    if (isPageDown(c) && (page + 1) * 19 < tempPool.length) page++;
    if (c >= Key.a && c <= Key.s) {
      int p = page * 19 + (c - Key.a);
      if (p < tempPool.length) await _activateOne(tempPool[p]);
    }
    if (c == Key.t) {
      await sortingPrompt(SortingScreens.activateRegulars);
      sortLiberals(tempPool, SortingScreens.activateRegulars);
    }
    if (c == Key.z) {
      await _activateBulk();
    }
    if (isBackKey(c)) break;
  }
}

List<ActivityType> _activism = [
  ActivityType.communityService,
  ActivityType.trouble,
  ActivityType.graffiti,
  ActivityType.hacking,
  ActivityType.writeGuardian,
];

List<ActivityType> _legal = [
  ActivityType.donations,
  ActivityType.sellTshirts,
  ActivityType.sellArt,
  ActivityType.sellMusic,
];

List<ActivityType> _illegal = [
  ActivityType.sellDrugs,
  ActivityType.prostitution,
  ActivityType.ccfraud,
];

List<ActivityType> _acquisition = [
  ActivityType.recruiting,
  ActivityType.stealCars,
  ActivityType.makeClothing,
  ActivityType.wheelchair,
];

List<ActivityType> _study = [
  ActivityType.study,
  ActivityType.takeClass,
];

List<ActivityType> _medical = [
  ActivityType.clinic,
  ActivityType.augment,
];

List<ActivityType> _teaching = [
  ActivityType.teachLiberalArts,
  ActivityType.teachCovert,
  ActivityType.teachFighting,
];

Future<void> _activateOne(Creature c) async {
  int state = 0;
  bool canDisposeCorpses =
      c.site?.creaturesPresent.any((p) => !p.alive) == true;
  bool canInterrogateHostages = c.site?.creaturesPresent
          .any((c) => c.alive && c.align == Alignment.conservative) ==
      true;
  while (true) {
    erase();
    printFunds();
    if (c.income > 0) {
      mvaddstr(0, 0, "${c.name} made \$${c.income} yesterday. What now?");
    } else {
      mvaddstr(0, 0, "Taking Action: What will ${c.name} do today?");
    }
    printCreatureInfo(c, showCarPrefs: ShowCarPrefs.showPreferences);
    makeDelimiter();
    _y = 10;
    _highlightedActivity = c.activity.type;
    _category(_activism, "A - Liberal Activism", state == Key.a, state != 0);
    _category(_legal, "B - Legal Fundraising", state == Key.b, state != 0);
    _category(_illegal, "C - Illegal Fundraising", state == Key.c, state != 0);
    _category(_acquisition, "D - Recruitment and Acquisition", state == Key.d,
        state != 0);
    _category(_study, "E - Education and Learning", state == Key.e, state != 0);
    _category(_teaching, "T - Teaching Classes", state == Key.t, state != 0);
    _category(_medical, "M - Medical and Support", state == Key.m, state != 0);
    _activity(
        ActivityType.interrogation, "I - Interrogate a Hostage", state != 0,
        grayOut: !canInterrogateHostages);
    _activity(ActivityType.bury, "Z - Corpse Disposal", state != 0,
        grayOut: !canDisposeCorpses);
    setColor(activeSafehouse?.siege.underSiege ?? false ? darkGray : lightGray);
    mvaddstr(_y++, 1, "G - Equip This Liberal");
    _activity(ActivityType.none, "X - Nothing for Now", state != 0);
    mvaddstrc(19, 40, lightGray, "? - About the Selected Activity");
    mvaddstrc(20, 40, lightGray, "Enter - Confirm Selection");
    if (state == Key.a) {
      _activismSubmenu(c);
    } else if (state == Key.b) {
      _legalSubmenu();
    } else if (state == Key.c) {
      _illegalSubmenu(c);
    } else if (state == Key.d) {
      _acquisitionSubmenu(c);
    } else if (state == Key.e) {
      _educationSubmenu(c);
    } else if (state == Key.t) {
      _teachingSubmenu();
    } else if (state == Key.m) {
      _medicalSubmenu(c);
    }
    _activityFooter(c);
    int key = await getKey();
    switch (key) {
      case Key.a:
        state = key;
        _activismDefault(c);
      case Key.b:
        state = key;
        _legalDefault(c);
      case Key.c:
        state = key;
        _illegalDefault(c);
      case Key.d:
        state = key;
        _acquisitionDefault(c);
      case Key.e:
        state = key;
      case Key.t:
        state = key;
      case Key.m:
        state = key;
        _medicalDefault(c);
      case Key.x:
        state = 0;
        c.activity = Activity.none();
      case Key.z:
        if (canDisposeCorpses) {
          c.activity = Activity(ActivityType.bury);
        }
      case Key.i:
        if (canInterrogateHostages) {
          await _selectTendHostage(c);
        }
      case Key.g:
        await equipLiberal(c);
    }
    if (key >= Key.num0 && key <= Key.num9) {
      if (state == Key.a) {
        _activismChoice(c, key - Key.num0);
      } else if (state == Key.b) {
        _legalChoice(c, key - Key.num0);
      } else if (state == Key.c) {
        _illegalChoice(c, key - Key.num0);
      } else if (state == Key.d) {
        await _acquisitionChoice(c, key - Key.num0);
      } else if (state == Key.e) {
        await _educationChoice(c, key - Key.num0);
      } else if (state == Key.t) {
        _teachingChoice(c, key - Key.num0);
      } else if (state == Key.m) {
        _medicalChoice(c, key - Key.num0);
      }
    }
    if (isBackKey(key)) {
      break;
    }
    if (key == "?".codePoint) {
      await helpOnActivity(c.activity.type);
    }
  }
}

int _y = 10;
ActivityType _highlightedActivity = ActivityType.none;
void _category(
    List<ActivityType> category, String desc, bool highlight, bool ignore) {
  if (highlight) {
    setColor(lightBlue);
  } else {
    setColor((!ignore && category.contains(_highlightedActivity))
        ? lightBlue
        : lightGray);
  }
  mvaddstr(_y++, 1, desc);
}

void _activity(ActivityType activity, String desc, bool ignore,
    {int x = 1, bool grayOut = false}) {
  if (grayOut) {
    setColor(darkGray);
  } else {
    setColor(
        !ignore && activity == _highlightedActivity ? lightBlue : lightGray);
  }
  mvaddstr(_y++, x, desc);
}

void _subActivity(ActivityType activity, String desc, {bool greyOut = false}) {
  _activity(activity, desc, false, x: 40, grayOut: greyOut);
}

void _activismSubmenu(Creature c) {
  _y = 10;
  _subActivity(ActivityType.communityService, "1 - Community Service");
  _subActivity(ActivityType.trouble, "2 - Liberal Disobedience");
  _subActivity(ActivityType.graffiti, "3 - Graffiti");
  String needHackerDen =
      c.site?.compound.hackerDen != true ? " (Need Den)" : "";
  _subActivity(ActivityType.hacking, "4 - Hacking$needHackerDen",
      greyOut: c.rawSkill[Skill.computers]! == 0 ||
          c.site?.compound.hackerDen != true);
  _subActivity(
      ActivityType.writeGuardian, "5 - Write Liberal Guardian Articles");
  String needVideoRoom =
      c.site?.compound.videoRoom != true ? " (Need Studio)" : "";
  _subActivity(
      ActivityType.streamGuardian, "6 - Stream Guardian TV$needVideoRoom",
      greyOut: c.site?.compound.videoRoom != true);
}

void _activismChoice(Creature c, int choice) {
  if (choice == 1) c.activity = Activity(ActivityType.communityService);
  if (choice == 2) c.activity = Activity(ActivityType.trouble);
  if (choice == 3) c.activity = Activity(ActivityType.graffiti);
  if (choice == 4 &&
      c.rawSkill[Skill.computers]! > 0 &&
      c.site?.compound.hackerDen == true) {
    c.activity = Activity(ActivityType.hacking);
  }
  if (choice == 5) c.activity = Activity(ActivityType.writeGuardian);
  if (choice == 6 && c.site?.compound.videoRoom == true) {
    c.activity = Activity(ActivityType.streamGuardian);
  }
}

void _activismDefault(Creature c) {
  if (c.juice < 0) {
    c.activity = Activity(ActivityType.communityService);
  } else if (c.rawSkill[Skill.computers]! > 2 &&
      c.site?.compound.hackerDen == true) {
    c.activity = Activity(ActivityType.hacking);
  } else if (c.rawSkill[Skill.art]! > 1) {
    c.activity = Activity(ActivityType.graffiti);
  } else {
    c.activity = Activity(ActivityType.trouble);
  }
}

void _legalSubmenu() {
  _y = 10;
  _subActivity(ActivityType.donations, "1 - Solicit Donations");
  _subActivity(ActivityType.sellTshirts, "2 - Make and Sell Clothing");
  _subActivity(ActivityType.sellArt, "3 - Make and Sell Art");
  _subActivity(ActivityType.sellMusic, "4 - Perform Live Music");
}

void _legalChoice(Creature c, int choice) {
  if (choice == 1) c.activity = Activity(ActivityType.donations);
  if (choice == 2) c.activity = Activity(ActivityType.sellTshirts);
  if (choice == 3) c.activity = Activity(ActivityType.sellArt);
  if (choice == 4) c.activity = Activity(ActivityType.sellMusic);
}

void _legalDefault(Creature c) {
  if (c.weapon.type.instrument) {
    c.activity = Activity(ActivityType.sellMusic);
  } else if (c.rawSkill[Skill.art]! > 1) {
    c.activity = Activity(ActivityType.sellArt);
  } else if (c.rawSkill[Skill.tailoring]! > 1) {
    c.activity = Activity(ActivityType.sellTshirts);
  } else if (c.rawSkill[Skill.music]! > 1) {
    c.activity = Activity(ActivityType.sellMusic);
  } else {
    c.activity = Activity(ActivityType.donations);
  }
}

void _illegalSubmenu(Creature c) {
  _y = 10;
  _subActivity(ActivityType.sellDrugs, "1 - Sell Weed Brownies");
  _subActivity(ActivityType.prostitution, "2 - Prostitution",
      greyOut: c.age < 18);
  String needHackerDen =
      c.site?.compound.hackerDen != true ? " (Need Den)" : "";
  _subActivity(ActivityType.ccfraud, "3 - Credit Card Fraud$needHackerDen",
      greyOut: c.rawSkill[Skill.computers] == 0 ||
          c.site?.compound.hackerDen != true);
}

void _illegalChoice(Creature c, int choice) {
  if (choice == 1) c.activity = Activity(ActivityType.sellDrugs);
  if (choice == 2 && c.age >= 18) {
    c.activity = Activity(ActivityType.prostitution);
  }
  if (choice == 3 &&
      c.rawSkill[Skill.computers] != 0 &&
      c.site?.compound.hackerDen == true) {
    c.activity = Activity(ActivityType.ccfraud);
  }
}

void _illegalDefault(Creature c) {
  if (c.rawSkill[Skill.computers]! > 1 && c.site?.compound.hackerDen == true) {
    c.activity = Activity(ActivityType.ccfraud);
  } else if (c.rawSkill[Skill.seduction]! > 1 && c.age >= 18) {
    c.activity = Activity(ActivityType.prostitution);
  } else {
    c.activity = Activity(ActivityType.sellDrugs);
  }
}

void _acquisitionSubmenu(Creature c) {
  _y = 10;
  _subActivity(ActivityType.recruiting, "1 - Recruiting");
  _subActivity(ActivityType.stealCars, "2 - Steal a Car");
  _subActivity(ActivityType.makeClothing, "3 - Make Clothing");
  _subActivity(ActivityType.wheelchair, "4 - Procure a Wheelchair",
      greyOut: c.canWalk || c.hasWheelchair);
}

Future<void> _acquisitionChoice(Creature c, int choice) async {
  if (choice == 1) await _selectRecruitTarget(c);
  if (choice == 2) c.activity = Activity(ActivityType.stealCars);
  if (choice == 3) await _selectClothingToMake(c);
  if (choice == 4 && !c.canWalk && !c.hasWheelchair) {
    c.activity = Activity(ActivityType.wheelchair);
  }
}

void _acquisitionDefault(Creature c) {
  if (!c.canWalk && !c.hasWheelchair) {
    c.activity = Activity(ActivityType.wheelchair);
  }
}

void _educationSubmenu(Creature c) {
  _y = 10;
  _subActivity(ActivityType.study, "1 - Study a Skill (Free)");
  _subActivity(ActivityType.takeClass, "2 - Take Classes (\$30/day)");
}

Future<void> _educationChoice(Creature c, int choice) async {
  if (choice == 1) {
    await _selectSkillForEducation(
        c, "study independently", ActivityType.study);
  }
  if (choice == 2) {
    await _selectSkillForEducation(
        c, "take classes in", ActivityType.takeClass);
  }
}

void _teachingSubmenu() {
  _y = 10;
  _subActivity(ActivityType.teachLiberalArts, "1 - Teach Liberal Arts");
  _subActivity(ActivityType.teachCovert, "2 - Teach Covert Ops");
  _subActivity(ActivityType.teachFighting, "3 - Teach Fighting");
}

void _teachingChoice(Creature c, int choice) {
  if (choice == 1) c.activity = Activity(ActivityType.teachLiberalArts);
  if (choice == 2) c.activity = Activity(ActivityType.teachCovert);
  if (choice == 3) c.activity = Activity(ActivityType.teachFighting);
}

void _medicalSubmenu(Creature c) {
  _y = 10;
  _subActivity(ActivityType.clinic, "1 - Go to the Hospital",
      greyOut: c.blood >= c.maxBlood);
  //_subActivity(ActivityType.augment, "2 - Augment a Liberal");
  _y++;
  mvaddstrc(_y++, 40, midGray, "Capable medics will always provide");
  mvaddstrc(_y++, 40, midGray, "medical care to themselves or others");
  mvaddstrc(_y++, 40, midGray, "in the same location.  This does not");
  mvaddstrc(_y++, 40, midGray, "interfere with other tasks.");
}

void _medicalChoice(Creature c, int choice) {
  if (choice == 1 && c.blood < c.maxBlood) {
    c.activity = Activity(ActivityType.clinic);
  } else if (choice == 2) {
    //c.activity = Activity(ActivityType.augment);
  }
}

void _medicalDefault(Creature c) {
  if (c.blood < c.maxBlood) {
    c.activity = Activity(ActivityType.clinic);
  }
}

Future<void> _selectRecruitTarget(Creature cr) async {
  await pagedInterface(
    headerPrompt:
        "What type of person will ${cr.name} try to meet and recruit?",
    headerKey: {4: "TYPE", 49: "DIFFICULTY TO ARRANGE MEETING"},
    footerPrompt: "Press a Letter to select a Profession",
    count: recruitableCreatures.length,
    lineBuilder: (y, key, index) {
      mvaddstrc(y, 0, lightGray, "$key - ${recruitableCreatures[index].name}");
      addDifficultyText(y, 49, recruitableCreatures[index].difficulty);
    },
    onChoice: (index) async {
      cr.activity = Activity(ActivityType.recruiting,
          idString: recruitableCreatures[index].type.id);
      return true;
    },
  );
}

Future<void> _selectClothingToMake(Creature cr) async {
  int minDifficulty(ClothingType c) =>
      c.makeDifficulty +
      c.allowedArmor.first.makeDifficulty -
      cr.skill(Skill.tailoring);
  List<ClothingType> craftable = clothingTypes.values
      .where((c) =>
          c.makeDifficulty >= 0 && (!c.deathsquadLegality || deathSquadsActive))
      .sorted((a, b) => a.name.compareTo(b.name))
      .sorted((a, b) => minDifficulty(a).compareTo(minDifficulty(b)));

  int selectedClothingIndex = -1;
  int selectedArmorIndex = 0;
  ClothingType? getSelectedClothing() {
    if (selectedClothingIndex == -1) return null;
    return craftable.elementAtOrNull(selectedClothingIndex);
  }

  ArmorUpgrade getSelectedArmor() =>
      getSelectedClothing()?.allowedArmor.elementAtOrNull(selectedArmorIndex) ??
      armorUpgrades.values.first;

  void renderFooter() {
    _clothingDetailFooter(
        getSelectedClothing()!, getSelectedArmor(), cr.skill(Skill.tailoring));
  }

  await pagedInterface(
    headerPrompt:
        "Which will ${cr.name} try to make?  (Note: Half Cost if you have cloth)",
    headerKey: {4: "NAME", 37: "DIFFICULTY", 60: "COST"},
    footerPrompt: "Press a Letter to select a Type of Clothing",
    pageSize: 12,
    count: craftable.length,
    lineBuilder: (y, key, index) {
      int difficulty = minDifficulty(craftable[index]);
      bool selected = selectedClothingIndex == index;
      Color color = lightGray;
      if (selected) color = white;
      mvaddstrc(y, 0, color, "$key - ${craftable[index].name}");
      addDifficultyText(y, 37, difficulty + 4);
      String price =
          "\$${craftable[index].makePrice + craftable[index].allowedArmor.first.makePrice}";
      mvaddstrc(y, 64 - price.length, lightGreen, price);
    },
    onChoice: (index) async {
      selectedClothingIndex = index;
      selectedArmorIndex = 0;
      renderFooter();
      return false;
    },
    onOtherKey: (key) {
      ClothingType? clothing = getSelectedClothing();
      if (key == Key.enter) {
        return true;
      }
      if ((key == Key.rightArrow || key == Key.rightAngleBracket) &&
          clothing != null) {
        if (selectedArmorIndex < clothing.allowedArmor.length - 1) {
          selectedArmorIndex++;
          renderFooter();
        }
      } else if ((key == Key.leftArrow || key == Key.leftAngleBracket) &&
          clothing != null) {
        if (selectedArmorIndex > 0) {
          selectedArmorIndex--;
          renderFooter();
        }
      } else if (key == Key.upArrow && clothing != null) {
        selectedClothingIndex = (selectedClothingIndex - 1) % craftable.length;
        selectedArmorIndex = 0;
        renderFooter();
      } else if (key == Key.downArrow && clothing != null) {
        selectedClothingIndex = (selectedClothingIndex + 1) % craftable.length;
        selectedArmorIndex = 0;
        renderFooter();
      }
      return false;
    },
  );
  if (selectedClothingIndex != -1) {
    cr.activity = Activity(ActivityType.makeClothing,
        idString:
            "${craftable[selectedClothingIndex].idName}:ARMOR$selectedArmorIndex");
  }
}

void _clothingDetailFooter(
    ClothingType clothing, ArmorUpgrade armor, int skill) {
  int armorIndex = clothing.allowedArmor.toList().indexOf(armor);
  eraseArea(startY: 16);
  makeDelimiter(y: 16);
  move(17, 0);
  bool alarming = clothing.alarming ||
      (armor.visible &&
          !clothing.allowVisibleArmor &&
          clothing.intrinsicArmorId != armor.idName);
  for (int i = 0; i < 2; i++) {
    eraseLine(17);
    if (armorIndex > 0) {
      addstrc(white, "< ");
    } else {
      addstrc(darkGray, "< ");
    }
    addstrc(lightGray, "${clothing.name}, ");
    addstrc(lightBlue, armor.name);
    addstrc(lightGreen, " \$${clothing.makePrice + armor.makePrice}");

    if (clothing.allowedArmor.length > 1) {
      addstrc(
          lightGray, " (${armorIndex + 1}/${clothing.allowedArmor.length})");
    }
    if (clothing.allowedArmor.length > armorIndex + 1) {
      addstrc(white, " >");
    } else {
      addstrc(darkGray, " >");
    }
    move(console.y, (console.width - console.x) ~/ 2);
  }

  if (alarming) {
    setColor(red);
  } else {
    setColor(lightBlue);
  }
  mvaddstrCenter(18, armor.description);

  mvaddstrc(19, 20, lightGray, "Special Traits: ");
  List<String> traits =
      clothing.traitsList(false, specifiedArmorUpgrade: armor);
  if (traits.isEmpty) {
    if (alarming) {
      addstrc(red, "Immediate Alarm");
    } else {
      addstrc(darkGray, "None");
    }
  } else {
    addstrc(lightBlue, traits.join(", "));
    if (alarming) {
      addstr(", ");
      addstrc(red, "Alarming");
    }
  }
  mvaddstrc(20, 20, lightGray, "Head: ");
  addstrc(lightBlue, "${armor.headArmor} Armor");
  mvaddstrc(21, 20, lightGray, "Torso: ");
  addstrc(lightBlue, "${armor.bodyArmor} Armor");
  mvaddstrc(22, 20, lightGray, "Limbs: ");
  addstrc(lightBlue, "${armor.limbArmor} Armor");
  mvaddstrc(20, 40, lightGray, "Dodge: ");
  if (armor.dodgePenalty > 0) {
    addstrc(red, "-${armor.dodgePenalty}");
  } else {
    addstrc(lightGreen, "No Penalty");
  }
  mvaddstrc(21, 40, lightGray, "Accuracy: ");
  if (armor.accuracyPenalty > 0) {
    addstrc(red, "-${armor.accuracyPenalty}");
  } else {
    addstrc(lightGreen, "No Penalty");
  }
  mvaddstrc(22, 40, lightGray, "Complexity: ");
  int difficulty = clothing.makeDifficulty + armor.makeDifficulty + 4 - skill;
  addDifficultyText(console.y, console.x, difficulty);

  setColor(white);
  mvaddstrCenter(
      24, "ENTER - Confirm Selection   ESC - Cancel Making Clothing");
}

Future<void> _selectSkillForEducation(
    Creature cr, String flavor, ActivityType activityType) async {
  List<Skill> skills = Skill.values;
  if (activityType == ActivityType.takeClass) {
    skills = skills.where((s) => s.canTakeClasses).toList();
  }
  await pagedInterface(
    headerPrompt: "What skill will ${cr.name} $flavor?",
    headerKey: {4: "SKILL", 21: "NOW", 27: "MAX", 34: "DESCRIPTION"},
    footerPrompt: "Press a Letter to select a Skill",
    count: skills.length,
    lineBuilder: (y, key, index) {
      Skill skill = skills[index];
      mvaddstrc(y, 0, lightGray, "$key - ${skill.displayName}");
      highlightColorForSkill(cr, skill);
      printSkillValue(cr, skill, y, 20, emphasizePotential: true);
      mvaddstrc(
          y,
          34,
          lightGray,
          activityType == ActivityType.takeClass
              ? skill.classText
              : skill.description);
    },
    onChoice: (index) async {
      cr.activity = Activity(activityType, skill: skills[index]);
      return true;
    },
  );
}

void _activityFooter(Creature cr) {
  mvaddstrc(22, 3, lightGray, "${cr.name} will");
  switch (cr.activity.type) {
    case ActivityType.none:
      addstr(" lay low and stay out of trouble.");
    case ActivityType.visit:
      addstr(" act with ${cr.gender.hisHer} squad.");
      mvaddstr(23, 3, "Squad activities always take precedence even if you");
      mvaddstr(24, 3, "assign a different individual activity.");
    case ActivityType.augment:
      addstr(" undergo surgery.");
    case ActivityType.bury:
      addstr(" bury the dead.");
      mvaddstr(23, 3, "Uses Street Smarts to avoid the police.");
    case ActivityType.ccfraud:
      addstr(" commit credit card fraud.");
      mvaddstr(23, 3, "Uses Computers.  Requires a Hacker Den.");
    case ActivityType.clinic:
      addstr(" go to the hospital.");
    case ActivityType.communityService:
      addstr(" volunteer for a local nonprofit.");
      mvaddstr(
          23, 3, "A tiny bit of juice.  It's not *real* though, you know?");
    case ActivityType.donations:
      addstr(" solicit donations.");
      mvaddstr(23, 3, "Uses Persuasion and Street Smarts.");
    case ActivityType.graffiti:
      addstr(" spray graffiti.");
      mvaddstr(23, 3, "Uses Art.");
    case ActivityType.hacking:
      addstr(" hack into private networks.");
      mvaddstr(23, 3, "Uses Computers.  Requires a Hacker Den.");
    case ActivityType.interrogation:
      addstr(" tend to hostages.");
      mvaddstr(23, 3, "Uses Psychology and other social skills.");
    case ActivityType.makeClothing:
      addstr(" make clothing.");
      mvaddstr(23, 3, "Uses Tailoring.");
    case ActivityType.prostitution:
      addstr(" have sex for money.");
      mvaddstr(23, 3, "Uses Seduction.");
    case ActivityType.recruiting:
      addstr(" recruit new members.");
      mvaddstr(23, 3, "Uses Street Smarts to find likely recruits.");
      mvaddstr(
          24, 3, "Persuasion or Seduction is used to convince them to join.");
    case ActivityType.sellArt:
      addstr(" make and sell art.");
      mvaddstr(23, 3, "Uses Art and Business.");
    case ActivityType.sellDrugs:
      addstr(" bake and sell weed brownies.");
      mvaddstr(23, 3, "Uses Street Smarts and Business.");
    case ActivityType.sellMusic:
      addstr(" perform live music for money.");
      mvaddstr(23, 3, "Uses Music and Business.");
    case ActivityType.sellTshirts:
      addstr(" make and sell clothing.");
      mvaddstr(23, 3, "Uses Tailoring and Business.");
    case ActivityType.stealCars:
      addstr(" steal a car.");
      mvaddstr(23, 3, "Uses Security and Street Smarts.");
    case ActivityType.streamGuardian:
      addstr(" stream for the Liberal Guardian.");
      mvaddstr(23, 3, "Uses Persuasion and various knowledge skills.");
    case ActivityType.study:
      addstr(" independently study ${cr.activity.skill?.displayName}.");
      mvaddstr(23, 3, "Slowly and safely gains experience for free.");
      mvaddstr(24, 3, "The only limit is your own potential.");
    case ActivityType.takeClass:
      addstr(" take classes in ${cr.activity.skill?.displayName}.");
      mvaddstr(23, 3, "Quickly and safely gains experience for \$10/day.");
      mvaddstr(
          24, 3, "Classes have a maximum level and not all skills are taught.");
    case ActivityType.teachCovert:
      mvaddstr(22, 3,
          "Trains: Computers, Security, Stealth, Disguise, Tailoring, Seduction,");
      mvaddstr(23, 3, "        Driving, and Street Smarts");
      mvaddstr(24, 3,
          "Classes cost up to \$60/day to conduct. All Liberals able will attend.");
    case ActivityType.teachFighting:
      mvaddstr(22, 3,
          "Trains: Martial Arts, Firearms, Throwing, Knife, Martial Arts,");
      mvaddstr(23, 3, "        Dodge, First Aid");
      mvaddstr(24, 3,
          "Classes cost up to \$100/day to conduct. All Liberals able will attend.");
    case ActivityType.teachLiberalArts:
      mvaddstr(22, 3, "Trains: Writing, Persuasion, Law, Religion, Science,");
      mvaddstr(23, 3, "        Business, Psychology, Music, and Art");
      mvaddstr(24, 3,
          "Classes cost up to \$20/day to conduct. All Liberals able will attend.");
    case ActivityType.trouble:
      addstr(" hit the streets and cause trouble.");
      mvaddstr(23, 3, "Uses Street Smarts to avoid trouble of your own.");
    case ActivityType.wheelchair:
      addstr(" procure a wheelchair.");
    case ActivityType.writeGuardian:
      addstr(" write articles for the Liberal Guardian.");
      mvaddstr(23, 3, "Uses Writing and various knowledge skills.");
    default:
      addstr(" report a bug to the developers: ${cr.activity.type.name}.");
  }
  mvaddstrc(20, 40, lightGray, "Enter - Confirm Selection");
}

Future<void> _activateBulk() async {
  List<Creature> temppool = pool
      .where((p) =>
          p.isActiveLiberal &&
          (p.squad == null || p.squad?.activity.type == ActivityType.none))
      .toList();

  if (temppool.isEmpty) return;

  int page = 0, selectedactivity = 0;

  while (true) {
    erase();

    setColor(lightGray);
    printFunds();

    mvaddstr(0, 0, "Activate Uninvolved Liberals");
    addHeader({4: "CODE NAME", 25: "CURRENT ACTIVITY", 51: "BULK ACTIVITY"});

    void addOption(int i, String name) {
      mvaddstrc(i + 1, 51, selectedactivity == i - 1 ? white : lightGray,
          "$i - $name");
    }

    addOption(1, "Liberal Activism");
    addOption(2, "Legal Fundraising");
    addOption(3, "Illegal Fundraising");
    addOption(4, "Stealing Cars");
    addOption(5, "Community Service");

    int y = 2;
    for (int p = page * 19;
        p < temppool.length && p < page * 19 + 19;
        p++, y++) {
      Creature tempp = temppool[p];
      mvaddstrc(y, 0, lightGray, "${letterAPlus(y - 2)} - ${tempp.name}");

      move(y, 25);
      setColor(tempp.activity.type.color);
      addstr(tempp.activity.type.label);
    }

    mvaddstrc(22, 0, lightGray,
        "Press a Letter to Assign an Activity.  Press a Number to select an Activity.");
    mvaddstr(23, 0, pageStr);

    int c = await getKey();

    //PAGE UP
    if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
      page--;
    }
    //PAGE DOWN
    if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
        (page + 1) * 19 < temppool.length) {
      page++;
    }

    if (c >= Key.a && c <= Key.s) {
      int p = page * 19 + c - Key.a;
      if (p < temppool.length) {
        Creature tempp = temppool[p];
        switch (selectedactivity) {
          case 0: //Activism
            if (tempp.attribute(Attribute.wisdom) > 7 || tempp.juice < 0) {
              tempp.activity.type = ActivityType.communityService;
            } else if (tempp.attribute(Attribute.wisdom) > 4) {
              tempp.activity.type = ActivityType.trouble;
            } else {
              if (tempp.skill(Skill.computers) > 2 &&
                  tempp.site?.compound.hackerDen == true) {
                tempp.activity.type = ActivityType.hacking;
              } else if (tempp.skill(Skill.art) > 1) {
                tempp.activity.type = ActivityType.graffiti;
                tempp.activity.view = null;
              } else {
                tempp.activity.type = ActivityType.trouble;
              }
            }
          case 1: //Fundraising
            if (tempp.weapon.type.instrument) {
              tempp.activity.type = ActivityType.sellMusic;
            } else if (tempp.skill(Skill.art) > 1) {
              tempp.activity.type = ActivityType.sellArt;
            } else if (tempp.skill(Skill.tailoring) > 1) {
              tempp.activity.type = ActivityType.sellTshirts;
            } else if (tempp.skill(Skill.music) > 1) {
              tempp.activity.type = ActivityType.sellMusic;
            } else {
              tempp.activity.type = ActivityType.donations;
            }
          case 2: //Illegal Fundraising
            if (tempp.skill(Skill.computers) > 1) {
              tempp.activity.type = ActivityType.ccfraud;
            } else if (tempp.skill(Skill.seduction) > 1 && tempp.age >= 18) {
              tempp.activity.type = ActivityType.prostitution;
            } else {
              tempp.activity.type = ActivityType.sellDrugs;
            }
          case 3: //Steal cars
            tempp.activity.type = ActivityType.stealCars;
          case 4: //Volunteer
            tempp.activity.type = ActivityType.communityService;
        }
      }
    }
    if (c >= Key.num1 && c <= Key.num6) {
      selectedactivity = c - Key.num1;
    }

    if (isBackKey(c)) break;
  }
}

Future<void> _selectTendHostage(Creature cr) async {
  List<Creature> hostages = cr.site?.creaturesPresent
          .where((c) =>
              c.alive &&
              c.align == Alignment.conservative &&
              c.location == cr.location)
          .toList() ??
      [];
  if (hostages.isEmpty) return;
  if (hostages.length == 1) {
    cr.activity = Activity(ActivityType.interrogation, idInt: hostages[0].id);
    return;
  }
  await pagedInterface(
    headerPrompt: "Which hostage will ${cr.name} be watching over?",
    headerKey: {
      4: "HOSTAGE NAME",
      25: "SKILL",
      33: "HEALTH",
      45: "LOCATION",
      60: "DAYS IN CAPTIVITY"
    },
    footerPrompt: "Press a Letter to select a Hostage",
    count: hostages.length,
    lineBuilder: (y, key, index) {
      Creature h = hostages[index];
      mvaddstrc(y, 0, lightGray, "$key - ${h.name}");
      mvaddstr(y, 25, "${h.rawSkill.values.reduce((a, b) => a + b)}");
      printHealthStat(y, 33, h, small: true);
      mvaddstrc(y, 45, lightGray, h.location?.name ?? "Missing");
      mvaddstr(y, 60,
          "${h.daysSinceJoined} Day${h.daysSinceJoined == 1 ? "" : "s"}");
    },
    onChoice: (index) async {
      cr.activity =
          Activity(ActivityType.interrogation, idInt: hostages[index].id);
      return true;
    },
  );
}

Future<void> equipLiberal(Creature c) async {
  //create a temp squad containing just this liberal
  Squad? oldActiveSquad = activeSquad;
  Squad newSquad = Squad();
  newSquad.members.add(c);
  squads.add(newSquad);
  activeSquad = newSquad;
  await equip(c.site?.loot);
  activeSquad = oldActiveSquad;
  squads.remove(newSquad);
}
