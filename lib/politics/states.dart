import 'package:lcs_new_age/utils/lcsrandom.dart';

class State {
  State(this.name, this.politicalLeaning);
  final String name;
  final int politicalLeaning;
  double rollMood(double baseMood) {
    double leaningMitigaton = 1;
    if (politicalLeaning > 0 && baseMood < 10) {
      leaningMitigaton = 0.75;
      if (baseMood < 5) leaningMitigaton = 0.25;
    }
    if (politicalLeaning < 0 && baseMood > 90) {
      leaningMitigaton = 0.75;
      if (baseMood > 95) leaningMitigaton = 0.25;
    }
    return baseMood +
        politicalLeaning * 4 * leaningMitigaton +
        lcsRandom(3 * politicalLeaning) * leaningMitigaton;
  }
}

final List<State> states = [
  State("Alabama", -6),
  State("Alaska", -3),
  State("Arizona", -2),
  State("Arkansas", -6),
  State("California", 5),
  State("Colorado", 1),
  State("Connecticut", 2),
  State("Delaware", 3),
  State("Florida", -2),
  State("Georgia", -1),
  State("Hawaii", 6),
  State("Idaho", -7),
  State("Illinois", 3),
  State("Indiana", -4),
  State("Iowa", -2),
  State("Kansas", -4),
  State("Kentucky", -5),
  State("Louisiana", -4),
  State("Maine", 1),
  State("Maryland", 5),
  State("Massachusetts", 7),
  State("Michigan", 0),
  State("Minnesota", 0),
  State("Mississippi", -4),
  State("Missouri", -4),
  State("Montana", -4),
  State("Nebraska", -5),
  State("Nevada", -1),
  State("New Hampshire", 0),
  State("New Jersey", 2),
  State("New Mexico", 2),
  State("New York", 4),
  State("North Carolina", -1),
  State("North Dakota", -7),
  State("Ohio", -2),
  State("Oklahoma", -7),
  State("Oregon", 2),
  State("Pennsylvania", 1),
  State("Rhode Island", 5),
  State("South Carolina", -4),
  State("South Dakota", -6),
  State("Tennessee", -6),
  State("Texas", -2),
  State("Utah", -5),
  State("Vermont", 6),
  State("Virginia", 1),
  State("Washington", 2),
  State("West Virginia", -7),
  State("Wisconsin", -1),
  State("Wyoming", -10),
];
