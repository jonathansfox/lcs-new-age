import 'package:collection/collection.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/politics/alignment.dart';

Map<String, WeaponType> weaponTypes = {};

class WeaponType extends ItemType {
  WeaponType(String id) : super(id) {
    weaponTypes[id] = this;
  }

  String? _shortName;
  String get shortName => _shortName ?? name;
  set shortName(String value) => _shortName = value;
  String? largeSubtypeName;
  String? smallSubtypeName;
  String? largeSubtypeShortName;
  String? smallSubtypeShortName;
  String? description;

  String? futureShortName;
  String? futureLargeSubtypeName;
  String? futureSmallSubtypeName;
  String? futureLargeSubtypeShortName;
  String? futureSmallSubtypeShortName;

  bool canTakeHostages = false;
  bool threatening = false;
  bool canThreatenHostages = true;
  bool protectsAgainstKidnapping = true;
  bool carriedByCivilians = false;
  bool get musicalAttack => attacks.any((a) => a.socialDamage) && instrument;
  bool instrument = false;
  DeepAlignment? bannedAtGunControl;
  bool suspicious = true;
  int size = 3;
  double get bashStrengthModifier => 0.6 + 0.2 * size;
  bool canGraffiti = false;
  bool autoBreakLock = false;
  List<Attack> attacks = [];
  int price = 0;

  Attack? get attack => attacks.firstOrNull;
  Attack? get rangedAttack => attacks.where((a) => a.ranged).firstOrNull;
  Attack? get meleeAttack => attacks.where((a) => !a.ranged).firstOrNull;

  bool get thrown => attacks.any((a) => a.thrown);
  bool get usesAmmo => attacks.any((a) => a.usesAmmo);

  Iterable<String> get acceptableCartridge =>
      attacks.map((attack) => attack.cartridge).nonNulls;
  Iterable<AmmoType> get acceptableAmmo => ammoTypes.values
      .where((at) => acceptableCartridge.contains(at.cartridge));
  int ammoCapacity = 1;
  bool canKeepOneInTheChamber = false;

  bool get isAGun {
    return attacks.any((a) => a.ranged && a.cartridge != null);
  }
}
