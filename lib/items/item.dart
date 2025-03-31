import 'dart:ui';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/items/money.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/utils/colors.dart';

part 'item.g.dart';

@JsonSerializable(ignoreUnannotated: true, createFactory: false)
class Item implements Comparable<Item> {
  factory Item(String idName, {int stackSize = 1}) {
    ItemType type = itemTypes[idName] ??
        itemTypes[mapOutdatedItem(idName)] ??
        itemTypes.values.first;
    if (type is WeaponType) {
      return Weapon(type.idName);
    } else if (type is ClothingType) {
      return Clothing(type.idName);
    } else if (type is AmmoType) {
      return Ammo(type.idName);
    } else if (type is LootType) {
      return Loot(type.idName);
    } else if (type.isMoney) {
      return Money(1);
    } else {
      debugPrint("Item constructor: Unknown item type: $idName");
      return Item.superConstructor(type.idName);
    }
  }
  Item.superConstructor(this.typeName, {this.stackSize = 1});
  factory Item.fromJson(Map<String, dynamic> json) {
    ItemType? type = itemTypes[json['typeName']] ??
        itemTypes[mapOutdatedItem(json['typeName'])];
    if (type is WeaponType) {
      return Weapon.fromJson(json);
    } else if (type is ClothingType) {
      return Clothing.fromJson(json);
    } else if (type is AmmoType) {
      return Ammo.fromJson(json);
    } else if (type is LootType) {
      return Loot.fromJson(json);
    } else if (type?.isMoney == true) {
      return Money.fromJson(json);
    } else {
      debugPrint("Item.fromJson: Unknown item type: ${json['typeName']}");
      return Item(json['typeName'])..stackSize = json['stackSize'];
    }
  }
  Map<String, dynamic> toJson() => _$ItemToJson(this);
  @JsonKey()
  int stackSize = 1;
  @JsonKey()
  String typeName;

  ItemType get type =>
      itemTypes[typeName] ?? itemTypes[mapOutdatedItem(typeName)]!;

  bool get isWeapon => false;
  bool get isClothing => false;
  bool get isAmmo => false;
  bool get isLoot => false;
  bool get isForSale => type.fenceValue > 0;

  double get fenceValue => type.fenceValue;
  double get stackFenceValue => fenceValue * stackSize;

  String equipTitle({bool full = false}) => type.name;
  void printEquipTitle({bool full = false, Color baseColor = lightGray}) =>
      addstrc(baseColor, equipTitle());

  Item clone() => Item(type.idName)..stackSize = stackSize;

  Item split(int amountToSplit) {
    if (amountToSplit > stackSize) amountToSplit = stackSize;
    Item newItem = clone()..stackSize = amountToSplit;
    stackSize -= amountToSplit;
    return newItem;
  }

  void merge(Item other) {
    if (compareTo(other) != 0) return;
    stackSize += other.stackSize;
    other.stackSize = 0;
  }

  @override
  int compareTo(Item other) {
    if (isWeapon && !other.isWeapon) return -1;
    if (!isWeapon && other.isWeapon) return 1;
    if (isClothing && !other.isClothing) return -1;
    if (!isClothing && other.isClothing) return 1;
    if (isAmmo && !other.isAmmo) return -1;
    if (!isAmmo && other.isAmmo) return 1;
    if (isLoot && !other.isLoot) return -1;
    if (!isLoot && other.isLoot) return 1;
    return 0;
  }
}

String mapOutdatedItem(String typename) {
  switch (typename) {
    case "WEAPON_BITE":
      return "WEAPON_NONE";
    case "OUTFIT_BLACKBLOC":
      return "CLOTHING_BLACKBLOC";
    case "ARMOR_MASK":
      return "CLOTHING_CLOTHES";
    case "WEAPON_REVOLVER_38":
      return "WEAPON_22_REVOLVER";
    case "WEAPON_REVOLVER_44":
      return "WEAPON_44_REVOLVER";
    case "WEAPON_SEMIPISTOL_45":
      return "WEAPON_45_HANDGUN";
    case "WEAPON_SEMIPISTOL_9MM":
      return "WEAPON_9MM_HANDGUN";
    case "WEAPON_SHOTGUN_AA12":
      return "WEAPON_AA12";
    case "WEAPON_AUTORIFLE_AK47":
      return "WEAPON_AK102";
    case "WEAPON_SEMIRIFLE_AR15":
      return "WEAPON_AR15";
    case "WEAPON_CARBINE_M4":
    case "WEAPON_AUTORIFLE_M16":
      return "WEAPON_M4";
    case "WEAPON_M249_MACHINEGUN":
      return "WEAPON_M250_MACHINEGUN";
    case "CLIP_38":
      return "AMMO_22";
    case "CLIP_44":
      return "AMMO_44";
    case "CLIP_45":
      return "AMMO_45";
    case "CLIP_9":
    case "CLIP_SMG":
      return "AMMO_9MM";
    case "CLIP_50AE":
      return "AMMO_50AE";
    case "CLIP_BUCKSHOT":
      return "AMMO_BUCKSHOT";
    case "CLIP_ASSAULT":
      return "AMMO_556";
    case "CLIP_GASOLINE":
      return "AMMO_GASOLINE";
    case "CLIP_DRUM":
      return "AMMO_68";
    default:
      if (typename.contains("ARMOR_")) {
        if (itemTypes.containsKey(typename.replaceFirst("ARMOR", "CLOTHING"))) {
          return typename.replaceFirst("ARMOR", "CLOTHING");
        } else {
          return "CLOTHING_CLOTHES";
        }
      }
      if (typename.contains("WEAPON_")) {
        return "WEAPON_9MM_HANDGUN";
      }
      if (typename.contains("CLIP_")) {
        return "AMMO_9MM";
      }
      debugPrint("UNKNOWN ITEM TYPE: $typename");
      return "CLOTHING_CLOTHES";
  }
}
