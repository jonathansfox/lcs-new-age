/* base - activate sleepers */
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/sort_creatures.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

Future<void> activateSleepers() async {
  // Comb the pool of Liberals for sleeper agents that can work
  List<Creature> temppool = pool
      .where((p) =>
          p.alive &&
          p.sleeperAgent &&
          p.align == Alignment.liberal &&
          !p.inHiding &&
          p.clinicMonthsLeft == 0 &&
          p.vacationDaysLeft == 0)
      .toList();

  if (temppool.isEmpty) return;

  sortLiberals(temppool, SortingScreens.activateSleepers);

  int page = 0;

  while (true) {
    erase();

    setColor(lightGray);
    printFunds();

    mvaddstr(0, 0, "Activate Sleeper Agents");
    makeDelimiter(y: 1);
    mvaddstr(1, 4, "CODE NAME");
    mvaddstr(1, 24, "JOB");
    mvaddstr(1, 42, "SITE");
    mvaddstr(1, 58, "ACTIVITY");

    int y = 2;
    for (Creature tempp in temppool.skip(page * 9).take(9)) {
      setColor(lightGray);
      String letter = letterAPlus((y - 2) ~/ 2);
      addOptionText(y, 0, letter, "$letter - ${tempp.name}");

      mvaddstr(y, 24, tempp.type.name);

      mvaddstr(y + 1, 6, "Effectiveness: ");

      if (tempp.infiltration > 0.8) {
        setColor(red);
      } else if (tempp.infiltration > 0.6) {
        setColor(purple);
      } else if (tempp.infiltration > 0.4) {
        setColor(yellow);
      } else if (tempp.infiltration > 0.2) {
        setColor(white);
      } else if (tempp.infiltration > 0.1) {
        setColor(lightGray);
      } else {
        setColor(green);
      }
      addstr("${(tempp.infiltration * 100).ceil()}%");

      mvaddstrc(y, 42, lightGray,
          tempp.workLocation.getName(short: true, includeCity: true));

      move(y, 58);
      setColor(tempp.activity.type.color);
      addstr(tempp.activity.type.label);
      y += 2;
    }

    mvaddstrc(22, 0, lightGray, "Press a Letter to Assign an Activity.");
    move(23, 0);
    addstr(pageStr);
    addstr(" T to sort people.");

    setColor(lightGray);

    int c = await getKey();

    //PAGE UP
    if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
      page--;
    }
    //PAGE DOWN
    if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
        (page + 1) * 9 < temppool.length) {
      page++;
    }

    if (c >= Key.a && c <= Key.s) {
      int p = page * 9 + c - Key.a;
      if (p < temppool.length) {
        await activateSleeper(temppool.elementAt(p));
      }
    }

    if (c == Key.t) {
      await sortingPrompt(SortingScreens.activateSleepers);
      sortLiberals(temppool, SortingScreens.activateSleepers);
    }

    if (isBackKey(c)) break;
  }
}

Future<void> activateSleeper(Creature cr) async {
  int state = 0, choice = 0;

  while (true) {
    erase();

    setColor(lightGray);
    printFunds();

    mvaddstr(0, 0, "Taking Undercover Action:   What will ");
    addstr(cr.name);
    addstr(" focus on?");

    printCreatureInfo(cr, showCarPrefs: ShowCarPrefs.showPreferences);

    makeDelimiter();

    setColor(state == Key.a ? white : lightGray);
    addOptionText(10, 1, "A", "A - Communication and Advocacy");

    setColor(state == Key.b ? white : lightGray);
    addOptionText(11, 1, "B", "B - Espionage");

    setColor(state == Key.c ? white : lightGray);
    addOptionText(12, 1, "C", "C - Join the Active LCS");

    addOptionText(20, 40, "Enter", "Enter - Confirm Selection");

    switch (state) {
      case Key.a:
        addOptionText(10, 40, "1", "1 - Lay Low",
            baseColorKey: cr.activity.type == ActivityType.none
                ? ColorKey.white
                : ColorKey.lightGray);
        addOptionText(11, 40, "2", "2 - Advocate Liberalism",
            baseColorKey: cr.activity.type == ActivityType.sleeperLiberal
                ? ColorKey.white
                : ColorKey.lightGray);
        bool canRecruit = true;
        String recruitText = "3 - Expand Sleeper Network";
        if (cr.subordinatesLeft <= 0) {
          canRecruit = false;
          if (cr.brainwashed) {
            recruitText = "3 - [Enlightened Can't Recruit]";
          } else {
            recruitText = "3 - [Need More Juice to Recruit]";
          }
        }
        addOptionText(12, 40, "3", recruitText,
            enabledWhen: canRecruit,
            baseColorKey: cr.activity.type == ActivityType.sleeperRecruit
                ? ColorKey.white
                : ColorKey.lightGray);

      case Key.b:
        addOptionText(10, 40, "1", "1 - Uncover Secrets",
            baseColorKey: cr.activity.type == ActivityType.sleeperSpy
                ? ColorKey.white
                : ColorKey.lightGray);
        addOptionText(11, 40, "2", "2 - Embezzle Funds",
            baseColorKey: cr.activity.type == ActivityType.sleeperEmbezzle
                ? ColorKey.white
                : ColorKey.lightGray);
        addOptionText(12, 40, "3", "3 - Steal Equipment",
            baseColorKey: cr.activity.type == ActivityType.sleeperSteal
                ? ColorKey.white
                : ColorKey.lightGray);
    }

    setColor(lightGray);
    switch (cr.activity.type) {
      case ActivityType.none:
        mvaddstr(22, 3, cr.name);
        addstr(" will stay out of trouble.");
      case ActivityType.sleeperLiberal:
        mvaddstr(22, 3, cr.name);
        addstr(" will build support for Liberal causes.");
      case ActivityType.sleeperRecruit:
        if (cr.subordinatesLeft > 0) {
          mvaddstr(22, 3, cr.name);
          addstr(" will try to recruit additional sleeper agents.");
        }
      case ActivityType.sleeperSpy:
        mvaddstr(22, 3, cr.name);
        addstr(" will snoop around for secrets and enemy plans.");
      case ActivityType.sleeperEmbezzle:
        mvaddstr(22, 3, cr.name);
        addstr(" will embezzle money for the LCS.");
      case ActivityType.sleeperSteal:
        mvaddstr(22, 3, cr.name);
        addstr(" will steal equipment and send it to the Camp.");
      case ActivityType.sleeperJoinLcs:
        mvaddstr(22, 3, cr.name);
        addstr(" will join the active LCS.");
      default:
        mvaddstrc(22, 3, red, "${cr.name} will dig around in the bugfield.");
        debugPrint("Unexpected sleeper activity type: "
            "${cr.activity.type.name}");
    }

    int c = await getKey();

    if (c >= Key.a && c <= Key.z) state = c;
    if ((c >= Key.a && c <= Key.z) || (c >= Key.num1 && c <= Key.num9)) {
      choice = c;
      switch (state) {
        case Key.a:
          switch (choice) {
            case Key.num2:
              cr.activity = Activity(ActivityType.sleeperLiberal);
            case Key.num3:
              if (cr.subordinatesLeft > 0) {
                cr.activity = Activity(ActivityType.sleeperRecruit);
              }
            case Key.num1:
            default:
              cr.activity = Activity.none();
          }
        case Key.b:
          switch (choice) {
            case Key.num1:
              cr.activity = Activity(ActivityType.sleeperSpy);
            case Key.num2:
              cr.activity = Activity(ActivityType.sleeperEmbezzle);
            case Key.num3:
              cr.activity = Activity(ActivityType.sleeperSteal);
            default:
              cr.activity = Activity.none();
          }
      }
    }

    if (state == Key.c) {
      cr.activity = Activity(ActivityType.sleeperJoinLcs);
    }
    if (c == Key.x) {
      cr.activity = Activity.none();
      break;
    }
    if (c == Key.enter || c == Key.escape || c == Key.space) {
      break;
    }
  }
}
