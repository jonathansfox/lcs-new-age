import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/creature_type_xml.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/ammo_type_xml.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/items/armor_upgrade_xml.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/clothing_type_xml.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/items/loot_type_xml.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/items/weapon_type_xml.dart';
import 'package:lcs_new_age/sitemode/shop.dart';
import 'package:lcs_new_age/sitemode/shop_xml.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_tabscript.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';
import 'package:lcs_new_age/vehicles/vehicle_type_xml.dart';
import 'package:xml/xml.dart';

void loadingFeedback(String fileName) {
  erase();
  mvaddstr(8, 2, "Loading Liberal Crime Squad...");
  mvaddstr(10, 2, "File: $fileName");
  refresh();
}

Future<void> loadXmlData() async {
  loadingFeedback("sitemaps.txt");
  oldMapMode = !(await readConfigFile("assets/maps/sitemaps.txt"));
  loadingFeedback("clothing.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/clothing.xml'));
  loadingFeedback("armor_upgrades.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/armor_upgrades.xml'));
  loadingFeedback("loot.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/loot.xml'));
  loadingFeedback("creatures.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/creatures.xml'));
  loadingFeedback("weapons.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/weapons.xml'));
  loadingFeedback("ammo.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/ammo.xml'));
  loadingFeedback("vehicles.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/vehicles.xml'));
  loadingFeedback("oubliette.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/oubliette.xml'));
  loadingFeedback("deptstore.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/deptstore.xml'));
  loadingFeedback("armsdealer.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/armsdealer.xml'));
  loadingFeedback("pawnshop.xml");
  _parseDocument(await rootBundle.loadString('assets/xml/pawnshop.xml'));
}

void _parseDocument(String xml) {
  XmlDocument doc = XmlDocument.parse(xml);
  XmlElement root = doc.rootElement;
  if (root.localName == 'shop') {
    String? id = root.getAttribute('name');
    if (id != null) {
      parseShop(shopTypes[id] ?? Shop(id), root);
    } else {
      debugPrint("Shop has no name attribute, skipping");
    }
    return;
  }
  for (XmlElement element in root.childElements) {
    String typeName = element.localName;
    String? id = element.getAttribute('idname');
    if (typeName == 'default') {
      debugPrint("Unknown default element in ${root.name.local}");
      continue;
    }
    if (id == null) {
      debugPrint("$typeName has no idname attribute, skipping");
      continue;
    }
    switch (typeName) {
      case 'clothingtype':
        parseClothingType(clothingTypes[id] ?? ClothingType(id), element);
      case 'armorupgrade':
        parseArmorUpgrade(armorUpgrades[id] ?? ArmorUpgrade(id), element);
      case 'loottype':
        parseLootType(lootTypes[id] ?? LootType(id), element);
      case 'creaturetype':
        parseCreatureType(creatureTypes[id] ?? CreatureType(id), element);
      case 'weapontype':
        parseWeaponType(weaponTypes[id] ?? WeaponType(id), element);
      case 'vehicletype':
        parseVehicleType(vehicleTypes[id] ?? VehicleType(id), element);
      case 'ammotype':
        parseAmmoType(ammoTypes[id] ?? AmmoType(id), element);
      default:
        debugPrint("Unknown element $typeName in ${root.name.local}");
    }
  }
}
