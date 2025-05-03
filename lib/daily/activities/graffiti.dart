import 'dart:math';

import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/arrest.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivityGraffiti(List<Creature> graffiti) async {
  int s;

  if (graffiti.isEmpty) return;

  for (s = 0; s < graffiti.length; s++) {
    if (!graffiti[s].weapon.type.canGraffiti) {
      // See if you can scrounge up a spray can
      Weapon? sprayPaint = graffiti[s]
          .base
          ?.loot
          .whereType<Weapon>()
          .firstWhereOrNull((w) => w.type.canGraffiti);
      WeaponType? sprayType =
          weaponTypes.values.firstWhereOrNull((w) => w.canGraffiti);
      if (sprayPaint != null) {
        await showMessage(
            "${graffiti[s].name} grabbed a ${sprayPaint.getName()} from ${graffiti[s].base!.name}.");
        graffiti[s].giveWeapon(sprayPaint, graffiti[s].base!.loot);
      } else if (sprayType != null && ledger.funds >= sprayType.price) {
        ledger.subtractFunds(sprayType.price, Expense.shopping);
        await showMessage(
            "${graffiti[s].name} bought spraypaint for graffiti.");
        graffiti[s]
            .giveWeapon(Weapon(sprayType.idName), graffiti[s].base!.loot);
      } else {
        await showMessage(
            "${graffiti[s].name} needs a spraycan equipped to do graffiti.");
        graffiti[s].activity = Activity.none();
      }
    }

    View issue = View.lcsKnown;
    int power = 1;

    if (oneIn(10) &&
        !graffiti[s].skillCheck(Skill.streetSmarts, Difficulty.average)) {
      // Spotted by cops!
      String activity;
      if (graffiti[s].activity.view != null) {
        activity = "working on the mural";
        graffiti[s].activity.view = null;
      } else {
        activity = "spraying an LCS tag";
      }

      await showMessage(
          "${graffiti[s].name} was spotted by the police while $activity!");
      criminalize(graffiti[s], Crime.vandalism);
      graffiti[s].train(Skill.streetSmarts, 20);

      sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);

      await attemptArrest(graffiti[s], null);
    } else if (graffiti[s].activity.view != null) {
      // Working on mural
      power = 0;
      if (oneIn(3)) {
        issue = graffiti[s].activity.view ?? View.lcsKnown;
        power = graffiti[s].skillRoll(Skill.art) ~/ 3;

        String quality = power > 3 ? " beautiful" : "";
        await showMessage(
            "${graffiti[s].name} has completed a$quality mural about ${issue.label}.");

        graffiti[s].activity.view = null;
        addjuice(graffiti[s], power, power * 20);
        graffiti[s].train(Skill.art, 10);
        graffiti[s].train(Skill.streetSmarts, 5);
      } else {
        await showMessage(
            "${graffiti[s].name} works through the night on a large mural.");
        graffiti[s].train(Skill.art, 10);
        graffiti[s].train(Skill.streetSmarts, 5);
      }
    } else if (oneIn(max(30 - graffiti[s].skill(Skill.art) * 2, 5))) {
      issue = View.issues.random;
      await showMessage(
          "${graffiti[s].name} has begun work on a large mural about ${issue.label}.");

      graffiti[s].activity.view = issue;
      power = 0;
      graffiti[s].train(Skill.art, 10);
      graffiti[s].train(Skill.streetSmarts, 5);
    } else {
      addjuice(graffiti[s], 1, 50);
      graffiti[s].train(Skill.art, 5);
      graffiti[s].train(Skill.streetSmarts, 5);
    }

    graffiti[s].train(Skill.art, 4);
    if (issue == View.lcsKnown) {
      changePublicOpinion(View.lcsKnown, lcsRandom(2));
      changePublicOpinion(View.lcsLiked, oneIn(8) ? 1 : 0);
    } else {
      changePublicOpinion(View.lcsKnown, 1);
      changePublicOpinion(View.lcsLiked, 1);
      politics.addBackgroundInfluence(issue, power);
    }
  }
}
