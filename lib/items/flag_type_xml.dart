import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/flag_type.dart';
import 'package:xml/xml.dart';

void parseFlagType(FlagType flag, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.localName;
    switch (key) {
      case 'name':
        flag.name = element.innerText;
      case 'shortname':
        flag.shortName = element.innerText;
      case 'asset':
        flag.asset = element.innerText;
      case 'category':
        flag.category = FlagCategory.values.asNameMap()[element.innerText] ??
            flag.category;
      case 'description':
        flag.description = element.innerText;
      case 'buyable':
        flag.buyable = bool.tryParse(element.innerText) ?? flag.buyable;
      case 'make_difficulty':
        flag.makeDifficulty =
            int.tryParse(element.innerText) ?? flag.makeDifficulty;
      case 'make_price':
        flag.makePrice = int.tryParse(element.innerText) ?? flag.makePrice;
      case 'fencevalue':
        flag.fenceValue = double.tryParse(element.innerText) ?? flag.fenceValue;
      default:
        debugPrint("Unknown flag type key: $key");
    }
  }
}
