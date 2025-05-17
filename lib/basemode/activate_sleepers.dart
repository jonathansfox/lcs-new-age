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
    addPageButtons(y: 23, x: 0);
    addOptionText(24, 0, "T", "T - Sorting options");
    console.x += 2;
    addInlineOptionText("Z", "Z - Assign tasks in bulk");
    console.x += 2;
    addInlineOptionText("Enter", "Enter - Done");

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

    if (c == Key.z) {
      await activateSleepersBulk();
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

    addOptionText(10, 1, "A", "A - Communication and Advocacy",
        baseColorKey: state == Key.a ? ColorKey.white : ColorKey.lightGray);
    addOptionText(11, 1, "B", "B - Espionage",
        baseColorKey: state == Key.b ? ColorKey.white : ColorKey.lightGray);
    addOptionText(12, 1, "C", "C - Join the Active LCS",
        baseColorKey: cr.activity.type == ActivityType.sleeperJoinLcs
            ? ColorKey.white
            : ColorKey.lightGray);

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

Future<void> activateSleepersBulk() async {
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

  int page = 0, selectedactivity = 0;

  while (true) {
    erase();
    setColor(lightGray);
    printFunds();

    mvaddstr(0, 0, "Activate Sleeper Agents in Bulk");
    addHeader({
      4: "CODE NAME",
      20: "JOB",
      35: "EFF",
      40: "CURRENT",
      58: "BULK ACTIVITY"
    });

    void addOption(int i, String name, {bool enabled = true}) {
      addOptionText(i + 1, 58, "$i", "$i - $name",
          baseColorKey: selectedactivity == i - 1 ? "W" : "w",
          enabledWhen: enabled);
    }

    addOption(1, "Lay Low");
    addOption(2, "Advocate Liberalism");
    addOption(3, "Uncover Secrets");
    addOption(4, "Embezzle Funds");
    addOption(5, "Steal Equipment");
    addOption(6, "Expand Network");
    addOption(7, "Join LCS");

    int y = 2;
    for (int p = page * 19;
        p < temppool.length && p < page * 19 + 19;
        p++, y++) {
      Creature tempp = temppool[p];
      String letter = letterAPlus(p - page * 19);
      addOptionText(y, 0, letter, "$letter - ${tempp.name}");
      setColor(lightGray);
      mvaddstr(y, 20, tempp.type.name);

      // Show infiltration level with color coding
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
      mvaddstr(y, 35, "${(tempp.infiltration * 100).ceil()}%");

      // Show current activity (first word only if long)
      move(y, 40);
      setColor(tempp.activity.type.color);
      String activityLabel = tempp.activity.type.label;
      if (activityLabel.length > 17) {
        addstr(activityLabel.split(" ").first);
      } else {
        addstr(activityLabel);
      }
    }

    mvaddstrc(22, 0, lightGray,
        "Press a Letter to Assign an Activity.  Press a Number to select an Activity.");
    addPageButtons(y: 23, x: 0);

    int c = await getKey();

    // Handle page navigation
    if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
      page--;
    }
    if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
        (page + 1) * 19 < temppool.length) {
      page++;
    }

    if (c >= Key.a && c <= Key.s) {
      int p = page * 19 + c - Key.a;
      if (p < temppool.length) {
        Creature tempp = temppool[p];
        switch (selectedactivity) {
          case 0: // Lay Low
            tempp.activity = Activity.none();
          case 1: // Advocate Liberalism
            tempp.activity = Activity(ActivityType.sleeperLiberal);
          case 2: // Uncover Secrets
            tempp.activity = Activity(ActivityType.sleeperSpy);
          case 3: // Embezzle Funds
            tempp.activity = Activity(ActivityType.sleeperEmbezzle);
          case 4: // Steal Equipment
            tempp.activity = Activity(ActivityType.sleeperSteal);
          case 5: // Expand Network
            if (tempp.subordinatesLeft > 0 && !tempp.brainwashed) {
              tempp.activity = Activity(ActivityType.sleeperRecruit);
            }
          case 6: // Join LCS
            tempp.activity = Activity(ActivityType.sleeperJoinLcs);
        }
      }
    }
    if (c >= Key.num1 && c <= Key.num8) {
      selectedactivity = c - Key.num1;
    }

    if (isBackKey(c)) break;
  }
}
