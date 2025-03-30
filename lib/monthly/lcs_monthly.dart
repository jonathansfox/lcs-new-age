/* monthly - LCS finances report */
import 'package:collection/collection.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/ammo_type.dart';
import 'package:lcs_new_age/items/clothing_type.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/items/loot.dart';
import 'package:lcs_new_age/items/loot_type.dart';
import 'package:lcs_new_age/items/weapon_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
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
    double weaponValue = 0, armorValue = 0, clipValue = 0, lootValue = 0;
    for (Site j in sites.where((s) => s.isSafehouse)) {
      for (Item item in j.loot) {
        if (item.type is WeaponType) {
          weaponValue += item.type.fenceValue * item.stackSize;
        }
        if (item.type is ClothingType) {
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
    liquidAssetLine("Tools and Weapons", weaponValue.round());
    liquidAssetLine("Clothing and Armor", armorValue.round());
    liquidAssetLine("Ammunition", clipValue.round());
    liquidAssetLine("Miscellaneous Loot", lootValue.round());

    if (page == numpages - 1) makeDelimiter(y: y);
    nextY();

    liquidAssetLine(
        "Total Liquid Assets",
        (ledger.funds + weaponValue + armorValue + clipValue + lootValue)
            .round());

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
    onChoice: (index) async {
      for (Site loc in sites.where((s) => s.controller == SiteController.lcs)) {
        Loot? l = loc.loot.whereType<Loot>().firstWhereOrNull(
            (l) => l.type.idName == lootTypesAvailable[index].idName);
        if (l == null) continue;
        l.split(1);
        if (l.stackSize == 0) loc.loot.remove(l);
        break;
      }
      lootTypeChosen = lootTypesAvailable[index];
      return true;
    },
  );
  return lootTypeChosen;
}

/* monthly - guardian - prints liberal guardian special editions */
Future<void> printNews(LootType li, Iterable<Creature> publishers) async {
  erase();
  setColor(white);

  int reception(int basePotency) {
    Creature? leader;
    Skill? skillUsed;
    int power = publishers.length +
        publishers.fold(0, (best, p) {
          Skill skill = p.activity.type == ActivityType.writeGuardian
              ? Skill.writing
              : Skill.persuasion;
          int roll = p.skillRoll(skill);
          if (skill == Skill.persuasion) roll -= 5;
          if (roll > best) {
            best = roll;
            leader = p;
            skillUsed = skill;
          }
          return best;
        });
    String article = switch (skillUsed) {
      Skill.writing => "article",
      Skill.persuasion => "stream",
      _ => "piece",
    };
    String leadersArticle = "${leader?.name ?? "The squad"}'s $article";
    if (power < 4) {
      mvaddstr(9, 1,
          "The information is posted to the internet with little fanfare.");
      mvaddstr(10, 1,
          "Some conspiracy theorists mention it, but most people don't believe it.");
      return basePotency ~/ 5;
    } else if (power < 10) {
      mvaddstr(9, 1, "$leadersArticle about this doesn't have much impact.");
      mvaddstr(10, 1,
          "The information is taken up by watchdog groups but never really catches on.");
      return basePotency ~/ 4;
    } else if (power < 15) {
      mvaddstr(9, 1, "$leadersArticle about this gets more views than usual.");
      mvaddstr(10, 1,
          "A prominent journalist investigates further, but can't prove it's true.");
      return basePotency ~/ 3;
    } else if (power < 20) {
      mvaddstr(9, 1, "$leadersArticle about this lays out the evidence.");
      mvaddstr(10, 1,
          "The story is picked up by several major networks and publications.");
      return basePotency ~/ 2;
    } else if (power < 25) {
      mvaddstr(9, 1, "$leadersArticle about this is electrifying.");
      mvaddstr(10, 1,
          "The major networks and publications take it up and run it for weeks.");
      return basePotency;
    } else {
      mvaddstr(
          9, 1, "$leadersArticle about this transforms the media narrative.");
      mvaddstr(10, 1,
          "The major networks and publications fixate on the story for weeks.");
      mvaddstr(11, 1,
          "The information is so explosive that it becomes a national scandal.");
      return (basePotency * 1.5).round();
    }
  }

  if (li.idName == "LOOT_INTHQDISK" || li.idName == "LOOT_SECRETDOCUMENTS") {
    criminalizeAll(publishers, Crime.treason);
  }

  List<View> issues = [View.lcsKnown, View.lcsLiked];
  int potency = 10;

  if (li.idName == "LOOT_CEOPHOTOS") // Tmp -XML
  {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring photos of a major CEO");
    move(7, 1);
    switch (lcsRandom(10)) {
      case 0:
        addstr("sexually assaulting animals.");
        issues.add(View.animalResearch);
      case 1:
        addstr("digging up graves and sleeping with the dead.");
      case 2:
        addstr("participating in a murder.");
        issues.add(View.policeBehavior);
        issues.add(View.justices);
      case 3:
        addstr("pointing guns at photos of the CEO's employees.");
        issues.add(View.gunControl);
      case 4:
        addstr("tongue-kissing an infamous dictator.");
      case 5:
        addstr(
            "on a date with an EPA regulator overseeing the CEO's facilities.");
        issues.add(View.pollution);
      case 6:
        addstr("shaking hands with the Grand Wizard of the KKK.");
        issues.add(View.civilRights);
      case 7:
        addstr("waving a Nazi flag at a supremacist rally.");
        issues.add(View.civilRights);
      case 8:
        addstr("torturing an employee with a hot iron.");
        issues.add(View.sweatshops);
      case 9:
        addstr(
            "on a date with an FDA regulator overseeing the CEO's products.");
        issues.add(View.genetics);
    }

    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    mvaddstr(console.y + 2, 1,
        "Be on guard for retaliation.  This guy is not the forgiving type...");
  } else if (li.idName == "LOOT_CEOLOVELETTERS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring salacious love letters from a");
    mvaddstr(7, 1, "major CEO ");
    switch (lcsRandom(8)) {
      case 0:
        addstr("addressed to his pet dog.  Yikes.");
        issues.add(View.animalResearch);
      case 1:
        addstr("to the judge that acquit him in a corruption trial.");
        issues.add(View.justices);
      case 2:
        addstr(
            "to a subordinate, demanding she submit to a sexual relationship.");
        issues.add(View.womensRights);
      case 3:
        addstr("to himself.  They're very steamy.");
      case 4:
        addstr("implying that he has enslaved his houseservants.");
        issues.add(View.sweatshops);
      case 5:
        addstr("to the FDA official overseeing the CEO's products.");
        issues.add(View.genetics);
        issues.add(View.pollution);
      case 6:
        addstr(
            "that alternate between romantic and threats of extreme violence.");
      case 7:
        addstr(
            "promising someone company profits in exchange for sexual favors.");
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    mvaddstr(console.y + 2, 1,
        "Be on guard for retaliation.  This guy is not the forgiving type...");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CEOTAXPAPERS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring a major CEO's tax papers ");
    move(7, 1);
    switch (lcsRandom(1)) {
      default:
        addstr("showing that he has engaged in consistent tax evasion.");
        issues.add(View.taxes);
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    mvaddstr(console.y + 2, 1,
        "Be on guard for retaliation.  This guy is not the forgiving type...");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CORPFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring Corporate files");
    move(7, 1);
    switch (lcsRandom(5)) {
      case 0:
        addstr("describing a genetic monster created in a lab.");
        issues.add(View.genetics);
      case 1:
        addstr("with a list of \"suspected\" LGBT employees.");
        issues.add(View.lgbtRights);
      case 2:
        addstr(
            "containing a memo: \"Terminate the pregnancy, I terminate you.\"");
        issues.add(View.womensRights);
      case 3:
        addstr("cheerfully describing foreign corporate sweatshops.");
        issues.add(View.sweatshops);
      case 4:
        addstr("describing an intricate tax scheme.");
        issues.add(View.taxes);
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    mvaddstr(console.y + 2, 1,
        "Be on guard for retaliation.  These guys don't like to lose...");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
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

    issues.addAll([View.intelligence, View.ccsHated]);
    potency = 100;
    ccsExposure = CCSExposure.exposed;
  } else if (li.idName == "LOOT_INTHQDISK" ||
      li.idName == "LOOT_SECRETDOCUMENTS") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story featuring CIA and other intelligence files ");
    move(7, 1);
    switch (lcsRandom(6)) {
      case 0:
        addstr("documenting the overthrow of a government.");
      case 1:
        addstr(
            "documenting the planned assassination of a Liberal federal judge.");
        issues.add(View.justices);
      case 2:
        addstr("containing private information on innocent citizens.");
      case 3:
        addstr("documenting \"harmful speech\" made by innocent citizens.");
        issues.add(View.freeSpeech);
      case 4:
        addstr("used to keep tabs on LGBT citizens.");
        issues.add(View.lgbtRights);
      case 5:
        addstr("documenting the infiltration of a pro-choice group.");
        issues.add(View.womensRights);
    }
    issues.add(View.intelligence);
    potency = reception(50);
    offendedCia = true;
    mvaddstr(console.y + 2, 1,
        "Be on guard for retaliation.  These guys REALLY don't like to lose...");
    for (Creature c in publishers) {
      addjuice(c, 50, 1000);
      criminalize(c, Crime.treason);
    }
  } else if (li.idName == "LOOT_POLICERECORDS") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring police records ");
    move(7, 1);
    switch (lcsRandom(7)) {
      case 0:
        addstr("documenting human rights abuses by the force.");
        issues.add(View.torture);
      case 1:
        addstr("documenting a pattern of torturing suspects.");
        issues.add(View.torture);
      case 2:
        addstr("documenting a systematic invasion of privacy by the force.");
        issues.add(View.intelligence);
      case 3:
        addstr("documenting a forced confession.");
      case 4:
        addstr("documenting widespread corruption in the force.");
      case 5:
        addstr(
            "documenting gladiatorial matches held between prisoners by guards.");
        issues.add(View.deathPenalty);
        issues.add(View.prisons);
      case 6:
        addstr(
            "documenting the coverup of several killings of unarmed Black men.");
        issues.add(View.civilRights);
    }
    issues.add(View.policeBehavior);
    potency = reception(50);
    mvaddstr(console.y + 2, 1,
        "The cops hate this, but what else is new?  They're already on your ass.");
  } else if (li.idName == "LOOT_JUDGEFILES") {
    mvaddstr(6, 1,
        "The Liberal Guardian runs a story with evidence of a Conservative judge ");
    move(7, 1);
    switch (lcsRandom(2)) {
      case 0:
        addstr("taking bribes to acquit murderers.");
      case 1:
        addstr("promising Conservative rulings in exchange for appointments.");
    }
    issues.add(View.justices);
    potency = reception(50);
    mvaddstr(console.y + 2, 1,
        "This Judge is too weak to pose a real threat to you moving forward.");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_RESEARCHFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring research papers ");
    move(7, 1);
    switch (lcsRandom(4)) {
      case 0:
        addstr("documenting horrific animal rights abuses.");
        issues.add(View.animalResearch);
      case 1:
        addstr("studying the effects of torture on cats.");
        issues.add(View.animalResearch);
      case 2:
        addstr("covering up the accidental creation of a genetic monster.");
        issues.add(View.genetics);
      case 3:
        addstr("showing human test subjects dying under genetic research.");
        issues.add(View.genetics);
    }
    potency = reception(50);
    mvaddstr(console.y + 2, 1,
        "The research company is too small to pose a real threat to you.");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_PRISONFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring prison documents ");
    move(7, 1);
    switch (lcsRandom(5)) {
      case 0:
        addstr("documenting human rights abuses by prison guards.");
      case 1:
        addstr("documenting a prison torture case.");
        issues.add(View.torture);
      case 2:
        addstr("documenting widespread corruption among prison employees.");
      case 3:
        addstr(
            "documenting gladiatorial matches held between prisoners by guards.");
      case 4:
        addstr("referring to prisoners using a wide variety of racist slurs.");
        issues.add(View.civilRights);
    }
    issues.addAll([View.prisons, View.deathPenalty]);
    potency = reception(50);
    mvaddstr(console.y + 2, 1,
        "The prison system doesn't love this, but what are they gonna do?  Jail you?");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CABLENEWSFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring cable news memos ");
    move(7, 1);
    switch (lcsRandom(4)) {
      case 0:
        addstr("calling their news 'the vanguard of Conservative thought'.");
      case 1:
        addstr("mandating negative coverage of Liberal politicians.");
      case 2:
        addstr("planning to drum up a false scandal about a Liberal figure.");
      case 3:
        addstr("instructing a female anchor to 'get sexier or get a new job'.");
        issues.add(View.womensRights);
    }
    issues.add(View.cableNews);
    offendedHicks = true;
    potency = reception(50);
    mvaddstr(console.y + 2, 1,
        "This is bound to get the Conservative masses a little riled up...");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_AMRADIOFILES") {
    mvaddstr(
        6, 1, "The Liberal Guardian runs a story featuring AM radio plans ");
    move(7, 1);
    switch (lcsRandom(4)) {
      case 0:
        addstr("calling listeners 'sheep to be told what to think'.");
      case 1:
        addstr("saying 'it's okay to lie, they don't need the truth'.");
      case 2:
        addstr("planning to drum up a false scandal about a Liberal figure.");
      case 3:
        addstr("to systematically promote hostility toward Black people.");
        issues.add(View.civilRights);
    }
    issues.add(View.amRadio);
    potency = reception(50);
    offendedHicks = true;
    mvaddstr(console.y + 2, 1,
        "This is bound to get the Conservative masses a little riled up...");
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  }

  for (View issue in issues) {
    changePublicOpinion(issue, potency);
  }

  await getKey();
}
