import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';

Map<String, ClothingType> clothingTypes = {};

class ClothingType extends ItemType {
  ClothingType(String id) : super(id) {
    clothingTypes[id] = this;
  }

  int makeDifficulty = 0;
  int makePrice = 0;
  bool deathsquadLegality = false;
  bool canGetBloody = true;
  bool canGetDamaged = true;
  int stealthValue = 0;
  bool coversHead = false;
  bool coversBody = true;
  bool coversArms = true;
  bool coversLegs = true;
  bool concealsFace = false;
  String? _shortName;
  String get shortName => _shortName ?? name;
  set shortName(String value) => _shortName = value;
  String? shortNameFuture;
  String description = "Buggy Armor";
  String? descriptionFuture;
  int interrogationBasePower = 0;
  int interrogationAssaultBonus = 0;
  int interrogationDrugBonus = 0;
  int professionalism = 0;
  int concealWeaponSize = 1;
  bool mask = false;
  bool surpriseMask = false;
  int durability = 1;
  int qualityLevels = 4;
  bool police = false;
  Iterable<WeaponType> get weaponsPermitted =>
      weaponsPermittedIds.map((id) => weaponTypes[id]).nonNulls;
  List<String> weaponsPermittedIds = [];
  bool upgradable = true;
  ArmorUpgrade? get intrinsicArmor => armorUpgrades[intrinsicArmorId];
  String? intrinsicArmorId;
  bool allowVisibleArmor = false;
  Iterable<ArmorUpgrade> get allowedArmor =>
      allowedArmorIds.map((id) => armorUpgrades[id]).nonNulls;
  List<String> allowedArmorIds = [];

  int makeDifficultyFor(Creature cr) =>
      makeDifficulty - cr.rawSkill[Skill.tailoring]! + 3;
}
