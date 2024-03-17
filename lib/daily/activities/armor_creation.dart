import 'dart:math';

import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/armor.dart';
import 'package:lcs_new_age/items/armor_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivityMakeArmor(Creature cr) async {
  ArmorType at = cr.activity.armorType ?? armorTypes.values.first;
  int cost = at.makePrice;
  int dif = at.makeDifficultyFor(cr);
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
    await showMessage("${cr.name} doesn't have enough money to make clothing.");
    return;
  }
  ledger.subtractFunds(cost, Expense.sewingSupplies);
  cr.train(Skill.tailoring, dif * 2 + 1);
  int quality = 1;
  while (min(lcsRandom(10), lcsRandom(10)) < dif - quality &&
      quality <= at.qualityLevels) {
    quality++;
    cr.train(Skill.tailoring, dif);
  }
  if (quality <= at.qualityLevels) {
    Item it = Armor.fromType(at, quality: quality);
    String rate;
    switch (quality) {
      case 1:
        rate = "first";
      case 2:
        rate = "second";
      case 3:
        rate = "third";
      case 4:
        rate = "fourth";
      default:
        rate = "${quality}th";
    }
    await showMessage("${cr.name} created $rate-rate ${at.name}.");
    cr.site?.loot.add(it);
  } else {
    switch (lcsRandom(7)) {
      case 0:
        await showMessage("${cr.name} produced an unwearable cloth monster.");
      case 1:
        await showMessage("${cr.name} wasted the materials for a ${at.name}.");
      case 2:
        await showMessage("${cr.name} tried to make ${at.name}, but failed.");
      case 3:
        await showMessage(
            "${cr.name} made a horrible nightmare of cloth and stitching.");
      case 4:
        await showMessage("${cr.name} stitched something bad.");
      case 5:
        await showMessage(
            "${cr.name} got inches and feet mixed up and is now drowning in cloth.");
      case 6:
        await showMessage(
            "${cr.name} got feet and inches mixed up and is now outfitting ants.");
    }
    cr.site?.loot.add(Loot("LOOT_RECYCLEDCLOTH"));
  }
}
