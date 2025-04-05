import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/high_scores.dart';
import 'package:lcs_new_age/title_screen/launch_game.dart';

Future<bool> checkForDefeat(
    [Ending possibleEnding = Ending.unspecified]) async {
  if (pool.any((p) =>
      p.alive &&
      p.align == Alignment.liberal &&
      !(p.sleeperAgent && p.hireId != null))) {
    return false;
  }

  HighScore yourScore;
  if (possibleEnding != Ending.unspecified) {
    yourScore = await saveHighScore(possibleEnding);
  } else {
    yourScore = await saveHighScore(switch (activeSite?.siege.activeSiegeType) {
      SiegeType.police => Ending.policeSiege,
      SiegeType.cia => Ending.ciaSiege,
      SiegeType.angryRuralMob => Ending.hicksSiege,
      SiegeType.corporateMercs => Ending.corporateSiege,
      SiegeType.ccs => Ending.ccsSiege,
      _ => Ending.dead,
    });
  }
  await deleteSaveGame();
  await viewHighScores(yourScore);
  endGame();
  return true;
}

enum EndTypes {
  other,
  won,
  hicks,
  cia,
  police,
  corp,
  reagan,
  dead,
  prison,
  executed,
  dating,
  hiding,
  disbandLoss,
  dispersed,
  ccs,
}

void endGame() {
  throw EndGameException();
}

enum Ending {
  victory,
  hicksSiege,
  ciaSiege,
  policeSiege,
  corporateSiege,
  ccsSiege,
  reaganified,
  dead,
  prison,
  executed,
  dating,
  hiding,
  disbandLoss,
  dispersed,
  unspecified,
}
