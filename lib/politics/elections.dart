/* politics - causes the people to vote (presidential, congressional, propositions) */
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

DeepAlignment getVoter([PoliticalParty? party]) {
  DeepAlignment voterAlignment = DeepAlignment.moderate;
  for (int i = 0; i < 2; i++) {
    var weights =
        politics.voterSpread(politics.publicOpinion[View.issues.random]!);
    if (party == politics.presidentParty) {
      // Less moderate when in power
      weights[DeepAlignment.moderate] = weights[DeepAlignment.moderate]! / 2;
    }
    if (party == PoliticalParty.republican) {
      // No liberals in the GOP
      weights[DeepAlignment.liberal] = 0;
      weights[DeepAlignment.eliteLiberal] = 0;
    } else if (party == PoliticalParty.democrat) {
      // No conservatives in the Democratic Party
      weights[DeepAlignment.conservative] = 0;
      weights[DeepAlignment.archConservative] = 0;
    }
    DeepAlignment viewOnIssue = lcsRandomWeighted(weights);
    if (voterAlignment < viewOnIssue) {
      voterAlignment = DeepAlignment.values[voterAlignment.index + 1];
    } else if (voterAlignment > viewOnIssue) {
      voterAlignment = DeepAlignment.values[voterAlignment.index - 1];
    }
  }
  return voterAlignment;
}

Future<void> elections() async {
  if (canSeeThings) {
    if (year % 4 == 0 && month == 11) {
      await showMessage("The Presidential Election is being held today!");
    } else if (year % 2 == 0 && month == 11) {
      await showMessage("Congressional Elections are being held today!");
    } else {
      await showMessage("Local elections are being held today!");
    }
  }

  if ((year % 4 == 0) && (month == 11)) {
    await presidentialElection();
  }

  if (year % 2 == 0) await senateElections((year % 6) ~/ 2);
  if (year % 2 == 0) await houseElections();

  await ballotMeasures();
}

Future<void> presidentialElection() async {
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "Presidential General Election $year");

    setColor(lightGray);
    move(2, 0);
    addstr(
        "After a long primary campaign, the people have rallied around two leaders...");
  }

  //Primaries
  int presidentOwnPartyApproval = 0;
  int veepOwnPartyApproval = 0;
  Map<PoliticalParty, Map<DeepAlignment, int>> primaryVotes = {
    for (var party in PoliticalParty.values)
      party: {for (var alignment in DeepAlignment.values) alignment: 0}
  };

  // run primaries for 100 voters of each party
  for (int i = 0; i < 100; i++) {
    Map<PoliticalParty, DeepAlignment> voter = {
      for (var party in PoliticalParty.values) party: getVoter(party)
    };
    int differenceFromPresident =
        (voter[politics.presidentParty]!.index - exec[Exec.president]!.index)
            .abs();
    // presidential approval within own party: 50% from adjacent
    if (differenceFromPresident == 0 ||
        (differenceFromPresident == 1 && oneIn(2))) {
      presidentOwnPartyApproval++;
    }
    // vice-presidential approval within own party: 33% from adjacent
    int differenceFromVP = (voter[politics.presidentParty]!.index -
            exec[Exec.vicePresident]!.index)
        .abs();
    if (differenceFromVP == 0 || (differenceFromVP == 1 && oneIn(3))) {
      veepOwnPartyApproval++;
    }
    // count ballots
    for (var party in PoliticalParty.values) {
      primaryVotes[party]!.update(voter[party]!, (value) => value + 1);
    }
  }

  Map<PoliticalParty, DeepAlignment> nomineeAlign = {
    for (var party in PoliticalParty.values) party: DeepAlignment.moderate
  };
  Map<PoliticalParty, FullName> nomineeName = {};

  // determine each party's nominee
  for (PoliticalParty party in PoliticalParty.values) {
    final candidateRankings = primaryVotes[party]!.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final candidateAlign = candidateRankings.first.key;
    nomineeAlign[party] = candidateAlign;
    nomineeName[party] = generateFullName(switch (candidateAlign) {
      DeepAlignment.archConservative => Gender.whiteMalePatriarch,
      DeepAlignment.eliteLiberal => Gender.nonbinary,
      _ => Gender.maleBias,
    });
  }

  // Special Incumbency Rules: If the incumbent president or vice president
  // has approval of over 50% in their party (40% for President), they win the
  // primary automatically. President wins the primary if their alignment wins
  // using the normal primary process as well.
  if (politics.execTerm == 1) // President running for re-election
  {
    debugPrint(
        "President running for re-election with $presidentOwnPartyApproval% approval in their party.");
    if (presidentOwnPartyApproval >= 40) {
      nomineeAlign[politics.presidentParty] = politics.exec[Exec.president]!;
    }
    if (nomineeAlign[politics.presidentParty] ==
        politics.exec[Exec.president]!) {
      nomineeName[politics.presidentParty] = politics.execName[Exec.president]!;
    } else {
      // Unpopular incumbent president not nominated for a second term
      // New candidate works with a clean slate.
      politics.execTerm = 2;
    }
  } else if (veepOwnPartyApproval >= 50) {
    // Vice-President running for President
    nomineeAlign[politics.presidentParty] = politics.exec[Exec.vicePresident]!;
    nomineeName[politics.presidentParty] =
        politics.execName[Exec.vicePresident]!;
  }

  //Print candidates
  if (canSeeThings) {
    for (int c = 0; c < PoliticalParty.values.length; c++) {
      PoliticalParty party = PoliticalParty.values[c];
      // Pick color by political orientation
      setColor(nomineeAlign[party]!.color);

      move(8 - ((c + 1) % 3) * 2, 0);
      // Choose title -- president or vice president special titles, otherwise
      // pick based on historically likely titles (eg, governor most likely...)
      if (party == politics.presidentParty && politics.execTerm == 1) {
        addstr("President ");
      } else if (party == politics.presidentParty &&
          nomineeName[party]! == execName[Exec.vicePresident]!) {
        addstr("Vice President ");
      } else if (oneIn(2)) {
        addstr("Governor ");
      } else if (oneIn(2)) {
        addstr("Senator ");
      } else if (oneIn(2)) {
        addstr("Representative ");
      } else if (oneIn(2)) {
        addstr("Ret. General ");
      } else if (oneIn(2)) {
        addstr("Mr. ");
      } else {
        addstr("Mrs. ");
      }

      addstr("${nomineeName[party]!}, ${nomineeAlign[party]!.veryShort}");
    }

    if (!disbanding) {
      mvaddstrc(8, 0, lightGray, "Press any key to watch the election unfold.");

      checkKey();
      await getKey();
    } else {
      await pause(200);
    }
  }

  PoliticalParty winner = PoliticalParty.republican;
  Map<PoliticalParty, int> votes = {
    for (var party in PoliticalParty.values) party: 0
  };

  Stopwatch sw = Stopwatch()..start();
  for (int l = 0; l < 1000; l++) // 1000 Voters!
  {
    if (l % 2 == 0 && oneIn(2)) {
      // Partyline Liberals (~25%)
      votes.update(PoliticalParty.democrat, (v) => v + 1);
    } else if (l % 2 == 1 && oneIn(2)) {
      // Partyline Conservatives (~25%)
      votes.update(PoliticalParty.republican, (v) => v + 1);
    } else {
      // Swing Voters (~50%)
      // Get the aggregate opinion of an issue voter
      DeepAlignment vote = getVoter();
      // Rank the candidates by how close they are to the voter (randomize ties)
      final rankedChoices = nomineeAlign
          .map((key, value) => MapEntry(key, (vote.index - value.index).abs()))
          .entries
          .toList()
        ..shuffle()
        ..sort((a, b) => a.value.compareTo(b.value));
      // Vote for the closest candidate
      votes.update(rankedChoices.first.key, (v) => v + 1);
    }

    if (l % 5 == 4) {
      int maxvote = 0;
      for (PoliticalParty party in PoliticalParty.values) {
        if (votes[party]! > maxvote) maxvote = votes[party]!;
      }
      List<PoliticalParty> eligible = [];
      for (PoliticalParty party in PoliticalParty.values) {
        if (votes[party] == maxvote) eligible.add(party);
      }
      bool recount = eligible.length > 1;
      winner = eligible.random;

      if (canSeeThings && sw.elapsedMilliseconds < 5 * (l + 1)) {
        for (int c = 0; c < PoliticalParty.values.length; c++) {
          PoliticalParty party = PoliticalParty.values[c];
          setColor(party == winner ? white : darkGray);
          mvaddstr(8 - ((c + 1) % 3) * 2, 45,
              "${votes[party]! ~/ 10}.${votes[party]! % 10}%");
          if (party == winner && recount && l == 999) {
            addstr(" (After Recount)");
          }
        }

        await pause(5 * (l + 1) - sw.elapsedMilliseconds);
      }
    }
  }

  if (canSeeThings) {
    mvaddstrc(8, 0, lightGray, "Press any key to continue the elections.    ");

    checkKey();
    await getKey();
  }

  //CONSTRUCT EXECUTIVE BRANCH
  if ((winner == politics.presidentParty) && (politics.execTerm == 1)) {
    politics.execTerm = 2;
  } else {
    politics.presidentParty = winner;
    politics.execTerm = 1;
    exec[Exec.president] = nomineeAlign[winner]!;
    execName[Exec.president] = nomineeName[winner]!;
    for (Exec e in Exec.values) {
      if (e != Exec.president) {
        politics.fillCabinetPost(e);
      }
    }
    uniqueCreatures.newPresident();
  }
}

Future<void> ballotMeasures() async {
  //PROPOSITIONS
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "Important State Ballot Measures $year");
  }

  int pnum = lcsRandom(4) + 4;
  Map<Law, bool> lawtaken = {for (var law in Law.values) law: false};
  Map<Law, double> lawpriority = {for (var law in Law.values) law: 0};
  Map<Law, int> lawdir = {for (var law in Law.values) law: 0};

  //DETERMINE PROPS
  for (Law l in Law.values) {
    double pmood = politics.publicSupportForLaw(l);
    int pvote = 0;
    for (int i = 0; i < 4; i++) {
      if (lcsRandom(100) < pmood) pvote++;
    }

    if (laws[l]!.index < pvote) lawdir[l] = 1;
    if (laws[l]!.index >= pvote) lawdir[l] = -1;
    if (laws[l]!.index == 0) lawdir[l] = 1;
    if (laws[l]!.index == 4) lawdir[l] = -1;

    pvote = laws[l]!.index * 25; //CALC PRIORITY

    lawpriority[l] = 5 * (pvote - pmood).abs() +
        lcsRandom(10) +
        politics.publicInterestForLaw(l);
  }

  List<Law> prop = List.filled(pnum, Law.elections);
  List<int> propdir = List.filled(pnum, 0);
  List<String> propnums = List.filled(pnum, "");
  if (canSeeThings) {
    for (int p = 0; p < pnum; p++) {
      String propnum = "";
      do {
        // this loop prevents duplicate proposition numbers from occurring
        propnum = nameBallotMeasure();
      } while (propnums.contains(propnum));
      propnums[p] = propnum;
    }
    propnums.sort();
  }

  for (int p = 0; p < pnum; p++) {
    double maxprior = lawpriority.entries
        .where((e) => lawtaken[e.key] != true)
        .reduce(
            (value, element) => element.value > value.value ? element : value)
        .value;
    List<Law> canlaw = lawpriority.entries
        .where((element) =>
            element.value == maxprior && lawtaken[element.key] == false)
        .map((e) => e.key)
        .toList();
    prop[p] = canlaw.random;
    lawtaken[prop[p]] = true;
    propdir[p] = lawdir[prop[p]]!;

    if (canSeeThings) {
      move(p * 3 + 2, 0);
      setColor(white);
      addstr("${propnums[p]}: ");
      setColor(propdir[p] > 0 ? lightGreen : red);
      addstr(billName(prop[p], propdir[p] > 0));
      setColor(lightGray);
    }
  }

  if (canSeeThings) {
    mvaddstrc(23, 0, lightGray, "Press any key to watch the elections unfold.");
    checkKey();
    await getKey();
  }

  List<int> yesVotesP = List.filled(pnum, 0);
  Stopwatch s = Stopwatch()..start();
  for (int l = 0; l < 1000; l++) {
    for (int p = 0; p < pnum; p++) {
      bool yeswin = false;
      bool recount = false;
      double mood = politics.publicSupportForLaw(prop[p]);
      if (lcsRandom(100) < mood ? propdir[p] == 1 : propdir[p] == -1) {
        yesVotesP[p]++;
      }
      int yesvotes = yesVotesP[p];

      if (l == 999) {
        if (yesvotes > 500) {
          yeswin = true;
        } else if (yesvotes == 500) {
          yeswin = (lcsRandom(100) < mood ? propdir[p] == 1 : propdir[p] == -1);
          recount = true;
        }
      }

      if (canSeeThings && (l % 10 == 9)) {
        if ((l != 999 && yesvotes > (l / 2 + 10)) || (l == 999 && yeswin)) {
          setColor(propdir[p] == 1 ? lightGreen : red);
        } else if (yesvotes < (l / 2 + 10) || l == 999) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(p * 3 + 2, 70, "${yesvotes ~/ 10}.${yesvotes % 10}% Yes");

        if ((l != 999 && yesvotes < (l / 2 + 10)) || (l == 999 && !yeswin)) {
          setColor(white);
        } else if (yesvotes > (l / 2 + 10) || l == 999) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(p * 3 + 3, 70,
            "${(l + 1 - yesvotes) ~/ 10}.${(l + 1 - yesvotes) % 10}% No");
      }

      if (canSeeThings && recount) {
        mvaddstrc(p * 3 + 3, 0, white, "A Recount was Necessary");
      }

      if (yeswin) {
        laws[prop[p]] = DeepAlignment.values[propdir[p] + laws[prop[p]]!.index];
      }
    }
    if (canSeeThings && s.elapsedMilliseconds < 4 * (l + 1)) {
      await pause(4 * (l + 1) - s.elapsedMilliseconds);
    }
  }

  if (canSeeThings) {
    mvaddstrc(
        23, 0, lightGray, "Press any key to reflect on what has happened.");
    checkKey();
    await getKey();
  }
}

Future<void> senateElections(int senmod) async {
  double mood = politics.publicMood();
  int electionBias = 4 - laws[Law.elections]!.index;
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "Senate Elections $year");
  }

  int x = 0, y = 2, s = 0;

  List<DeepAlignment> senators = [];
  for (int i = 0; i < politics.senate.length; i++) {
    if (senmod != -1 && i % 3 != senmod) continue;
    senators.add(politics.senate[i]);
  }
  senators.sort();

  for (s = 0; s < senators.length; s++) {
    if (canSeeThings) {
      mvaddstrc(y, x, senators[s].color, senators[s].label);
    }

    x += 20;
    if (x > 70) {
      x = 0;
      y++;
    }
  }

  if (canSeeThings) {
    mvaddstrc(23, 0, lightGray, "Press any key to watch the elections unfold.");
    checkKey();
    await getKey();
  }

  int vote;
  List<int> change = [0, 0, 0, 0, 0];

  x = 0;
  y = 2;

  final sw = Stopwatch()..start();
  for (int s = 0; s < senators.length; s++) {
    vote = 0;
    int seatBias = politics.termLimitsPassed ? 0 : (2 - senators[s].index) * 20;
    for (int i = 0; i < 4; i++) {
      if (mood >
          lcsRandom(100) +
              seatBias -
              (s / senators.length - 0.5) * 20 +
              4 * electionBias) {
        vote++;
      }
    }

    change[senators[s].index]--;
    if (politics.rollIncumbentAutowin()) {
      vote = senators[s].index;
    }
    senators[s] = DeepAlignment.values[vote];
    change[senators[s].index]++;

    if (canSeeThings) {
      setColor(senators[s].color);
      mvaddstr(y, x, "                    ");
      mvaddstr(y, x, senators[s].label);
      if (sw.elapsedMilliseconds < 30 * (s + 1)) {
        _showNetChange(change);
        await pause(30 * (s + 1) - sw.elapsedMilliseconds);
      }
    }

    x += 20;
    if (x > 70) {
      x = 0;
      y++;
    }
  }

  for (int i = 0; i < politics.senate.length; i++) {
    if (senmod != -1 && i % 3 != senmod) continue;
    politics.senate[i] = senators[i ~/ 3];
  }

  if (canSeeThings) {
    _showWinner(change, mood, 2);
    mvaddstr(23, 0, "Press any key to continue the elections.    ");
    checkKey();
    await getKey();
  }
}

Future<void> houseElections() async {
  double mood = politics.publicMood();
  int electionBias = 4 - laws[Law.elections]!.index;
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "House Elections $year");
  }

  int x = 0, y = 2;

  politics.house.sort();
  for (int h = 0; h < politics.house.length; h++) {
    if (canSeeThings) {
      move(y, x);

      setColor(house[h].color);
      addstr(house[h].veryShort);
    }

    x += 3;
    if (x > 78) {
      x = 0;
      y++;
    }
  }

  if (canSeeThings) {
    mvaddstrc(23, 0, lightGray, "Press any key to watch the elections unfold.");
    checkKey();
    await getKey();
  }

  int vote;
  List<int> change = [0, 0, 0, 0, 0];

  x = 0;
  y = 2;

  final sw = Stopwatch()..start();
  for (int h = 0; h < politics.house.length; h++) {
    vote = 0;
    for (int i = 0; i < 4; i++) {
      int seatBias = politics.termLimitsPassed ? 0 : (2 - house[h].index) * 20;
      if (mood >
          lcsRandom(100) +
              seatBias -
              (h / house.length - 0.5) * 10 * electionBias +
              4 * electionBias) {
        vote++;
      }
    }

    change[house[h].index]--;
    if (politics.rollIncumbentAutowin()) {
      vote = house[h].index;
    }
    house[h] = DeepAlignment.values[vote];
    change[house[h].index]++;

    if (canSeeThings) {
      move(y, x);
      setColor(house[h].color);
      addstr(house[h].veryShort);
      if (sw.elapsedMilliseconds < 5 * (h + 1)) {
        _showNetChange(change);
        refresh();
        await pause(5 * (h + 1) - sw.elapsedMilliseconds);
      }
    }

    x += 3;
    if (x > 78) {
      x = 0;
      y++;
    }
  }

  if (canSeeThings) {
    _showWinner(change, mood, 6);
    if (!disbanding) {
      mvaddstr(23, 0, "Press any key to continue the elections.    ");

      checkKey();
      await getKey();
    } else {
      await pause(800);
    }
  }
}

void _showNetChange(List<int> change) {
  mvaddstrc(20, 0, lightGray, "Net change:");
  addstr("   L+: ");
  if (change[4] > 0) addstr("+");
  addstr("${change[4]}");
  addstr("   L: ");
  if (change[3] > 0) addstr("+");
  addstr("${change[3]}");
  addstr("   m: ");
  if (change[2] > 0) addstr("+");
  addstr("${change[2]}");
  addstr("   C: ");
  if (change[1] > 0) addstr("+");
  addstr("${change[1]}");
  addstr("   C+: ");
  if (change[0] > 0) addstr("+");
  addstr("${change[0]}");
  addstr("        ");
}

void _showWinner(List<int> change, double mood, int thresholdForVictory) {
  move(21, 0);
  DeepAlignment winner;
  if (change[0] + change[1] > change[3] + change[4] + thresholdForVictory) {
    if (change[1] < change[0]) {
      winner = DeepAlignment.archConservative;
    } else {
      winner = DeepAlignment.conservative;
    }
  } else if (change[3] + change[4] >
      change[0] + change[1] + thresholdForVictory) {
    if (change[3] < change[4]) {
      winner = DeepAlignment.eliteLiberal;
    } else {
      winner = DeepAlignment.liberal;
    }
  } else if (change[0] > thresholdForVictory && change[4] <= 0) {
    winner = DeepAlignment.archConservative;
  } else if (change[4] > thresholdForVictory && change[0] <= 0) {
    winner = DeepAlignment.eliteLiberal;
  } else {
    winner = DeepAlignment.moderate;
  }
  setColor(winner.color);
  switch (winner) {
    case DeepAlignment.archConservative:
      addstr("The power of the Arch Conservative far right is growing...");
    case DeepAlignment.conservative:
      addstr("The power of the Republican Party is growing.");
    case DeepAlignment.moderate:
      addstr("The balance of power has largely held.");
      if (change[0] > 0 && change[4] > 0) {
        mvaddstr(22, 0, "But the political center is disappearing.");
      } else if (change[0] > 0) {
        mvaddstrc(22, 0, red,
            "But the Arch Conservative far right still gained seats.");
      }
    case DeepAlignment.liberal:
      addstr("The Democratic Party is gaining ground.");
      if (change[0] > 0) {
        mvaddstrc(22, 0, red,
            "But the Arch Conservative far right also gained seats.");
      }
    case DeepAlignment.eliteLiberal:
      addstr("The Elite Liberal far left is growing!");
      if (change[0] > 0) {
        mvaddstrc(22, 0, red,
            "But the Arch Conservative far right also gained seats.");
      }
  }
  setColor(lightGray);
}

enum InitiativeStates {
  alaska,
  arizona,
  arkansas,
  california,
  colorado,
  idaho,
  maine,
  massachusetts,
  michigan,
  missouri,
  montana,
  nebraska,
  nevada,
  northDakota,
  ohio,
  oklahoma,
  oregon,
  southDakota,
  utah,
  washington,
  wyoming,
}

String nameBallotMeasure() {
  return switch (InitiativeStates.values.random) {
    InitiativeStates.alaska => "AK Measure ${lcsRandom(3) + 1}",
    InitiativeStates.arizona => "AZ Amendment ${lcsRandom(3) + 1}",
    InitiativeStates.arkansas => "AR Amendment ${lcsRandom(3) + 1}",
    InitiativeStates.california => "CA Proposition ${lcsRandom(10) + 1}",
    InitiativeStates.colorado => "CO Proposition ${140 + lcsRandom(30)}",
    InitiativeStates.idaho => "ID Amendment ${lcsRandom(5) + 1}",
    InitiativeStates.maine => "ME Question ${lcsRandom(3) + 1}",
    InitiativeStates.massachusetts => "MA Question ${lcsRandom(3) + 1}",
    InitiativeStates.michigan => "MI Proposal ${lcsRandom(3) + 1}",
    InitiativeStates.missouri => "MO Amendment ${lcsRandom(3) + 1}",
    InitiativeStates.montana => "MT Amendment ${60 + lcsRandom(20)}",
    InitiativeStates.nebraska => "NE Initiative ${440 + lcsRandom(100)}",
    InitiativeStates.nevada => "NV Question ${lcsRandom(5) + 1}",
    InitiativeStates.northDakota => "ND Measure ${lcsRandom(3) + 1}",
    InitiativeStates.ohio => "OH Issue ${lcsRandom(3) + 1}",
    InitiativeStates.oklahoma => "OK Question ${800 + lcsRandom(100)}",
    InitiativeStates.oregon => "OR Measure ${120 + lcsRandom(20)}",
    InitiativeStates.southDakota => "SD Measure ${30 + lcsRandom(10)}",
    InitiativeStates.utah => "UT Amendment ${letterAPlus(lcsRandom(7))}",
    InitiativeStates.washington => "WA Initiative ${900 + lcsRandom(1000)}",
    InitiativeStates.wyoming => "WY Amendment ${letterAPlus(lcsRandom(3))}",
  };
}
