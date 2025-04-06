import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';

part 'weapon.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Weapon extends Item {
  Weapon(super.typeName, {super.stackSize = 1}) : super.superConstructor();
  factory Weapon.fromType(WeaponType type, {bool fullammo = false}) {
    Weapon w = Weapon(type.idName);
    if (fullammo && type.usesAmmo && type.ammoCapacity > 0) {
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

  String getName({bool sidearm = false, bool primary = false}) {
    if (primary) return type.largeSubtypeName ?? type.name;
    if (sidearm) return type.smallSubtypeShortName ?? type.shortName;
    return type.name;
  }

  @override
  String equipTitle({bool full = false}) {
    String et = type.name;
    if (ammo > 0) et += " ($ammo)";
    return et;
  }

  bool reload(Ammo magazine) {
    int capacity = type.ammoCapacity;
    if (type.canKeepOneInTheChamber && ammo > 0) capacity++;
    if (acceptableCartridge.contains(magazine.type.cartridge) &&
        ammo < capacity) {
      loadedAmmoType = magazine.type;
      // +1 capacity if there's an extra bullet chambered outside the magazine
      int load = min(capacity - ammo, magazine.stackSize);
      magazine.stackSize -= load;
      ammo += load;
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
      if (attack.usesAmmo) {
        //attack = attack.();
        attack.damage = loadedAmmoType?.damage ?? attack.damage;
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

  bool get isAGun => type.isAGun;
  bool get isCurrentlyLegal {
    return (type.bannedAtGunControl?.index ?? 99) > laws[Law.gunControl]!.index;
  }
}
