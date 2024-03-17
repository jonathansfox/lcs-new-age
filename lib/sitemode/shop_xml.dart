import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/saveload/parse_value.dart';
import 'package:lcs_new_age/sitemode/shop.dart';
import 'package:xml/xml.dart';

void parseShop(Shop shop, XmlElement xml) {
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "only_sell_legal_items":
        shop.onlySellLegalItems =
            parseBool(element.innerText) ?? shop.onlySellLegalItems;
      case "fullscreen":
        shop.fullscreen = parseBool(element.innerText) ?? shop.fullscreen;
      case "allow_selling":
        shop.allowSelling = parseBool(element.innerText) ?? shop.allowSelling;
      case "increase_prices_with_illegality":
        shop.increasePricesWithIllegality =
            parseBool(element.innerText) ?? shop.increasePricesWithIllegality;
      case "exit":
        shop.exitText = element.innerText;
      case "entry":
        shop.description = element.innerText;
      case "letter":
        if (element.innerText.isNotEmpty) {
          shop.letter = element.innerText;
        }
      case "department":
        Shop department = Shop.departmentOf(shop);
        parseShop(department, element);
        shop.departments.add(department);
      case "item":
        ShopItem? item = parseShopItem(element, shop);
        if (item != null) {
          shop.items.add(item);
        }
      case "sell_masks":
        shop.sellMasks = parseBool(element.innerText) ?? shop.sellMasks;
    }
  }
}

ShopItem? parseShopItem(XmlElement xml, Shop shop) {
  String? itemClass;
  String? itemId;
  int? price;
  String? description;
  String? letter;
  for (XmlElement element in xml.childElements) {
    String key = element.name.local;
    switch (key) {
      case "class":
        itemClass = element.innerText;
      case "type":
        itemId = element.innerText;
      case "price":
        price = int.tryParse(element.innerText) ?? price;
      case "description":
        description = element.innerText;
      case "letter":
        letter = element.innerText;
    }
  }
  if (itemClass != null && itemId != null && price != null) {
    return ShopItem(itemClass, itemId, price, shop)
      ..description = description
      ..letter = letter;
  } else {
    debugPrint("Invalid shop item in XML: ${xml.toXmlString()}");
    return null;
  }
}
