import 'package:json_annotation/json_annotation.dart';

class ItemType {
  ItemType(this.idName) {
    name = idName;
    fenceValue = 0;
    itemTypes[idName] = this;
  }
  String name = "Buggy Item";
  String? nameFuture;
  String idName;
  double fenceValue = 0;
  bool isMoney = false;

  static ItemType fromJson(String id) => itemTypes[id]!;
  String toJson() => idName;
}

final Map<String, ItemType> itemTypes = {};

class ItemTypeJsonConverter<T extends ItemType>
    implements JsonConverter<T, String> {
  const ItemTypeJsonConverter();

  @override
  T fromJson(String json) => ItemType.fromJson(json) as T;

  @override
  String toJson(ItemType object) => object.toJson();
}
