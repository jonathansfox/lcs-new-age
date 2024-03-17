import 'package:collection/collection.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/attack.dart';
import 'package:lcs_new_age/items/item_type.dart';

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
  bool musicalAttack = false;
  bool instrument = false;
  int legality = 2;
  double bashStrengthModifier = 1;
  bool suspicious = true;
  int size = 15;
  bool canGraffiti = false;
  bool autoBreakLock = false;
  List<Attack> attacks = [];

  Attack? get attack => attacks.firstOrNull;
  Attack? get rangedAttack => attacks.where((a) => a.ranged).firstOrNull;
  Attack? get meleeAttack => attacks.where((a) => !a.ranged).firstOrNull;

  bool get thrown => attacks.any((a) => a.thrown);
  bool get usesAmmo => attacks.any((a) => a.usesAmmo);
  AmmoType? get ammoType =>
      attacks.firstWhereOrNull((a) => a.ammoTypeId != null)?.ammoType;
  int? _ammoCapacity;
  int get ammoCapacity => _ammoCapacity ?? ammoType?.ammo ?? 0;
}
