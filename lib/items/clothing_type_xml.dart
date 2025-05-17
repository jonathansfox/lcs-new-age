import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:xml/xml.dart';

Map<String, XmlElement> originalXml = {};

void parseClothingType(ClothingType clothing, XmlElement xml,
    {bool modifying = false}) {
  if (!modifying) {
    originalXml[clothing.idName] = xml;
  }
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "make_difficulty":
        clothing.makeDifficulty =
            int.tryParse(element.innerText) ?? clothing.makeDifficulty;
      case "make_price":
        clothing.makePrice =
            int.tryParse(element.innerText) ?? clothing.makePrice;
      case "deathsquad_legality":
        clothing.deathsquadLegality =
            parseBool(element.innerText) ?? clothing.deathsquadLegality;
      case "lawenforcement":
        clothing.police = parseBool(element.innerText) ?? clothing.police;
      case "can_get_bloody":
        clothing.canGetBloody =
            parseBool(element.innerText) ?? clothing.canGetBloody;
      case "can_get_damaged":
        clothing.canGetDamaged =
            parseBool(element.innerText) ?? clothing.canGetDamaged;
      case "body_covering":
        for (XmlElement e in element.childElements) {
          if (e.name.local == "body") {
            clothing.coversBody = parseBool(e.innerText) ?? clothing.coversBody;
          } else if (e.name.local == "head") {
            clothing.coversHead = parseBool(e.innerText) ?? clothing.coversHead;
          } else if (e.name.local == "arms") {
            clothing.coversArms = parseBool(e.innerText) ?? clothing.coversArms;
          } else if (e.name.local == "legs") {
            clothing.coversLegs = parseBool(e.innerText) ?? clothing.coversLegs;
          } else if (e.name.local == "conceals_face") {
            clothing.concealsFace =
                parseBool(e.innerText) ?? clothing.concealsFace;
          }
        }
      case "stealth_value":
        clothing.stealthValue =
            int.tryParse(element.innerText) ?? clothing.stealthValue;
      case "name":
        clothing.name = element.innerText;
      case "shortname":
        clothing.shortName = element.innerText;
      case "fencevalue":
        clothing.fenceValue =
            double.tryParse(element.innerText) ?? clothing.fenceValue;
      case "interrogation":
        for (XmlElement e in element.childElements) {
          if (e.name.local == "basepower") {
            clothing.interrogationBasePower =
                int.tryParse(e.innerText) ?? clothing.interrogationBasePower;
          } else if (e.name.local == "assaultbonus") {
            clothing.interrogationAssaultBonus =
                int.tryParse(e.innerText) ?? clothing.interrogationAssaultBonus;
          } else if (e.name.local == "drugbonus") {
            clothing.interrogationDrugBonus =
                int.tryParse(e.innerText) ?? clothing.interrogationDrugBonus;
          }
        }
      case "modification_of":
        if (originalXml.containsKey(element.innerText)) {
          parseClothingType(clothing, originalXml[element.innerText]!,
              modifying: true);
          debugPrint(originalXml[element.innerText]!.outerXml);
        } else {
          debugPrint("Modification of ${element.innerText} could not be "
              "completed because ${element.innerText} was not found");
        }
      case "professionalism":
        clothing.professionalism =
            int.tryParse(element.innerText) ?? clothing.professionalism;
      case "conceal_weapon_size":
        clothing.concealWeaponSize =
            int.tryParse(element.innerText) ?? clothing.concealWeaponSize;
      case "appropriate_weapon":
        clothing.weaponsPermittedIds.add(element.innerText);
      case "durability":
        clothing.durability =
            int.tryParse(element.innerText) ?? clothing.durability;
      case "description":
        clothing.description = element.innerText;
      case "alarming":
        clothing.alarming = parseBool(element.innerText) ?? clothing.alarming;
      case "upgradable":
        clothing.upgradable =
            parseBool(element.innerText) ?? clothing.upgradable;
      case "intrinsic_armor":
        clothing.intrinsicArmorId = element.innerText;
      case "allow_visible_armor":
        clothing.allowVisibleArmor =
            parseBool(element.innerText) ?? clothing.allowVisibleArmor;
      case "armor_allowed":
        clothing.allowedArmorIds.add(element.innerText);
      default:
        debugPrint("Unknown clothing type key: $key");
    }
  }
}
