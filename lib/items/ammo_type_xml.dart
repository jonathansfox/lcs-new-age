import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:xml/xml.dart';

void parseClipType(AmmoType type, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "name":
        type.name = element.innerText;
      case "name_future":
        type.nameFuture = element.innerText;
      case "ammo":
        type.ammo = int.tryParse(element.innerText) ?? type.ammo;
      case "fencevalue":
        type.fenceValue = int.tryParse(element.innerText) ?? type.fenceValue;
    }
  }
}
