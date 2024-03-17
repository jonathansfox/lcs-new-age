import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/item.dart';

part 'ammo.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Ammo extends Item {
  Ammo(super.typeName, {super.stackSize}) : super.superConstructor();
  factory Ammo.fromJson(Map<String, dynamic> json) => _$AmmoFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$AmmoToJson(this);

  @override
  AmmoType get type => super.type as AmmoType;
  @override
  bool get isAmmo => true;
  @override
  bool get isForSale => type.fenceValue > 0;

  @override
  int compareTo(Item other) {
    if (other is! Ammo) return super.compareTo(other);
    if (type.idName != other.type.idName) {
      return type.idName.compareTo(other.type.idName);
    }
    return 0;
  }
}
