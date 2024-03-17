import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/weapon_type_xml.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:xml/xml.dart';

Skill? parseSkill(String skillString) {
  Skill? skill = Skill.values.firstWhereOrNull(
      (s) => s.name.toLowerCase() == skillString.toLowerCase());
  if (skill == null) {
    switch (skillString) {
      case "handtohand":
      case "axe":
      case "club":
      case "sword":
        skill = Skill.martialArts;
      case "pistol":
      case "rifle":
      case "shotgun":
      case "smg":
        skill = Skill.firearms;
      case "streetsense":
        skill = Skill.streetSmarts;
      case "firstaid":
        skill = Skill.firstAid;
    }
  }
  return skill;
}

void parseCreatureType(CreatureType type, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "alignment":
        String? alignment = element.innerText;
        if (alignment == "PUBLIC MOOD") {
          type.alignment = CreatureTypeAlignment.any;
        } else if (alignment == "LIBERAL") {
          type.alignment = CreatureTypeAlignment.liberal;
        } else if (alignment == "MODERATE") {
          type.alignment = CreatureTypeAlignment.moderate;
        } else if (alignment == "CONSERVATIVE") {
          type.alignment = CreatureTypeAlignment.conservative;
        } else {
          debugPrint("Invalid alignment for ${type.id}: $alignment");
        }
      case "age":
        type.age = switch (element.innerText) {
          "DOGYEARS" => (2, 6),
          "CHILD" => (7, 11),
          "TEENAGER" => (14, 17),
          "YOUNGADULT" => (18, 25),
          "MATURE" => (20, 59),
          "GRADUATE" => (26, 29),
          "MIDDLEAGED" => (35, 59),
          "SENIOR" => (65, 95),
          _ => parseRange(element.innerText) ?? type.age,
        };
      case "attribute_points":
        type.extraAttributePoints = int.tryParse(element.innerText) ?? 0;
      case "attributes":
        for (XmlElement e in element.childElements) {
          Attribute? att;
          switch (e.name.local) {
            case "strength":
              att = Attribute.strength;
            case "intelligence":
              att = Attribute.intelligence;
            case "agility":
              att = Attribute.agility;
            case "charisma":
              att = Attribute.charisma;
            case "heart":
              att = Attribute.heart;
            case "wisdom":
              att = Attribute.wisdom;
            case "health":
              break;
            default:
              debugPrint("Ignoring attribute for ${type.id}: ${e.name.local}");
          }
          if (att != null) {
            (int, int)? val = parseRange(e.innerText);
            if (val != null) {
              type.attributePoints[att] = val;
            } else {
              debugPrint(
                  "Unable to parse ${e.name.local} value for ${type.id}: ${element.innerText}");
            }
          }
        }
      case "juice":
        type.juice = parseRange(element.innerText) ?? type.juice;
      case "infiltration":
        type.infiltration = parseRange(element.innerText) ?? type.infiltration;
      case "skills":
        for (XmlElement e in element.childElements) {
          Skill? skill = parseSkill(e.name.local);
          if (skill == null) {
            debugPrint("Ignoring skill for ${type.id}: ${e.name.local}");
          } else {
            (int, int)? val = parseRange(e.innerText);
            if (val != null) {
              if ((type.skillPoints[skill]?.$2 ?? 0) > 0) {
                debugPrint(
                    "Overwriting skill points for ${type.id}: ${skill.name} (${e.name.local})");
              }
              type.skillPoints[skill] = val;
            } else {
              debugPrint(
                  "Unable to parse ${e.name.local} value for ${type.id}: ${e.innerText}");
            }
          }
        }
      case "seethroughdisguise":
        type.seeThroughDisguise =
            int.tryParse(element.innerText) ?? type.seeThroughDisguise;
      case "gender":
        Gender? gender;
        switch (element.innerText) {
          case "RANDOM":
          case "NEUTRAL":
            gender = Gender.nonbinary;
          case "MALE":
            gender = Gender.male;
          case "FEMALE":
            gender = Gender.female;
          case "GENDER_WHITEMALEPATRIARCH":
            gender = Gender.whiteMalePatriarch;
          case "MALE BIAS":
            gender = Gender.maleBias;
          case "FEMALE BIAS":
            gender = Gender.femaleBias;
          default:
            debugPrint("Ignoring gender for ${type.id}: ${element.innerText}");
        }
        if (gender != null) {
          type.gender = gender;
        }
      case "money":
        type.money = parseRange(element.innerText) ?? type.money;
      case "armor":
        type.armorTypeIds.add(element.innerText);
      case "weapon":
        type.weaponTypeIds.add(element.innerText);
      case "encounter_name":
        type.encounterNames.add(element.innerText);
      case "type_name":
        type.name = element.innerText;
      case "talkreceptive":
        type.talkReceptive = parseBool(element.innerText) ?? type.talkReceptive;
      case "seethroughstealth":
        type.seeThroughStealth =
            int.tryParse(element.innerText) ?? type.seeThroughStealth;
      case "seeThroughDisguise":
        type.seeThroughDisguise =
            int.tryParse(element.innerText) ?? type.seeThroughDisguise;
      case "kidnap_resistant":
        type.kidnapResistant =
            parseBool(element.innerText) ?? type.kidnapResistant;
      case "reports_to_police":
        type.reportsToPolice =
            parseBool(element.innerText) ?? type.reportsToPolice;
      case "intimidation_resistant":
        type.intimidationResistant =
            parseBool(element.innerText) ?? type.intimidationResistant;
      case "can_perform_arrests":
        type.canPerformArrests =
            parseBool(element.innerText) ?? type.canPerformArrests;
      case "animal":
        type.animal = parseBool(element.innerText) ?? type.animal;
      case "dog":
        type.dog = parseBool(element.innerText) ?? type.dog;
      case "recruit_activity_difficulty":
        type.recruitActivityDifficulty =
            int.tryParse(element.innerText) ?? type.recruitActivityDifficulty;
      case "edgelord":
        type.edgelord = parseBool(element.innerText) ?? type.edgelord;
      case "social_attack":
        type.socialAttacks.add(parseAttack(element));
      default:
        debugPrint("Ignoring ${type.id} property: ${element.name.local}");
    }
  }
}
