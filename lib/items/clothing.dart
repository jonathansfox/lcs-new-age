import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/body.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/item.dart';

part 'clothing.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Clothing extends Item {
  Clothing(super.typeName, {super.stackSize, this.armorId})
      : super.superConstructor();
  Clothing.fromType(ClothingType type, {int quality = 1})
      : _quality = quality,
        super.superConstructor(type.idName);
  factory Clothing.fromJson(Map<String, dynamic> json) =>
      _$ClothingFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$ClothingToJson(this);

  @JsonKey()
  bool bloody = false;
  @JsonKey(
      includeToJson: true,
      includeFromJson: true,
      defaultValue: false,
      name: "damaged")
  bool _damaged = false;
  bool get damaged =>
      _damaged ||
      bodyArmor < (armor?.bodyArmor ?? 0) ||
      headArmor < (armor?.headArmor ?? 0) ||
      _limbArmor.values.any((a) => a < (armor?.limbArmor ?? 0));
  set damaged(bool value) {
    if (!value) {
      bodyArmor = armor?.bodyArmor ?? 0;
      headArmor = armor?.headArmor ?? 0;
      _limbArmor = {};
    }
    _damaged = value;
  }

  @JsonKey(includeToJson: true, includeFromJson: true, defaultValue: 1)
  int _quality = 1;

  @override
  ClothingType get type => super.type as ClothingType;
  @override
  bool get isClothing => true;
  @override
  bool get isForSale => !bloody && !damaged && fenceValue > 0;
  int get quality => _quality;
  set quality(int value) {
    _quality = value.clamp(1, type.qualityLevels);
  }

  @JsonKey()
  String? armorId;
  ArmorUpgrade? get armor => armorUpgrades[armorId];
  set armor(ArmorUpgrade? value) {
    armorId = value?.name ?? "";
  }

  bool get fireResistant => armor?.fireResistant ?? false;

  @JsonKey(defaultValue: 0)
  int bodyArmor = 0;
  @JsonKey(defaultValue: 0)
  int headArmor = 0;
  @JsonKey(includeToJson: true, includeFromJson: true, defaultValue: {})
  Map<String, int> _limbArmor = {};

  int getLimbArmor(BodyPart part) =>
      _limbArmor[part.name] ?? armor?.limbArmor ?? 0;
  void setLimbArmor(BodyPart part, int value) {
    _limbArmor[part.name] = value;
  }

  int getArmorForLocation(BodyPart part) {
    if (part.weakSpot) return headArmor;
    if (part.critical) return bodyArmor;
    return getLimbArmor(part);
  }

  void damageArmorInLocation(BodyPart part, int damage) {
    if (part.weakSpot) {
      headArmor = (headArmor - damage).clamp(0, headArmor);
    } else if (part.critical) {
      bodyArmor = (bodyArmor - damage).clamp(0, bodyArmor);
    } else {
      int currentArmor = getLimbArmor(part);
      setLimbArmor(part, (currentArmor - damage).clamp(0, currentArmor));
    }
    damaged = true;
  }

  @override
  double get fenceValue {
    if (quality <= type.qualityLevels) {
      return type.fenceValue / quality;
    } else {
      return 0;
    }
  }

  @override
  Clothing clone() => Clothing(type.idName)
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
    if (other is! Clothing) return super.compareTo(other);
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
    if (part.weakSpot) return type.coversHead || headArmor > 0;
    if (part.critical) return type.coversBody || bodyArmor > 0;
    // Technically, this doesn't account for the difference
    // between arms and legs, but that literally only comes
    // up for overalls, which don't cover arms.
    if (type.coversArms || type.coversLegs) return true;
    return getLimbArmor(part) > 0;
  }
}
