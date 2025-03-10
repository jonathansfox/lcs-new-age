import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/politics/alignment.dart';

part 'attack.g.dart';

@JsonSerializable()
class Attack {
  Attack();
  factory Attack.fromJson(Map<String, dynamic> json) => _$AttackFromJson(json);
  Map<String, dynamic> toJson() => _$AttackToJson(this);
  int priority = 0;
  bool ranged = false;
  bool thrown = false;
  bool get usesAmmo => cartridge != null;
  List<String> attackDescription = [];
  String hitDescription = "hitting";
  bool alwaysDescribeHit = false;
  bool canBackstab = false;
  String hitPunctuation = "";
  Skill skill = Skill.martialArts;
  String? cartridge;
  int initiative = 0;
  int accuracyBonus = 0;
  int numberOfAttacks = 1;
  int successiveAttacksDifficulty = 0;
  int strengthMin = 0;
  int strengthMax = 0;
  int damage = 0;
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
  int noDamageReductionForLimbsChance = 0;
  Fire? fire;
}

@JsonSerializable()
class Fire {
  Fire();
  factory Fire.fromJson(Map<String, dynamic> json) => _$FireFromJson(json);
  Map<String, dynamic> toJson() => _$FireToJson(this);
  int chance = 0;
  int chanceCausesDebris = 0;
}

enum SeverType {
  none,
  clean,
  nasty,
}
