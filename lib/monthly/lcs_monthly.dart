/* monthly - LCS finances report */
import 'package:collection/collection.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/armor_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> fundReport(bool disbanding) async {
  if (disbanding) return;

  int page = 0;
  bool showledger = false;
  String num;
  const String dotdotdot =
      ". . . . . . . . . . . . . . . . . . . . . . . . . . . . . . ";

  int expenselines = 0;
  for (int i = 0; i < Expense.values.length; i++) {
    if (ledger.expense[Expense.values[i]] != 0) {
      expenselines++;
    }
  }

  while (true) {
    erase();

    int y = 2, totalmoney = 0, dailymoney = 0, numpages = 1;

    void nextY() {
      if (++y >= 23) {
        y = 2;
        numpages++;
      }
    }

    mvaddstrc(0, 0, white, "Liberal Crime Squad: Funding Report");

    for (Income inc in Income.values) {
      if (ledger.income[inc] != 0) {
        showledger = true;
        if (page == numpages - 1) {
          mvaddstrc(y, 0, lightGray, dotdotdot);
          setColor(green);
          num = "+\$${ledger.income[inc]}";
          mvaddstr(y, 60 - num.length, num);
          if (ledger.dailyIncome[inc] != 0) {
            num = " (+\$${ledger.dailyIncome[inc]})";
          } else {
            setColor(lightGray);
            num = " (\$0)";
          }
          mvaddstr(y, 73 - num.length, num);
          setColor(lightGray);
          switch (inc) {
            case Income.brownies:
              mvaddstr(y, 0, "Brownies");
            case Income.cars:
              mvaddstr(y, 0, "Car Sales");
            case Income.creditCardFraud:
              mvaddstr(y, 0, "Credit Card Fraud");
            case Income.donations:
              mvaddstr(y, 0, "Donations");
            case Income.artSales:
              mvaddstr(y, 0, "Art Sales");
            case Income.embezzlement:
              mvaddstr(y, 0, "Embezzlement");
            case Income.extortion:
              mvaddstr(y, 0, "Extortion");
            case Income.hustling:
              mvaddstr(y, 0, "Hustling");
            case Income.pawn:
              mvaddstr(y, 0, "Pawning Goods");
            case Income.prostitution:
              mvaddstr(y, 0, "Prostitution");
            case Income.busking:
              mvaddstr(y, 0, "Street Music");
            case Income.thievery:
              mvaddstr(y, 0, "Thievery");
            case Income.tshirts:
              mvaddstr(y, 0, "T-Shirt Sales");
            default:
              mvaddstr(y, 0, "Other Income");
          }
        }
        totalmoney += ledger.income[inc] ?? 0;
        dailymoney += ledger.dailyIncome[inc] ?? 0;

        nextY();
      }
    }

    // If expenses are too long to fit on this page, start them on the next page so it isn't broken in half unnecessarily
    if (y + expenselines >= 23 && y > 2) {
      y = 2;
      numpages++;
    }

    for (Expense exp in Expense.values) {
      if (ledger.expense[exp] != 0) {
        showledger = true;
        if (page == numpages - 1) {
          mvaddstrc(y, 0, lightGray, dotdotdot);
          setColor(darkRed);
          num = "-\$${ledger.expense[exp]}";
          mvaddstr(y, 60 - num.length, num);
          num = " (-\$${ledger.dailyExpense[exp]})";
          mvaddstr(y, 73 - num.length, num);
          setColor(lightGray);
          switch (exp) {
            case Expense.activism:
              mvaddstr(y, 0, "Activism");
            case Expense.artSupplies:
              mvaddstr(y, 0, "Art Supplies");
            case Expense.augmentation:
              mvaddstr(y, 0, "Augmentation");
            case Expense.cars:
              mvaddstr(y, 0, "Automobiles");
            case Expense.confiscated:
              mvaddstr(y, 0, "Confiscated");
            case Expense.dating:
              mvaddstr(y, 0, "Dating");
            case Expense.groceries:
              mvaddstr(y, 0, "Groceries");
            case Expense.hostageTending:
              mvaddstr(y, 0, "Hostage Tending");
            case Expense.legalFees:
              mvaddstr(y, 0, "Legal Fees");
            case Expense.shopping:
              mvaddstr(y, 0, "Purchasing Goods");
            case Expense.recruitment:
              mvaddstr(y, 0, "Recruitment");
            case Expense.rent:
              mvaddstr(y, 0, "Rent");
            case Expense.compoundUpgrades:
              mvaddstr(y, 0, "Safehouse Investments");
            case Expense.sewingSupplies:
              mvaddstr(y, 0, "Sewing Supplies");
            case Expense.training:
              mvaddstr(y, 0, "Training");
            case Expense.travel:
              mvaddstr(y, 0, "Travel");
            default:
              mvaddstr(y, 0, "Other Expenses");
          }
        }
        totalmoney -= ledger.expense[exp] ?? 0;
        dailymoney -= ledger.dailyExpense[exp] ?? 0;

        nextY();
      }
    }

    if (showledger) {
      if (page == numpages - 1) makeDelimiter(y: y);

      nextY();

      if (page == numpages - 1) {
        mvaddstrc(y, 0, white, "Net Change This Month (Day):");
        if (totalmoney > 0) {
          setColor(lightGreen);
          num = "+";
        } else if (totalmoney < 0) {
          setColor(red);
          num = "-";
        } else {
          setColor(white);
          num = "";
        }
        num += "\$${totalmoney.abs()}";
        mvaddstr(y, 60 - num.length, num);
        if (dailymoney > 0) {
          setColor(lightGreen);
          num = " (+\$${dailymoney.abs()})";
        } else if (dailymoney < 0) {
          setColor(red);
          num = " (-\$${dailymoney.abs()})";
        } else {
          setColor(white);
          num = " (\$0)";
        }
        mvaddstr(y, 73 - num.length, num);
      }

      nextY();
    }

    // Blank line between income/expenses and assets if not starting a new page
    if (y > 2) y++;
    if (y + 7 >= 23) {
      //Start a new page if the liquid assets won't fit on the rest of the current page.
      y = 2;
      numpages++;
    }
    // tally up liquid assets
    int weaponValue = 0, armorValue = 0, clipValue = 0, lootValue = 0;
    for (Site j in sites.where((s) => s.isSafehouse)) {
      for (Item item in j.loot) {
        if (item.type is WeaponType) {
          weaponValue += item.type.fenceValue * item.stackSize;
        }
        if (item.type is ArmorType) {
          armorValue += item.type.fenceValue * item.stackSize;
        }
        if (item.type is AmmoType) {
          clipValue += item.type.fenceValue * item.stackSize;
        }
        if (item.type is LootType) {
          lootValue += item.type.fenceValue * item.stackSize;
        }
      }
    }

    void liquidAssetLine(String label, int value) {
      if (page == numpages - 1) {
        mvaddstrc(y, 0, lightGray, dotdotdot);
        mvaddstr(y, 0, label);
        setColor(value > 0 ? green : lightGray);
        num = "\$$value";
        mvaddstr(y, 60 - num.length, num);
      }

      nextY();
    }

    liquidAssetLine("Cash", ledger.funds);
    liquidAssetLine("Tools and Weapons", weaponValue);
    liquidAssetLine("Clothing and Armor", armorValue);
    liquidAssetLine("Ammunition", clipValue);
    liquidAssetLine("Miscellaneous Loot", lootValue);

    if (page == numpages - 1) makeDelimiter(y: y);
    nextY();

    liquidAssetLine("Total Liquid Assets",
        ledger.funds + weaponValue + armorValue + clipValue + lootValue);

    setColor(lightGray);
    if (numpages > 1) {
      mvaddstr(24, 0, "Press Enter to reflect on the report.  ");
      addstr(pageStr);

      while (true) {
        int c = await getKey();

        if (isBackKey(c)) {
          return;
        }

        //PAGE UP
        if (isPageUp(c) || c == Key.upArrow || c == Key.leftArrow) {
          page--;
          if (page < 0) page = numpages - 1;
          break;
        }
        //PAGE DOWN
        if (isPageDown(c) || c == Key.downArrow || c == Key.rightArrow) {
          page++;
          if (page >= numpages) page = 0;
          break;
        }
      }
    } else {
      mvaddstr(24, 0, "Press any key to reflect on the report.");

      await getKey();

      return;
    }
  }
}

/* monthly - lets the player choose a special edition for the guardian */
Future<LootType?> chooseSpecialEdition() async {
  //Temporary, maybe put special edition definition into an xml file. -XML
  const List<String> docs = [
    "LOOT_AMRADIOFILES",
    "LOOT_CABLENEWSFILES",
    "LOOT_CCS_BACKERLIST",
    "LOOT_CEOLOVELETTERS",
    "LOOT_CEOPHOTOS",
    "LOOT_CEOTAXPAPERS",
    "LOOT_CORPFILES",
    "LOOT_INTHQDISK",
    "LOOT_JUDGEFILES",
    "LOOT_POLICERECORDS",
    "LOOT_PRISONFILES",
    "LOOT_RESEARCHFILES",
    "LOOT_SECRETDOCUMENTS",
  ];

  //char havetype[LOOTNUM];
  //for(int l=0;l<LOOTNUM;l++)havetype[l]=0;
  List<bool> havetype = List.filled(docs.length, false);
  List<LootType> lootTypesAvailable = [];

  //FIND ALL LOOT TYPES
  for (Site loc in sites.where((s) => s.controller == SiteController.lcs)) {
    consolidateLoot(loc.loot);
    for (Loot l in loc.loot.whereType<Loot>()) {
      int index = docs.indexOf(l.type.idName);
      if (index == -1) continue;
      if (havetype[index]) continue;
      lootTypesAvailable.add(l.type);
      havetype[index] = true;
    }
  }
  if (lootTypesAvailable.isEmpty) return null;

  //PICK ONE
  LootType? lootTypeChosen;
  await pagedInterface(
    headerPrompt: "Do you want to publish secrets in the Liberal Guardian?",
    headerKey: {4: "SECRETS POSSESSED"},
    footerPrompt:
        "Enter - Now is not the time to attract this sort of attention",
    count: lootTypesAvailable.length,
    lineBuilder: (y, key, index) {
      mvaddstr(y, 0, "$key - ${lootTypesAvailable[index].name}");
    },
    onChoice: (index) {
      for (Site loc in sites.where((s) => s.controller == SiteController.lcs)) {
        Loot? l = loc.loot.whereType<Loot>().firstWhereOrNull(
            (l) => l.type.idName == lootTypesAvailable[index].idName);
        if (l == null) continue;
        l.split(1);
        if (l.stackSize == 0) loc.loot.remove(l);
        break;
      }
      lootTypeChosen = lootTypesAvailable[index];
    },
  );
  return lootTypeChosen;
}

/* monthly - guardian - prints liberal guardian special editions */
Future<void> printNews(LootType li, int publishers) async {
  erase();
  setColor(white);

  if (li.idName == "LOOT_CEOPHOTOS") // Tmp -XML
  {
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring photos of a major CEO");
    move(7, 1);
    switch (lcsRandom(10)) {
      case 0:
        addstr("sexually assaulting animals.");
        changePublicOpinion(View.animalResearch, 15);
      case 1:
        addstr("digging up graves and sleeping with the dead.");
      case 2:
        addstr("participating in a murder.");
        changePublicOpinion(View.policeBehavior, 15);
        changePublicOpinion(View.justices, 10);
      case 3:
        addstr("pointing guns at photos of the CEO's employees.");
        changePublicOpinion(View.gunControl, 10);
      case 4:
        addstr("tongue-kissing an infamous dictator.");
      case 5:
        addstr(
            "on a date with an EPA regulator overseeing the CEO's facilities.");
        changePublicOpinion(View.pollution, 10);
      case 6:
        addstr("shaking hands with the Grand Wizard of the KKK.");
        changePublicOpinion(View.civilRights, 15);
      case 7:
        addstr("waving a Nazi flag at a supremacist rally.");
        changePublicOpinion(View.civilRights, 15);
      case 8:
        addstr("torturing an employee with a hot iron.");
        changePublicOpinion(View.sweatshops, 10);
      case 9:
        addstr(
            "on a date with an FDA regulator overseeing the CEO's products.");
        changePublicOpinion(View.genetics, 10);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.ceoSalary, 50);
    changePublicOpinion(View.corporateCulture, 50);
    offendedCorps = true;
    mvaddstr(10, 1,
        "Be on guard for retaliation.  This guy is still rich as fuck...");
  } else if (li.idName == "LOOT_CEOLOVELETTERS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring salacious love letters from a");
    mvaddstr(7, 1, "major CEO ");
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(8)) {
      case 0:
        addstr("addressed to his pet dog.  Yikes.");
        changePublicOpinion(View.animalResearch, 15);
      case 1:
        addstr("to the judge that acquit him in a corruption trial.");
        changePublicOpinion(View.justices, 15);
      case 2:
        addstr(
            "to a subordinate, demanding she submit to a sexual relationship.");
        changePublicOpinion(View.womensRights, 10);
      case 3:
        addstr("to himself.  They're very steamy.");
      case 4:
        addstr("implying that he has enslaved his houseservants.");
        changePublicOpinion(View.sweatshops, 10);
      case 5:
        addstr("to the FDA official overseeing the CEO's products.");
        changePublicOpinion(View.genetics, 10);
        changePublicOpinion(View.pollution, 10);
      case 6:
        addstr(
            "that alternate between romantic and threats of extreme violence.");
      case 7:
        addstr(
            "promising someone company profits in exchange for sexual favors.");
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.ceoSalary, 50);
    changePublicOpinion(View.corporateCulture, 50);
    offendedCorps = true;
    mvaddstr(10, 1,
        "Be on guard for retaliation.  This guy is not the forgiving type...");
  } else if (li.idName == "LOOT_CEOTAXPAPERS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring a major CEO's tax papers ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(1)) {
      default:
        addstr("showing that he has engaged in consistent tax evasion.");
        changePublicOpinion(View.taxes, 25);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.ceoSalary, 50);
    changePublicOpinion(View.corporateCulture, 50);
    offendedCorps = true;
    mvaddstr(10, 1,
        "Be on guard for retaliation.  This guy is not the forgiving type...");
  } else if (li.idName == "LOOT_CORPFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring Corporate files");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(5)) {
      case 0:
        addstr("describing a genetic monster created in a lab.");
        changePublicOpinion(View.genetics, 50);
      case 1:
        addstr("with a list of \"suspected\" LGBT employees.");
        changePublicOpinion(View.lgbtRights, 50);
      case 2:
        addstr(
            "containing a memo: \"Terminate the pregnancy, I terminate you.\"");
        changePublicOpinion(View.womensRights, 50);
      case 3:
        addstr("cheerfully describing foreign corporate sweatshops.");
        changePublicOpinion(View.sweatshops, 50);
      case 4:
        addstr("describing an intricate tax scheme.");
        changePublicOpinion(View.taxes, 50);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.ceoSalary, 50);
    changePublicOpinion(View.corporateCulture, 50);
    offendedCorps = true;
    mvaddstr(10, 1,
        "Be on guard for retaliation.  These guys don't like to lose...");
  } else if (li.idName == "LOOT_CCS_BACKERLIST") {
    mvaddstr(5, 1,
        "The Liberal Guardian runs more than one thousand pages of documents about ");
    mvaddstr(6, 1,
        "the CCS organization, also revealing in extreme detail the names and ");
    mvaddstr(7, 1,
        "responsibilities of Conservative Crime Squad sympathizers and supporters");
    mvaddstr(8, 1,
        "in the state and federal governments. Sections precisely document the");
    mvaddstr(9, 1,
        "extensive planning to create an extra-judicial death squad that would be");
    mvaddstr(10, 1,
        "above prosecution, and could hunt down law-abiding Liberals and act");
    mvaddstr(11, 1,
        "as a foil when no other enemies were present to direct public energy");
    mvaddstr(12, 1, "against.");

    mvaddstr(14, 1,
        "The scandal reaches into the heart of the Conservative leadership in the");
    mvaddstr(15, 1,
        "country, and the full ramifications of this revelation may not be felt");
    mvaddstr(16, 1,
        "for months. One thing is clear, however, from the immediate public reaction");
    mvaddstr(17, 1,
        "toward the revelations, and the speed with which even AM Radio and Cable");
    mvaddstr(18, 1, "News denounce the CCS.");

    mvaddstr(20, 1,
        "This is the beginning of the end for the Conservative Crime Squad.");

    changePublicOpinion(View.intelligence, 50);
    changePublicOpinion(View.ccsLiked, 100);
    ccsExposure = CCSExposure.exposed;
  } else if (li.idName == "LOOT_INTHQDISK" ||
      li.idName == "LOOT_SECRETDOCUMENTS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring CIA and other intelligence files ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(6)) {
      case 0:
        addstr("documenting the overthrow of a government.");
      case 1:
        addstr(
            "documenting the planned assassination of a Liberal federal judge.");
        changePublicOpinion(View.justices, 50);
      case 2:
        addstr("containing private information on innocent citizens.");
      case 3:
        addstr("documenting \"harmful speech\" made by innocent citizens.");
        changePublicOpinion(View.freeSpeech, 50);
      case 4:
        addstr("used to keep tabs on LGBT citizens.");
        changePublicOpinion(View.lgbtRights, 50);
      case 5:
        addstr("documenting the infiltration of a pro-choice group.");
        changePublicOpinion(View.womensRights, 50);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.intelligence, 50);
    offendedCia = true;
    mvaddstr(10, 1,
        "Be on guard for retaliation.  These guys REALLY don't like to lose...");
  } else if (li.idName == "LOOT_POLICERECORDS") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring police records ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(6)) {
      case 0:
        addstr("documenting human rights abuses by the force.");
        changePublicOpinion(View.torture, 15);
      case 1:
        addstr("documenting a pattern of torturing suspects.");
        changePublicOpinion(View.torture, 50);
      case 2:
        addstr("documenting a systematic invasion of privacy by the force.");
        changePublicOpinion(View.intelligence, 15);
      case 3:
        addstr("documenting a forced confession.");
      case 4:
        addstr("documenting widespread corruption in the force.");
      case 5:
        addstr(
            "documenting gladiatorial matches held between prisoners by guards.");
        changePublicOpinion(View.deathPenalty, 25);
        changePublicOpinion(View.prisons, 25);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.policeBehavior, 50);
    mvaddstr(10, 1,
        "The cops hate this, but what else is new?  They're already on your ass.");
  } else if (li.idName == "LOOT_JUDGEFILES") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story with evidence of a Conservative judge ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(2)) {
      case 0:
        addstr("taking bribes to acquit murderers.");
      case 1:
        addstr("promising Conservative rulings in exchange for appointments.");
    }
    mvaddstr(8, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.justices, 50);
    mvaddstr(9, 1,
        "This Judge is too weak to pose a real threat to you moving forward.");
  } else if (li.idName == "LOOT_RESEARCHFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring research papers ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(4)) {
      case 0:
        addstr("documenting horrific animal rights abuses.");
        changePublicOpinion(View.animalResearch, 50);
      case 1:
        addstr("studying the effects of torture on cats.");
        changePublicOpinion(View.animalResearch, 50);
      case 2:
        addstr("covering up the accidental creation of a genetic monster.");
        changePublicOpinion(View.genetics, 50);
      case 3:
        addstr("showing human test subjects dying under genetic research.");
        changePublicOpinion(View.genetics, 50);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    mvaddstr(10, 1,
        "The research company is too small to pose a real threat to you.");
  } else if (li.idName == "LOOT_PRISONFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring prison documents ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    changePublicOpinion(View.prisons, 50);
    switch (lcsRandom(4)) {
      case 0:
        addstr("documenting human rights abuses by prison guards.");
      case 1:
        addstr("documenting a prison torture case.");
        changePublicOpinion(View.torture, 50);
      case 2:
        addstr("documenting widespread corruption among prison employees.");
      case 3:
        addstr(
            "documenting gladiatorial matches held between prisoners by guards.");
        changePublicOpinion(View.deathPenalty, 25);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.deathPenalty, 25);
    mvaddstr(10, 1,
        "The prison system doesn't love this, but what are they gonna do?  Jail you?");
  } else if (li.idName == "LOOT_CABLENEWSFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring cable news memos ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(4)) {
      case 0:
        addstr("calling their news 'the vanguard of Conservative thought'.");
      case 1:
        addstr("mandating negative coverage of Liberal politicians.");
      case 2:
        addstr("planning to drum up a false scandal about a Liberal figure.");
      case 3:
        addstr("instructing a female anchor to 'get sexier or get a new job'.");
        changePublicOpinion(View.womensRights, 20);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.cableNews, 50);
    offendedHicks = true;
    mvaddstr(10, 1,
        "This is bound to get the Conservative masses a little riled up...");
  } else if (li.idName == "LOOT_AMRADIOFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring AM radio plans ");
    move(7, 1);
    changePublicOpinion(View.lcsKnown, 10);
    changePublicOpinion(View.lcsLiked, 10);
    switch (lcsRandom(4)) {
      case 0:
        addstr("calling listeners 'sheep to be told what to think'.");
      case 1:
        addstr("saying 'it's okay to lie, they don't need the truth'.");
      case 2:
        addstr("planning to drum up a false scandal about a Liberal figure.");
      case 3:
        addstr("to systematically promote hostility toward Black people.");
        changePublicOpinion(View.civilRights, 25);
    }
    mvaddstr(9, 1,
        "The major networks and publications take it up and run it for weeks.");
    changePublicOpinion(View.amRadio, 50);
    offendedHicks = true;
    mvaddstr(10, 1,
        "This is bound to get the Conservative masses a little riled up...");
  }

  await getKey();
}
