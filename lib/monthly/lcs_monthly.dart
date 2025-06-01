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
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
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
            case Income.ransom:
              mvaddstr(y, 0, "Ransoming Hostages");
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
      addOptionText(24, 0, "Enter", "Enter - Reflect on the report.  ");
      addPageButtons();

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
  erase();
  await pagedInterface(
    headerPrompt: "Do you want to publish secrets in the Liberal Guardian?",
    headerKey: {4: "SECRETS POSSESSED"},
    backButtonText:
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

  String story = "";
  int startY = 6;

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
    story += "\n\n";
    if (power < 4) {
      story += "The information is posted to the internet with little fanfare."
          "Some conspiracy theorists mention it, but most people don't believe it.";
      return basePotency ~/ 5;
    } else if (power < 10) {
      story += "$leadersArticle about this doesn't have much impact. "
          "The information is taken up by watchdog groups but never really catches on.";
      return basePotency ~/ 4;
    } else if (power < 15) {
      story += "$leadersArticle about this gets more views than usual. ";
      story +=
          "The information is taken up by watchdog groups but never really catches on.";
      return basePotency ~/ 4;
    } else if (power < 15) {
      story += "$leadersArticle about this gets more views than usual. "
          "A prominent journalist investigates further, but can't prove it's true.";
      return basePotency ~/ 3;
    } else if (power < 20) {
      story += "$leadersArticle about this lays out the evidence. "
          "The story is picked up by several major networks and publications.";
      return basePotency ~/ 2;
    } else if (power < 25) {
      story += "$leadersArticle about this is electrifying. "
          "The major networks and publications take it up and run it for weeks.";
      return basePotency;
    } else {
      story += "$leadersArticle about this transforms the media narrative. "
          "The major networks and publications fixate on the story for weeks. "
          "The information is so explosive that it becomes a national scandal.";
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
    story =
        "The Liberal Guardian runs a story featuring photos of a major CEO ";
    switch (lcsRandom(10)) {
      case 0:
        story += "sexually assaulting animals.";
        issues.add(View.animalResearch);
      case 1:
        story += "digging up graves and sleeping with the dead.";
      case 2:
        story += "participating in a murder.";
        issues.add(View.policeBehavior);
        issues.add(View.justices);
      case 3:
        story += "pointing guns at photos of the CEO's employees.";
        issues.add(View.gunControl);
      case 4:
        story += "tongue-kissing an infamous dictator.";
      case 5:
        story +=
            "on a date with an EPA regulator overseeing the CEO's facilities.";
        issues.add(View.pollution);
      case 6:
        story += "shaking hands with the Grand Wizard of the KKK.";
        issues.add(View.civilRights);
      case 7:
        story += "waving a Nazi flag at a supremacist rally.";
        issues.add(View.civilRights);
      case 8:
        story += "torturing an employee with a hot iron.";
        issues.add(View.sweatshops);
      case 9:
        story +=
            "on a date with an FDA regulator overseeing the CEO's products.";
        issues.add(View.genetics);
    }

    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    for (Creature p in publishers) {
      p.offendedCorps++;
    }
    story +=
        "\n\nBe on guard for retaliation.  This guy is not the forgiving type...";
    addparagraph(6, 1, story);
  } else if (li.idName == "LOOT_CEOLOVELETTERS") {
    story =
        "The Liberal Guardian runs a story featuring salacious love letters from a";
    mvaddstr(7, 1, "major CEO ");
    switch (lcsRandom(8)) {
      case 0:
        story += "addressed to his pet dog.  Yikes.";
        issues.add(View.animalResearch);
      case 1:
        story += "to the judge that acquit him in a corruption trial.";
        issues.add(View.justices);
      case 2:
        story +=
            "to a subordinate, demanding she submit to a sexual relationship.";
        issues.add(View.womensRights);
      case 3:
        story += "to himself.  They're very steamy.";
      case 4:
        story += "implying that he has enslaved his houseservants.";
        issues.add(View.sweatshops);
      case 5:
        story += "to the FDA official overseeing the CEO's products.";
        issues.add(View.genetics);
        issues.add(View.pollution);
      case 6:
        story +=
            "that alternate between romantic and threats of extreme violence.";
      case 7:
        story +=
            "promising someone company profits in exchange for sexual favors.";
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    for (Creature p in publishers) {
      p.offendedCorps++;
    }
    story +=
        "\n\nBe on guard for retaliation.  This guy is not the forgiving type...";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CEOTAXPAPERS") {
    story =
        "The Liberal Guardian runs a story featuring a major CEO's tax papers ";
    switch (lcsRandom(1)) {
      default:
        story += "showing that he has engaged in consistent tax evasion.";
        issues.add(View.taxes);
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    for (Creature p in publishers) {
      p.offendedCorps++;
    }
    story +=
        "\n\nBe on guard for retaliation.  This guy is not the forgiving type...";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CORPFILES") {
    story = "The Liberal Guardian runs a story featuring Corporate files ";
    switch (lcsRandom(5)) {
      case 0:
        story += "describing a genetic monster created in a lab.";
        issues.add(View.genetics);
      case 1:
        story += "with a list of \"suspected\" LGBT employees.";
        issues.add(View.lgbtRights);
      case 2:
        story +=
            "containing a memo: \"Terminate the pregnancy, I terminate you.\"";
        issues.add(View.womensRights);
      case 3:
        story += "cheerfully describing foreign corporate sweatshops.";
        issues.add(View.sweatshops);
      case 4:
        story += "describing an intricate tax scheme.";
        issues.add(View.taxes);
    }
    issues.add(View.ceoSalary);
    issues.add(View.corporateCulture);
    potency = reception(50);
    offendedCorps = true;
    for (Creature p in publishers) {
      p.offendedCorps++;
    }
    story +=
        "\n\nBe on guard for retaliation.  These guys don't like to lose...";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CCS_BACKERLIST") {
    story =
        "The Liberal Guardian runs more than one thousand pages of documents about "
        "the CCS organization, also revealing in extreme detail the names and "
        "responsibilities of Conservative Crime Squad sympathizers and supporters "
        "in the state and federal governments. Sections precisely document the "
        "extensive planning to create an extra-judicial death squad that would be "
        "above prosecution, and could hunt down law-abiding Liberals and act "
        "as a foil when no other enemies were present to direct public energy "
        "against.\n\n"
        "The scandal reaches into the heart of the Conservative leadership in the "
        "country, and the full ramifications of this revelation may not be felt "
        "for months. One thing is clear, however, from the immediate public reaction "
        "toward the revelations, and the speed with which even AM Radio and Cable "
        "News denounce the CCS.\n\n"
        "This is the beginning of the end for the Conservative Crime Squad.";
    startY = 5;

    issues.addAll([View.intelligence, View.ccsHated]);
    potency = 100;
    ccsExposure = CCSExposure.exposed;
  } else if (li.idName == "LOOT_INTHQDISK" ||
      li.idName == "LOOT_SECRETDOCUMENTS") {
    story =
        "The Liberal Guardian runs a story featuring CIA and other intelligence files ";
    switch (lcsRandom(6)) {
      case 0:
        story += "documenting the overthrow of a government.";
      case 1:
        story +=
            "documenting the planned assassination of a Liberal federal judge.";
        issues.add(View.justices);
      case 2:
        story += "containing private information on innocent citizens.";
      case 3:
        story += "documenting \"harmful speech\" made by innocent citizens.";
        issues.add(View.freeSpeech);
      case 4:
        story += "used to keep tabs on LGBT citizens.";
        issues.add(View.lgbtRights);
      case 5:
        story += "documenting the infiltration of a pro-choice group.";
        issues.add(View.womensRights);
    }
    story +=
        "\n\nBe on guard for retaliation.  These guys REALLY don't like to lose...";
    issues.add(View.intelligence);
    potency = reception(50);
    offendedCia = true;
    for (Creature c in publishers) {
      addjuice(c, 50, 1000);
      criminalize(c, Crime.treason);
      c.offendedCIA++;
    }
  } else if (li.idName == "LOOT_POLICERECORDS") {
    story = "The Liberal Guardian runs a story featuring police records ";
    switch (lcsRandom(7)) {
      case 0:
        story += "documenting human rights abuses by the force.";
        issues.add(View.torture);
      case 1:
        story += "documenting a pattern of torturing suspects.";
        issues.add(View.torture);
      case 2:
        story += "documenting a systematic invasion of privacy by the force.";
        issues.add(View.intelligence);
      case 3:
        story += "documenting a forced confession.";
      case 4:
        story += "documenting widespread corruption in the force.";
      case 5:
        story +=
            "documenting gladiatorial matches held between prisoners by guards.";
        issues.add(View.deathPenalty);
        issues.add(View.prisons);
      case 6:
        story +=
            "documenting the coverup of several killings of unarmed Black men.";
        issues.add(View.civilRights);
    }
    issues.add(View.policeBehavior);
    potency = reception(50);
    story +=
        "\n\nThe cops hate this, but what else is new?  They're already on your ass.";
  } else if (li.idName == "LOOT_JUDGEFILES") {
    story =
        "The Liberal Guardian runs a story with evidence of a Conservative judge ";
    switch (lcsRandom(2)) {
      case 0:
        story += "taking bribes to acquit murderers.";
      case 1:
        story += "promising Conservative rulings in exchange for appointments.";
    }
    issues.add(View.justices);
    potency = reception(50);
    story +=
        "\n\nThis Judge is too weak to pose a real threat to you moving forward.";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_RESEARCHFILES") {
    story = "The Liberal Guardian runs a story featuring research papers ";
    switch (lcsRandom(4)) {
      case 0:
        story += "documenting horrific animal rights abuses.";
        issues.add(View.animalResearch);
      case 1:
        story += "studying the effects of torture on cats.";
        issues.add(View.animalResearch);
      case 2:
        story += "covering up the accidental creation of a genetic monster.";
        issues.add(View.genetics);
      case 3:
        story += "showing human test subjects dying under genetic research.";
        issues.add(View.genetics);
    }
    potency = reception(50);
    story +=
        "\n\nThe research company is too small to pose a real threat to you.";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_PRISONFILES") {
    story = "The Liberal Guardian runs a story featuring prison documents ";
    switch (lcsRandom(5)) {
      case 0:
        story += "documenting human rights abuses by prison guards.";
      case 1:
        story += "documenting a prison torture case.";
        issues.add(View.torture);
      case 2:
        story += "documenting widespread corruption among prison employees.";
      case 3:
        story +=
            "documenting gladiatorial matches held between prisoners by guards.";
      case 4:
        story += "referring to prisoners using a wide variety of racist slurs.";
        issues.add(View.civilRights);
    }
    issues.addAll([View.prisons, View.deathPenalty]);
    potency = reception(50);
    story +=
        "\n\nThe prison system doesn't love this, but what are they gonna do?  Jail you?";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
    }
  } else if (li.idName == "LOOT_CABLENEWSFILES") {
    story = "The Liberal Guardian runs a story featuring cable news memos ";
    switch (lcsRandom(7)) {
      case 0:
        story += "mandating that any investigative news stories must be "
            "approved by the network's Conservative commentators before they "
            "can be aired.";
      case 1:
        story += "mandating negative coverage of Liberal politicians.";
      case 2:
        story += "planning to drum up a false scandal about a Liberal figure "
            "that they privately acknowledge to be unimpeachable.";
      case 3:
        story += "instructing a female anchor to 'slim down or get a new job'.";
        issues.add(View.womensRights);
      case 4:
        story +=
            "directing staff to prioritize crime coverage in which the suspect "
            "is Black.";
        issues.add(View.civilRights);
      case 5:
        story +=
            "searching for particularly ineffectual Liberal media personalities "
            "to bring on opposite one of their Conservative hosts.";
      case 6:
        story +=
            "intenarnally acknowledging that several of their recent stories "
            "have been largely made up.";
    }
    issues.add(View.cableNews);
    offendedAngryRuralMobs = true;
    potency = reception(50);
    story +=
        "\n\nThis is bound to get the Conservative masses a little riled up...";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
      c.offendedAngryRuralMobs++;
    }
  } else if (li.idName == "LOOT_AMRADIOFILES") {
    story = "The Liberal Guardian runs a story featuring AM radio plans ";
    switch (lcsRandom(5)) {
      case 0:
        story += "to promote a foreign dictator as a hero to listeners "
            "after a major radio host received a large sum of money from "
            "the dictator's regime.";
      case 1:
        story += "brainstorming, in very blunt terms, which overt lies to "
            "tell listeners based on what they think their listeners are "
            "'stupid enough' to believe.";
      case 2:
        story += "planning to drum up a false scandal about a Liberal figure "
            "that they privately acknowledge to be unimpeachable.";
      case 3:
        story += "to systematically promote hostility toward Black people.";
        issues.add(View.civilRights);
      case 4:
        story += "to make sure to follow the name of every LGBT figure "
            "mentioned on the program with the words \"who is known to be a "
            "pedophile and a groomer, by the way.\"";
        issues.add(View.lgbtRights);
    }
    issues.add(View.amRadio);
    potency = reception(50);
    offendedAngryRuralMobs = true;
    story +=
        "\n\nThis is bound to get the Conservative masses a little riled up...";
    for (Creature c in publishers) {
      addjuice(c, 20, 1000);
      c.offendedAngryRuralMobs++;
    }
  }
  addparagraph(startY, 1, story);

  // Take snapshot of public opinion before changes
  Map<View, double> beforeOpinion = Map.from(gameState.politics.publicOpinion);

  for (View issue in issues) {
    changePublicOpinion(issue, potency);
  }

  // Archive the public opinion changes
  NewsStory archiveStory = NewsStory.unpublished(NewsStories.majorEvent);
  archiveStory.publication = Publication.liberalGuardian;
  archiveStory.view = View.lcsKnown;
  archiveStory.liberalSpin = true;
  archiveStory.priority = potency;
  archiveStory.body = story;

  // Set headline based on the type of exposé
  archiveStory.headline = switch (li.idName) {
    "LOOT_CEOPHOTOS" => "CEO SCANDAL EXPOSED",
    "LOOT_CEOLOVELETTERS" => "CEO LOVE LETTERS REVEALED",
    "LOOT_CEOTAXPAPERS" => "CEO TAX EVASION UNCOVERED",
    "LOOT_CORPFILES" => "CORPORATE CORRUPTION EXPOSED",
    "LOOT_CCS_BACKERLIST" => "CCS GOVERNMENT TIES REVEALED",
    "LOOT_INTHQDISK" || "LOOT_SECRETDOCUMENTS" => "INTELLIGENCE FILES LEAKED",
    "LOOT_POLICERECORDS" => "POLICE MISCONDUCT EXPOSED",
    "LOOT_JUDGEFILES" => "JUDICIAL CORRUPTION REVEALED",
    "LOOT_RESEARCHFILES" => "RESEARCH ABUSES UNCOVERED",
    "LOOT_PRISONFILES" => "PRISON ABUSES EXPOSED",
    "LOOT_CABLENEWSFILES" => "CABLE NEWS BIAS REVEALED",
    "LOOT_AMRADIOFILES" => "AM RADIO PROPAGANDA EXPOSED",
    _ => "LIBERAL GUARDIAN EXPOSÉ"
  };

  // Record the opinion changes in effects
  for (View issue in issues) {
    double change =
        gameState.politics.publicOpinion[issue]! - beforeOpinion[issue]!;
    if (change != 0) {
      archiveStory.effects[issue] = change;
    }
  }

  // Archive the story directly
  archiveNewsStory(archiveStory);

  await getKey();
}
