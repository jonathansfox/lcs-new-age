import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/high_scores.dart';
import 'package:lcs_new_age/title_screen/new_game.dart';
import 'package:lcs_new_age/title_screen/world.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String gameVersion = "1.3.5";
bool megaFounderCheat = false;

Future<void> titleScreen() async {
  HighScores? highScores = await loadHighScores();
  printTitleScreen(highScores);

  // Get the last save file to show founder name
  final prefs = await SharedPreferences.getInstance();
  int? lastGameId = prefs.getInt("lastGameId");
  String continueText = "C - Continue Last Game";
  if (lastGameId != null) {
    List<SaveFile> saveFiles = await loadGameList();
    SaveFile? lastSave = saveFiles
        .firstWhereOrNull((save) => save.gameId == lastGameId.toString());
    if (lastSave?.gameState != null) {
      String founder = lastSave!.gameState!.lcs.pool
              .firstWhereOrNull(
                  (e) => e.hireId == null && e.align == Alignment.liberal)
              ?.name ??
          "Unknown";
      continueText = "C - Continue as &G$founder&x";
    } else {
      lastGameId = null;
    }
  }

  // Check if there are any saved games
  List<SaveFile> saveFiles = await loadGameList();
  bool hasSaves = saveFiles.isNotEmpty;

  // Check if there are any high scores
  bool hasHighScores = highScores.scoreList.isNotEmpty;

  // Add menu options
  setColor(white);
  mvaddstrCenter(10, "Select an Option to Pursue your Liberal Agenda");
  setColor(lightGray);
  addOptionText(12, 10, "C", continueText, enabledWhen: lastGameId != null);
  addOptionText(12, 48, "L", "L - Load a Saved Game", enabledWhen: hasSaves);
  addOptionText(13, 10, "N", "N - Start a New Game");
  addOptionText(13, 48, "I", "I - Import a Save");
  addOptionText(14, 10, "H", "H - View High Scores",
      enabledWhen: hasHighScores);
  addOptionText(14, 48, "V", "V - View Changelog");
  //rainbowLine(15, 47, 4, '▄', reverse: true);

  while (true) {
    int c = await getKey();

    switch (c) {
      case Key.c:
        if (lastGameId != null) {
          List<SaveFile> saveFiles = await loadGameList();
          SaveFile? lastSave = saveFiles
              .firstWhereOrNull((save) => save.gameId == lastGameId.toString());
          if (lastSave != null && await loadGameFromSave(lastSave)) {
            mode = GameMode.base;
            await baseMode();
            return;
          }
        }
      case Key.n:
        await setupNewGame();
        makeWorld();
        await makeCharacter();
        mode = GameMode.base;
        await baseMode();
        return;
      case Key.l:
        if (await loadGameMenu()) {
          mode = GameMode.base;
          await baseMode();
          return;
        }
        return;
      case Key.h:
        if (hasHighScores) {
          await viewHighScores();
          return;
        }
      case Key.i:
        await importSave();
        return;
      case Key.v:
        await showChangelog();
        return;
    }
  }
}

void printTitleScreen(HighScores? highScores) {
  erase();
  titleScreenFrame(bottom: 23);
  titleScreenScores(highScores, startY: 17);
  setColor(lightGreen);
  mvaddstrCenter(2, "LIBERAL CRIME SQUAD: NEW AGE");
  move(2, console.x - 7);
  setColor(RainbowFlag.lightBlue);
  addstr("NEW AGE");
  setColor(midGray);
  mvaddstrCenter(4, "Maintained by Jonathan S. Fox, with gratitude to:");
  mvaddstrCenter(5, "Bay 12 Games, IssacG, SlatersQuest, Kamal-Sadek, Grundee");
  mvaddstrCenter(
      6, "and many others who have contributed to LCS over the years");

  setColor(black, background: lightGray);
  mvaddstr(23, 65, "Version $gameVersion");
  setColor(lightGray);
  mvaddstrCenter(24, "(click the game window to give it keyboard focus)");
}

void titleScreenFrame({bool includeEmDash = true, int bottom = 22}) {
  setColor(green, background: lightGray);
  mvaddstr(0, 0, "".padLeft(80));
  for (int i = 1; i <= bottom; i++) {
    mvaddstr(i, 0, " ");
    mvaddstr(i, 1, " ");
    mvaddstr(i, 78, " ");
    mvaddstr(i, 79, " ");
  }
  mvaddstr(bottom, 0, "".padLeft(80));
  setColor(lightGray);
  if (includeEmDash) {
    mvaddstr(8, 2, "".padLeft(76, emDash));
    mvaddstr(16, 2, "".padLeft(76, emDash));
  }
}

void titleScreenScores(HighScores? highScores, {int startY = 9}) {
  highScores ??= HighScores();
  mvaddstrc(startY, 4, white, "Universal Liberal Statistics");
  mvaddstrc(startY + 1, 4, lightGray,
      "Total Liberals Recruited: ${highScores.universalRecruits}");
  mvaddstr(
      startY + 2, 4, "Total Liberals Martyred: ${highScores.universalMartyrs}");
  mvaddstr(startY + 3, 4,
      "Total Conservatives Killed: ${highScores.universalKills}");
  mvaddstr(startY + 4, 4,
      "Total Conservatives Kidnapped: ${highScores.universalKidnappings}");
  mvaddstr(
      startY + 1, 44, "Total Americas Lost: ${highScores.universalLosses}");
  mvaddstr(
      startY + 2, 44, "Total Americas Saved: ${highScores.universalVictories}");
  if (highScores.wins.isNotEmpty) {
    mvaddstr(startY + 3, 44,
        "Fastest Victory: ${getMonth(highScores.scoreList.first.month)} ${highScores.scoreList.first.year}");
  }
}

void rainbowLine(
  int y,
  int x,
  int lengthPerSegment,
  String character, {
  bool reverse = false,
}) {
  int sign = reverse ? -1 : 1;
  setColor(RainbowFlag.red, background: console.currentBackground);
  mvaddstr(y, x, "".padLeft(lengthPerSegment, character));
  setColor(RainbowFlag.orange, background: console.currentBackground);
  mvaddstr(
      y, x + lengthPerSegment * sign, "".padLeft(lengthPerSegment, character));
  setColor(RainbowFlag.yellow, background: console.currentBackground);
  mvaddstr(y, x + 2 * lengthPerSegment * sign,
      "".padLeft(lengthPerSegment, character));
  setColor(RainbowFlag.green, background: console.currentBackground);
  mvaddstr(y, x + 3 * lengthPerSegment * sign,
      "".padLeft(lengthPerSegment, character));
  setColor(RainbowFlag.blue, background: console.currentBackground);
  mvaddstr(y, x + 4 * lengthPerSegment * sign,
      "".padLeft(lengthPerSegment, character));
  setColor(RainbowFlag.purple, background: console.currentBackground);
  mvaddstr(y, x + 5 * lengthPerSegment * sign,
      "".padLeft(lengthPerSegment, character));
}

void addQuote() {
  List<List<String>> quotes = [
    [
      "\"For some, a dream come true $emDash",
      "to others, an offensive piece of crap!\"",
    ],
  ];

  int centerX = 55;

  List<String> quote = quotes.random;
  mvaddstr(2, centerX - quote[0].length ~/ 2, quote[0]);
  mvaddstr(3, centerX - quote[1].length ~/ 2, quote[1]);
}
