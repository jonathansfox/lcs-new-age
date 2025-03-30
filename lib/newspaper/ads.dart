import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

void displaysinglead(bool liberalguardian, List<(int, int)> addplace,
    List<int> storyXStart, List<int> storyXEnd) {
  int x, y;
  (x, y) = addplace.random;
  addplace.remove((x, y));

  int sx = 0, ex = 0, sy = 0, ey = 0;
  if (x == 0) {
    sx = 0;
    ex = 23 + lcsRandom(4);
  }
  if (x == 1) {
    sx = 57 - lcsRandom(4);
    ex = 79;
  }
  if (y == 0) {
    sy = 2;
    ey = 9;
  }
  if (y == 1) {
    sy = 10;
    ey = 17;
  }
  if (y == 2) {
    sy = 18;
    ey = 24;
  }
  int choice = x + y * 2;

  String ch = '?';
  switch (lcsRandom(6)) {
    case 0:
      ch = "\u2591";
    case 1:
      ch = "\u2592"; //CH_MEDIUM_SHADE;
    case 2:
      ch = "\u2593"; //CH_DARK_SHADE;
    case 3:
      ch = "\u2588"; //CH_FULL_BLOCK;
    case 4:
      ch = "\u253C"; //CH_BOX_DRAWINGS_LIGHT_VERTICAL_AND_HORIZONTAL;
    case 5:
      ch = '*';
  }

  for (y = sy; y <= ey; y++) {
    if (storyXStart[y] < ex && ex < 43) storyXStart[y] = ex + 2;
    if (storyXEnd[y] > sx && sx > 43) storyXEnd[y] = sx - 2;

    if (ey == 9 && y == 9) continue;
    if (ey == 17 && y == 17) continue;
    for (x = sx; x <= ex; x++) {
      if (y == sy || y == 8 || y == 16 || y == 24 || x == sx || x == ex) {
        mvaddchar(y, x, ch);
      }
    }
  }

  //AD CONTENT
  {
    List<int> storyXStart = List.filled(25, 40);
    List<int> storyXEnd = List.filled(25, 40);
    for (int i = sy + 1; i <= ey - 1; i++) {
      storyXStart[i] = sx + 1;
      storyXEnd[i] = ex - 1;
    }

    String ad;
    if (!liberalguardian) {
      // Regular Newspaper Ads
      switch (choice) {
        case 0:
          ad = "&cNo Fee&r";
          ad += "&cConsignment Program&r&r";
          ad += "&cCall for Details&r";
        case 1:
          ad = "&cFine Leather Chairs&r&r";
          ad += "&cSpecial Purchase&r";
          ad += "&cNow \$${lcsRandom(201 + 400)}";
          ad += "&r";
        case 2:
          ad = "&cParis Flea Market&r&r";
          ad += "&cSale&r";
          ad += "&c50% Off&r";
        case 3:
          ad = "&cQuality Pre-Owned&r";
          ad += "&cVehicles&r";
          ad += "&c${year - lcsRandom(15)} Lexus GS 300&r";
          ad += "&cSedan 4D&r";
          ad += "&cOnly \$${lcsRandom(16 + 15)}";
          ad += "&r";
        case 4:
          ad = "&cSpa&r";
          ad += "&cHealth, Beauty&r";
          ad += "&cand Fitness&r&r";
          ad += "&c7 Days a Week&r";
        case 5:
          ad = "&c";
          switch (lcsRandom(5)) {
            // less explicit personals in regular newspaper than Liberal Guardian
            case 0:
              ad += "Searching For Love";
            case 1:
              ad += "Seeking Love";
            case 2:
              ad += "Are You Lonely?";
            case 3:
              ad += "Looking For Love";
            case 4:
              ad += "Soulmate Wanted";
          }
          ad += "&r&r";
          ad += "&c${sexdesc()} ${sexwho()} ${sexseek()}&r";
          ad += "&c${sextype()} w/ ${sexwho()}&r";
        default:
          ad = "&cDebuggers Needed&r&r";
          ad += "&cIt Seems&r";
          ad += "&cYou've Found&r";
          ad += "&cA Bug!&r";
      }
    } else {
      // Liberal Guardian Ads
      switch (choice) // should be 6 choices from 1 to 6
      {
        case 0:
          ad = "&cWant Organic?&r&r";
          ad += "&cVisit The Vegan&r";
          ad += "&cCo-Op&r";
        case 1:
          ad = "&cLiberal Defense Lawyer&r";
          ad += "&c";
          ad += "${lcsRandom(11 + 20)}";
          ad += " Years Experience&r&r";
          ad += "&cCall Today&r";
        case 2:
          ad = "&cAbortion Clinic&r&r";
          ad += "&cWalk-in, No&r";
          ad += "&cQuestions Asked&r";
          ad += "&cOpen 24/7&r";
        case 3:
          ad = "&cMarijuana Dispensary&r&r";
          ad += "&cNo ID Or Prescription Needed!&r";
          ad += "&cPlease Pay In Cash.&r";
        case 4:
          ad = "&cGot Slack?&r&r";
          ad += "&cVisit Your Local&r";
          ad += "&cSubGenius Clench&r";
          ad += "&cFor More Info&r";
        case 5:
          ad = "&c";
          switch (lcsRandom(5)) {
            // more explicit personals in Liberal Guardian than regular newspaper
            case 0:
              ad += "Searching For Sex";
            case 1:
              ad += "Seeking Sex";
            case 2:
              ad += "Wanna Have Sex?";
            case 3:
              ad += "Looking For Sex";
            case 4:
              ad += "Sex Partner Wanted";
          }
          ad += "&r&r";
          ad += "&c${sexdesc()} ${sexwho()} ${sexseek()}&r";
          ad += "&c${sextype()} w/ ${sexwho()}&r";
        default:
          ad = "&cDebuggers Needed&r&r";
          ad += "&cIt Seems&r";
          ad += "&cYou've Found&r";
          ad += "&cA Bug!&r";
      }
    }

    displayNewsStory(ad, storyXStart, storyXEnd, sy + 1);
  }
}

void displayAds(NewsStory ns, bool liberalguardian, List<int> storyXStart,
    List<int> storyXEnd) {
  int adnumber = 0;
  if (!liberalguardian) {
    if (ns.page >= 10) adnumber++;
    if (ns.page >= 20) adnumber += lcsRandom(2) + 1;
    if (ns.page >= 30) adnumber += lcsRandom(2) + 1;
    if (ns.page >= 40) adnumber += lcsRandom(2) + 1;
    if (ns.page >= 50) adnumber += lcsRandom(2) + 1;
  } else {
    if (ns.guardianpage >= 2) adnumber++;
    if (ns.guardianpage >= 3) adnumber += lcsRandom(2) + 1;
    if (ns.guardianpage >= 4) adnumber += lcsRandom(2) + 1;
    if (ns.guardianpage >= 5) adnumber += lcsRandom(2) + 1;
    if (ns.guardianpage >= 6) adnumber += lcsRandom(2) + 1;
  }
  List<(int, int)> addplace = [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)];
  for (adnumber = (adnumber > 6 ? 6 : adnumber); adnumber > 0; adnumber--) {
    displaysinglead(liberalguardian, addplace, storyXStart, storyXEnd);
  }
}

/* pick a descriptor acronym */
String sexdesc() => ["DTE", "ND", "NS", "VGL"].random;

/* what kind of person? */
String sexwho() => [
      "BB", "BBC", "BF", "BHM", "BiF", "BiM", //
      "BBW", "BMW", "CD", "DWF", "DWM", "FTM", "GAM", "GBM",
      "GF", "GG", "GHM", "GWC", "GWF", "GWM", "MBC", "MBiC",
      "MHC", "MTF", "MWC", "SBF", "SBM", "SBiF", "SBiM",
      "SSBBW", "SWF", "SWM", "TG", "TS", "TV"
    ].random;

/* seeking acronym */
String sexseek() => ["ISO", "LF"].random;

/* what type of sex? */
String sextype() => [
      "225", "ATM", "BDSM", "CBT", "BJ", "DP", "D/s", "GB", //
      "HJ", "OTK", "PNP", "TT", "SWS", "W/S"
    ].random;
