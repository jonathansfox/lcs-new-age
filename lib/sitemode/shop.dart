import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/common_display/print_party.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/daily/shopsnstuff.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/ammo.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/item_type.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/weapon.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Map<String, Shop> shopTypes = {};

abstract class ShopOption {
  bool display() => true;
  String halfscreenDescription() => description ?? "";
  String fullscreenDescription() => description ?? "";
  bool isAvailable() => true;
  String? description;
  String? _letter;
  String? get letter => _letter?.toLowerCase();
  set letter(String? val) => _letter = val;
  Future<void> choose(Squad customers, Creature buyer, bool sleeper) async {}
}

class ShopItem extends ShopOption {
  ShopItem(this.itemClass, this.itemId, int price, this.parentShop)
      : _price = price,
        sleeperprice = (price * 0.8).round();
  final String itemClass;
  final String itemId;
  final int _price;
  int price(bool sleeper) {
    int scale = 1;
    if (parentShop.increasePricesWithIllegality && itemClass == "WEAPON") {
      WeaponType weaponType = weaponTypes[itemId]!;
      scale = laws[Law.gunControl]!.index -
          (weaponType.bannedAtGunControl?.index ?? 3) +
          2;
      if (scale < 1) scale = 1;
    }
    if (sleeper) {
      return sleeperprice * scale;
    }
    return _price * scale;
  }

  final Shop parentShop;
  final int sleeperprice;
  String? _description;
  @override
  String? get description => _description ?? itemTypes[itemId]?.name;
  @override
  set description(String? val) => _description = val;

  @override
  bool display() => isAvailable();

  @override
  bool isAvailable() {
    if (parentShop.onlySellLegalItems) {
      if (itemClass == "WEAPON") {
        if ((weaponTypes[itemId]!.bannedAtGunControl?.index ?? 99) <
            laws[Law.gunControl]!.index) {
          return false;
        }
      }
    }
    return true;
  }

  @override
  Future<void> choose(Squad customers, Creature buyer, bool sleeper) async {
    if (ledger.funds >= price(sleeper)) {
      if (!isAvailable()) return;
      ledger.subtractFunds(price(sleeper), Expense.shopping);
      switch (itemClass) {
        case "WEAPON":
          Weapon i = Weapon(itemId);
          buyer.giveWeapon(i, buyer.base?.loot);
        case "AMMO":
        case "CLIP":
          Ammo i = Ammo(itemId);
          buyer.takeAmmo(i, buyer.base?.loot, 1);
          if (i.stackSize > 0) buyer.base?.loot.add(i);
        case "ARMOR":
          Clothing i = Clothing(itemId);
          buyer.giveArmor(i, buyer.base?.loot);
        case "LOOT":
          Loot i = Loot(itemId);
          buyer.base!.loot.add(i);
      }
    }
  }
}

class Shop extends ShopOption {
  factory Shop(String id) {
    Shop shop = Shop._()..id = id;
    shopTypes[id] = shop;
    return shop;
  }
  factory Shop.departmentOf(Shop parent) {
    Shop department = Shop._()
      ..onlySellLegalItems = parent.onlySellLegalItems
      ..fullscreen = parent.fullscreen
      ..increasePricesWithIllegality = parent.increasePricesWithIllegality;
    return department;
  }
  Shop._();

  String id = "";
  bool onlySellLegalItems = true;
  bool fullscreen = false;
  bool increasePricesWithIllegality = false;
  bool allowSelling = false;
  bool sellMasks = false;
  String exitText = "";

  List<Shop> departments = [];
  List<ShopItem> items = [];
  Iterable<ShopOption> get options =>
      <ShopOption>[].followedBy(departments).followedBy(items);

  @override
  Future<void> choose(Squad customers, Creature buyer, bool sleeper) async {
    await enter(customers, buyer: buyer);
  }

  Future<void> enter(Squad customers, {Creature? buyer}) async {
    if (fullscreen) {
      await browseFullscreen(customers, buyer);
    } else {
      await browseHalfscreen(customers, buyer);
    }
  }

  Future<void> browseHalfscreen(Squad customers, Creature? buyer) async {
    buyer ??= customers.members[0];
    int page = 0, partysize = squadsize(customers);

    List<ShopOption> availableOptions =
        options.where((o) => o.display()).toList();

    while (true) {
      erase();
      setColor(lightGray);

      locHeader();
      printParty();

      mvaddstr(8, 45, "Buyer: ");
      addstr(buyer!.name);

      //Write wares and prices
      int y = 10, x = 1, takenLetters = 0;
      for (int p = page * 19;
          p < availableOptions.length && p < page * 19 + 20;
          p++) {
        if (availableOptions[p].isAvailable()) {
          setColor(lightGray);
        } else {
          setColor(darkGray);
        }
        if (x == 1) {
          move(y, 1);
        } else {
          move(y, 40);
        }

        if (availableOptions[p].letter != null) {
          addchar(availableOptions[p].letter!.toUpperCase());
        } else {
          // Find an available letter to use for this ware.
          bool done = false;
          while (takenLetters < 27 && !done) {
            done = true;
            if (Key.a + takenLetters ==
                    Key.b || // Letters used by the shop UI are disallowed.
                Key.a + takenLetters == Key.e ||
                (Key.a + takenLetters == Key.s && allowSelling) ||
                (Key.a + takenLetters == Key.m && sellMasks)) {
              takenLetters++;
              done = false;
              continue;
            }
            for (int i = 0; i < availableOptions.length; i++) {
              if (availableOptions[i].letter != null &&
                  letterAPlus(takenLetters) == availableOptions[i].letter) {
                takenLetters++;
                done = false;
                break;
              }
            }
          }
          availableOptions[p].letter = letterAPlus(takenLetters);
          addchar(letterAPlus(takenLetters++));
        }

        addstr(" - ");
        addstr(availableOptions[p].halfscreenDescription());
        if (availableOptions[p] is ShopItem) {
          addstr(" (\$${(availableOptions[p] as ShopItem).price(false)})");
        }
        if (x == 1) {
          x = 2;
        } else {
          y++;
          x = 1;
        }
      }
      if (sellMasks) {
        move(y, 1 + (x - 1) * 39);
        if (ledger.funds >= 15) {
          setColor(lightGray);
        } else {
          setColor(darkGray);
        }
        addstr("M - Buy a Mask (\$15)");
      }
      if (x == 2) y++;

      mvaddstrc(y++, 1, lightGray, "E - Look over Equipment");

      if (allowSelling) {
        move(y++, 1);
        if (customers.members[0].base?.loot.isNotEmpty == true) {
          setColor(lightGray);
        } else {
          setColor(darkGray);
        }
        addstr("S - Sell something");
      }

      setColorConditional(activeSquadMemberIndex != -1);
      mvaddstr(++y, 1, "0 - Show the squad's Liberal status");
      setColorConditional(
          partysize > 0 && (activeSquadMemberIndex == -1 || partysize > 1));
      mvaddstr(y++, 40, "# - Check the status of a squad Liberal");
      setColorConditional(partysize >= 2);
      mvaddstr(y, 1, "B - Choose a buyer");

      mvaddstrc(y, 40, lightGray, "Enter - $exitText");

      int c = await getKey();

      for (int i = 0; i < availableOptions.length; i++) {
        if (c == availableOptions[i].letter?.toUpperCase().codePoint) {
          await availableOptions[i].choose(customers, buyer, false);
          break;
        }
      }

      if (c == Key.e && buyer.base != null) {
        await equip(buyer.base!.loot);
      } else if (c == Key.s &&
          allowSelling &&
          buyer.base?.loot.isNotEmpty == true) {
        await sellLoot(customers);
      } else if (c == Key.m && sellMasks && ledger.funds >= 15) {
        await maskselect(buyer);
      } else if (c == Key.b) {
        buyer = await chooseBuyer(buyer);
      } else if (c == Key.num0) {
        activeSquadMemberIndex = -1;
      } else if (c >= Key.num1 && c < Key.num1 + customers.members.length) {
        buyer = customers.members[c - Key.num1];
        if (activeSquadMember == buyer) {
          await fullCreatureInfoScreen(buyer);
        } else {
          activeSquadMember = buyer;
        }
      } else if (isBackKey(c)) {
        break;
      }
    }
  }

  Future<void> browseFullscreen(Squad customers, Creature? buyer) async {
    buyer ??= customers.members[0];
    int page = 0;

    List<ShopOption> availableOptions =
        options.where((o) => o.display()).toList();

    while (true) {
      erase();
      mvaddstrc(0, 0, lightGray, "What will ");
      addstr(buyer.name);
      addstr(" buy?");
      addHeader({4: "PRODUCT NAME", 39: "PRICE"});

      //Write wares and prices
      for (int p = page * 19, y = 2;
          p < availableOptions.length && p < page * 19 + 19;
          p++, y++) {
        setColorConditional(availableOptions[p].isAvailable());
        move(y, 0);
        addchar(letterAPlus(y - 2));
        addstr(" - ");
        addstr(availableOptions[p].fullscreenDescription());
        if (availableOptions[p] is ShopItem) {
          addstr(" (\$${(availableOptions[p] as ShopItem).price(false)})");
        }
      }

      mvaddstrc(22, 0, lightGray,
          "Press a Letter to select an option"); //allow customize "option"? -XML
      mvaddstr(23, 0, pageStr);
      mvaddstr(24, 0, "Enter - ${buyer.name} $exitText");

      int c = await getKey();

      //PAGE UP
      if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
        page--;
      }
      //PAGE DOWN
      if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
          (page + 1) * 19 < availableOptions.length) page++;

      if (c >= Key.a && c <= Key.s) {
        int p = page * 19 + c - Key.a;
        if (p < availableOptions.length && availableOptions[p].isAvailable()) {
          await availableOptions[p].choose(customers, buyer, false);
        }
        break;
      }

      if (isBackKey(c)) break;
    }
  }

  Future<void> sellLoot(Squad customers) async {
    int partysize = squadsize(customers);

    while (true) {
      erase();

      locHeader();
      printParty();

      Site base = customers.members[0].base!;
      bool lootAvailable = base.loot.isNotEmpty;

      mvaddstrc(10, 1, lightGray, "E - Look over Equipment");
      setColorConditional(lootAvailable);
      mvaddstr(10, 40, "F - Pawn Selectively");
      mvaddstr(11, 1, "W - Pawn all Weapons");
      mvaddstr(11, 40, "A - Pawn all Ammunition");
      mvaddstr(12, 1, "C - Pawn all Clothes");
      mvaddstr(12, 40, "L - Pawn all Loot");
      setColorConditional(activeSquadMember != null);
      mvaddstr(15, 1, "0 - Show the squad's Liberal status");
      setColorConditional(
          partysize > 0 && (activeSquadMemberIndex == -1 || partysize > 1));
      mvaddstr(15, 40, "# - Check the status of a squad Liberal");

      mvaddstrc(16, 40, lightGray, "Enter - Done pawning");

      int c = await getKey();

      if (isBackKey(c)) break;

      if (c == Key.e) {
        await equip(base.loot);
      }

      if (c == Key.w || c == Key.a || c == Key.c) {
        move(18, 1);
        setColor(white);
        String items = switch (c) {
          Key.w => "weapons",
          Key.a => "ammo",
          _ => "clothes",
        };
        addstr("Really sell all $items? (Y)es to confirm.           ");

        if (await getKey() != Key.y) c = 0; //no sale
      }

      if ((c == Key.w ||
              c == Key.c ||
              c == Key.l ||
              c == Key.a ||
              c == Key.f) &&
          lootAvailable) {
        int fenceamount = 0;

        if (c == Key.f) {
          fenceamount = await fenceselect(customers);
        } else {
          for (Item loot in base.loot.where((i) => i.isForSale).toList()) {
            if (c == Key.w && loot.isWeapon) {
              fenceamount += loot.stackFenceValue.round();
              base.loot.remove(loot);
            } else if (c == Key.c && loot.isClothing) {
              fenceamount += loot.stackFenceValue.round();
              base.loot.remove(loot);
            } else if (c == Key.a && loot.isAmmo) {
              fenceamount += loot.stackFenceValue.round();
              base.loot.remove(loot);
            } else if (c == Key.l && loot.isLoot) {
              if (!(loot as Loot).type.noQuickFencing) {
                fenceamount += loot.stackFenceValue.round();
                base.loot.remove(loot);
              }
            }
          }
        }

        if (fenceamount > 0) {
          mvaddstrc(8, 1, white, "You add \$$fenceamount to Liberal Funds.");

          await getKey();

          ledger.addFunds(fenceamount, Income.pawn);
        }
      }
    }
  }

  Future<int> fenceselect(Squad customers) async {
    int ret = 0, page = 0;

    Site base = customers.members[0].base!;

    consolidateLoot(base.loot);

    List<int> selected = [for (Item _ in base.loot) 0];

    while (true) {
      erase();

      mvaddstrc(0, 0, lightGray, "What will you sell?");

      if (ret != 0) {
        mvaddstr(0, 30, "Estimated Liberal Amount: \$$ret");
      }

      printParty();

      int x = 1, y = 10;
      String outstr, itemstr;

      for (int l = page * 18; l < base.loot.length && l < page * 18 + 18; l++) {
        if (selected[l] > 0) {
          setColor(lightGreen);
        } else if (base.loot[l].isForSale) {
          setColor(lightGray);
        } else {
          setColor(darkGray);
        }
        itemstr = base.loot[l].equipTitle();
        if (base.loot[l].stackSize > 1) {
          if (selected[l] > 0) {
            itemstr += " ${selected[l]}/";
          } else {
            itemstr += " x";
          }
          itemstr += base.loot[l].stackSize.toString();
        }

        outstr = "${letterAPlus(l - page * 18)} - $itemstr";

        mvaddstr(y, x, outstr);

        x += 26;
        if (x > 53) {
          x = 1;
          y++;
        }
      }

      //PAGE UP
      setColor(lightGray);
      if (page > 0) {
        mvaddstr(17, 1, previousPageStr);
      }
      //PAGE DOWN
      if ((page + 1) * 18 < base.loot.length) {
        mvaddstr(17, 53, nextPageStr);
      }

      mvaddstrc(23, 1, lightGray, "Press a letter to select an item to sell.");
      mvaddstr(24, 1, "Enter - Done");

      int c = await getKey();

      if (c >= Key.a && c <= Key.r) {
        int slot = c - Key.a + page * 18;

        if (slot >= 0 && slot < base.loot.length) {
          if (selected[slot] > 0) {
            ret -= (base.loot[slot].fenceValue * selected[slot]).round();
            selected[slot] = 0;
          } else {
            if (base.loot[slot].isForSale) {
              if (base.loot[slot].stackSize > 1) {
                selected[slot] =
                    await promptAmount(0, base.loot[slot].stackSize);
              } else {
                selected[slot] = 1;
              }
              ret += (base.loot[slot].fenceValue * selected[slot]).round();
            }
          }
        }
      }

      if (isBackKey(c)) break;

      //PAGE UP
      if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
        page--;
      }
      //PAGE DOWN
      if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
          (page + 1) * 18 < base.loot.length) {
        page++;
      }
    }

    for (int l = base.loot.length - 1; l >= 0; l--) {
      if (selected[l] > 0) {
        base.loot[l].stackSize -= selected[l];
        if (base.loot[l].stackSize <= 0) base.loot.removeAt(l);
      }
    }

    return ret;
  }

  Future<void> maskselect(Creature buyer) async {
    ClothingType? mask;

    List<ClothingType> masktype =
        clothingTypes.values.where((a) => a.mask && !a.surpriseMask).toList();

    int page = 0;

    while (true) {
      erase();

      mvaddstrc(0, 0, white, "Which mask will ${buyer.name} buy?");
      addHeader({4: "PRODUCT NAME", 39: "DESCRIPTION"});

      for (int p = page * 19, y = 2;
          p < masktype.length && p < page * 19 + 19;
          p++, y++) {
        setColor(lightGray);
        mvaddstr(y, 0, "${letterAPlus(y - 2)} - ${masktype[p].name}");
        mvaddstrc(y, 39, lightGray, masktype[p].description.trim());
      }

      mvaddstrc(22, 0, lightGray, "Press a Letter to select a Mask");
      move(23, 0);
      addstr(pageStr);
      mvaddstr(24, 0, "Z - Surprise ");
      addstr(buyer.name);
      addstr(" With a Random Mask");

      int c = await getKey();

      //PAGE UP
      if ((isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) && page > 0) {
        page--;
      }
      //PAGE DOWN
      if ((isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) &&
          (page + 1) * 19 < masktype.length) {
        page++;
      }

      if (c >= Key.a && c <= Key.s) {
        int p = page * 19 + c - Key.a;
        if (p < masktype.length) {
          mask = masktype[p];
          break;
        }
      }
      if (c == Key.z) {
        mask =
            clothingTypes.values.where((a) => a.mask && a.surpriseMask).random;
        break;
      }

      if (isBackKey(c)) break;
    }

    if (mask != null && ledger.funds >= 15) {
      Clothing a = Clothing(mask.idName);
      buyer.giveArmor(a, buyer.base?.loot);
      ledger.subtractFunds(15, Expense.shopping);
    }
  }
}
