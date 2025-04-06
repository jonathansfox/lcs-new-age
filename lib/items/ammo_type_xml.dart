import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:xml/xml.dart';

void parseAmmoType(AmmoType type, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "name":
        type.name = element.innerText;
      case "name_future":
        type.nameFuture = element.innerText;
      case "cartridge":
        type.cartridge = element.innerText;
      case "damage":
        type.damage = int.tryParse(element.innerText) ?? type.damage;
      case "multihit":
        type.multihit = int.tryParse(element.innerText) ?? type.multihit;
      case "recoil":
        type.recoil = int.tryParse(element.innerText) ?? type.recoil;
      case "fencevalue":
        type.fenceValue = double.tryParse(element.innerText) ?? type.fenceValue;
      case "boxsize":
        type.boxSize = int.tryParse(element.innerText) ?? type.boxSize;
      case "boxprice":
        type.boxPrice = int.tryParse(element.innerText) ?? type.boxPrice;
      default:
        debugPrint("Unknown ammo type key: $key");
    }
  }
}
