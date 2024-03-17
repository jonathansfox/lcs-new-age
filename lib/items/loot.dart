import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot_type.dart';

part 'loot.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Loot extends Item {
  Loot(super.typeName, {super.stackSize}) : super.superConstructor();
  Loot.fromType(LootType type, {super.stackSize})
      : super.superConstructor(type.idName);
  factory Loot.fromJson(Map<String, dynamic> json) => _$LootFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$LootToJson(this);

  @override
  LootType get type => lootTypes[typeName]!;
  @override
  bool get isLoot => true;
  @override
  bool get isForSale => type.fenceValue > 0;

  @override
  int compareTo(Item other) {
    if (other is! Loot) return super.compareTo(other);
    if (type.idName != other.type.idName) {
      return type.idName.compareTo(other.type.idName);
    }
    return 0;
  }
}
