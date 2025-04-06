import 'package:lcs_new_age/basemode/disbanding.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/constitution.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

DeepAlignment determinePoliticianVote(DeepAlignment alignment, Law law) {
  DeepAlignment vote = alignment;
  double mood = politics.publicSupportForLaw(law);
  if (vote == DeepAlignment.archConservative ||
      vote == DeepAlignment.eliteLiberal) {
    // Extremist -- Damn public opinion, I'm doing what I think is right
  } else {
    // Political center
    // Consult public opinion and then adjust the vote by up to 1 step
    int polling = 0;
    for (int i = 0; i < 4; i++) {
      if (lcsRandom(100) < mood) {
        polling++;
      }
    }
    int delta = polling - alignment.index;
    if (delta.abs() > 1) {
      polling = polling - delta ~/ delta.abs();
    }
    vote = DeepAlignment.values[polling];
  }
  return vote;
}

enum BillStatus {
  signed,
  vetoOverride,
  passedCongress,
  failed,
}

DeepAlignment cabinetDeliberation(Exec decisionMaker) {
  int vote;
  if (exec[decisionMaker]! >= DeepAlignment.conservative &&
      exec[decisionMaker]! <= DeepAlignment.liberal) {
    // only consult Cabinet if decisionMaker isn't an extremist
    vote = ((exec[Exec.president]!.index +
                exec[Exec.vicePresident]!.index +
                exec[Exec.secretaryOfState]!.index +
                exec[Exec.attorneyGeneral]!.index +
                lcsRandomDouble(9) -
                4) /
            4)
        .clamp(0, 4)
        .round();
  } else {
    vote = exec[decisionMaker]!.index;
  }
  return DeepAlignment.values[vote];
}

/* politics - causes congress to act on legislation */
Future<void> congress() async {
  if (canSeeThings) {
    await showMessage("Congress is acting on legislation!");
  }

  //CHANGE THINGS AND REPORT
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "Legislative Agenda $year");
  }

  int cnum = lcsRandom(3) + 1;
  List<Law> bill = [for (int i = 0; i < cnum; i++) Law.elections];
  List<int> billdir = [for (int i = 0; i < cnum; i++) 0];
  List<BillStatus> billStatus = [
    for (int i = 0; i < cnum; i++) BillStatus.passedCongress
  ];
  Map<Law, bool> lawtaken = {for (var law in Law.values) law: false};
  Map<Law, int> lawpriority = {for (var law in Law.values) law: 0};
  Map<Law, int> lawdir = {for (var law in Law.values) law: 0};

  List<DeepAlignment> house = [...politics.house];
  List<DeepAlignment> senate = [...politics.senate];
  house.shuffle();
  senate.shuffle();

  //DETERMINE BILLS
  int pup, pdown;
  for (Law l in Law.values) {
    pup = 0;
    pdown = 0;

    // Consult House
    for (int cl = 0; cl < house.length; cl++) {
      DeepAlignment housealign = house[cl];
      if (laws[l]! < housealign) {
        pup++;
        if (housealign == DeepAlignment.eliteLiberal) pup += 2;
      } else if (laws[l]! > housealign) {
        pdown++;
        if (housealign == DeepAlignment.archConservative) pdown += 2;
      }
    }
    // Consult Senate
    for (int sl = 0; sl < senate.length; sl++) {
      DeepAlignment senatealign = senate[sl];
      if (laws[l]! < senatealign) {
        pup += 4;
        if (senatealign == DeepAlignment.eliteLiberal) pup += 6;
      } else if (laws[l]! > senatealign) {
        pdown += 4;
        if (senatealign == DeepAlignment.archConservative) pdown += 6;
      }
    }
    // Consult Public Opinion
    double mood = politics.publicSupportForLaw(l);
    int publicPosition = 0;
    for (int i = 0; i < 4; i++) {
      if (10 + 20 * i < mood) publicPosition++;
    }
    if (laws[l]!.index < publicPosition) pup += 150;
    if (laws[l]!.index > publicPosition) pdown += 150;

    if (pup > pdown) {
      lawdir[l] = 1;
    } else if (pup == pdown) {
      lawdir[l] = lcsRandom(2) * 2 - 1;
    } else {
      lawdir[l] = -1;
    }
    if (laws[l] == DeepAlignment.archConservative) lawdir[l] = 1;
    if (laws[l] == DeepAlignment.eliteLiberal) lawdir[l] = -1;

    //CALC PRIORITY
    lawpriority[l] = ((pup - pdown).abs() *
            ((politics.publicInterestForLaw(l) + lcsRandom(25)) / 100))
        .round();
  }

  for (int c = 0; c < cnum; c++) {
    int maxprior = lawpriority.entries
        .where((e) => lawtaken[e.key] != true)
        .reduce(
            (value, element) => element.value > value.value ? element : value)
        .value;
    List<Law> canlaw = lawpriority.entries
        .where((element) =>
            element.value == maxprior && lawtaken[element.key] == false)
        .map((e) => e.key)
        .toList();
    bill[c] = canlaw.random;
    lawtaken[bill[c]] = true;
    billdir[c] = lawdir[bill[c]]!;

    if (canSeeThings) {
      mvaddstrc(c * 3 + 2, 0, white, "Joint Resolution $year-${c + 1}");

      move(c * 3 + 3, 0);
      if (billdir[c] == 1) {
        setColor(lightGreen);
      } else {
        setColor(red);
      }
      addstr(billName(bill[c], billdir[c] > 0));
      setColor(lightGray);
      refresh();
    }
  }

  if (canSeeThings) {
    mvaddstrc(23, 0, lightGray, "Press any key to watch the votes unfold.");
    await getKey();
    mvaddstr(0, 62, "House");
    mvaddstr(0, 70, "Senate");
  }

  for (int c = 0; c < cnum; c++) {
    bool yesWinHouse = false, yesWinSenate = false;
    int yesVotesHouse = 0, yesVotesSenate = 0;
    DeepAlignment vote;
    int s = 0;

    Stopwatch sw = Stopwatch()..start();
    for (int l = 0; l < house.length; l++) {
      vote = determinePoliticianVote(house[l], bill[c]);

      if (laws[bill[c]]! > vote && billdir[c] == -1) yesVotesHouse++;
      if (laws[bill[c]]! < vote && billdir[c] == 1) yesVotesHouse++;

      if (l == house.length - 1) {
        if (yesVotesHouse > house.length / 2) yesWinHouse = true;
        if (yesVotesHouse > house.length * 2 / 3) {
          billStatus[c] = BillStatus.vetoOverride;
        }
      }

      if (canSeeThings) {
        if (l == house.length - 1 && yesWinHouse) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(c * 3 + 2, 62, "$yesVotesHouse Yea");

        if (l == house.length - 1 && !yesWinHouse) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(c * 3 + 3, 62, "${l + 1 - yesVotesHouse} Nay");
      }

      if ((l + 1) / house.length >= (s + 1) / senate.length) {
        vote = determinePoliticianVote(senate[s++], bill[c]);

        if (laws[bill[c]]! > vote && billdir[c] == -1) yesVotesSenate++;
        if (laws[bill[c]]! < vote && billdir[c] == 1) yesVotesSenate++;
      }

      if (l == house.length - 1) {
        if (yesVotesSenate > senate.length / 2) yesWinSenate = true;
        if (yesVotesSenate < senate.length * 2 / 3 &&
            billStatus[c] == BillStatus.vetoOverride) {
          billStatus[c] = BillStatus.passedCongress;
        }
        if (yesVotesSenate == senate.length / 2) {
          //TIE BREAKER
          DeepAlignment vote = cabinetDeliberation(Exec.vicePresident);
          if (laws[bill[c]]! > vote && billdir[c] == -1) yesWinSenate = true;
          if (laws[bill[c]]! < vote && billdir[c] == 1) yesWinSenate = true;

          //ASSURED SIGNING BY PRESIDENT IF VP VOTED YES
          if (yesWinSenate) billStatus[c] = BillStatus.signed;
        }
      }

      if (canSeeThings) {
        if (l == house.length - 1 && yesWinSenate) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(c * 3 + 2, 70, "$yesVotesSenate Yea");

        if (l == house.length - 1 &&
            yesVotesSenate == senate.length ~/ 2 &&
            yesWinSenate) {
          mvaddstrc(c * 3 + 2, 78, white, "VP");
        }

        if (l == house.length - 1 && !yesWinSenate) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(c * 3 + 3, 70, "${s - yesVotesSenate} Nay");

        if (l == house.length - 1 &&
            yesVotesSenate == senate.length ~/ 2 &&
            !yesWinSenate) {
          mvaddstrc(c * 3 + 3, 78, white, "VP");
        }

        if (sw.elapsedMilliseconds < 2 * (l + 1)) {
          await pause(sw.elapsedMilliseconds - 2 * (l + 1));
        }
      }
    }

    if (!yesWinHouse || !yesWinSenate) billStatus[c] = BillStatus.failed;
  }

  int havebill = 0;
  for (int c = 0; c < cnum; c++) {
    if (billStatus[c] != BillStatus.failed) havebill++;
  }

  if (havebill > 0) {
    if (canSeeThings) {
      mvaddstrc(23, 0, lightGray,
          "Press any key to watch the President.                   ");

      await getKey();

      mvaddstr(0, 35, "President");

      await pause(500);
    }

    for (int c = 0; c < bill.length; c++) {
      if (billStatus[c] != BillStatus.failed) {
        DeepAlignment vote = cabinetDeliberation(Exec.president);

        if ((laws[bill[c]]! > vote && billdir[c] == -1) ||
            (laws[bill[c]]! < vote && billdir[c] == 1)) {
          billStatus[c] = BillStatus.signed;
        }
      }

      if (canSeeThings) {
        move(c * 3 + 2, 35);
        if (billStatus[c] == BillStatus.signed) {
          setColor(billdir[c] > 0 ? lightGreen : red);
          addstr(execName[Exec.president]!.firstLast);
        } else if (billStatus[c] == BillStatus.failed) {
          setColor(darkGray);
          addstr("Dead in Congress");
        } else if (billStatus[c] == BillStatus.vetoOverride) {
          setColor(billdir[c] > 0 ? lightGreen : red);
          addstr("VETO OVERRIDDEN");
        } else {
          setColor(white);
          addstr("*** VETO ***");
        }
        await pause(500);
      }

      if (billStatus[c] == BillStatus.signed ||
          billStatus[c] == BillStatus.vetoOverride) {
        laws[bill[c]] = DeepAlignment
            .values[(laws[bill[c]]!.index + billdir[c]).clamp(0, 4)];
      }
    }

    if (canSeeThings) {
      mvaddstrc(23, 0, lightGray,
          "Press any key to reflect on what has happened.    ");
      checkKey();
      await getKey();
    }
  } else if (canSeeThings) {
    mvaddstrc(
        23, 0, lightGray, "None of the items made it to the President's desk.");
    mvaddstr(24, 0, "Press any key to reflect on what has happened.    ");
    checkKey();
    await getKey();
  }

  //CONGRESS CONSTITUTION CHANGES
  List<int> housemake = summarizePoliticalBody(house);
  List<int> senatemake = summarizePoliticalBody(senate);

  // Throw out non-L+ Justices?
  bool tossj = false;
  for (int j = 0; j < court.length; j++) {
    if (court[j] != DeepAlignment.eliteLiberal) tossj = true;
  }
  if (housemake[4] + housemake[3] / 2 >= house.length * 2 / 3 &&
      senatemake[4] + senatemake[3] / 2 >= senate.length * 2 / 3 &&
      tossj &&
      !politics.supremeCourtPurged) {
    await tryToPurgeSupremeCourt();
  }

  // Purge Congress, implement term limits, and hold new elections?
  if ((housemake[4] + housemake[3] / 2 < house.length * 2 / 3 ||
          senatemake[4] + senatemake[3] / 2 < senate.length * 2 / 3) &&
      politics.publicMood() > 80 &&
      !politics.termLimitsPassed) {
    await tryToPassTermLimits();
  }

  // LET ARCH-CONSERVATIVES REPEAL THE CONSTITUTION AND LOSE THE GAME?
  if (housemake[0] > house.length * 1 / 2 &&
      senatemake[0] >= senate.length * 1 / 2 &&
      laws.values.every((law) => law == DeepAlignment.archConservative) &&
      politics.timeSinceLastConstitutionRepealAttempt > 5) {
    politics.timeSinceLastConstitutionRepealAttempt = 0;
    await tryToRepealConstitution();
  } else {
    politics.timeSinceLastConstitutionRepealAttempt++;
  }
}
