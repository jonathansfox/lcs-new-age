import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

const int carsPerPage = 18;
Future<void> setVehicles() async {
  if (activeSquad == null) return;
  int page = 0;
  while (true) {
    erase();
    mvaddstrc(0, 0, white, "Choosing the Right Liberal Vehicle");
    printParty(fullParty: true);
    printCars(page);
    setColor(lightGray);
    //PAGE UP
    if (page > 0) {
      addOptionText(17, 1, previousPageStr.split(" ").first, previousPageStr);
    }
    //PAGE DOWN
    if ((page + 1) * carsPerPage < vehiclePool.length) {
      addOptionText(17, 53, nextPageStr.split(" ").first, nextPageStr);
    }

    mvaddstr(18, 1,
        "Press a letter to specify passengers for that Liberal vehicle.");
    mvaddstr(19, 1, "Capitalize the letter to select a driver.");
    mvaddstr(
        20, 1, "Press a number to remove that squad member from a vehicle.");
    mvaddstr(21, 1,
        "Note:  Vehicles in yellow have already been selected by another squad.");
    mvaddstr(22, 1,
        "       Vehicles in red have been selected by both this squad and another.");
    mvaddstr(23, 1,
        "       These cars may be used by both squads but not on the same day.");
    addOptionText(24, 1, "Enter", "Enter - Done");

    String rawKey = await getKeyCaseSensitive();
    int input = rawKey.codePoint;
    int listIndex = input - Key.a;
    int carIndex = listIndex + page * carsPerPage;
    int squadIndex = input - '1'.codePoint;
    if (listIndex >= 0 &&
        listIndex < carsPerPage &&
        carIndex < vehiclePool.length) {
      bool driver = true;
      if (rawKey.codeUnitAt(0) >= Key.a) driver = false;
      int c = 0;
      if (squad.length > 1) {
        mvaddstrc(8, 20, white,
            "Choose a Liberal to ${driver ? "drive it" : "be a passenger"}.");
        c = (await getKey()) - '1'.codePoint;
      }
      if (c >= 0 && c < squad.length) {
        Creature p = squad[c];
        p.preferredCarId = vehiclePool[carIndex].id;
        if (driver) {
          p.preferredDriver = driver;
        } else {
          p.preferredDriver = false;
        }
      }
    } else if (squadIndex >= 0 && squadIndex < squad.length) {
      squad[squadIndex].preferredCarId = null;
      squad[squadIndex].preferredDriver = false;
    } else if (isPageUp(input) && page > 0) {
      page--;
    } else if (isPageDown(input) &&
        (page + 1) * carsPerPage < vehiclePool.length) {
      page++;
    } else if (isBackKey(input)) {
      return;
    }
  }
}

void printCars(int page) {
  int x = 1, y = 10;
  for (int l = page * carsPerPage;
      l < vehiclePool.length && l < page * carsPerPage + carsPerPage;
      l++) {
    bool thisSquad = activeSquad?.members
            .any((p) => p.alive && p.preferredCarId == vehiclePool[l].id) ??
        false;
    bool anotherSquad = pool
        .where((p) => !(activeSquad?.members.contains(p) ?? false))
        .any((p) => p.preferredCarId == vehiclePool[l].id);
    String colorKey = ColorKey.lightGray;
    if (thisSquad && anotherSquad) {
      colorKey = ColorKey.red;
    } else if (anotherSquad) {
      colorKey = ColorKey.yellow;
    } else if (thisSquad) {
      colorKey = ColorKey.lightGreen;
    }

    String key = letterAPlus(l - (page * carsPerPage));
    addOptionText(y, x, key, "$key - ${vehiclePool[l].fullName()}",
        baseColorKey: colorKey);
    x += 26;
    if (x > 53) {
      x = 1;
      y++;
    }
  }
}

/* base - reorder party */
Future<void> orderparty() async {
  activeSquadMemberIndex = -1;

  int partysize = squadsize(activeSquad);

  if (partysize <= 1) return;

  while (true) {
    printParty();
    mvaddstrc(8, 26, white, "Choose squad member to move");

    int oldPos = await getKey();

    if (oldPos < Key.num1 || oldPos > partysize + Key.num1 - 1) {
      return; // User chose index out of range, exit
    }
    makeDelimiter();
    setColor(white);
    String str = "Choose squad member to replace ";
    str += squad[oldPos - Key.num1].name;
    str += " in Spot ${oldPos - Key.num1 + 1}";
    int x = 39 - ((str.length - 1) >> 1);
    if (x < 0) x = 0;
    mvaddstr(8, x, str);

    int newPos = await getKey();

    if (newPos < Key.num1 || newPos > partysize + Key.num1 - 1) {
      return; // User chose index out of range, exit
    }
    squad.swap(oldPos - Key.num1, newPos - Key.num1);
  }
}
