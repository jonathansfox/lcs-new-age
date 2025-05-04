import 'package:lcs_new_age/creature/name_lists.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

/// Capitalizes the first letter of a string
String capitalize(String s) => s[0].toUpperCase() + s.substring(1);

/// Generates a monster name by combining various elements
String generateMonsterName() {
  String first;
  final last = monsterLastNames.random;

  int form = lcsRandom(10);
  if (form < 3) {
    first = monsterFirstNames.random;
  } else if (form < 6) {
    first = colors.random;
  } else if (form < 9) {
    first = metals.random;
  } else {
    first = gemstones.random;
  }

  if (form < 3) {
    return "$first ${capitalize(last)}";
  } else if (form < 6) {
    return "$first ${colors.random}$last";
  } else if (form < 9) {
    return "$first ${metals.random}$last";
  } else {
    return "$first ${gemstones.random}$last";
  }
}
