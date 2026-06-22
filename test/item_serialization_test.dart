import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/money.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';

import 'test_support.dart';

/// Test #2: every item subtype survives a JSON round-trip.
///
/// `Item.fromJson` dispatches on the resolved type to Weapon/Clothing/Ammo/
/// Loot/Flag/Money. This exercises that dispatch for every registered type and
/// checks that each subtype's generated serializer preserves its state.
Item _roundTrip(Item item) =>
    Item.fromJson(jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>);

void main() {
  setUpAll(ensureGameDataLoaded);

  group('Every registered item type round-trips', () {
    test('subtype, typeName and serialization are preserved', () {
      for (final ItemType type in itemTypes.values) {
        final Item item = Item(type.idName);
        final Item back = _roundTrip(item);
        expect(back.runtimeType, item.runtimeType,
            reason: 'Subtype changed for ${type.idName}');
        expect(back.typeName, item.typeName,
            reason: 'typeName changed for ${type.idName}');
        expect(back.toJson(), equals(item.toJson()),
            reason: 'Serialization not idempotent for ${type.idName}');
      }
    });
  });

  group('Stateful item fields survive round-trip', () {
    test('weapon retains ammo and loaded ammo type', () {
      final WeaponType gun = weaponTypes.values
          .firstWhere((w) => w.usesAmmo && w.acceptableAmmo.isNotEmpty);
      final Weapon w = Weapon(gun.idName)
        ..loadedAmmoType = gun.acceptableAmmo.first
        ..ammo = 3;
      final Weapon back = _roundTrip(w) as Weapon;
      expect(back.ammo, 3);
      expect(back.loadedAmmoId, w.loadedAmmoId);
      expect(back.toJson(), equals(w.toJson()));
    });

    test('clothing retains quality, bloody flag, armor and damage', () {
      final ClothingType ct =
          clothingTypes.values.firstWhere((c) => c.allowedArmor.isNotEmpty);
      final Clothing c = Clothing(ct.idName)
        ..quality = 3
        ..bloody = true
        ..bodyArmor = 1
        ..headArmor = 1;
      final Clothing back = _roundTrip(c) as Clothing;
      expect(back.quality, c.quality);
      expect(back.bloody, isTrue);
      expect(back.armorId, c.armorId);
      expect(back.bodyArmor, c.bodyArmor);
      expect(back.headArmor, c.headArmor);
      expect(back.toJson(), equals(c.toJson()));
    });

    test('ammo retains stack size', () {
      final Ammo a = Ammo(ammoTypes.values.first.idName)..stackSize = 17;
      expect((_roundTrip(a) as Ammo).stackSize, 17);
    });

    // Money should never actually be persisted as an item, but if the design
    // ever changes so it can, it must survive the round-trip as Money (not
    // silently become Loot, since MONEY is a LootType flagged isMoney).
    test('money round-trips as Money with its amount intact', () {
      final Item back = _roundTrip(Money(250));
      expect(back, isA<Money>(),
          reason: 'money must deserialize as Money, not Loot');
      expect(back.stackSize, 250);
    });
  });
}
