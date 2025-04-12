/* common - moves all squad members and their cars to a new location */
import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

void locatesquad(Squad squad, Site loc) {
  for (Creature c in squad.members) {
    c.location = loc;
    c.car?.locationId = loc.id;
  }
}

/* common - gives juice to everyone in the active party */
void juiceparty(int juice, int cap) {
  activeSquad?.livingMembers.forEach((c) => addjuice(c, juice, cap));
}

/* common - gives juice to a given creature */
void addjuice(Creature cr, int juice, int cap) {
  // Ignore zero changes
  if (juice == 0) return;

  // Check against cap
  if ((juice > 0 && cr.juice >= cap) || (juice < 0 && cr.juice <= cap)) return;

  // Apply juice gain
  cr.juice += juice;

  // Ensure cap isn't overshot
  if (juice > 0 && cr.juice >= cap) cr.juice = cap;
  if (juice < 0 && cr.juice <= cap) cr.juice = cap;

  // Pyramid scheme of juice trickling up the chain
  Creature? recruiter = pool.firstWhereOrNull((p) => p.id == cr.hireId);
  if (recruiter != null) {
    addjuice(recruiter, (juice / 5).round(), cap);
  }

  // Bounds check
  if (cr.juice > 1000) cr.juice = 1000;
  if (cr.juice < -50) cr.juice = -50;
}

/* common - Displays options to choose from and returns an int corresponding
            to the index of the option in the vector. */
Future<int> choiceprompt(
    String firstline,
    String secondline,
    List<String> option,
    String optiontypename,
    bool allowexitwochoice,
    String exitString) async {
  int page = 0;

  while (true) {
    erase();
    mvaddstrc(0, 0, white, firstline);
    mvaddstrc(1, 0, lightGray, secondline);

    //Write options
    for (int p = page * 19, y = 2;
        p < option.length && p < page * 19 + 19;
        p++, y++) {
      String letter = letterAPlus(y - 2);
      addOptionText(y, 0, letter, "$letter - ${option[p]}");
    }

    setColor(lightGray);
    move(22, 0);
    switch (optiontypename[0]) {
      case 'a':
      case 'e':
      case 'i':
      case 'o':
      case 'u':
      case 'A':
      case 'E':
      case 'I':
      case 'O':
      case 'U':
        addstr("Press a Letter to select an $optiontypename");
      default:
        addstr("Press a Letter to select a $optiontypename");
    }
    move(23, 0);
    addstr(pageStr);
    if (allowexitwochoice) addOptionText(24, 0, "Enter", "Enter - $exitString");

    int c = await getKey();

    //PAGE UP
    if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
      page--;
    }
    //PAGE DOWN
    if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
        (page + 1) * 19 < option.length) {
      page++;
    }

    if (c >= Key.a && c <= Key.s) {
      int p = page * 19 + c - Key.a;
      if (p < option.length) return p;
    }

    if (allowexitwochoice && (isBackKey(c))) break;
  }
  return -1;
}
