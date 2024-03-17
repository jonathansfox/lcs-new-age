import 'package:lcs_new_age/items/armor_type.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:xml/xml.dart';

void parseArmorType(ArmorType armor, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "make_difficulty":
        armor.makeDifficulty =
            int.tryParse(element.innerText) ?? armor.makeDifficulty;
      case "make_price":
        armor.makePrice = int.tryParse(element.innerText) ?? armor.makePrice;
      case "deathsquad_legality":
        armor.deathsquadLegality =
            parseBool(element.innerText) ?? armor.deathsquadLegality;
      case "lawenforcement":
        armor.police = parseBool(element.innerText) ?? armor.police;
      case "can_get_bloody":
        armor.canGetBloody = parseBool(element.innerText) ?? armor.canGetBloody;
      case "can_get_damaged":
        armor.canGetDamaged =
            parseBool(element.innerText) ?? armor.canGetDamaged;
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
      case "body_covering":
        for (XmlElement e in element.childElements) {
          if (e.name.local == "body") {
            armor.coversBody = parseBool(e.innerText) ?? armor.coversBody;
          } else if (e.name.local == "head") {
            armor.coversHead = parseBool(e.innerText) ?? armor.coversHead;
          } else if (e.name.local == "arms") {
            armor.coversArms = parseBool(e.innerText) ?? armor.coversArms;
          } else if (e.name.local == "legs") {
            armor.coversLegs = parseBool(e.innerText) ?? armor.coversLegs;
          } else if (e.name.local == "conceals_face") {
            armor.concealsFace = parseBool(e.innerText) ?? armor.concealsFace;
          }
        }
      case "stealth_value":
        armor.stealthValue =
            int.tryParse(element.innerText) ?? armor.stealthValue;
      case "name":
        armor.name = element.innerText;
      case "shortname":
        armor.shortName = element.innerText;
      case "fencevalue":
        armor.fenceValue = int.tryParse(element.innerText) ?? armor.fenceValue;
      case "interrogation":
        for (XmlElement e in element.childElements) {
          if (e.name.local == "basepower") {
            armor.interrogationBasePower =
                int.tryParse(e.innerText) ?? armor.interrogationBasePower;
          } else if (e.name.local == "assaultbonus") {
            armor.interrogationAssaultBonus =
                int.tryParse(e.innerText) ?? armor.interrogationAssaultBonus;
          } else if (e.name.local == "drugbonus") {
            armor.interrogationDrugBonus =
                int.tryParse(e.innerText) ?? armor.interrogationDrugBonus;
          }
        }
      case "professionalism":
        armor.professionalism =
            int.tryParse(element.innerText) ?? armor.professionalism;
      case "conceal_weapon_size":
        armor.concealWeaponSize =
            int.tryParse(element.innerText) ?? armor.concealWeaponSize;
      // Ignore this; everything has 4 quality levels
      /*
      case "qualitylevels":
        armor.qualityLevels =
            int.tryParse(element.innerText) ?? armor.qualityLevels;
      */
      case "appropriate_weapon":
        armor.weaponsPermittedIds.add(element.innerText);
      case "durability":
        armor.durability = int.tryParse(element.innerText) ?? armor.durability;
    }
  }
}
