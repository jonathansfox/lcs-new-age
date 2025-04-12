import 'dart:math';

import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/politics/alignment.dart';

int levelFromXP(int juice) {
  if (juice <= -50) return -2;
  if (juice <= -10) return -1;
  if (juice < 0) return 0;
  if (juice < 10) return 1;
  if (juice < 50) return 2;
  if (juice < 100) return 3;
  if (juice < 200) return 4;
  if (juice < 500) return 5;
  if (juice < 1000) return 6;
  return 7;
}

int levelAttribute(Creature creature, Attribute attribute) {
  int value = creature.permanentAttribute(attribute);
  if ((attribute == Attribute.heart &&
          creature.align == Alignment.conservative) ||
      (attribute == Attribute.wisdom && creature.align == Alignment.liberal)) {
    return value;
  }
  if (creature.level <= -2) value = 1;
  if (creature.level == -1) value = (value * 0.6).round();
  if (creature.level == 0) value = (value * 0.8).round();
  if (creature.level >= 2) {
    value = (value * (1 + (creature.level - 1) / 10)).round();
  }
  return max(1, value);
}

String levelTitle(int level, Alignment align) {
  const List<String> liberalTitles = [
    "In Crisis",
    "Unstable",
    "Struggling",
    "Civilian",
    "Activist",
    "Socialist Threat",
    "Revolutionary",
    "Urban Commando",
    "Liberal Guardian",
    "Elite Liberal",
  ];
  const List<String> moderateTitles = [
    "In Crisis",
    "Unstable",
    "Struggling",
    "Civilian",
    "Hard Worker",
    "Respected",
    "Upstanding Citizen",
    "Great Person",
    "Peacemaker",
    "Peace Prize Winner",
  ];
  List<String> conservativeTitles = [
    "In Crisis",
    "Unstable",
    "Struggling",
    "Mindless Conservative",
    "Heckler",
    "Right-Wing Goon",
    "Violent Vigilante",
    "Rural Reactionary",
    "Conservative Crusader",
    "Arch Conservative",
  ];
  List titleList;
  if (align == Alignment.liberal) {
    titleList = liberalTitles;
  } else if (align == Alignment.moderate) {
    titleList = moderateTitles;
  } else {
    titleList = conservativeTitles;
  }
  if (level <= 7) {
    return titleList[level + 2];
  } else {
    return "${titleList[9]} ${romanNumeral(level - 6)}";
  }
}
