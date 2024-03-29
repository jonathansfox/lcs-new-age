import 'package:lcs_new_age/utils/lcsrandom.dart';

enum Gender {
  nonbinary("their", "they", "them", "themselves"),
  male("his", "he", "him", "himself"),
  female("her", "she", "her", "herself"),
  whiteMalePatriarch("his", "he", "him", "himself"),
  maleBias("his", "he", "him", "himself"),
  femaleBias("her", "she", "she", "herself");

  const Gender(this.hisHer, this.heShe, this.himHer, this.himselfHerself);
  final String hisHer;
  String get hisHerCap => hisHer[0].toUpperCase() + hisHer.substring(1);
  final String heShe;
  String get heSheCap => heShe[0].toUpperCase() + heShe.substring(1);
  final String himHer;
  final String himselfHerself;
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
