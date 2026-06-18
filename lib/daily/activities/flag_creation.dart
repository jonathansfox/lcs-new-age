import 'dart:math';

import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/flag.dart';
import 'package:lcs_new_age/items/flag_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivityMakeFlag(Creature cr) async {
  FlagType flag = cr.activity.flagType ?? flagTypes.values.first;
  int cost = flag.makePrice;
  int dif = flag.makeDifficultyFor(cr);

  // Halve the supply cost if there is cloth on hand to repurpose.
  Iterable<Item>? cloths =
      cr.site?.loot.where((e) => e is Loot && e.type.cloth);
  Item? foundCloth;
  if (cloths != null && cloths.isNotEmpty) {
    foundCloth = cloths.reduce((previousValue, element) =>
        previousValue.type.fenceValue > element.type.fenceValue
            ? element
            : previousValue);
  }
  if (foundCloth != null) {
    cost = cost ~/ 2;
    if (foundCloth.stackSize > 1) {
      foundCloth.stackSize--;
    } else {
      cr.site?.loot.remove(foundCloth);
    }
  }

  if (ledger.funds < cost) {
    await showMessage("${cr.name} doesn't have enough money to make a flag.");
    cr.activity = Activity.none();
    return;
  }
  ledger.subtractFunds(cost, Expense.sewingSupplies);
  cr.train(Skill.tailoring, flag.makeDifficulty * 2 + 1);

  // A single skill check: succeed and you get a flag, fail and the supplies are
  // ruined (no second-rate flag).
  if (max(lcsRandom(10), lcsRandom(10)) >= dif) {
    cr.site?.loot.add(Flag.fromType(flag));
    await showMessage("${cr.name} sewed a ${flag.name}.");
    cr.activity = Activity.none();
  } else {
    switch (lcsRandom(7)) {
      case 0:
        await showMessage(
            "${cr.name} messed up and made an ugly, unusable flag.");
      case 1:
        await showMessage(
            "${cr.name} wasted the materials for a ${flag.name}.");
      case 2:
        await showMessage(
            "${cr.name} tried to make a ${flag.name}, but failed.");
      case 3:
        await showMessage("${cr.name} made a nightmarish flag monster.");
      case 4:
        await showMessage("${cr.name} mixed up the colors on a ${flag.name}.");
      case 5:
        await showMessage(
            "${cr.name} really messed up trying to make a ${flag.name}.");
      case 6:
        await showMessage(
            "${cr.name} got feet and inches mixed up and made a flag for ants.");
    }
    cr.site?.loot.add(Loot(LootTypeIds.recycledCloth));
  }
}
