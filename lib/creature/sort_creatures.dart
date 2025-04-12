import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

enum CreatureSortMethod {
  none,
  name,
  locationAndName,
  squadOrName,
}

enum SortingScreens {
  liberals,
  hostages,
  clinic,
  justice,
  sleepers,
  dead,
  away,
  activateRegulars,
  activateSleepers,
  assembleSquad,
  baseAssignment;

  String get description {
    return switch (this) {
      SortingScreens.liberals => "active Liberals",
      SortingScreens.hostages => "hostages",
      SortingScreens.clinic => "Liberals in treatment",
      SortingScreens.justice => "oppressed Liberals",
      SortingScreens.sleepers => "sleeper agents",
      SortingScreens.dead => "the deceased",
      SortingScreens.away => "people away",
      SortingScreens.activateRegulars => "Liberal activity",
      SortingScreens.activateSleepers => "sleeper activity",
      SortingScreens.assembleSquad => "available Liberals",
      SortingScreens.baseAssignment => "squadless members",
    };
  }
}

int Function(Creature a, Creature b) creatureSortFunction(
    CreatureSortMethod method) {
  switch (method) {
    case CreatureSortMethod.none:
      return (a, b) => 0;
    case CreatureSortMethod.name:
      return (a, b) => a.name.compareTo(b.name);
    case CreatureSortMethod.locationAndName:
      return (a, b) => (a.locationId ?? "").compareTo(b.locationId ?? "");
    case CreatureSortMethod.squadOrName:
      return (a, b) {
        int squadComparison = (a.squadId ?? double.maxFinite)
            .compareTo(b.squadId ?? double.maxFinite);
        if (squadComparison != 0) return squadComparison;
        return a.name.compareTo(b.name);
      };
  }
}

/* common - Prompt to decide how to sort liberals.*/
Future<void> sortingPrompt(SortingScreens sortScreen) async {
  erase();
  move(1, 1);
  setColor(lightGray);
  addstr("Choose how to sort the list of ${sortScreen.description}.");
  addOptionText(3, 2, "A", "A - No sorting.");
  addOptionText(4, 2, "B", "B - Sort by name.");
  addOptionText(5, 2, "C", "C - Sort by location and name.");
  addOptionText(6, 2, "D", "D - Sort by squad or name.");

  while (true) {
    int c = await getKey();

    if (c == Key.a) {
      activeSortingChoice[sortScreen] = CreatureSortMethod.none;
      break;
    } else if (c == Key.b) {
      activeSortingChoice[sortScreen] = CreatureSortMethod.name;
      break;
    } else if (c == Key.c) {
      activeSortingChoice[sortScreen] = CreatureSortMethod.locationAndName;
      break;
    } else if (c == Key.d) {
      activeSortingChoice[sortScreen] = CreatureSortMethod.squadOrName;
      break;
    } else if (c == Key.x || isBackKey(c)) {
      break;
    }
  }
}

void sortLiberals(List<Creature> liberals, SortingScreens screen) {
  liberals.sort(creatureSortFunction(
      activeSortingChoice[screen] ?? CreatureSortMethod.none));
}
