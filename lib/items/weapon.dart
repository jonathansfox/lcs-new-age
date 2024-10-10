import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';

part 'weapon.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Weapon extends Item {
  Weapon(super.typeName, {super.stackSize = 1}) : super.superConstructor();
  factory Weapon.fromType(WeaponType type, {bool fullammo = false}) {
    Weapon w = Weapon(type.idName);
    if (fullammo) {
      w.ammo = type.ammoCapacity;
      w.loadedAmmoType = ammoTypes.values.firstWhere(
          (a) => type.attacks.any((attack) => attack.cartridge == a.cartridge));
    }
    return w;
  }

  factory Weapon.fromJson(Map<String, dynamic> json) => _$WeaponFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$WeaponToJson(this);

  @JsonKey()
  int ammo = 0;

  @JsonKey()
  String? loadedAmmoId;

  @override
  WeaponType get type => super.type as WeaponType;
  @override
  bool get isWeapon => true;
  @override
  bool get isForSale => true;

  Skill get skill => type.attack?.skill ?? Skill.martialArts;
  AmmoType? get loadedAmmoType => ammoTypes[loadedAmmoId];
  set loadedAmmoType(AmmoType? value) => loadedAmmoId = value?.idName;
  bool get empty => stackSize <= 0;
  Iterable<String> get acceptableCartridge => type.acceptableCartridge;
  Iterable<AmmoType> get acceptableAmmo => type.acceptableAmmo;

  @override
  Item clone() {
    return Weapon(type.idName)
      ..ammo = ammo
      ..loadedAmmoType = loadedAmmoType;
  }

  String getName({bool sidearm = false}) {
    return (sidearm && type.shortName != "") ? type.shortName : type.name;
  }

  @override
  String equipTitle({bool full = false}) {
    String et = type.name;
    if (ammo > 0) et += " ($ammo)";
    return et;
  }

  bool reload(Ammo magazine) {
    if (acceptableCartridge.contains(magazine.type.cartridge) &&
        (ammo < type.ammoCapacity)) {
      loadedAmmoType = magazine.type;
      //for loose ammo: min(type.ammoCapacity - ammo, magazine.stackSize);
      int load = type.ammoCapacity - ammo;
      ammo += load;
      //for loose ammo: magazine.stackSize -= load;
      magazine.stackSize -= 1;
      return true;
    } else {
      return false;
    }
  }

  Attack? getAttack(bool forceRanged, bool forceMelee, bool forceNoReload,
      {bool allowSocial = false, Alignment? wielderAlignment}) {
    Iterable<Attack> attacks = type.attacks.where((a) =>
        a.alignmentRestriction == null ||
        a.alignmentRestriction == wielderAlignment);
    if (allowSocial && type.attacks.any((a) => a.socialDamage)) {
      return type.attacks.firstWhere((a) => a.socialDamage);
    }
    for (Attack attack in attacks) {
      if (forceRanged && !attack.ranged) continue;
      if (forceMelee && attack.ranged) continue;
      if (forceNoReload && attack.usesAmmo && ammo == 0) continue;
      if (attack.usesAmmo &&
          loadedAmmoType?.cartridge != attack.cartridge &&
          ammo > 0) {
        continue;
      }
      return attack;
    }
    return null;
  }

  @override
  int compareTo(Item other) {
    if (other is! Weapon) return super.compareTo(other);
    if (type.idName != other.type.idName) {
      return type.idName.compareTo(other.type.idName);
    }
    if (ammo < other.ammo) return -1;
    if (ammo > other.ammo) return 1;
    return 0;
  }
}
