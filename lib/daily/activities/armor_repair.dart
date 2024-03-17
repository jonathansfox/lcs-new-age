import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/items/armor.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

Future<void> doActivityRepairArmor(Creature cr) async {
  Armor? armor;
  bool pile = false;
  if (cr.armor.bloody || cr.armor.damaged) {
    armor = cr.armor;
  } else {
    // Identify the best armor to repair
    int score(Armor a) {
      int score = 0;
      if (a.bloody) score++;
      if (a.damaged) score++;
      return score;
    }

    Armor? bestScore(Armor? a, Armor b) {
      if (a == null) {
        if (score(b) > 0) return b;
        return null;
      }
      return score(a) >= score(b) ? a : b;
    }

    armor = cr.base?.loot.whereType<Armor>().fold(null, bestScore);
    pile = true;
  }

  if (armor == null) return;

  String armorName = armor.type.name;
  String aan = pile ? aOrAn(armorName) : cr.gender.hisHer;
  bool repairFailed = true;
  bool armorDestroyed = armor.quality > armor.type.qualityLevels;
  if (armor.damaged) {
    int difficulty = armor.type.makeDifficultyFor(cr);
    cr.train(Skill.tailoring, difficulty);
  }

  if (pile && armor.stackSize > 0) {
    Item newArmor = armor.split(1);
    cr.base!.loot.add(newArmor);
    armor = newArmor as Armor;
  }

  if (armorDestroyed) {
    await showMessage(
        "${cr.name} recycles the remains of $aan $armorName into cloth.",
        color: red);
  } else if (repairFailed && armor.bloody) {
    await showMessage("${cr.name} washes $aan $armorName.", color: lightBlue);
  } else {
    await showMessage("${cr.name} repairs $aan $armorName.", color: lightGreen);
  }

  armor.bloody = false;
  armor.damaged = false;
  if (armorDestroyed) {
    if (!pile) {
      cr.strip();
    } else {
      cr.base!.loot.remove(armor);
    }
    cr.base!.loot.add(Loot("LOOT_RECYCLEDCLOTH"));
  }
}
