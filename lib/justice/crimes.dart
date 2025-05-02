import 'package:collection/collection.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';

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

class CrimeData {
  CrimeData({
    required this.crime,
    required this.perpetrators,
    required this.key,
  });

  final Crime crime;
  final String key;
  final List<Creature> perpetrators;
}

void criminalize(Creature creature, Crime crime, {double heatMultiplier = 1}) {
  creature.criminalize(crime, heatMultiplier: heatMultiplier);
}

void addPotentialCrime(Iterable<Creature> creatures, Crime crime,
    {String reasonKey = ""}) {
  CrimeData crimeData = CrimeData(
    crime: crime,
    perpetrators: creatures.toList(),
    key: reasonKey,
  );
  if (crimeData.key != "") {
    // Check if the crime already added to the list
    if (gameState.potentialCrimes
        .any((c) => c.crime == crimeData.crime && c.key == crimeData.key)) {
      // If it exists, update the perpetrators list to include the new ones
      List<Creature> perpetrators = gameState.potentialCrimes
          .firstWhere(
              (c) => c.crime == crimeData.crime && c.key == crimeData.key)
          .perpetrators
          .toList();
      bool add = false;
      for (var creature in creatures) {
        if (!perpetrators.contains(creature)) {
          perpetrators.add(creature);
          add = true;
        }
      }
      if (!add) return;
      // Remove the old crime data and add the new one with updated perpetrators
      gameState.potentialCrimes.removeWhere(
          (c) => c.crime == crimeData.crime && c.key == crimeData.key);
      gameState.potentialCrimes.add(CrimeData(
          crime: crimeData.crime,
          perpetrators: perpetrators,
          key: crimeData.key));
      return;
    }
  }
  gameState.potentialCrimes.add(crimeData);
}

void clearPotentialCrimes() {
  gameState.potentialCrimes.clear();
}

void commitPotentialCrimes() {
  // Iterate through all potential crimes and criminalize the perpetrators
  Set<Creature> allPerpetrators = gameState.potentialCrimes
      .expand((crimeData) => crimeData.perpetrators)
      .sortedByCompare((c) => c.id, (a, b) => a.compareTo(b))
      .toSet();
  int murderCounts =
      gameState.potentialCrimes.where((c) => c.crime == Crime.murder).length;
  int assaultCounts =
      gameState.potentialCrimes.where((c) => c.crime == Crime.assault).length;
  int kidnappingCounts = gameState.potentialCrimes
      .where((c) => c.crime == Crime.kidnapping)
      .length;
  int terrorismCounts =
      gameState.potentialCrimes.where((c) => c.crime == Crime.terrorism).length;
  int violenceScore =
      murderCounts + (assaultCounts - murderCounts) ~/ 3 + kidnappingCounts * 2;
  if (violenceScore > 5 && terrorismCounts < 1) {
    // Charge with terrorism if you did a bunch of terrorizing
    criminalizeAll(allPerpetrators, Crime.terrorism);
  }
  for (var crimeData in gameState.potentialCrimes) {
    for (var creature in crimeData.perpetrators) {
      creature.criminalize(crimeData.crime);
    }
  }
  gameState.potentialCrimes.clear();
}

void criminalizeAll(Iterable<Creature> creatures, Crime crime,
    {bool splitHeat = false}) {
  for (var creature in creatures) {
    creature.criminalize(crime,
        heatMultiplier: splitHeat ? 1 / creatures.length : 1);
  }
}

int crimeHeat(Crime crime) {
  switch (crime) {
    case Crime.treason:
    case Crime.terrorism:
      return 100;
    case Crime.racketeering:
      return 50;
    case Crime.arson:
    case Crime.escapingPrison:
    case Crime.aidingEscape:
    case Crime.cyberTerrorism:
      return 20;
    case Crime.murder:
    case Crime.kidnapping:
    case Crime.bankRobbery:
    case Crime.extortion:
    case Crime.embezzlement:
    case Crime.grandTheftAuto:
    case Crime.creditCardFraud:
    case Crime.dataTheft:
      return 5;
    case Crime.unlawfulBurial:
    case Crime.resistingArrest:
    case Crime.drugDistribution:
      return 1;
    case Crime.harboring:
    case Crime.breakingAndEntering:
    case Crime.juryTampering:
    case Crime.cyberVandalism:
    case Crime.vandalism:
    case Crime.illegalEntry:
    case Crime.assault:
    case Crime.theft:
    case Crime.prostitution:
    case Crime.publicNudity:
    case Crime.loitering:
    case Crime.disturbingThePeace:
      return 0;
    case Crime.flagBurning:
      switch (laws[Law.flagBurning]) {
        case DeepAlignment.archConservative:
          return 5;
        case DeepAlignment.conservative:
          return 1;
        default:
          return 0;
      }
    case Crime.unlawfulSpeech:
      switch (laws[Law.freeSpeech]) {
        case DeepAlignment.archConservative:
          return 5;
        case DeepAlignment.conservative:
          return 1;
        default:
          return 0;
      }
  }
}
