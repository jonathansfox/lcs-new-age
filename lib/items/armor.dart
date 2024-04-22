import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/items/armor_type.dart';
import 'package:lcs_new_age/items/item.dart';

part 'armor.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Armor extends Item {
  Armor(super.typeName, {super.stackSize}) : super.superConstructor();
  Armor.fromType(ArmorType type, {int quality = 1})
      : _quality = quality,
        super.superConstructor(type.idName);
  factory Armor.fromJson(Map<String, dynamic> json) => _$ArmorFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ArmorToJson(this);

  @JsonKey()
  bool bloody = false;
  @JsonKey()
  bool damaged = false;
  @JsonKey(includeToJson: true, includeFromJson: true, defaultValue: 1)
  int _quality = 1;

  @override
  ArmorType get type => super.type as ArmorType;
  @override
  bool get isArmor => true;
  @override
  bool get isForSale => !bloody && !damaged && fenceValue > 0;
  int get quality => _quality;
  set quality(int value) {
    _quality = value.clamp(1, type.qualityLevels);
  }

  @override
  int get fenceValue {
    if (quality <= type.qualityLevels) {
      return type.fenceValue ~/ quality;
    } else {
      return 0;
    }
  }

  @override
  Armor clone() => Armor(type.idName)
    ..bloody = bloody
    ..damaged = damaged
    ..quality = quality;

  String get shortName => type.shortName;
  String get longName {
    if (quality > type.durability) {
      return "Tattered Rags";
    } else if (damaged) {
      return "${type.name} (d)";
    } else {
      return type.name;
    }
  }

  @override
  String equipTitle({bool full = false}) {
    String et = full ? type.name : type.shortName;
    if (quality > type.qualityLevels) {
      et = "Tattered Rags";
    }
    if ((quality > 1 && quality <= type.qualityLevels) || bloody || damaged) {
      et += "[";
      if (quality > 9) {
        et += "X";
      } else if (quality > 1) {
        et += quality.toString();
      }
      if (bloody) {
        et += "B";
      }
      if (damaged) {
        et += "D";
      }
      et += "]";
    }
    return et;
  }

  @override
  int compareTo(Item other) {
    if (other is! Armor) return super.compareTo(other);
    if (type.idName != other.type.idName) {
      return type.idName.compareTo(other.type.idName);
    }
    if (quality > other.quality) return -1;
    if (quality < other.quality) return 1;
    if (bloody && !other.bloody) return -1;
    if (!bloody && other.bloody) return 1;
    if (damaged && !other.damaged) return -1;
    if (!damaged && other.damaged) return 1;
    return 0;
  }

  bool covers(BodyPart part) {
    if (part.weakSpot) return type.coversHead;
    if (part.critical) return type.coversBody;
    // Technically, this doesn't account for the difference
    // between arms and legs, but that literally only comes
    // up for overalls, which don't cover arms.
    return type.coversArms || type.coversLegs;
  }
}
