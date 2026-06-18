import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/items/flag_type.dart';
import 'package:lcs_new_age/items/item.dart';

part 'flag.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class Flag extends Item {
  Flag(super.typeName, {super.stackSize}) : super.superConstructor();
  Flag.fromType(FlagType type, {super.stackSize})
      : super.superConstructor(type.idName);
  factory Flag.fromJson(Map<String, dynamic> json) => _$FlagFromJson(json);
  @override
  Map<String, dynamic> toJson() => _$FlagToJson(this);

  @override
  FlagType get type => flagTypes[typeName]!;
  @override
  bool get isFlag => true;
  @override
  bool get isForSale => type.fenceValue > 0;

  @override
  String equipTitle({bool full = false}) => type.shortName;

  @override
  int compareTo(Item other) {
    if (other is! Flag) return super.compareTo(other);
    if (type.idName != other.type.idName) {
      return type.idName.compareTo(other.type.idName);
    }
    return 0;
  }
}
