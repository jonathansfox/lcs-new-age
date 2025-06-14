import 'dart:math';

import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivityHacking(List<Creature> hack) async {
  if (hack.isEmpty) return;

  String msg = "";
  int hackSkill = 0;
  for (int h = 0; h < hack.length; h++) {
    hackSkill = max(hackSkill, hack[h].skillRoll(Skill.computers));
    hack[h].train(Skill.computers, 5);
  }
  int hackTeamSkill = hackSkill + hack.length - 1;

  void loot(String type) => hack[0].site!.loot.add(Loot(type));

  if (Difficulty.hard > hackTeamSkill) return;

  View issue = View.issues.random;
  Crime crime;
  int trackdif = Difficulty.formidable;
  int juiceval = 5;

  if (hack.length > 1) {
    msg = "Your hackers have ";
  } else {
    msg = hack[0].name;
    msg += " has ";
  }

  if (Difficulty.formidable <= hackTeamSkill) {
    // Major hack
    trackdif = Difficulty.heroic;
    juiceval = 10;
    crime = Crime.dataTheft;

    switch (lcsRandom(6)) {
      case 0:
        msg += "pilfered files from a Corporate server.";
        loot("LOOT_CORPFILES");
      case 1:
        msg += "caused a scare by breaking into a CIA network.";
        trackdif = Difficulty.mythic;
        crime = Crime.cyberTerrorism;
        juiceval = 25;
        changePublicOpinion(View.intelligence, 5, coloredByLcsOpinions: true);
      case 2:
        msg += "sabotaged a genetics research company's network.";
        crime = Crime.cyberVandalism;
        changePublicOpinion(View.genetics, 5, coloredByLcsOpinions: true);
      case 3:
        msg += "intercepted internal media emails.";
        if (oneIn(2)) {
          loot("LOOT_CABLENEWSFILES");
        } else {
          loot("LOOT_AMRADIOFILES");
        }
      case 4:
        msg += "broke into military networks leaving LCS slogans.";
        trackdif = Difficulty.superHeroic;
        crime = Crime.cyberTerrorism;
        juiceval = 25;
        changePublicOpinion(View.military, 5, coloredByLcsOpinions: true);
        changePublicOpinion(View.lcsKnown, 5);
      case 5:
        msg += "uncovered information on dangerous research.";
        loot("LOOT_RESEARCHFILES");
      case 6:
        msg += "discovered evidence of judicial corruption.";
        loot("LOOT_JUDGEFILES");
    }
  } else {
    // Minor hack
    crime = Crime.cyberVandalism;
    const hacks = [
      "defaced",
      "knocked out",
      "crashed",
      "hacked",
    ];
    const targets = [
      "corporate website",
      "Conservative forum",
      "Conservative blog",
      "news website",
      "government website"
    ];
    msg += "${hacks.random} a ${targets.random}.";
    changePublicOpinion(issue, 1);
  }

  int trackEvade = hackSkill - lcsRandom(5);

  debugPrint("Hacking: $msg, $crime, $trackdif, $trackEvade");

  if (trackdif > trackEvade) {
    criminalizeAll(hack, crime, splitHeat: true);
  }

  // Award juice to the hacking team for a job well done
  for (int h = 0; h < hack.length; h++) {
    addjuice(hack[h], juiceval, 200);
  }

  if (msg.isNotEmpty) await showMessage(msg);
}

Future<void> doActivityCCFraud(List<Creature> cc) async {
  int hackSkill = 0;
  for (int h = 0; h < cc.length; h++) {
    hackSkill += cc[h].skillRoll(Skill.computers);
    cc[h].train(Skill.computers, 5);
  }

  int difficulty = Difficulty.challenging;
  int fundgain = 0;
  while (difficulty < hackSkill) {
    fundgain += lcsRandom(51);
    difficulty += 2;
  }
  if (fundgain == 0) return;

  ledger.addFunds(fundgain, Income.creditCardFraud);
  for (int h = 0; h < cc.length; h++) {
    cc[h].income = fundgain ~/ cc.length;
    if (fundgain / 10 > lcsRandom(hackSkill + 1) / 2 + hackSkill / 2) {
      criminalize(cc[h], Crime.creditCardFraud);
    }
  }

  await showMessage("Your hackers have stolen \$$fundgain from credit cards.");
}
