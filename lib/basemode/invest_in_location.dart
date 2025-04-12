import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> investInLocation(Site loc) async {
  int solarCost = switch (laws[Law.pollution]!) {
    DeepAlignment.archConservative => 60000,
    DeepAlignment.conservative => 40000,
    DeepAlignment.moderate => 30000,
    DeepAlignment.liberal => 20000,
    DeepAlignment.eliteLiberal => 10000,
  };
  int dieselCost = switch (laws[Law.pollution]!) {
    DeepAlignment.archConservative => 300,
    DeepAlignment.conservative => 500,
    DeepAlignment.moderate => 750,
    DeepAlignment.liberal => 1000,
    DeepAlignment.eliteLiberal => 2000,
  };

  while (true) {
    erase();
    locHeader(loc);
    printLocation(loc);
    if (loc.upgradable) {
      if (!loc.compound.fortified) {
        String fortifyText = "Fortify the compound for a siege";
        if (loc.type == SiteType.bunker) {
          fortifyText = "Repair the bunker fortifications";
        } else if (loc.type == SiteType.bombShelter) {
          fortifyText = "Fortify the bomb shelter entrances";
        }
        addOptionText(8, 1, "W", "W - $fortifyText (\$2000)",
            enabledWhen: ledger.funds >= 2000);
      }
      if (!loc.compound.cameras) {
        addOptionText(9, 1, "C",
            "C - Place Security Cameras around the compound (\$2000)",
            enabledWhen: ledger.funds >= 2000);
      }
      if (!loc.compound.boobyTraps) {
        addOptionText(10, 1, "T",
            "T - Place Booby Traps throughout the compound (\$3000)",
            enabledWhen: ledger.funds >= 3000);
      }
      if (!loc.compound.bollards) {
        addOptionText(11, 1, "B",
            "B - Install heavy Bollards to keep vehicles away (\$3000)",
            enabledWhen: ledger.funds >= 3000);
      }
      if (!loc.compound.generator) {
        addOptionText(12, 1, "G",
            "G - Install a backup diesel generator for the compound (\$3000)",
            enabledWhen: ledger.funds >= 3000);
      }
      if (!loc.compound.aaGun && !loc.compound.solarPanels) {
        addOptionText(13, 1, "P",
            "P - Install a battery and Solar Panel array on the roof (\$${solarCost ~/ 1000},000)",
            enabledWhen: ledger.funds >= solarCost);
        if (laws[Law.gunControl] == DeepAlignment.archConservative) {
          addOptionText(14, 1, "A",
              "A - Install a perfectly legal Anti-Aircraft gun on the roof (\$35,000)",
              enabledWhen: ledger.funds >= 35000);
        } else {
          addOptionText(14, 1, "A",
              "A - Install and conceal an illegal Anti-Aircraft gun on the roof (\$200,000)",
              enabledWhen: ledger.funds >= 200000);
        }
      }
      if (!loc.compound.videoRoom) {
        addOptionText(
            15, 1, "V", "V - Prepare a room as a Video Studio (\$2000)",
            enabledWhen: ledger.funds >= 2000);
      }
      if (!loc.compound.hackerDen) {
        addOptionText(16, 1, "H", "H - Prepare a room as a Hacker Den (\$4000)",
            enabledWhen: ledger.funds >= 4000);
      }
      if (!loc.businessFront && !loc.discreet) {
        addOptionText(17, 1, "F",
            "F - Set up a Business Front to ward off suspicion (\$3000)",
            enabledWhen: ledger.funds >= 3000);
      }
    }
    if (loc.compound.generator) {
      addOptionText(18, 1, "D",
          "D - Stockpile 5 days of diesel for the generator (\$$dieselCost)",
          enabledWhen: ledger.funds >= dieselCost);
    }
    addOptionText(19, 1, "R", "R - Stockpile 20 daily rations of food (\$150)",
        enabledWhen: ledger.funds >= 150);
    addOptionText(20, 1, "Enter", "Enter - Done");
    int c = await getKey();
    if (isBackKey(c)) break;
    if (loc.upgradable) {
      if (c == Key.w) {
        if (!loc.compound.fortified && ledger.funds >= 2000) {
          ledger.subtractFunds(2000, Expense.compoundUpgrades);
          loc.compound.fortified = true;
        }
      }
      if (c == Key.c) {
        if (!loc.compound.cameras && ledger.funds >= 2000) {
          ledger.subtractFunds(2000, Expense.compoundUpgrades);
          loc.compound.cameras = true;
        }
      }
      if (c == Key.t) {
        if (!loc.compound.boobyTraps && ledger.funds >= 3000) {
          ledger.subtractFunds(3000, Expense.compoundUpgrades);
          loc.compound.boobyTraps = true;
        }
      }
      if (c == Key.b) {
        if (!loc.compound.bollards && ledger.funds >= 3000) {
          ledger.subtractFunds(3000, Expense.compoundUpgrades);
          loc.compound.bollards = true;
        }
      }
      if (c == Key.g) {
        if (!loc.compound.generator && ledger.funds >= 3000) {
          ledger.subtractFunds(3000, Expense.compoundUpgrades);
          loc.compound.generator = true;
        }
      }
      if (c == Key.p) {
        if (!loc.compound.solarPanels &&
            !loc.compound.aaGun &&
            ledger.funds >= solarCost) {
          ledger.subtractFunds(solarCost, Expense.compoundUpgrades);
          loc.compound.solarPanels = true;
        }
      }
      if (c == Key.a) {
        int aagunPrice = 200000;
        if (laws[Law.gunControl] == DeepAlignment.archConservative) {
          aagunPrice = 35000;
        }
        if (!loc.compound.aaGun &&
            !loc.compound.solarPanels &&
            ledger.funds >= aagunPrice) {
          ledger.subtractFunds(aagunPrice, Expense.compoundUpgrades);
          loc.compound.aaGun = true;
        }
      }
      if (c == Key.v) {
        if (!loc.compound.videoRoom && ledger.funds >= 2000) {
          ledger.subtractFunds(2000, Expense.compoundUpgrades);
          loc.compound.videoRoom = true;
        }
      }
      if (c == Key.h) {
        if (!loc.compound.hackerDen && ledger.funds >= 4000) {
          ledger.subtractFunds(4000, Expense.compoundUpgrades);
          loc.compound.hackerDen = true;
        }
      }
    }
    if (c == Key.d && ledger.funds >= dieselCost) {
      if (loc.compound.generator) {
        ledger.subtractFunds(dieselCost, Expense.compoundUpgrades);
        loc.compound.diesel += 5;
      }
    }
    if (c == Key.r) {
      if (ledger.funds >= 150) {
        ledger.subtractFunds(150, Expense.compoundUpgrades);
        loc.compound.rations += 20;
      }
    }
    if (c == Key.f) {
      if (!loc.businessFront && !loc.discreet && ledger.funds >= 3000) {
        ledger.subtractFunds(3000, Expense.compoundUpgrades);
        loc.businessFront = true;
        do {
          String first = lastName(), second = lastName(), third = lastName();
          String short, long;
          (short, long) = [
            ("Life Ins.", "$first Life Insurance"),
            ("Manpower", "$first Manpower, LLC"),
            ("Holding", "$first Holding Company"),
            ("Services", "$first Elite Services"),
            ("Design", "$first Design Agency"),
            ("Realty", "$first Real Estate"),
            ("Disposal", "$first Waste Disposal"),
            ("Accounts", "$first & $second Accounts"),
            ("Advisory", "$first Advisory"),
            ("Finance", "$first $second Finance"),
            ("Legal", "$first & $second Legal"),
            ("Software", "$first Software"),
            ("Technic", "$first Technical"),
            ("Global", "$first Global"),
            ("Partners", "$first $second $third Partnership"),
            ("Acme", "Acme LLC Co. Inc."),
          ].random;
          loc.frontName = long;
          loc.shortName = short;
        } while (sites.where((l) => l.shortName == loc.shortName).length > 1);
      }
    }
  }
}
