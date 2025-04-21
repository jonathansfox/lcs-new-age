import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

void preparePage(NewsStory ns, bool liberalguardian) {
  setColor(lightGray, background: lightGray);
  for (int x = 0; x < 80; x++) {
    for (int y = 0; y < 25; y++) {
      mvaddchar(y, x, ' ');
    }
  }
  setColor(lightGray);

  List<String> publicationNames = [
    "The Times",
    "The Herald",
    "The Post",
    "The Globe",
    "The Daily"
  ];

  if (ns.page == 1 || (liberalguardian && ns.guardianpage == 1)) {
    // TOP
    int pap = lcsRandom(5);
    for (int x = 0; x < 80; x++) {
      for (int y = 0; y < 5; y++) {
        move(y, x);
        if (liberalguardian) {
          ns.publicationName = "Liberal Guardian";
          ns.publicationAlignment = DeepAlignment.eliteLiberal;
          drawCPCGlyph(newstops[5][x][y]);
        } else {
          ns.publicationName = publicationNames[pap];
          ns.publicationAlignment = DeepAlignment.moderate;
          drawCPCGlyph(newstops[pap][x][y]);
        }
      }
    }

    if (!liberalguardian) // Liberal Guardian graphics don't support adding a date
    {
      // DATE
      setColor(black, background: lightGray);
      mvaddstr(3, 66 + (day < 10 ? 1 : 0), getMonthShort(month));
      addstr(" $day, $year");
    }
  } else {
    if (liberalguardian) {
      ns.publicationName = "Liberal Guardian";
      ns.publicationAlignment = DeepAlignment.eliteLiberal;
    } else {
      ns.publicationName = publicationNames.random;
      ns.publicationAlignment = DeepAlignment.moderate;
    }
    // PAGE
    setColor(black, background: lightGray);
    move(0, 76);
    if (!liberalguardian) {
      addstr(ns.page.toString());
    } else {
      addstr(ns.guardianpage.toString());
    }
  }
}
