import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';

class Attack {
  int priority = 0;
  bool ranged = false;
  bool thrown = false;
  String? ammoTypeId;
  AmmoType? get ammoType => ammoTypes[ammoTypeId ?? ""];
  bool get usesAmmo => ammoTypeId != null;
  List<String> attackDescription = [];
  String hitDescription = "hitting";
  bool alwaysDescribeHit = false;
  bool canBackstab = false;
  String hitPunctuation = "";
  Skill skill = Skill.firearms;
  int accuracyBonus = 0;
  int numberOfAttacks = 1;
  int successiveAttacksDifficulty = 0;
  int strengthMin = 0;
  int strengthMax = 0;
  int randomDamage = 0;
  int fixedDamage = 0;
  int get averageDamage => fixedDamage + (randomDamage / 2).round();
  bool socialDamage = false;
  bool bruises = false;
  bool cuts = false;
  bool tears = false;
  bool burns = false;
  bool shoots = false;
  bool bleeds = false;
  bool stuns = false;
  Alignment? alignmentRestriction;
  SeverType severType = SeverType.none;
  bool damagesArmor = false;
  int armorPenetration = 0;
  int noDamageReductionForLimbsChance = 0;
  Critical? critical;
  Fire? fire;
}

class Critical {
  int chance = 0;
  int hitsRequired = 0;
  int? randomDamage;
  int? fixedDamage;
  SeverType? severType;
}

class Fire {
  int chance = 0;
  int chanceCausesDebris = 0;
}

enum SeverType {
  none,
  clean,
  nasty,
}
