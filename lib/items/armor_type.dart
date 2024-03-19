import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';

Map<String, ArmorType> armorTypes = {};
String maskPrototypeId = "ARMOR_MASK";

class ArmorType extends ItemType {
  ArmorType(String id) : super(id) {
    armorTypes[id] = this;
  }
  factory ArmorType.mask(String id) {
    ArmorType? maskPrototype = armorTypes[maskPrototypeId];
    ArmorType mask = ArmorType(id);
    mask.mask = true;
    mask.concealsFace = maskPrototype?.concealsFace ?? true;
    mask.coversHead = maskPrototype?.coversHead ?? true;
    mask.interrogationAssaultBonus =
        maskPrototype?.interrogationAssaultBonus ?? 4;
    mask.interrogationBasePower = maskPrototype?.interrogationBasePower ?? 4;
    mask.interrogationDrugBonus = maskPrototype?.interrogationDrugBonus ?? 4;
    mask.professionalism = maskPrototype?.professionalism ?? 1;
    mask.stealthValue = maskPrototype?.stealthValue ?? 1;
    mask.qualityLevels = maskPrototype?.qualityLevels ?? 1;
    return mask;
  }

  int makeDifficulty = 0;
  int makePrice = 0;
  bool deathsquadLegality = false;
  bool canGetBloody = true;
  bool canGetDamaged = true;
  int stealthValue = 0;
  int bodyArmor = 0;
  int headArmor = 0;
  int limbArmor = 0;
  bool fireResistant = false;
  bool coversHead = false;
  bool coversBody = false;
  bool coversArms = false;
  bool coversLegs = false;
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
  int concealWeaponSize = 5;
  bool mask = false;
  bool surpriseMask = false;
  int durability = 1;
  int qualityLevels = 4;
  bool police = false;
  Iterable<WeaponType> get weaponsPermitted =>
      weaponsPermittedIds.map((id) => weaponTypes[id]).nonNulls;
  List<String> weaponsPermittedIds = [];

  int makeDifficultyFor(Creature cr) =>
      makeDifficulty - cr.rawSkill[Skill.tailoring]! + 3;
}
