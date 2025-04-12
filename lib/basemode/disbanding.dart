import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

int oldForceMonth = -1;
Future<bool> showDisbandingScreen() async {
  if (oldForceMonth == month) return true;
  oldForceMonth = month;

  letTheUnworthyLeave();

  erase();
  mvaddstrc(0, 0, white, "${getMonth(month)} $year");

  printExec();
  printHouse(2);
  printSenate(3);
  printCourtBrief(4);
  printLaws();

  printMood();

  addOptionText(24, 0, "R", "R - Recreate the Liberal Crime Squad");
  addOptionText(24, 54, "Any Other Key", "Any Other Key - Next Month");

  return await getKey() != Key.r;
}

void letTheUnworthyLeave() {
  for (int p = pool.length - 1; p >= 0; p--) {
    int targetjuice = lcsRandom(100 * (year - disbandTime + 1));
    if (targetjuice > 1000) targetjuice = 1000;
    if (pool[p].juice < targetjuice &&
        pool[p].hireId != null &&
        !pool[p].sleeperAgent) {
      pool[p].alive = false;
    }
  }
}

void printExec() {
  mvaddstrc(1, 0, exec[Exec.president]!.color,
      "President: ${execName[Exec.president]}, ${exec[Exec.president]!.label}");
  if (politics.execTerm == 1) {
    addstr(", 1st Term");
  } else {
    addstr(", 2nd Term");
  }
}

void printHouse(int y) {
  List<int> housemake = summarizePoliticalBody(house);
  setPoliticalBodyColor(housemake);
  mvaddstr(y, 0, "House: ${summaryText(housemake)}");
}

void printSenate(int y) {
  List<int> senatemake = summarizePoliticalBody(senate);
  setPoliticalBodyColor(senatemake);
  mvaddstr(y, 0, "Senate: ${summaryText(senatemake)}");
}

void printCourtBrief(int y) {
  List<int> courtmake = summarizePoliticalBody(court);
  setPoliticalBodyColor(courtmake);
  mvaddstr(y, 0, "Court: ${summaryText(courtmake)}");
}

void printLaws() {
  for (Law l in laws.keys) {
    setColor(laws[l]?.color ?? yellow);
    mvaddstr(6 + (l.index / 3).floor(), l.index % 3 * 30, l.label);
  }
}

void printMood() {
  int mood = 0;
  for (View v in View.issues) {
    mood += (publicOpinion[v] ?? 0).round();
  }
  mood = (78 - (mood * 77) / (View.issues.length * 100)).round();
  DeepAlignment align;
  if (mood >= 64) {
    align = DeepAlignment.archConservative;
  } else if (mood >= 48) {
    align = DeepAlignment.conservative;
  } else if (mood >= 32) {
    align = DeepAlignment.moderate;
  } else if (mood >= 16) {
    align = DeepAlignment.liberal;
  } else {
    align = DeepAlignment.eliteLiberal;
  }
  mvaddstrc(20, 34, align.color, "Public Mood");
  mvaddstrc(21, 1, DeepAlignment.eliteLiberal.color, "Liberal");
  mvaddstrc(21, 67, DeepAlignment.archConservative.color, "Conservative");
  mvaddstrc(22, 0, DeepAlignment.eliteLiberal.color, "<———————————————");
  mvaddstrc(22, 16, DeepAlignment.liberal.color, "————————————————");
  mvaddstrc(22, 32, DeepAlignment.moderate.color, "————————————————");
  mvaddstrc(22, 48, DeepAlignment.conservative.color, "————————————————");
  mvaddstrc(22, 64, DeepAlignment.archConservative.color, "———————————————>");
  mvaddstrc(22, mood, align.color, "O");
}

String summaryText(List<int> body) => List.generate(
    5, (i) => "${body[4 - i]} ${DeepAlignment.values[4 - i].short}").join(", ");

List<int> summarizePoliticalBody(List<DeepAlignment> body) {
  List<int> summary = [0, 0, 0, 0, 0];
  for (DeepAlignment individual in body) {
    summary[individual.index]++;
  }
  return summary;
}

void setPoliticalBodyColor(List<int> body) {
  int majority = (body.fold(0, (a, b) => a + b) / 2).floor() + 1;
  DeepAlignment align;
  if (body[0] >= majority) {
    align = DeepAlignment.archConservative;
  } else if (body[4] >= majority) {
    align = DeepAlignment.eliteLiberal;
  } else if (body[0] + body[1] >= majority) {
    align = DeepAlignment.conservative;
  } else if (body[3] + body[4] >= majority) {
    align = DeepAlignment.liberal;
  } else {
    align = DeepAlignment.moderate;
  }
  setColor(align.color);
}
