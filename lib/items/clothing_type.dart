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

  int makeDifficulty = -1;
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
  bool alarming = false;
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
  Iterable<ArmorUpgrade> get allowedArmor {
    List<ArmorUpgrade> armors = [];
    if (intrinsicArmorId != null) {
      armors.add(armorUpgrades[intrinsicArmorId]!);
    } else {
      armors.add(armorUpgrades.values.first);
    }
    armors.addAll(allowedArmorIds
        .map((id) => armorUpgrades[id]!)
        .where((a) => !armors.contains(a)));
    if (upgradable && intrinsicArmorId == null) {
      if (allowVisibleArmor) {
        armors.addAll(armorUpgrades.values
            .where((a) => a.visible && !a.restricted && !armors.contains(a)));
      }
      armors.addAll(armorUpgrades.values
          .where((a) => !a.visible && !a.restricted && !armors.contains(a)));
      if (!allowVisibleArmor) {
        armors.addAll(armorUpgrades.values
            .where((a) => a.visible && !a.restricted && !armors.contains(a)));
      }
    }
    return armors;
  }

  List<String> allowedArmorIds = [];

  List<String> traitsList(bool includeArmor,
      {ArmorUpgrade? specifiedArmorUpgrade}) {
    List<String> traits = [];
    specifiedArmorUpgrade ??= intrinsicArmor;
    if (concealsFace) {
      traits.add("Hides Face");
    }
    if (stealthValue > 1 &&
        (allowVisibleArmor || (specifiedArmorUpgrade?.visible != true))) {
      if (stealthValue == 2) {
        traits.add("Sneaky");
      } else {
        traits.add("Very Sneaky");
      }
    }
    if (includeArmor && (specifiedArmorUpgrade?.bodyArmor ?? 0) > 0) {
      traits.add("Armor [${specifiedArmorUpgrade!.bodyArmor}]");
    }
    if (specifiedArmorUpgrade?.fireResistant ?? false) {
      traits.add("Fire Resistant");
    }
    if (concealWeaponSize >= 3) {
      traits.add("Hammerspace");
    } else if (concealWeaponSize == 2) {
      traits.add("Spacious");
    } else if (concealWeaponSize == 0) {
      traits.add("No Pockets");
    }
    return traits;
  }

  int makeDifficultyFor(Creature cr, ArmorUpgrade armor) =>
      makeDifficulty + armor.makeDifficulty - cr.skill(Skill.tailoring) + 4;
}
