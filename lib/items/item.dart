import 'package:json_annotation/json_annotation.dart';
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

part 'item.g.dart';

@JsonSerializable(ignoreUnannotated: true, createFactory: false)
class Item implements Comparable<Item> {
  factory Item(String idName, {int stackSize = 1}) {
    ItemType type = itemTypes[idName] ?? itemTypes.values.first;
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
    ItemType? type = itemTypes[json['typeName']];
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

  ItemType get type => itemTypes[typeName]!;

  bool get isWeapon => false;
  bool get isClothing => false;
  bool get isAmmo => false;
  bool get isLoot => false;
  bool get isForSale => type.fenceValue > 0;

  double get fenceValue => type.fenceValue;
  double get stackFenceValue => fenceValue * stackSize;

  String equipTitle({bool full = false}) => type.name;

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
