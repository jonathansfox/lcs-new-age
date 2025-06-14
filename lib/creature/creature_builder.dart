/* ensures that the creature's work location is appropriate to its type */
import 'dart:math';

import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/creature_work_locations.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/hardcoded_creature_type_stuff.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Creature creatureBuilder(Creature creature, {Alignment? align}) {
  CreatureType type = creature.type;
  creature.name = type.randomEncounterName;

  creature.location = activeSite;
  giveWorkLocation(creature, type);

  creature.align = align ?? type.randomAlignment;
  creature.birthDate = type.randomBirthay;
  creature.juice = type.juice.roll();

  _giveEquipment(creature, type);
  _giveAttributes(creature, type);
  _giveSkills(creature, type);
  _giveGender(creature, type);

  creature.infiltration = type.infiltration.rollDouble() / 100;

  applyHardcodedCreatureTypeStuff(creature, type);

  // Convert to Conservative if alienated
  if (mode == GameMode.site) {
    if ((siteAlienated != SiteAlienation.none &&
            creature.align == Alignment.moderate) ||
        (siteAlienated == SiteAlienation.alienatedEveryone &&
            creature.align == Alignment.liberal)) {
      conservatize(creature);
    }

    if (siteAlarm && creature.align == Alignment.conservative) {
      creature.nonCombatant = creature.calculateWillRunAway();
    }
  }

  return creature;
}

void _giveAttributes(Creature creature, CreatureType type) {
  for (Attribute a in type.attributePoints.keys) {
    int minPoints = type.attributePoints[a]!.$1;
    int maxPoints = type.attributePoints[a]!.$2;
    if ((a == Attribute.heart && creature.align == Alignment.liberal) ||
        (a == Attribute.wisdom && creature.align == Alignment.conservative)) {
      minPoints = max(6, minPoints);
      maxPoints = max(10, maxPoints);
    } else if ((a == Attribute.wisdom && creature.align == Alignment.liberal) ||
        (a == Attribute.heart && creature.align == Alignment.conservative)) {
      minPoints = min(1, minPoints);
      maxPoints = min(4, maxPoints);
    } else if (creature.align == Alignment.moderate &&
        (a == Attribute.heart || a == Attribute.wisdom)) {
      minPoints = max(3, minPoints);
      maxPoints = min(7, maxPoints);
    }
    creature.rawAttributes[a] =
        minPoints + lcsRandom(maxPoints - minPoints + 1);
  }
  int total = creature.rawAttributes.values.reduce((a, b) => a + b);
  int roll = type.extraAttributePoints.$1 +
      lcsRandom(
          type.extraAttributePoints.$2 - type.extraAttributePoints.$1 + 1);
  int extraAttributePoints = roll + 35 - total;
  int extraPointValue = extraAttributePoints.sign;
  for (int i = 0; i < extraAttributePoints.abs(); i++) {
    Iterable<Attribute> possibleAttributes = Attribute.values.where((element) {
      int total = creature.rawAttributes[element]! + extraPointValue;
      return total >= type.attributePoints[element]!.$1 &&
          total <= type.attributePoints[element]!.$2;
    });
    if (possibleAttributes.isEmpty) break;
    Attribute attribute = possibleAttributes.random;
    creature.rawAttributes[attribute] =
        creature.rawAttributes[attribute]! + extraPointValue;
  }
  total = creature.rawAttributes.values.reduce((a, b) => a + b);
}

void _giveEquipment(Creature creature, CreatureType type) {
  ClothingType? armorType = type.randomArmor;
  if (armorType != null && armorType.idName != "CLOTHING_NONE") {
    creature.equippedClothing = Clothing(armorType.idName);
  }
  type.randomWeaponFor(creature);
  creature.money = type.money.roll();
}

void _giveGender(Creature creature, CreatureType type) {
  bool conforming = switch (laws[Law.genderEquality]!) {
    DeepAlignment.archConservative => true,
    DeepAlignment.conservative => !oneIn(20),
    DeepAlignment.moderate => !oneIn(5),
    DeepAlignment.liberal => oneIn(2),
    DeepAlignment.eliteLiberal => false,
  };
  bool canBeTrans = switch (laws[Law.lgbtRights]!) {
    DeepAlignment.archConservative => false,
    DeepAlignment.conservative => oneIn(20),
    DeepAlignment.moderate => oneIn(5),
    DeepAlignment.liberal => oneIn(2),
    DeepAlignment.eliteLiberal => true,
  };
  int nbChance = switch (laws[Law.lgbtRights]!) {
    DeepAlignment.archConservative => 20,
    DeepAlignment.conservative => 20,
    DeepAlignment.moderate => 16,
    DeepAlignment.liberal => 12,
    DeepAlignment.eliteLiberal => 8,
  };
  Gender any() {
    if ((creature.isLiberal || canBeTrans) && oneIn(nbChance)) {
      return Gender.nonbinary;
    } else {
      return [Gender.male, Gender.female].random;
    }
  }

  // Resolve gender by profession
  switch (type.gender) {
    case Gender.nonbinary:
      creature.gender = any();
    case Gender.whiteMalePatriarch:
    case Gender.male:
      creature.gender = Gender.male;
    case Gender.female:
      creature.gender = Gender.female;
    case Gender.femaleBias:
      if (type.id == CreatureTypeIds.sexWorker && oneIn(4)) {
        creature.gender = any();
      } else {
        creature.gender = conforming ? Gender.female : any();
      }
    case Gender.maleBias:
      creature.gender = conforming ? Gender.male : any();
  }

  // Gender assigned at birth to match gender expression
  creature.genderAssignedAtBirth = creature.gender;
  // ...UNLESS
  if (creature.isLiberal || canBeTrans) {
    if (creature.gender == Gender.nonbinary) {
      creature.genderAssignedAtBirth = [Gender.male, Gender.female].random;
      creature.cannotDetransition = true;
    } else if (oneIn(20)) {
      creature.cannotDetransition = true;
      if (creature.gender == Gender.male) {
        creature.genderAssignedAtBirth = Gender.female;
      } else {
        creature.genderAssignedAtBirth = Gender.male;
      }
    }
  }
}

void _giveSkills(Creature creature, CreatureType type) {
  for (MapEntry<Skill, (int, int)> entry in type.skillPoints.entries) {
    creature.rawSkill[entry.key] = min(creature.skillCap(entry.key),
        entry.value.$1 + lcsRandom(entry.value.$2 - entry.value.$1 + 1));
  }
  int randomskills = lcsRandom(4) + 4;
  if (creature.age > 20) {
    randomskills += (creature.age - 20.0) ~/ 5.0;
  } else {
    randomskills -= (20 - creature.age) ~/ 2;
  }
  List<Skill> possible = [...Skill.values];
  while (randomskills > 0 && possible.isNotEmpty) {
    int i = lcsRandom(possible.length);
    Skill randomskill = possible[i];
    possible.removeAt(i);
    // 95% chance of not allowing rarer weapon skills on anyone
    if (!oneIn(20)) {
      if (randomskill == Skill.heavyWeapons) continue;
    }
    // 90% chance of not allowing firearms skill on moderates and liberals
    if (!oneIn(10) && creature.align != Alignment.conservative) {
      if (randomskill == Skill.firearms) continue;
    }
    while (creature.skillCap(randomskill) > creature.skill(randomskill)) {
      creature.rawSkill[randomskill] = creature.skill(randomskill) + 1;
      randomskills--;
      if (randomskills <= 0 || lcsRandom(2) == 0) break;
    }
  }
}
