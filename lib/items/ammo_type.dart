import 'package:lcs_new_age/items/item_type.dart';

Map<String, AmmoType> ammoTypes = {};

class AmmoType extends ItemType {
  AmmoType(String id) : super(id) {
    ammoTypes[id] = this;
  }
  // Number of rounds in the magazine; used for the old "clip" ammo model,
  // and should be changed once we switch to the new system
  int ammo = 0;
}
