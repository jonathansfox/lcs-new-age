import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:xml/xml.dart';

void parseArmorUpgrade(ArmorUpgrade armor, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "name":
        armor.name = element.innerText;
      case "description":
        armor.description = element.innerText;
      case "visible":
        armor.visible = parseBool(element.innerText) ?? armor.visible;
      case "make_difficulty":
        armor.makeDifficulty =
            int.tryParse(element.innerText) ?? armor.makeDifficulty;
      case "make_price":
        armor.makePrice = int.tryParse(element.innerText) ?? armor.makePrice;
      case "dodgepenalty":
        armor.dodgePenalty =
            int.tryParse(element.innerText) ?? armor.dodgePenalty;
      case "armor":
        for (XmlElement e in element.childElements) {
          if (e.name.local == "body") {
            armor.bodyArmor = int.tryParse(e.innerText) ?? armor.bodyArmor;
          } else if (e.name.local == "head") {
            armor.headArmor = int.tryParse(e.innerText) ?? armor.headArmor;
          } else if (e.name.local == "limbs") {
            armor.limbArmor = int.tryParse(e.innerText) ?? armor.limbArmor;
          } else if (e.name.local == "fireprotection") {
            armor.fireResistant = parseBool(e.innerText) ?? armor.fireResistant;
          }
        }
      case "restricted":
        armor.restricted = parseBool(element.innerText) ?? armor.restricted;
      case "accuracypenalty":
        armor.accuracyPenalty =
            int.tryParse(element.innerText) ?? armor.accuracyPenalty;
      default:
        debugPrint("Unknown armor upgrade key: $key");
    }
  }
}
