import 'package:lcs_new_age/creature/attributes.dart';

int ageModifierForAttribute(Attribute attribute, int age) {
  if (age < childAge) return childAgeModifiers[attribute]!;
  if (age < teenAge) return teenAgeModifiers[attribute]!;
  if (age > elderlyAge) return elderlyAgeModifiers[attribute]!;
  if (age > oldAge) return oldAgeModifiers[attribute]!;
  if (age > middleAge) return middleAgeModifiers[attribute]!;
  return 0;
}

// older age damages base health using a different mechanism and should not
// modify health in this table
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

const int middleAge = 52;
const Map<Attribute, int> middleAgeModifiers = {
  Attribute.strength: -1,
  Attribute.agility: -1,
  Attribute.intelligence: 1,
  Attribute.charisma: 1,
  Attribute.wisdom: 0,
  Attribute.heart: 0,
};

// younger ages are allowed to modify health
const int teenAge = 16;
const Map<Attribute, int> teenAgeModifiers = {
  Attribute.strength: -1,
  Attribute.agility: 0,
  Attribute.intelligence: -1,
  Attribute.charisma: -1,
  Attribute.wisdom: -1,
  Attribute.heart: 1,
};

const int childAge = 16;
const Map<Attribute, int> childAgeModifiers = {
  Attribute.strength: -3,
  Attribute.agility: 0,
  Attribute.intelligence: -3,
  Attribute.charisma: -2,
  Attribute.wisdom: -2,
  Attribute.heart: 2,
};
