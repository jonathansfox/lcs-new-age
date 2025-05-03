import 'dart:convert';
import 'dart:math';

import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

const int scoreVersion = 1;

class HighScores {
  HighScores(
      {this.universalRecruits = 0,
      this.universalMartyrs = 0,
      this.universalKills = 0,
      this.universalKidnappings = 0,
      this.universalFunds = 0,
      this.universalSpent = 0,
      this.universalFlagBuys = 0,
      this.universalFlagBurns = 0,
      this.universalLosses = 0,
      this.universalVictories = 0});
  HighScores.fromJson(Map<String, dynamic> json)
      : scoreList = (json['highScores'] as List<dynamic>? ?? [])
            .map<HighScore>(
                (a) => HighScore.fromJson(a as Map<String, dynamic>))
            .toList(),
        universalRecruits = json['universalRecruits'] ?? 0,
        universalMartyrs = json['universalMartyrs'] ?? 0,
        universalKills = json['universalKills'] ?? 0,
        universalKidnappings = json['universalKidnappings'] ?? 0,
        universalFunds = json['universalFunds'] ?? 0,
        universalSpent = json['universalSpent'] ?? 0,
        universalFlagBuys = json['universalFlagBuys'] ?? 0,
        universalFlagBurns = json['universalFlagBurns'] ?? 0,
        universalLosses = json['universalLosses'] ?? 0,
        universalVictories = json['universalVictories'] ?? 0;
  Map<String, dynamic> toJson() => {
        'highScores': scoreList.map((e) => e.toJson()).toList(),
        'universalRecruits': universalRecruits,
        'universalMartyrs': universalMartyrs,
        'universalKills': universalKills,
        'universalKidnappings': universalKidnappings,
        'universalFunds': universalFunds,
        'universalSpent': universalSpent,
        'universalFlagBuys': universalFlagBuys,
        'universalFlagBurns': universalFlagBurns,
        'universalLosses': universalLosses,
        'universalVictories': universalVictories,
      };
  List<HighScore> scoreList = [];
  int universalRecruits = 0;
  int universalMartyrs = 0;
  int universalKills = 0;
  int universalKidnappings = 0;
  int universalFunds = 0;
  int universalSpent = 0;
  int universalFlagBuys = 0;
  int universalFlagBurns = 0;
  int universalLosses = 0;
  int universalVictories = 0;

  Iterable<HighScore> get wins =>
      scoreList.where((e) => e.endType == Ending.victory);
}

class HighScore {
  HighScore({
    required this.slogan,
    required this.month,
    required this.year,
    required this.statRecruits,
    required this.statMartyrs,
    required this.statKills,
    required this.statKidnappings,
    required this.statFunds,
    required this.statSpent,
    required this.statBuys,
    required this.statBurns,
    required this.endType,
  });
  HighScore.fromJson(Map<String, dynamic> json)
      : slogan = json['slogan'] ?? "",
        month = json['month'] ?? 0,
        year = json['year'] ?? 2023,
        statRecruits = json['statRecruits'] ?? 0,
        statMartyrs = json['statMartyrs'] ?? 0,
        statKills = json['statKills'] ?? 0,
        statKidnappings = json['statKidnappings'] ?? 0,
        statFunds = json['statFunds'] ?? 0,
        statSpent = json['statSpent'] ?? 0,
        statBuys = json['statBuys'] ?? 0,
        statBurns = json['statBurns'] ?? 0,
        endType = Ending.values[json['endType']];
  Map<String, dynamic> toJson() => {
        'slogan': slogan,
        'month': month,
        'year': year,
        'statRecruits': statRecruits,
        'statMartyrs': statMartyrs,
        'statKills': statKills,
        'statKidnappings': statKidnappings,
        'statFunds': statFunds,
        'statSpent': statSpent,
        'statBuys': statBuys,
        'statBurns': statBurns,
        'endType': endType.index,
      };
  String slogan;
  int month;
  int year;
  int statRecruits;
  int statMartyrs;
  int statKills;
  int statKidnappings;
  int statFunds;
  int statSpent;
  int statBuys;
  int statBurns;
  Ending endType;

  int compareTo(HighScore other) {
    if (endType == Ending.victory && other.endType != Ending.victory) {
      return -1;
    } else if (endType != Ending.victory && other.endType == Ending.victory) {
      return 1;
    } else if (endType == Ending.victory && other.endType == Ending.victory) {
      return daysSince2000 - other.daysSince2000;
    } else {
      return other.score - score;
    }
  }

  int get daysSince2000 =>
      DateTime(year, month, 1).difference(DateTime(2000, 1, 1)).inDays;
  int get score =>
      statRecruits * 1000 +
      statKills * 50 +
      statKidnappings * 50 +
      statFunds +
      statSpent;
}

Future<void> viewHighScores([HighScore? yourScore]) async {
  HighScores? highScores = await loadHighScores();
  if (highScores.scoreList.isEmpty) return;

  erase();
  mvaddstrc(0, 0, white, "The Liberal ELITE");

  int y = 2;
  for (HighScore s in highScores.scoreList) {
    if (s.endType == Ending.victory) {
      if (s == yourScore) {
        setColor(lightGreen);
      } else {
        setColor(green);
      }
    } else {
      setColor(red);
    }
    mvaddstr(y, 0, s.slogan);
    if (s.score == yourScore?.score &&
        s.daysSince2000 == yourScore?.daysSince2000) {
      if (s.endType == Ending.victory) {
        setColor(lightGreen);
      } else {
        setColor(darkRed);
      }
    } else {
      setColor(lightGray);
    }
    move(y + 1, 0);
    switch (s.endType) {
      case Ending.victory:
        addstr("The Liberal Crime Squad liberalized the country in ");
      case Ending.policeSiege:
        addstr("The Liberal Crime Squad was brought to justice in ");
      case Ending.ciaSiege:
        addstr("The Liberal Crime Squad was blotted out in ");
      case Ending.hicksSiege:
        addstr("The Liberal Crime Squad was mobbed in ");
      case Ending.corporateSiege:
        addstr("The Liberal Crime Squad was downsized in ");
      case Ending.dead:
        addstr("The Liberal Crime Squad was KIA in ");
      case Ending.reaganified:
        addstr("The country was Reaganified in ");
      case Ending.prison:
        addstr("The Liberal Crime Squad died in prison in ");
      case Ending.executed:
        addstr("The Liberal Crime Squad was executed in ");
      case Ending.dating:
        addstr("The Liberal Crime Squad was on vacation in ");
      case Ending.hiding:
        addstr("The Liberal Crime Squad was in permanent hiding in ");
      case Ending.disbandLoss:
        addstr("The Liberal Crime Squad was hunted down in ");
      case Ending.dispersed:
        addstr("The Liberal Crime Squad was scattered in ");
      case Ending.ccsSiege:
        addstr("The Liberal Crime Squad was out-Crime Squadded in ");
      case Ending.unspecified:
        addstr("The Liberal Crime Squad was defeated in ");
    }
    addstr("${getMonth(s.month)} ${s.year}.");
    mvaddstr(y + 2, 0, "Recruits: ${s.statRecruits}");
    mvaddstr(y + 3, 0, "Martyrs: ${s.statMartyrs}");
    mvaddstr(y + 2, 20, "Kills: ${s.statKills}");
    mvaddstr(y + 3, 20, "Kidnappings: ${s.statKidnappings}");
    mvaddstr(y + 2, 40, "\$ Taxed: ${s.statFunds}");
    mvaddstr(y + 3, 40, "\$ Spent: ${s.statSpent}");
    mvaddstr(y + 2, 60, "Flags Bought: ${s.statBuys}");
    mvaddstr(y + 3, 60, "Flags Burned: ${s.statBurns}");
    y += 4;
  }

  setColor(lightGreen);

  //UNIVERSAL STATS
  mvaddstr(22, 0, "Universal Liberal Statistics:");
  mvaddstr(23, 0, "Recruits: ${highScores.universalRecruits}");
  mvaddstr(24, 0, "Martyrs: ${highScores.universalMartyrs}");
  mvaddstr(23, 20, "Kills: ${highScores.universalKills}");
  mvaddstr(24, 20, "Kidnappings: ${highScores.universalKidnappings}");
  mvaddstr(23, 40, "\$ Taxed: ${highScores.universalFunds}");
  mvaddstr(24, 40, "\$ Spent: ${highScores.universalSpent}");
  mvaddstr(23, 60, "Flags Bought: ${highScores.universalFlagBuys}");
  mvaddstr(24, 60, "Flags Burned: ${highScores.universalFlagBurns}");
  await getKey();
}

/* loads the high scores file */
Future<HighScores> loadHighScores() async {
  final prefs = await SharedPreferences.getInstance();
  final int loadversion = prefs.getInt("scoreVersion") ?? -1;
  HighScores highScores;
  switch (loadversion) {
    case -1:
      highScores = HighScores();
    case 1:
      final String? scoreString = prefs.getString("score");
      if (scoreString == null || scoreString == "") {
        highScores = HighScores();
      } else {
        final json = jsonDecode(scoreString);
        highScores = HighScores.fromJson(json);
      }
    default:
      debugPrint("loadHighScores: Unknown scoreVersion: $loadversion");
      highScores = HighScores();
  }

  // Load high scores from saved games
  final List<SaveFile> saveFiles = await loadGameList();
  for (final saveFile in saveFiles) {
    if (saveFile.gameState != null) {
      final GameState gameState = saveFile.gameState!;
      highScores.universalRecruits += gameState.stats.recruits;
      highScores.universalMartyrs += gameState.stats.martyrs;
      highScores.universalKills += gameState.stats.kills;
      highScores.universalKidnappings += gameState.stats.kidnappings;
      highScores.universalFunds += gameState.ledger.totalIncome;
      highScores.universalSpent += gameState.ledger.totalExpense;
      highScores.universalFlagBuys += gameState.stats.flagsBought;
      highScores.universalFlagBurns += gameState.stats.flagsBurned;
    }
  }

  // Sort and limit to top 5 scores
  highScores.scoreList.sort((a, b) => a.compareTo(b));
  highScores.scoreList =
      highScores.scoreList.sublist(0, min(5, highScores.scoreList.length));

  return highScores;
}

Future<HighScore> saveHighScore(Ending ending) async {
  HighScores highScores = await loadHighScores();

  //MERGE THE STATS
  highScores.universalRecruits += stats.recruits;
  highScores.universalMartyrs += stats.martyrs;
  highScores.universalKills += stats.kills;
  highScores.universalKidnappings += stats.kidnappings;
  highScores.universalFunds += ledger.totalIncome;
  highScores.universalSpent += ledger.totalExpense;
  highScores.universalFlagBuys += stats.flagsBought;
  highScores.universalFlagBurns += stats.flagsBurned;
  if (ending == Ending.victory) {
    highScores.universalVictories++;
  } else {
    highScores.universalLosses++;
  }

  //PLACE THIS HIGH SCORE BY DATE IF NECESSARY
  HighScore yourScore = HighScore(
    slogan: slogan,
    month: month,
    year: year,
    statRecruits: stats.recruits,
    statMartyrs: stats.martyrs,
    statKills: stats.kills,
    statKidnappings: stats.kidnappings,
    statFunds: ledger.totalIncome,
    statSpent: ledger.totalExpense,
    statBuys: stats.flagsBought,
    statBurns: stats.flagsBurned,
    endType: ending,
  );
  highScores.scoreList.add(yourScore);
  highScores.scoreList.sort((a, b) => a.compareTo(b));
  highScores.scoreList =
      highScores.scoreList.sublist(0, min(5, highScores.scoreList.length));

  //SAVE THE STATS
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt("scoreVersion", scoreVersion);
  await prefs.setString("score", jsonEncode(highScores.toJson()));

  return yourScore;
}
