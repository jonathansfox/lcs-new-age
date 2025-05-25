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

class CountryName {
  CountryName(this.name, this.shortName, this.capital, this.leader);
  String name;
  String shortName;
  String capital;
  FullName leader;
}

CountryName generateCountryName() {
  String shortName =
      "${countryPrefixes.random}${countryMiddle.random}${countrySuffixes.random}";
  String longName = oneIn(2)
      ? "${countryTitles.random} of $shortName"
      : "$shortName ${countryTitles.random}";
  String capital = switch (lcsRandom(3)) {
    1 => "St. ${lastName()}",
    2 => "${["New", "Green", "Bright", "Fort", "High"].random} "
        "${["Haven", "Hill", "Bridge", "Bull", "Lake"].random}",
    _ => "${countryPrefixes.random}${countrySuffixes.random}",
  };
  FullName leader = generateFullName(Gender.male);
  return CountryName(
    longName,
    shortName,
    capital,
    leader,
  );
}

String generateCompanyName() {
  return "${[
    "Anti", "Dis", "Fore", "Uni", "Sub", "Pre", "Under", "Inter", //
  ].random}${[
    "bolt", "card", "fold", "run", "star", "flow", "wind", "fire", //
  ].random} ${[
    "Industries", "Enterprises", "Holdings", "Group", "International", //
  ].random}";
}
