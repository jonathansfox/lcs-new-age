/* endgame - attempts to pass a constitutional amendment to help win the game */
import 'dart:ui';

import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/basemode/liberal_agenda.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/elections.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/states.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/saveload/save_load.dart';
import 'package:lcs_new_age/title_screen/game_over.dart';
import 'package:lcs_new_age/title_screen/high_scores.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> tryToPurgeSupremeCourt() async {
  if (canSeeThings) {
    erase();

    mvaddstrc(12, 6, white,
        "The Elite Liberal Congress is proposing an ELITE LIBERAL AMENDMENT!");

    await getKey();
  }

  //STATE THE AMENDMENT
  if (canSeeThings) {
    int tossnum = 0;
    for (int j = 0; j < politics.court.length; j++) {
      if (court[j] != DeepAlignment.eliteLiberal) tossnum++;
    }

    amendmentHeading();

    mvaddstr(2, 5, "The following former citizen");
    if (tossnum != 1) {
      addstr("s are");
    } else {
      addstr(" is");
    }
    addstr(" branded Arch-Conservative:");

    int y = 4;

    for (int j = 0; j < politics.court.length; j++) {
      if (court[j] != DeepAlignment.eliteLiberal) {
        mvaddstr(y++, 0, politics.courtName[j].toString());
      }
    }

    mvaddstr(y + 1, 5, "In particular, the aforementioned former citizen");
    if (tossnum != 1) addstr("s");
    addstr(" may");
    mvaddstr(y + 2, 0, "not serve on the Supreme Court.  Said former citizen");
    if (tossnum != 1) addstr("s");
    addstr(" will");
    mvaddstr(y + 3, 0, "be deported to ");
    if (tossnum != 1) {
      addstr("Conservative countries");
    } else {
      addstr("a Conservative country");
    }
    addstr(" of the President's");
    mvaddstr(y + 4, 0, "choosing to be replaced by ");
    if (tossnum != 1) {
      addstr("Proper Justices");
    } else {
      addstr("a Proper Justice");
    }
    addstr(", also of");
    mvaddstr(
        y + 5, 0, "the President's choosing with the advice and consent of");
    mvaddstr(y + 6, 0, "the Senate.");

    mvaddstr(24, 0, "Press 'C' to watch the ratification process unfold.");

    while (await getKey() != Key.c) {}
  }

  if (await ratifyConstitutionalAmendment(DeepAlignment.eliteLiberal)) {
    //BLAST JUSTICES
    for (int j = 0; j < politics.court.length; j++) {
      if (court[j] != DeepAlignment.eliteLiberal) {
        do {
          politics.courtName[j] = generateFullName();
        } while (politics.courtName[j].firstLast.length > 20);
        court[j] = DeepAlignment.eliteLiberal;
      }
    }
    politics.supremeCourtPurged = true;
  }

  if (canSeeThings) {
    mvaddstr(24, 0, "Press any key to reflect on what has happened.");

    await getKey();
  }
}

/* endgame - attempts to pass a constitutional amendment to help win the game */
Future<void> tryToPassTermLimits() async {
  if (politics.termLimitsPassed) {
    return; // Durr~! Don't pass this amendment if it's already passed!
  }
  if (canSeeThings) {
    erase();

    mvaddstrc(12, 6, white,
        "A National Convention has proposed an ELITE LIBERAL AMENDMENT!");

    await getKey();
  }

  //STATE THE AMENDMENT
  if (canSeeThings) {
    amendmentHeading();

    mvaddstr(
        2, 5, "In light of the Conservative nature of entrenched politicians,");
    mvaddstr(3, 0,
        "and the corrupting influence of incumbency on the democratic process,");
    mvaddstr(4, 0,
        "all members of the House of Representatives and Senate shall henceforth");
    mvaddstr(5, 0,
        "be limited to one term in office.  This shall be immediately enforced");
    mvaddstr(6, 0,
        "by holding elections to replace all members of Congress upon the");
    mvaddstr(7, 0, "ratification of this amendment.");

    mvaddstr(24, 0, "Press 'C' to watch the ratification process unfold.");

    while (await getKey() != Key.c) {}
  }

  if (await ratifyConstitutionalAmendment(DeepAlignment.eliteLiberal,
      bypassCongress: true)) {
    politics.termLimitsPassed = true;
    politics.laws[Law.elections] = DeepAlignment.eliteLiberal;
    if (canSeeThings) {
      mvaddstr(24, 0,
          "Press any key to hold new elections!                           ");
      await getKey();
    }
    await senateElections(0);
    await senateElections(1);
    await senateElections(2);
    await houseElections();
  } else if (canSeeThings) {
    mvaddstr(24, 0, "Press any key to reflect on what has happened.");

    await getKey();
  }
}

/* endgame - attempts to pass a constitutional amendment to lose the game */
Future<void> tryToRepealConstitution() async {
  if (canSeeThings) {
    setColor(white);

    erase();
    mvaddstr(12, 3,
        "The Arch-Conservative Congress is proposing an ARCH-CONSERVATIVE AMENDMENT!");

    await getKey();

    //STATE THE AMENDMENT
    amendmentHeading();

    mvaddstr(
        2, 5, "In recognition of the fact that society is degenerating under");
    mvaddstr(
        3, 0, "the pressure of the elite liberal threat, WE THE PEOPLE HEREBY");
    mvaddstr(
        4, 0, "REPEAL THE CONSTITUTION.  The former United States are to be");
    mvaddstr(
        5, 0, "reorganized into the CONFEDERATED STATES OF AMERICA, with new");
    mvaddstr(6, 0, "boundaries to be determined by leading theologians.");
    mvaddstr(8, 5, "Ronald Reagan is to be King, forever, even after death.");
    mvaddstr(10, 5,
        "The following Executive Officers are also chosen in perpetuity:");
    mvaddstr(11, 0,
        "Minister of Love Strom Thurmond, Minister of Peace Jesse Helms,");
    mvaddstr(12, 0, "and Minister of Truth Jerry Falwell.");
    mvaddstr(
        14, 5, "Even though all of the aforementioned persons are deceased,");
    mvaddstr(
        15, 0, "they shall nominally hold these posts without end, and all");
    mvaddstr(
        16, 0, "actual decisions shall be made by business representatives,");
    mvaddstr(17, 0, "chosen by respected business leaders.");
    mvaddstr(
        19, 5, "People may petition Jesus for a redress of grievances, as");
    mvaddstr(20, 0, "He will be the only one listening.");
    mvaddstr(22, 5, "Have a nice day.");

    mvaddstr(24, 0, "Press 'C' to watch the ratification process unfold.");

    while (await getKey() != Key.c) {}
  }

  if (await ratifyConstitutionalAmendment(DeepAlignment.archConservative)) {
    if (canSeeThings) {
      mvaddstr(24, 0,
          "Press any key to reflect on what has happened ONE LAST TIME.");

      await getKey();
    }

    politics.constitutionalAmendments = 0; // Constitution repealed...

    for (Law l in laws.keys) {
      laws[l] = DeepAlignment.archConservative;
    }

    //REAGANIFY
    HighScore yourScore;
    if (canSeeThings) {
      execName[Exec.president] = FullName("Ronald", "", "Reagan", Gender.male);
      execName[Exec.vicePresident] =
          FullName("Strom", "", "Thurmond", Gender.male);
      execName[Exec.secretaryOfState] =
          FullName("Jesse", "", "Helms", Gender.male);
      execName[Exec.attorneyGeneral] =
          FullName("Jerry", "", "Falwell", Gender.male);
      for (Exec e in exec.keys) {
        exec[e] = DeepAlignment.archConservative;
      }

      await liberalAgenda(AgendaVibe.conservativeVictory);
      yourScore = await saveHighScore(Ending.reaganified);
    } else {
      switch (cantSeeReason) {
        case CantSeeReason.dating:
          //DATING AND REAGANIFIED
          await defeatMessages(
            "You went on vacation when the country was on the verge of collapse.",
            "The Conservatives have made the world in their image.",
            "They'll round up the last of you eventually.  All is lost.",
          );
          yourScore = await saveHighScore(Ending.dating);
        case CantSeeReason.hiding:
          //HIDING AND REAGANIFIED
          await defeatMessages(
            "You went into hiding when the country was on the verge of collapse.",
            "The Conservatives have made the world in their image.",
            "They'll round the last of you up eventually.  All is lost.",
          );
          yourScore = await saveHighScore(Ending.hiding);
        case CantSeeReason.prison:
          //IF YOU ARE ALL IN PRISON, JUST PASS AWAY QUIETLY
          await defeatMessages(
            "While you were on the inside, the country degenerated...",
            "Your kind are never released these days.",
            "Ain't no sunshine...",
          );
          yourScore = await saveHighScore(Ending.prison);
        case CantSeeReason.disbanded:
          //DISBANDED AND REAGANIFIED
          await defeatMessages(
            "You disappeared safely, but you hadn't done enough.",
            "The Conservatives have made the world in their image.",
            "They'll round the last of you up eventually.  All is lost.",
          );
          yourScore = await saveHighScore(Ending.disbandLoss);
        case CantSeeReason.hospital:
          //HOSPITALIZED AND REAGANIFIED
          await defeatMessages(
            "You were in the hospital when the country was on the verge of collapse.",
            "The Conservatives have made the world in their image.",
            "They'll round the last of you up eventually.  All is lost.",
          );
          yourScore = await saveHighScore(Ending.reaganified);
        case CantSeeReason.other:
        case CantSeeReason.none:
          //OTHER AND REAGANIFIED
          await defeatMessages(
            "You weren't there when the country was on the verge of collapse.",
            "The Conservatives have made the world in their image.",
            "They'll round the last of you up eventually.  All is lost.",
          );
          yourScore = await saveHighScore(Ending.reaganified);
      }
    }

    await deleteSaveGame();
    await viewHighScores(yourScore);
    endGame();
  } else {
    if (canSeeThings) {
      mvaddstr(24, 0,
          "Press any key to breathe a sigh of relief.                   ");

      await getKey();
    }
  }
}

/* endgame - checks if a constitutional amendment is ratified */
Future<bool> ratifyConstitutionalAmendment(DeepAlignment level,
    {bool bypassCongress = false, Law? lawview, View? view}) async {
  if (canSeeThings) {
    erase();

    mvaddstrc(0, 0, white, "The Ratification Process:");
  }

  //THE STATE VOTE WILL BE BASED ON VIEW OF LAW
  double mood;
  if (lawview != null) {
    mood = politics.publicSupportForLaw(lawview);
  } else {
    mood = politics.publicMood();
  }
  //OR OF A PARTICULAR ISSUE
  if (view != null) mood = politics.publicOpinion[view] ?? mood;

  //CONGRESS
  bool ratified = false;

  if (!bypassCongress) {
    ratified = true;

    if (canSeeThings) {
      mvaddstr(0, 62, "House");
      mvaddstr(0, 70, "Senate");
      mvaddstr(
          24, 0, "Press any key to watch the Congressional votes unfold.     ");
      await getKey();
    }

    bool yesWinHouse = false, yesWinSenate = false;
    int yesVotesHouse = 0, yesVotesSenate = 0, vote, s = 0;

    Stopwatch sw = Stopwatch()..start();
    for (int l = 0; l < house.length; l++) {
      vote = house[l].index;
      if (vote >= 1 && vote <= 3) vote += lcsRandom(3) - 1;

      if (level.index == vote) yesVotesHouse++;

      if (l == house.length - 1) {
        if (yesVotesHouse >= house.length * 3 / 4) {
          yesWinHouse = true;
        }
      }

      if (canSeeThings) {
        if (l == house.length - 1 && yesWinHouse) {
          setColor(level.color);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(2, 62, "$yesVotesHouse Yea");

        if (l == house.length - 1 && !yesWinHouse) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(3, 62, "${l + 1 - yesVotesHouse} Nay");
      }

      if (l % 4 == 0 && s < senate.length) {
        vote = senate[s++].index;
        if (vote >= 1 && vote <= 3) {
          if (politics.publicMood() < 15) {
            vote += lcsRandom(2) - 1;
          } else if (politics.publicMood() > 85) {
            vote += lcsRandom(2);
          } else {
            vote += lcsRandom(3) - 1;
          }
        }

        if (level.index == vote) yesVotesSenate++;
      }

      if (l == house.length - 1 && yesVotesSenate >= senate.length * 2 / 3) {
        yesWinSenate = true;
      }

      if (canSeeThings) {
        if (l == house.length - 1 && yesWinSenate) {
          setColor(level.color);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(2, 70, "$yesVotesSenate Yea");

        if (l == house.length - 1 && !yesWinSenate) {
          setColor(white);
        } else if (l == house.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(3, 70, "${s - yesVotesSenate} Nay");

        if (sw.elapsedMilliseconds < l * 10) {
          await pause(l * 10 - sw.elapsedMilliseconds);
        }
      }
    }

    if (!yesWinHouse || !yesWinSenate) ratified = false;
  } else {
    ratified = true;
  }

  //STATES
  if (ratified) {
    ratified = false;

    int yesstate = 0;

    if (canSeeThings) {
      setColor(white);

      for (int s = 0; s < 50; s++) {
        if (s < 17) {
          move(5 + s, 1);
        } else if (s < 34) {
          move(5 + s - 17, 28);
        } else {
          move(5 + s - 34, 55);
        }
        addstr(states[s].name);
      }

      mvaddstr(24, 0,
          "Press any key to watch the State votes unfold.              ");

      await getKey();
    }

    Color forColor = level.color;
    Color againstColor = darkGray;

    Stopwatch sw = Stopwatch()..start();
    for (int s = 0; s < states.length; s++) {
      double smood = states[s].rollMood(mood);

      int vote = 0;
      if (lcsRandom(100) < smood) vote++;
      if (lcsRandom(100) < smood) vote++;
      if (lcsRandom(100) < smood) vote++;
      if (lcsRandom(100) < smood) vote++;
      if (vote == 3 && oneIn(2)) vote = 4;
      if (vote == 1 && oneIn(2)) vote = 0;

      if (canSeeThings) {
        setColor(vote == level.index ? forColor : againstColor);
        if (s < 17) {
          move(5 + s, 20);
        } else if (s < 34) {
          move(5 + s - 17, 47);
        } else {
          move(5 + s - 34, 74);
        }
      }
      if (vote == level.index) {
        yesstate++;
        if (canSeeThings) addstr("Yea");
      } else if (canSeeThings) {
        addstr("Nay");
      }

      if (canSeeThings) {
        if (s == states.length - 1 && yesstate >= states.length * 2 / 3) {
          setColor(level.color);
        } else if (s == states.length - 1) {
          setColor(darkGray);
        } else {
          setColor(lightGray);
        }
        mvaddstr(23, 50, "$yesstate Yea");

        if (s == states.length - 1 && yesstate >= states.length * 2 / 3) {
          setColor(darkGray);
        } else if (s == states.length - 1) {
          setColor(white);
        } else {
          setColor(lightGray);
        }
        mvaddstr(23, 60, "${s + 1 - yesstate} Nay");

        if (sw.elapsedMilliseconds < s * 50) {
          await pause(s * 50 - sw.elapsedMilliseconds);
        }
      }
    }

    if (yesstate >= states.length * 2 / 3) ratified = true;
  }

  if (canSeeThings) {
    setColor(white);
    move(23, 0);
    if (ratified) {
      addstr("AMENDMENT ADOPTED.");
      politics.constitutionalAmendments++;
    } else {
      addstr("AMENDMENT REJECTED.");
    }
  }

  return ratified;
}

/* endgame - header for announcing constitutional amendments */
void amendmentHeading() {
  erase();

  mvaddstrc(0, 0, white,
      "Proposed Amendment ${romanNumeral(politics.constitutionalAmendments + 1)} to the United States Constitution:");
}
