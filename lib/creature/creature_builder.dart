/* ensures that the creature's work location is appropriate to its type */
import 'package:lcs_new_age/creature/attributes.dart';
import 'package:lcs_new_age/creature/conversion.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/creature_work_locations.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/hardcoded_creature_type_stuff.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/armor.dart';
import 'package:lcs_new_age/items/armor_type.dart';
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

  applyHardcodedCreatureTypeStuff(creature, type);

  // Convert to Conservative if alienated
  if ((siteAlienated != SiteAlienation.none &&
          creature.align == Alignment.moderate) ||
      (siteAlienated == SiteAlienation.alienatedEveryone &&
          creature.align == Alignment.liberal)) {
    conservatize(creature);
  }

  return creature;
}

void _giveAttributes(Creature creature, CreatureType type) {
  for (Attribute attribute in Attribute.values) {
    if (attribute == Attribute.wisdom) continue;
    if (attribute == Attribute.heart) {
      if (creature.align == Alignment.liberal) {
        List<int> pool = _6d3pool();
        creature.rawAttributes[Attribute.heart] = _highest3(pool);
        creature.rawAttributes[Attribute.wisdom] = _lowest3(pool);
      } else if (creature.align == Alignment.conservative) {
        List<int> pool = _6d3pool();
        creature.rawAttributes[Attribute.heart] = _lowest3(pool);
        creature.rawAttributes[Attribute.wisdom] = _highest3(pool);
      } else {
        creature.rawAttributes[Attribute.heart] = _5d3dropExtremes();
        creature.rawAttributes[Attribute.wisdom] = _5d3dropExtremes();
      }
    } else {
      creature.rawAttributes[attribute] = _3d3();
    }
  }
  for (int i = 0; i < type.extraAttributePoints; i++) {}
}

void _giveEquipment(Creature creature, CreatureType type) {
  ArmorType? armorType = type.randomArmor;
  if (armorType != null) creature.equippedArmor = Armor(armorType.idName);
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
  Gender any() {
    if (creature.isLiberal && oneIn(20)) {
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
      creature.gender = conforming ? Gender.female : any();
    case Gender.maleBias:
      creature.gender = conforming ? Gender.male : any();
  }

  // Gender assigned at birth to match gender expression
  creature.genderAssignedAtBirth = creature.gender;
  // ...UNLESS
  if (creature.isLiberal) {
    if (creature.gender == Gender.nonbinary) {
      creature.genderAssignedAtBirth = [Gender.male, Gender.female].random;
    } else if (oneIn(20)) {
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
    creature.rawSkill[entry.key] = entry.value.$1 + lcsRandom(entry.value.$2);
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

// ignore: non_constant_identifier_names
int _3d3() {
  return lcsRandom(3) + lcsRandom(3) + lcsRandom(3) + 3;
}

// ignore: non_constant_identifier_names
List<int> _6d3pool() {
  return [for (int i = 0; i < 6; i++) lcsRandom(3) + 1]..sort();
}

int _lowest3(List<int> pool) {
  return pool[0] + pool[1] + pool[2];
}

int _highest3(List<int> pool) {
  int pl = pool.length;
  return pool[pl - 1] + pool[pl - 2] + pool[pl - 3];
}

// ignore: non_constant_identifier_names
int _5d3dropExtremes() {
  List<int> rolls = [for (int i = 0; i < 5; i++) lcsRandom(3) + 1];
  rolls.sort();
  return rolls[1] + rolls[2] + rolls[3];
}
