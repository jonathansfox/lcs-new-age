import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/high_scores.dart';
import 'package:lcs_new_age/title_screen/new_game.dart';
import 'package:lcs_new_age/title_screen/world.dart';
import 'package:lcs_new_age/utils/colors.dart';

const String gameVersion = "1.2.4";
bool megaFounderCheat = false;

Future<void> titleScreen() async {
  HighScores? highScores = await loadHighScores();
  while (true) {
    printTitleScreen(highScores);
    int c = await getKey();
    if (c == Key.i) {
      await importSave();
    } else if (c == Key.h) {
      await viewHighScores();
      continue;
    }
    break;
  }
  await loadSaveOrStartNewGame();
  mode = GameMode.base;
  await baseMode();
}

Future<void> loadSaveOrStartNewGame() async {
  if (await loadGameMenu()) {
    return;
  }

  // on failure, create a new game
  await setupNewGame();
  makeWorld();
  await makeCharacter();
}

void printTitleScreen(HighScores? highScores) {
  erase();
  titleScreenFrame();
  titleScreenScores(highScores);
  setColor(lightGreen);
  mvaddstr(3, 4, "LIBERAL CRIME SQUAD: ");
  setColor(RainbowFlag.lightBlue);
  addstr("NEW AGE");
  setColor(lightGray);
  mvaddstr(5, 8, "A Liberal Adventure");
  mvaddstr(3, 41, "\"For some, a dream come true $emDash");
  mvaddstr(5, 37, "to others, an offensive piece of crap!\"");
  mvaddstrCenter(
      17, "Liberal Crime Squad: New Age is maintained by Jonathan S. Fox.");
  mvaddstrCenter(18,
      "Thank you to Tarn Adams of Bay 12 Games for making the original game,");
  mvaddstrCenter(
      19, "and for releasing LCS as open source so the rest of us could waste");
  mvaddstrCenter(20, "all these years updating it into the game it is today.");
  setColor(black, background: lightGray);
  mvaddstr(22, 65, "Version $gameVersion");
  setColor(lightGray);
  mvaddstrCenter(23,
      "Press I to Import a saved game.  Any other key to Pursue your Liberal Agenda.");
  mvaddstrCenter(24, "(click the game window to give it keyboard focus)");
}

void titleScreenFrame() {
  setColor(green, background: lightGray);
  mvaddstr(0, 0, "".padLeft(80));
  for (int i = 1; i < 23; i++) {
    mvaddstr(i, 0, " ");
    mvaddstr(i, 1, " ");
    mvaddstr(i, 78, " ");
    mvaddstr(i, 79, " ");
  }
  mvaddstr(22, 0, "".padLeft(80));
  setColor(lightGray);
  mvaddstr(8, 2, "".padLeft(76, emDash));
  mvaddstr(15, 2, "".padLeft(76, emDash));
}

void titleScreenScores(HighScores? highScores) {
  highScores ??= HighScores();
  mvaddstr(9, 4, "Universal Liberal Statistics");
  mvaddstr(11, 4, "Total Liberals Recruited: ${highScores.universalRecruits}");
  mvaddstr(12, 4, "Total Liberals Martyred: ${highScores.universalMartyrs}");
  mvaddstr(13, 4, "Total Conservatives Killed: ${highScores.universalKills}");
  mvaddstr(14, 4,
      "Total Conservatives Kidnapped: ${highScores.universalKidnappings}");
  mvaddstr(11, 44, "Total Americas Lost: ${highScores.universalLosses}");
  mvaddstr(12, 44, "Total Americas Saved: ${highScores.universalVictories}");
  if (highScores.wins.isNotEmpty) {
    mvaddstr(13, 44,
        "Fastest Victory: ${getMonth(highScores.scoreList.first.month)} ${highScores.scoreList.first.year}");
  }
  if (highScores.scoreList.isNotEmpty) {
    mvaddstr(14, 44, "Press H to view more high scores.");
  }
}
