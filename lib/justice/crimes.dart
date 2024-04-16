import 'package:lcs_new_age/creature/creature.dart';

enum Crime {
  treason("Treason", "treason"),
  terrorism("Terrorism", "terrorism"),
  murder("Murder", "murder"),
  kidnapping("Kidnapping", "kidnapping"),
  bankRobbery("Bank Robbery", "bank robbery"),
  arson("Arson", "arson"),
  flagBurning("Flag Burning", "desecration of the national flag"),
  unlawfulSpeech("Unlawful Speech", "unlawful speech"),
  drugDistribution(
      "Drug Distribution", "distribution of a controlled substance"),
  escapingPrison("Escaping Prison", "escaping from prison"),
  aidingEscape("Releasing Prisoners", "aiding a prison escape"),
  juryTampering("Jury Tampering", "jury tampering"),
  racketeering("Racketeering", "racketeering"),
  extortion("Extortion", "extortion"),
  embezzlement("Embezzlement", "embezzlement"),
  assault("Assault", "assault"),
  grandTheftAuto("Grand Theft Auto", "grand theft auto"),
  theft("Theft", "theft"),
  prostitution("Prostitution", "prostitution"),
  illegalEntry("Illegal Entry", "illegal entry into the United States"),
  harboring("Harboring", "harboring an illegal alien"),
  cyberTerrorism("Digital Terrorism", "breaching national security systems"),
  dataTheft("Digital Theft", "stealing private information"),
  cyberVandalism("Digital Vandalism", "vandalizing computer systems"),
  creditCardFraud("Credit Card Fraud", "credit card fraud"),
  unlawfulBurial("Unlawful Burial", "unlawful burial"),
  breakingAndEntering("Breaking and Entering", "breaking and entering"),
  vandalism("Vandalism", "vandalism"),
  resistingArrest("Resisting Arrest", "resisting arrest"),
  disturbingThePeace("Disturbing the Peace", "disturbing the peace"),
  publicNudity("Public Nudity", "public nudity"),
  loitering("Loitering", "loitering");

  const Crime(this.wantedFor, this.chargedWith);
  final String wantedFor;
  final String chargedWith;
}

void criminalize(Creature creature, Crime crime) {
  creature.criminalize(crime);
}

void criminalizeAll(Iterable<Creature> creatures, Crime crime) {
  for (var creature in creatures) {
    creature.criminalize(crime);
  }
}

int crimeHeat(Crime crime) {
  switch (crime) {
    case Crime.treason:
    case Crime.terrorism:
      return 100;
    case Crime.arson:
    case Crime.racketeering:
    case Crime.escapingPrison:
    case Crime.aidingEscape:
      return 50;
    case Crime.murder:
    case Crime.kidnapping:
    case Crime.bankRobbery:
    case Crime.resistingArrest:
    case Crime.cyberTerrorism:
    case Crime.extortion:
    case Crime.embezzlement:
      return 20;
    case Crime.drugDistribution:
    case Crime.creditCardFraud:
    case Crime.flagBurning:
    case Crime.unlawfulSpeech:
    case Crime.juryTampering:
    case Crime.grandTheftAuto:
      return 5;
    case Crime.harboring:
    case Crime.unlawfulBurial:
    case Crime.breakingAndEntering:
    case Crime.dataTheft:
    case Crime.vandalism:
    case Crime.cyberVandalism:
      return 1;
    case Crime.illegalEntry:
    case Crime.assault:
    case Crime.theft:
    case Crime.prostitution:
    case Crime.publicNudity:
    case Crime.loitering:
    case Crime.disturbingThePeace:
      return 0;
  }
}
