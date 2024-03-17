import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot_type.dart';

part 'money.g.dart';

LootType money = LootType("MONEY")
  ..name = "\$"
  ..isMoney = true
  ..stackable = true;

@JsonSerializable()
class Money extends Item {
  Money([int amount = 1])
      : super.superConstructor(money.idName, stackSize: amount);
  factory Money.fromJson(Map<String, dynamic> json) => _$MoneyFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$MoneyToJson(this);

  @override
  String equipTitle({bool full = false}) {
    return "\$$stackSize";
  }
}
