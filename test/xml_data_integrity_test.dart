import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/armor_upgrade.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/flag_type.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/sitemode/shop.dart';
import 'package:lcs_new_age/vehicles/vehicle_type.dart';

import 'test_support.dart';

/// Tests #4 and #5: the XML game data loads cleanly and is internally
/// consistent. These guard against typos and renames in assets/xml that the
/// Dart compiler can't catch but that crash the game when the affected entity
/// spawns or a screen does an unchecked `map[id]!` lookup.

/// Scrapes the creature id string literals out of the CreatureTypeIds source.
/// Dart has no runtime reflection under `flutter test` (`dart:mirrors` is
/// unavailable), so the source file is the single source of truth and we read
/// it directly rather than maintaining a parallel list.
Set<String> _creatureTypeIdsInSource() {
  final String source =
      File('lib/creature/creature_type.dart').readAsStringSync();
  return RegExp(r'static const String \w+ = "([^"]+)";')
      .allMatches(source)
      .map((m) => m.group(1)!)
      .toSet();
}

void main() {
  setUpAll(ensureGameDataLoaded);

  group('XML data integrity (#4)', () {
    test('all type tables are populated', () {
      expect(weaponTypes, isNotEmpty);
      expect(ammoTypes, isNotEmpty);
      expect(clothingTypes, isNotEmpty);
      expect(creatureTypes, isNotEmpty);
      expect(lootTypes, isNotEmpty);
      expect(flagTypes, isNotEmpty);
      expect(vehicleTypes, isNotEmpty);
      expect(armorUpgrades, isNotEmpty);
    });

    test('every mapOutdatedItem migration target exists', () {
      // Right-hand sides of mapOutdatedItem (item.dart): old saves are migrated
      // *to* these ids, so they must resolve or the migration corrupts items.
      const targets = <String>[
        'WEAPON_NONE', 'CLOTHING_BLACKBLOC', 'CLOTHING_CLOTHES',
        'WEAPON_22_REVOLVER', 'WEAPON_44_REVOLVER', 'WEAPON_45_HANDGUN',
        'WEAPON_9MM_HANDGUN', 'WEAPON_AA12', 'WEAPON_AK102', 'WEAPON_AR15',
        'WEAPON_M4', 'WEAPON_M250_MACHINEGUN', 'AMMO_22', 'AMMO_44', 'AMMO_45',
        'AMMO_9MM', 'AMMO_50AE', 'AMMO_BUCKSHOT', 'AMMO_556', 'AMMO_GASOLINE',
        'AMMO_68',
      ];
      for (final id in targets) {
        expect(itemTypes.containsKey(id), isTrue,
            reason: 'mapOutdatedItem target "$id" missing from itemTypes');
      }
    });

    // creatures.xml ids that intentionally have no CreatureTypeIds constant.
    // Currently empty: every creature has a constant. If you add a creature
    // that genuinely needs no Dart constant, list it here with a reason; a new
    // unlisted creature should fail the reverse check rather than be accepted.
    const xmlOnlyByDesign = <String>{};

    test('every CreatureTypeIds constant is defined in creatures.xml', () {
      final Set<String> sourceIds = _creatureTypeIdsInSource();
      expect(sourceIds, isNotEmpty,
          reason: 'Source scan matched no CreatureTypeIds constants — the regex '
              'in _creatureTypeIdsInSource is stale.');
      for (final id in sourceIds) {
        expect(creatureTypes.containsKey(id), isTrue,
            reason: 'CreatureTypeIds value "$id" is missing from creatures.xml');
      }
    });

    test('every creatures.xml creature has a CreatureTypeIds constant', () {
      final Set<String> sourceIds = _creatureTypeIdsInSource();
      // CREATURE_ prefix filter drops the "(string)" schema-doc template.
      final xmlIds =
          creatureTypes.keys.where((k) => k.startsWith('CREATURE_'));
      for (final id in xmlIds) {
        if (xmlOnlyByDesign.contains(id)) continue;
        expect(sourceIds.contains(id), isTrue,
            reason: 'creatures.xml defines "$id" with no CreatureTypeIds '
                'constant. Add one to CreatureTypeIds, or add "$id" to '
                'xmlOnlyByDesign with a reason.');
      }
    });
  });

  group('XML cross-references resolve (#5)', () {
    test('every gun has at least one compatible ammo type', () {
      for (final w in weaponTypes.values.where((w) => w.isAGun)) {
        expect(w.acceptableAmmo, isNotEmpty,
            reason: 'Gun ${w.idName} has no compatible ammo type '
                '(cartridge mismatch)');
      }
    });

    test('creature loadouts reference real weapons and clothing', () {
      // Valid non-weapon-id loadout values: "CIVILIAN" routes to
      // giveCivilianWeapon; an empty entry leaves the creature unarmed.
      // (WEAPON_NONE is a real weapon type and resolves normally.)
      const weaponSentinels = <String>{'CIVILIAN', ''};
      for (final type in creatureTypes.values) {
        for (final id in type.weaponTypeIds) {
          if (weaponSentinels.contains(id)) continue;
          expect(weaponTypes.containsKey(id), isTrue,
              reason: '${type.id} references missing weapon "$id"');
        }
        for (final id in type.armorTypeIds) {
          if (id.isEmpty) continue;
          expect(clothingTypes.containsKey(id), isTrue,
              reason: '${type.id} references missing clothing "$id"');
        }
      }
    });

    test('shop inventories reference real items', () {
      void checkShop(Shop shop) {
        for (final dept in shop.departments) {
          checkShop(dept);
        }
        for (final item in shop.items) {
          final Map<String, ItemType> table = switch (item.itemClass) {
            'WEAPON' => weaponTypes,
            'AMMO' || 'CLIP' => ammoTypes,
            'ARMOR' => clothingTypes,
            'LOOT' => lootTypes,
            _ => itemTypes,
          };
          expect(table.containsKey(item.itemId), isTrue,
              reason: 'Shop ${shop.id} sells missing '
                  '${item.itemClass} "${item.itemId}"');
        }
      }

      for (final shop in shopTypes.values) {
        checkShop(shop);
      }
    });
  });
}
