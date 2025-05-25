import 'package:lcs_new_age/utils/lcsrandom.dart';

enum Gender {
  nonbinary("their", "they", "them", "themselves", "", "friend"),
  male("his", "he", "him", "himself", "s", "man"),
  female("her", "she", "her", "herself", "s", "woman"),
  whiteMalePatriarch("his", "he", "him", "himself", "s", "man"),
  maleBias("his", "he", "him", "himself", "s", "man"),
  femaleBias("her", "she", "she", "herself", "s", "woman");

  const Gender(this.hisHer, this.heShe, this.himHer, this.himselfHerself,
      this.s, this.manWoman);
  final String hisHer;
  String get hisHerCap => hisHer[0].toUpperCase() + hisHer.substring(1);
  final String heShe;
  String get heSheCap => heShe[0].toUpperCase() + heShe.substring(1);
  final String himHer;
  final String himselfHerself;
  final String s;
  final String manWoman;

  Gender get simplified {
    return switch (this) {
      Gender.nonbinary => Gender.nonbinary,
      Gender.male ||
      Gender.maleBias ||
      Gender.whiteMalePatriarch =>
        Gender.male,
      Gender.female || Gender.femaleBias => Gender.female,
    };
  }
}

Gender forceGenderBinary(Gender gender) {
  if (gender == Gender.nonbinary) {
    if (lcsRandom(2) > 0) {
      gender = Gender.male;
    } else {
      gender = Gender.female;
    }
  }
  if (gender == Gender.maleBias) {
    if (lcsRandom(4) > 0) {
      gender = Gender.male;
    } else {
      gender = Gender.female;
    }
  }
  if (gender == Gender.femaleBias) {
    if (lcsRandom(4) > 0) {
      gender = Gender.female;
    } else {
      gender = Gender.male;
    }
  }
  return gender;
}
