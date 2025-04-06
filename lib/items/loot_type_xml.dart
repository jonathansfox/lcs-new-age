import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:xml/xml.dart';

void parseLootType(LootType loot, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.localName;
    switch (key) {
      case 'name':
        loot.name = element.innerText;
      case 'stackable':
        loot.stackable = bool.tryParse(element.innerText) ?? loot.stackable;
      case 'no_quick_fencing':
        loot.noQuickFencing =
            bool.tryParse(element.innerText) ?? loot.noQuickFencing;
      case 'cloth':
        loot.cloth = bool.tryParse(element.innerText) ?? loot.cloth;
      case 'fencevalue':
        loot.fenceValue = double.tryParse(element.innerText) ?? loot.fenceValue;
      default:
        debugPrint("Unknown loot type key: $key");
    }
  }
}
