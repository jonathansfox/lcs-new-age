import 'package:lcs_new_age/items/item_type.dart';

Map<String, AmmoType> ammoTypes = {};

class AmmoType extends ItemType {
  AmmoType(String id) : super(id) {
    ammoTypes[id] = this;
  }
  // Number of rounds in the magazine; used for the old "clip" ammo model,
  // and should be changed once we switch to the new system
  String cartridge = "";
  int damage = 0;
  int multihit = 1;
  int recoil = 1;
  int boxSize = 1;
  int boxPrice = 0;
}
