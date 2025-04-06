Map<String, ArmorUpgrade> armorUpgrades = {};

class ArmorUpgrade {
  ArmorUpgrade(String id) : idName = id {
    armorUpgrades[id] = this;
  }

  String idName = "BUGGY_CHITIN";
  String name = "Buggy Chitin";
  String description = "Something lying around in the bugfield.";
  bool restricted = false;
  bool visible = false;
  int dodgePenalty = 0;
  int accuracyPenalty = 0;
  int bodyArmor = 0;
  int headArmor = 0;
  int limbArmor = 0;
  bool fireResistant = false;
  int makeDifficulty = 0;
  int makePrice = 0;
}
