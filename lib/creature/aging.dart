import 'package:lcs_new_age/creature/attributes.dart';

int ageModifierForAttribute(Attribute attribute, int age) {
  switch (age) {
    case < childAge:
      return childAgeModifiers[attribute]!;
    case < teenAge:
      return teenAgeModifiers[attribute]!;
    case >= middleAge:
      return middleAgeModifiers[attribute]!;
    case >= oldAge:
      return oldAgeModifiers[attribute]!;
    case >= elderlyAge:
      return elderlyAgeModifiers[attribute]!;
    default:
      return 0;
  }
}

const int elderlyAge = 70;
const Map<Attribute, int> elderlyAgeModifiers = {
  Attribute.strength: -6,
  Attribute.agility: -6,
  Attribute.intelligence: 3,
  Attribute.charisma: 3,
  Attribute.wisdom: 2,
  Attribute.heart: 0,
};

const int oldAge = 52;
const Map<Attribute, int> oldAgeModifiers = {
  Attribute.strength: -3,
  Attribute.agility: -3,
  Attribute.intelligence: 2,
  Attribute.charisma: 2,
  Attribute.wisdom: 1,
  Attribute.heart: 0,
};

const int middleAge = 35;
const Map<Attribute, int> middleAgeModifiers = {
  Attribute.strength: -1,
  Attribute.agility: -1,
  Attribute.intelligence: 1,
  Attribute.charisma: 1,
  Attribute.wisdom: 0,
  Attribute.heart: 0,
};

const int teenAge = 16;
const Map<Attribute, int> teenAgeModifiers = {
  Attribute.strength: -1,
  Attribute.agility: 0,
  Attribute.intelligence: -1,
  Attribute.charisma: -1,
  Attribute.wisdom: -1,
  Attribute.heart: 1,
};

const int childAge = 12;
const Map<Attribute, int> childAgeModifiers = {
  Attribute.strength: -3,
  Attribute.agility: 0,
  Attribute.intelligence: -3,
  Attribute.charisma: -2,
  Attribute.wisdom: -2,
  Attribute.heart: 2,
};
