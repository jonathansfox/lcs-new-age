import 'package:lcs_new_age/items/item_type.dart';

Map<String, LootType> lootTypes = {};

class LootType extends ItemType {
  LootType(String id) : super(id) {
    lootTypes[id] = this;
  }
  bool stackable = false;
  bool noQuickFencing = false;
  bool cloth = false;
}
