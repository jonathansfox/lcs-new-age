import 'dart:ui';

import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/time.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

void preparePage(NewsStory ns, bool liberalguardian) {
  Publication publication = ns.publication;
  Color bgColor = publication.backgroundColor;
  setColor(lightGray, background: bgColor);
  for (int x = 0; x < 80; x++) {
    for (int y = 0; y < 25; y++) {
      mvaddchar(y, x, ' ');
    }
  }
  setColor(lightGray);

  if (ns.page == 1 || (liberalguardian && ns.guardianpage == 1)) {
    // TOP
    switch (publication) {
      case Publication.cableNews:
        cableNewsTop();
      case Publication.amRadio:
        amRadioTop();
      case Publication.times:
        theTimesTop();
      case Publication.herald:
        theHeraldTop();
      case Publication.post:
        thePostTop();
      case Publication.globe:
        theGlobeTop();
      case Publication.daily:
        theDailyTop();
      case Publication.liberalGuardian:
        liberalGuardianTop();
      case Publication.conservativeStar:
        conservativeStarTop();
    }

    // DATE
    setColor(black, background: bgColor);
    mvaddstr(0, 66 + (day < 10 ? 1 : 0), getMonthShort(month));
    addstr(" $day, $year");
  } else {
    // PAGE
    setColor(black, background: bgColor);
    move(0, 76);
    if (!liberalguardian) {
      addstr(ns.page.toString());
    } else {
      addstr(ns.guardianpage.toString());
    }
  }
}

void conservativeStarTop() {
  Color bgColor = Publication.conservativeStar.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "SAVING AMERICA ONE BULLET AT A TIME");
  setColor(darkRed, background: bgColor);
  print3x3NewsText(1, 1, "Conservative Star");
  setColor(black, background: bgColor);
  mvaddstr(1, 68, "DEO VINDICE");
  mvaddstr(2, 68, "WE KNOW OUR");
  setColor(white, background: darkRed);
  mvaddstr(3, 68, "  ENEMIES  ");
  setColor(black, background: bgColor);
  _addDivider(Publication.conservativeStar);
}

void cableNewsTop() {
  Color bgColor = Publication.cableNews.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 1, " USA NEWS ");
  addstrc(black, bg: bgColor, "  POLITICS   OPINION   SPORTS   MONEY   MORE");
  print3x3NewsText(1, 1, "Balanced");
  setColor(darkRed, background: bgColor);
  print3x3NewsText(1, 35, "Cable News");
  setColor(white, background: UnitedStatesFlag.red);
  mvaddstr(1, 73, " ZERO ");
  setColor(black, background: UnitedStatesFlag.white);
  mvaddstr(2, 73, " BIAS ");
  setColor(white, background: UnitedStatesFlag.blue);
  mvaddstr(3, 73, " ZONE ");
  _addDivider(Publication.cableNews);
}

void amRadioTop() {
  Color bgColor = Publication.amRadio.backgroundColor;
  mvaddstrc(0, 1, black, bg: bgColor, " LATEST NEWS ");
  addstrc(UnitedStatesFlag.blue, bg: bgColor, "  TUNE IN NOW   SHOP   ABOUT");
  setColor(black, background: bgColor);
  print3x3NewsText(1, 1, "THE ");
  setColor(darkRed, background: bgColor);
  print3x3NewsText(1, 15, "AM RADIO");
  setColor(black, background: bgColor);
  print3x3NewsText(1, 47, "NETWORK");
  _addDivider(Publication.amRadio);
}

void liberalGuardianTop() {
  Color bgColor = Publication.liberalGuardian.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, slogan.toUpperCase());
  setColor(green, background: bgColor);
  print3x3NewsText(1, 1, "Liberal Guardian");
  setColor(black, background: bgColor);
  mvaddstr(1, 70, "THE TRUTH");
  mvaddstr(2, 70, "IS ALWAYS");
  mvaddstr(3, 75, "FREE");
  _addDivider(Publication.liberalGuardian);
}

void thePostTop() {
  Color bgColor = Publication.post.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "U.S.   POLITICS   BUSINESS   WORLD   FOOD   LIFESTYLE");
  print3x5NewsText(1, 1, "The Post");
  mvaddstr(1, 63, "PLEASE SUPPORT");
  mvaddstr(2, 61, "OUR PULITZER PRIZE");
  mvaddstr(3, 61, "WINNING JOURNALISM");
  _addDivider(Publication.post);
}

void theHeraldTop() {
  Color bgColor = Publication.herald.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "U.S.   POLITICS   BUSINESS   WORLD   FOOD   LIFESTYLE");
  print3x5NewsText(1, 1, "The Herald");
  mvaddstr(1, 64, "SUBSCRIBE \$3/WK");
  mvaddstr(2, 64, "FOR FULL ACCESS");
  mvaddstr(3, 64, "DIGITAL EDITION");
  _addDivider(Publication.herald);
}

void theTimesTop() {
  Color bgColor = Publication.times.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "U.S.   WORLD   BUSINESS   ARTS   LIFESTYLE   OPINION");
  print3x5NewsText(1, 1, "The Times");
  _addStocks();
  _addDivider(Publication.times);
}

void theGlobeTop() {
  Color bgColor = Publication.globe.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "U.S.   WORLD   BUSINESS   ARTS   LIFESTYLE   OPINION");
  print3x5NewsText(1, 1, "The Globe");
  _addStocks();
  _addDivider(Publication.globe);
}

void theDailyTop() {
  Color bgColor = Publication.daily.backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(0, 2, "U.S.   WORLD   BUSINESS   ARTS   LIFESTYLE   OPINION");
  print3x5NewsText(1, 1, "The Daily");
  mvaddstr(1, 65, "FOR JUST \$1/WK");
  mvaddstr(2, 67, "SUBSCRIBE TO");
  mvaddstr(3, 61, "AMERICA'S NEWSROOM");
  _addDivider(Publication.daily);
}

void _addStocks() {
  Color bgColor = Publication.times.backgroundColor;
  _addStockTicker(1, 67, "S&P", bgColor);
  _addStockTicker(2, 67, "DOW", bgColor);
  _addStockTicker(3, 67, "NASDAQ", bgColor);
}

void _addStockTicker(int y, int x, String name, Color bgColor) {
  setColor(black, background: bgColor);
  mvaddstr(y, x, name);
  double performance = lcsRandomDouble(4) - 2;
  if (performance > 0) {
    mvaddstrc(
        y, x + 7, green, bg: bgColor, "+${performance.toStringAsFixed(1)}%");
  } else {
    mvaddstrc(y, x + 7, red, bg: bgColor, "${performance.toStringAsFixed(1)}%");
  }
}

void _addDivider([Publication? publication]) {
  Color bgColor = (publication ?? Publication.times).backgroundColor;
  setColor(black, background: bgColor);
  mvaddstr(4, 0, "━" * 80);
}
