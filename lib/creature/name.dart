import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name_lists.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'name.g.dart';

@JsonSerializable()
class FullName {
  FullName(this.first, this.middle, this.last, this.gender);
  factory FullName.fromJson(Map<String, dynamic> json) =>
      _$FullNameFromJson(json);
  Map<String, dynamic> toJson() => _$FullNameToJson(this);
  String first;
  String middle;
  String last;
  @JsonKey(defaultValue: Gender.nonbinary)
  Gender gender;

  @override
  String toString() => "$first $middle $last";

  String get firstLast => "$first $last";
}

FullName generateFullName([Gender gender = Gender.nonbinary]) {
  gender = forceGenderBinary(gender);
  return FullName(
      firstName(gender), firstName(gender), lastName(gender), gender);
}

String lastName([Gender gender = Gender.nonbinary]) {
  if (gender == Gender.whiteMalePatriarch) {
    return archconservativeLastNames.random;
  } else {
    return lastNames.random;
  }
}

String firstName([Gender gender = Gender.nonbinary, bool forceBinary = true]) {
  if (forceBinary) {
    gender = forceGenderBinary(gender);
  }
  switch (gender) {
    case Gender.whiteMalePatriarch:
      return whiteMalePatriarchFirstNames.random;
    case Gender.male:
      return maleFirstNames.followedBy(genderNeutralFirstNames).random;
    case Gender.female:
      return femaleFirstNames.followedBy(genderNeutralFirstNames).random;
    default:
      return genderNeutralFirstNames.random;
  }
}
