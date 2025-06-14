import 'dart:ui';

import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/items/clothing.dart';
import 'package:lcs_new_age/politics/states.dart';
import 'package:lcs_new_age/sitemode/stealth.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

const emDash = "—";

bool clearScreenOnNextMessage = false;
Future<void> showMessage(String message,
    {Color color = lightGray, bool delimeter = true}) async {
  if (clearScreenOnNextMessage) {
    erase();
  } else if (delimeter) {
    makeDelimiter();
  }
  mvaddstrc(8, 1, color, message);
  await getKey();
}

void printFunds({
  int y = 0,
  int offsetFromRight = 1,
  String prefix = "Money: ",
  Color color = lightGray,
}) {
  String str = "$prefix \$${ledger.funds}";
  mvaddstrc(y, console.width - str.length - offsetFromRight, color, str);
}

void printSquadActivityDescription(int y, int x, Squad squad) {
  String str = squad.activity.description;
  setColor(squad.activity.color);
  if (squad.activity.type == ActivityType.none) {
    bool previousActivity = false, multipleActivities = false;
    Iterable<Activity> activities = squad.members.map((e) => e.activity);
    for (Activity activity in activities) {
      String desc = activity.description;
      setColor(activity.color);
      if (previousActivity && str != desc) multipleActivities = true;
      str = desc;
      previousActivity = true;
    }
    if (multipleActivities) {
      str = "Acting Individually";
      setColor(white);
    }
  }
  mvaddstr(y, x, str);
}

void makeDelimiter({int y = 8}) {
  mvaddstrc(y, 0, lightGray, "".padRight(console.width, emDash));
}

void addHeader(Map<int, String> items, {int y = 1}) {
  makeDelimiter(y: y);
  for (MapEntry entry in items.entries) {
    mvaddstr(y, entry.key, entry.value);
  }
}

void setColorForArmor(Creature creature) {
  Clothing armor = creature.clothing;
  Color fg = lightGray;
  Color bg = black;
  if (armor.bloody) {
    fg = white;
    bg = darkRed;
  }
  if (mode == GameMode.site) {
    switch (disguiseQuality(creature)) {
      case DisguiseQuality.inconspicuous:
        fg = lightGreen;
      case DisguiseQuality.authorityFigure:
        fg = blue;
      case DisguiseQuality.unusual:
        fg = yellow;
      case DisguiseQuality.disturbing:
        fg = orange;
      case DisguiseQuality.alarming:
      case DisguiseQuality.trespassing:
        fg = red;
      case DisguiseQuality.hidden:
        fg = darkGray;
    }
  } else if (armor.quality > armor.type.qualityLevels) {
    fg = red;
  } else if (armor.damaged) {
    fg = yellow;
  } else if (armor.quality > 1) {
    fg = orange;
  }
  setColor(fg, background: bg);
}

void printHealthStat(int y, int x, Creature creature, {bool small = false}) {
  move(y, x);
  bool bleeding = creature.body.parts.any((e) => e.bleeding > 0);

  setColor(lightGreen);
  if (creature.blood < creature.maxBlood) setColor(white);
  if (bleeding) setColor(red);
  if (!creature.alive) setColor(darkGray);

  if (small) {
    addstr("${creature.blood}");
  } else {
    addstr("${creature.blood}/${creature.maxBlood}");
  }
  addstrc(lightBlue, creature.clothing.shortArmorDetail());
}

String romanNumeral(int num) {
  String roman = "";
  while (num >= 1000) {
    roman += "M";
    num -= 1000;
  }
  if (num >= 900) {
    roman += "CM";
    num -= 900;
  } else if (num >= 500) {
    roman += "D";
    num -= 500;
  } else if (num >= 400) {
    roman += "CD";
    num -= 400;
  }
  while (num >= 100) {
    roman += "C";
    num -= 100;
  }
  if (num >= 90) {
    roman += "XC";
    num -= 90;
  } else if (num >= 50) {
    roman += "L";
    num -= 50;
  } else if (num >= 40) {
    roman += "XL";
    num -= 40;
  }
  while (num >= 10) {
    roman += "X";
    num -= 10;
  }
  if (num >= 9) {
    roman += "IX";
    num -= 9;
  } else if (num >= 5) {
    roman += "V";
    num -= 5;
  } else if (num >= 4) {
    roman += "IV";
    num -= 4;
  }
  while (num >= 1) {
    roman += "I";
    num -= 1;
  }
  return roman;
}

String randomStateName() => states.random.name;

String randomCityName() => [
      /* City population < 100,000 = listed once if the city is somehow important
        (i.e., biggest city in a U.S. state or territory, or most important city in a
        metropolitan area with over 200,000 people)
        100,000 < City population <   200,000 = listed once
        200,000 < City population <   400,000 = listed twice
        400,000 < City population <   600,000 = listed 3 times
        600,000 < City population < 1,000,000 = listed 4 times
      1,000,000 < City population < 5,000,000 = listed 5 times
      5,000,000 < City population = city listed 6 times and each of its 5 its boroughs listed 1-2 times
      Anyway, for states/territories without big cities their biggest city is listed once.  */
      "Abilene, TX", // dummy comment so it doesn't autoformat the list
      "Akron, OH",
      "Albany, NY",
      "Albuquerque, NM", "Albuquerque, NM", "Albuquerque, NM",
      "Alexandria, VA",
      "Allentown, PA",
      "Amarillo, TX",
      "Anaheim, CA", "Anaheim, CA", "Anaheim, CA",
      "Anchorage, AK", "Anchorage, AK", "Anchorage, AK",
      "Ann Arbor, MI",
      "Antioch, CA",
      "Appleton, WI",
      "Arlington, TX", "Arlington, TX", "Arlington, TX",
      "Arvada, CO",
      "Asheville, NC",
      "Atlantic City, NJ",
      "Athens, GA",
      "Atlanta, GA", "Atlanta, GA", "Atlanta, GA",
      "Augusta, GA",
      "Aurora, CO", "Aurora, CO", "Aurora, CO",
      "Aurora, IL",
      "Austin, TX", "Austin, TX", "Austin, TX", "Austin, TX",
      "Bakersfield, CA", "Bakersfield, CA", "Bakersfield, CA",
      "Baltimore, MD", "Baltimore, MD", "Baltimore, MD", "Baltimore, MD",
      "Barnstable, MA",
      "Baton Rouge, LA", "Baton Rouge, LA",
      "Bellevue, WA",
      "Bellingham, WA",
      "Beaumont, TX",
      "Berkeley, CA",
      "Billings, MT",
      "Biloxi, MS",
      "Binghamton, NY",
      "Birmingham, AL", "Birmingham, AL",
      "Boise, ID", "Boise, ID",
      "Boston, MA", "Boston, MA", "Boston, MA", "Boston, MA",
      "Boulder, CO",
      "Bremerton, WA",
      "Bridgeport, CT",
      "Broken Arrow, OK",
      "Brooklyn, NY", "Brooklyn, NY",
      "Brownsville, TX",
      "Buffalo, NY", "Buffalo, NY",
      "Burbank, CA",
      "Burlington, VT",
      "Cambridge, MA",
      "Canton, OH",
      "Cape Coral, FL",
      "Carlsbad, CA",
      "Carrollton, TX",
      "Cary, NC",
      "Cedar Rapids, IA",
      "Centennial, CO",
      "Champaign, IL",
      "Chandler, AZ", "Chandler, AZ",
      "Charleston, SC",
      "Charleston, WV",
      "Charlotte, NC", "Charlotte, NC", "Charlotte, NC", "Charlotte, NC",
      "Charlottesville, VA",
      "Chattanooga, TN",
      "Chesapeake, VA", "Chesapeake, VA",
      "Cheyenne, WY",
      "Chicago, IL", "Chicago, IL", "Chicago, IL", "Chicago, IL", "Chicago, IL",
      "Chico, CA",
      "Chula Vista, CA", "Chula Vista, CA",
      "Cincinnati, OH", "Cincinnati, OH",
      "Clarksville, TN",
      "Clearwater, FL",
      "Cleveland, OH", "Cleveland, OH", "Cleveland, OH",
      "College Station, TX",
      "Colorado Springs, CO", "Colorado Springs, CO", "Colorado Springs, CO",
      "Columbia, MO",
      "Columbia, SC",
      "Columbus, GA", "Columbus, GA",
      "Columbus, OH", "Columbus, OH", "Columbus, OH", "Columbus, OH",
      "Concord, CA",
      "Coral Springs, FL",
      "Corona, CA",
      "Corpus Christi, TX", "Corpus Christi, TX", "Corpus Christi, TX",
      "Costa Mesa, CA",
      "Crestview, FL",
      "Dallas, TX", "Dallas, TX", "Dallas, TX", "Dallas, TX", "Dallas, TX",
      "Daly City, CA",
      "Davenport, IA",
      "Dayton, OH",
      "Daytona Beach, FL",
      "Denton, TX",
      "Denver, CO", "Denver, CO", "Denver, CO", "Denver, CO",
      "Des Moines, IA", "Des Moines, IA",
      "Detroit, MI", "Detroit, MI", "Detroit, MI", "Detroit, MI",
      "Downey, CA",
      "Duluth, MN",
      "Durham, NC", "Durham, NC",
      "El Cajon, CA",
      "El Monte, CA",
      "El Paso, TX", "El Paso, TX", "El Paso, TX", "El Paso, TX",
      "Elgin, IL",
      "Elk Grove, CA",
      "Elkhart, IN",
      "Elizabeth, NJ",
      "Erie, PA",
      "Escondido, CA",
      "Eugene, OR",
      "Evansville, IN",
      "Everett, WA",
      "Fairfield, CA",
      "Fargo, ND",
      "Fayetteville, AR",
      "Fayetteville, NC", "Fayetteville, NC",
      "Flint, MI",
      "Florence, SC",
      "Fontana, CA", "Fontana, CA",
      "Fort Collins, CO",
      "Fort Lauderdale, FL",
      "Fort Smith, AR",
      "Fort Wayne, IN", "Fort Wayne, IN",
      "Fort Worth, TX", "Fort Worth, TX", "Fort Worth, TX", "Fort Worth, TX",
      "Fremont, CA", "Fremont, CA",
      "Fresno, CA", "Fresno, CA", "Fresno, CA",
      "Frisco, TX",
      "Fullerton, TX",
      "Gainesville, FL",
      "Garden Grove, CA",
      "Garland, TX", "Garland, TX",
      "Gilbert, AZ", "Gilbert, AZ",
      "Glendale, AZ", "Glendale, AZ",
      "Glendale, CA",
      "Grand Prairie, TX",
      "Grand Rapids, MI",
      "Greeley, CO",
      "Green Bay, WI",
      "Greensboro, NC", "Greensboro, NC",
      "Greenville, SC",
      "Gresham, OR",
      "Hagerstown, MD",
      "Hampton, VA",
      "Harrisburg, PA",
      "Hartford, CT",
      "Hayward, CA",
      "Hempstead, NY",
      "Henderson, NV", "Henderson, NV",
      "Hialeah, FL", "Hialeah, FL",
      "Hickory, NC",
      "High Point, NC",
      "Hollywood, CA",
      "Hollywood, FL",
      "Honolulu, HI", "Honolulu, HI", "Honolulu, HI",
      "Houma, LA",
      "Houston, TX", "Houston, TX", "Houston, TX", "Houston, TX", "Houston, TX",
      "Huntington, WV",
      "Huntington Beach, CA",
      "Huntsville, AL",
      "Independence, MO",
      "Indianapolis, IN", "Indianapolis, IN", "Indianapolis, IN",
      "Indianapolis, IN",
      "Inglewood, CA",
      "Irvine, CA", "Irvine, CA",
      "Irving, TX", "Irving, TX",
      "Jackson, MS",
      "Jacksonville, FL", "Jacksonville, FL", "Jacksonville, FL",
      "Jacksonville, FL",
      "Jersey City, NJ", "Jersey City, NJ",
      "Johnson City, TN",
      "Joliet, IL",
      "Kalamazoo, MI",
      "Kansas City, KS",
      "Kansas City, MO", "Kansas City, MO", "Kansas City, MO",
      "Kent, WA",
      "Killeen, TX",
      "Kingsport, TN",
      "Knoxville, TN",
      "Lafayette, IN",
      "Lafayette, LA",
      "Lake Charles, LA",
      "Lake Havasu City, AZ",
      "Lakeland, FL",
      "Lakewood, CO",
      "Lancaster, CA",
      "Lancaster, PA",
      "Lansing, MI",
      "Laredo, TX", "Laredo, TX",
      "Las Cruces, NM",
      "Las Vegas, NV", "Las Vegas, NV", "Las Vegas, NV", "Las Vegas, NV",
      "Lewisville, TX",
      "Lexington, KY", "Lexington, KY", "Lexington, KY",
      "Lincoln, NE", "Lincoln, NE",
      "Little Rock, AR",
      "Long Beach, CA", "Long Beach, CA", "Long Beach, CA",
      "Long Island, NY", "Long Island, NY", "Long Island, NY",
      "Long Island, NY",
      "Longview, TX",
      "Los Angeles, CA", "Los Angeles, CA", "Los Angeles, CA",
      "Los Angeles, CA", "Los Angeles, CA",
      "Louisville, KY", "Louisville, KY", "Louisville, KY", "Louisville, KY",
      "Lowell, MA",
      "Lubbock, TX", "Lubbock, TX",
      "Lynchburg, VA",
      "Macon, GA",
      "Madison, WI", "Madison, WI",
      "Manchester, NH",
      "Manhattan, NY", "Manhattan, NY",
      "McAllen, TX",
      "McKinney, TX",
      "Medford, OR",
      "Memphis, TN", "Memphis, TN", "Memphis, TN", "Memphis, TN",
      "Merced, CA",
      "Mesa, AZ", "Mesa, AZ", "Mesa, AZ",
      "Mesquite, TX",
      "Miami, FL", "Miami, FL", "Miami, FL",
      "Miami Gardens, FL",
      "Midland, TX",
      "Milwaukee, WI", "Milwaukee, WI", "Milwaukee, WI",
      "Minneapolis, MN", "Minneapolis, MN", "Minneapolis, MN",
      "Miramar, FL",
      "Mobile, AL",
      "Modesto, CA", "Modesto, CA",
      "Montgomery, AL", "Montgomery, AL",
      "Moreno Valley, CA", "Moreno Valley, CA",
      "Murfreesboro, TN",
      "Murrieta, CA",
      "Myrtle Beach, SC",
      "Naperville, IL",
      "Naples, FL",
      "Nashville, TN", "Nashville, TN", "Nashville, TN", "Nashville, TN",
      "New Haven, CT",
      "New London, CT",
      "New Orleans, LA", "New Orleans, LA", "New Orleans, LA",
      "New York, NY", "New York, NY", "New York, NY", "New York, NY",
      "New York, NY", "New York, NY",
      "Newark, NJ", "Newark, NJ",
      "Newport, RI",
      "Newport News, VA",
      "Norfolk, VA", "Norfolk, VA",
      "Norman, OK",
      "North Charleston, SC",
      "North Las Vegas, NV", "North Las Vegas, NV",
      "Norwalk, CA",
      "Oakland, CA", "Oakland, CA", "Oakland, CA",
      "Ocala, FL",
      "Oceanside, CA",
      "Odessa, TX",
      "Ogden, UT",
      "Oklahoma City, OK", "Oklahoma City, OK", "Oklahoma City, OK",
      "Oklahoma City, OK",
      "Olathe, KS",
      "Olympia, WA",
      "Omaha, NE", "Omaha, NE", "Omaha, NE",
      "Ontario, CA",
      "Orange, CA",
      "Orlando, FL", "Orlando, FL",
      "Overland Park, KS",
      "Oxnard, CA", "Oxnard, CA",
      "Palm Bay, FL",
      "Palmdale, CA",
      "Pasadena, CA",
      "Pasadena, TX",
      "Paterson, NJ",
      "Pearland, TX",
      "Pembroke Pines, FL",
      "Pensacola, FL",
      "Peoria, IL",
      "Peoria, AZ",
      "Philadelphia, PA", "Philadelphia, PA", "Philadelphia, PA",
      "Philadelphia, PA", "Philadelphia, PA",
      "Phoenix, AZ", "Phoenix, AZ", "Phoenix, AZ", "Phoenix, AZ", "Phoenix, AZ",
      "Pittsburgh, PA", "Pittsburgh, PA", "Pittsburgh, PA",
      "Plano, TX", "Plano, TX",
      "Pomona, CA",
      "Pompano Beach, FL",
      "Port St. Lucie, FL",
      "Portland, ME",
      "Portland, OR", "Portland, OR", "Portland, OR", "Portland, OR",
      "Poughkeepsie, NY",
      "Prescott, AZ",
      "Providence, RI",
      "Provo, UT",
      "Pueblo, CO",
      "Queens, NY", "Queens, NY",
      "Raleigh, NC", "Raleigh, NC", "Raleigh, NC",
      "Rancho Cucamonga, CA",
      "Reading, PA",
      "Reno, NV", "Reno, NV",
      "Rialto, CA",
      "Richardson, TX",
      "Richland, WA",
      "Richmond, CA",
      "Richmond, VA", "Richmond, VA",
      "Riverside, CA", "Riverside, CA", "Riverside, CA",
      "Roanoke, VA",
      "Rochester, MN",
      "Rochester, NY", "Rochester, NY",
      "Rockford, IL",
      "Roseville, CA",
      "Round Rock, TX",
      "Sacramento, CA", "Sacramento, CA", "Sacramento, CA",
      "Salem, OR",
      "Salinas, CA",
      "Salisbury, MD",
      "Salt Lake City, UT",
      "San Antonio, TX", "San Antonio, TX", "San Antonio, TX",
      "San Antonio, TX", "San Antonio, TX",
      "San Bernadino, CA", "San Bernadino, CA",
      "San Diego, CA", "San Diego, CA", "San Diego, CA", "San Diego, CA",
      "San Diego, CA",
      "San Francisco, CA", "San Francisco, CA", "San Francisco, CA",
      "San Francisco, CA",
      "San Jose, CA", "San Jose, CA", "San Jose, CA", "San Jose, CA",
      "San Luis Obispo, CA",
      "San Mateo, CA",
      "Santa Ana, CA", "Santa Ana, CA", "Santa Ana, CA",
      "Santa Clara, CA",
      "Santa Clarita, CA",
      "Santa Cruz, CA",
      "Santa Maria, CA",
      "Santa Rosa, CA",
      "Sarasota, FL",
      "Savannah, GA",
      "Scottsdale, AZ", "Scottsdale, AZ",
      "Scranton, PA",
      "Seattle, WA", "Seattle, WA", "Seattle, WA", "Seattle, WA",
      "Shreveport, LA", "Shreveport, LA",
      "Sioux Falls, SD",
      "Simi Valley, CA",
      "South Bend, IN",
      "Spartanburg, SC",
      "Spokane, WA", "Spokane, WA",
      "Springfield, IL",
      "Springfield, MA",
      "Springfield, MO",
      "St. Louis, MO", "St. Louis, MO", "St. Louis, MO",
      "St. Paul, MN", "St. Paul, MN",
      "St. Petersburg, FL", "St. Petersburg, FL",
      "Stamford, CT",
      "Staten Island, NY",
      "Sterling Heights, MI",
      "Stockton, CA", "Stockton, CA",
      "Sunnyvale, CA",
      "Surprise, AZ",
      "Syracuse, NY",
      "Tacoma, WA", "Tacoma, WA",
      "Tallahassee, FL",
      "Tampa, FL", "Tampa, FL", "Tampa, FL",
      "Temecula, CA",
      "Tempe, AZ",
      "The Bronx, NY", "The Bronx, NY",
      "Thornton, CO",
      "Thousand Oaks, CA",
      "Toledo, OH", "Toledo, OH",
      "Topeka, KS",
      "Torrance, CA",
      "Trenton, NJ",
      "Tuscaloosa, AL",
      "Tucson, AZ", "Tucson, AZ", "Tucson, AZ",
      "Tulsa, OK", "Tulsa, OK", "Tulsa, OK",
      "Tyler, TX",
      "Utica, NY",
      "Vallejo, CA",
      "Vancouver, WA",
      "Ventura, CA",
      "Victorville, CA",
      "Virginia Beach, VA", "Virginia Beach, VA", "Virginia Beach, VA",
      "Visalia, CA",
      "Waco, TX",
      "Warren, MI",
      "Washington, DC", "Washington, DC", "Washington, DC", "Washington, DC",
      "Waterbury, CT",
      "West Covina, CA",
      "West Jordan, UT",
      "West Palm Beach, FL",
      "West Valley City, UT",
      "Westminster, CO",
      "White Plains, NY",
      "Wichita, KS", "Wichita, KS", "Wichita, KS",
      "Wichita Falls, TX",
      "Wilmington, DE",
      "Wilmington, NC",
      "Winston-Salem, NC", "Winston-Salem, NC",
      "Worcester, MA",
      "Yakima, WA",
      "Yonkers, NY",
      "York, PA",
      "Youngstown, OH",
      "Yuma, AZ"
    ].random;

String letterAPlus(int index, {bool capitalize = true}) {
  if (capitalize) {
    return String.fromCharCode('A'.codeUnitAt(0) + index);
  } else {
    return String.fromCharCode('a'.codeUnitAt(0) + index);
  }
}

void addDifficultyText(int y, int x, int difficulty) {
  if (difficulty < 0) difficulty = 0;
  var (Color color, String text) = switch (difficulty) {
    0 => (lightGreen, "Trivial"),
    1 => (lightBlue, "Very Easy"),
    2 => (blue, "Easy"),
    3 => (blue, "Below Average"),
    4 => (lightGray, "Average"),
    5 => (lightGray, "Above Average"),
    6 => (yellow, "Hard"),
    7 => (yellow, "Very Hard"),
    8 => (orange, "Extremely Difficult"),
    9 => (red, "Almost Impossible"),
    _ => (darkRed, "Impossible"),
  };
  mvaddstrc(y, x, color, text);
}

Future<void> pagedInterface({
  String headerPrompt = "",
  Map<int, String> headerKey = const {},
  String footerPrompt = "",
  int pageSize = 20,
  int linesPerOption = 1,
  int topY = 0,
  bool showBackButton = true,
  String? backButtonText,
  required int count,
  required void Function(int y, String key, int index) lineBuilder,
  required Future<bool> Function(int index) onChoice,
  bool Function(int key)? onOtherKey,
}) async {
  int page = 0;
  int pageCount = (count / pageSize).ceil();
  while (true) {
    eraseArea(startY: topY, startX: 0, endY: pageSize + 3 + topY, endX: 80);
    mvaddstrc(topY, 0, white, headerPrompt);
    addHeader(headerKey, y: topY + 1);
    setColor(lightGray);
    mvaddstrx(pageSize + 2 + topY, 0, footerPrompt);
    for (int i = 0; i + page * pageSize < count && i < pageSize; i++) {
      lineBuilder(
          i + 2 + topY, letterAPlus(i ~/ linesPerOption), i + page * pageSize);
    }
    setColor(lightGray);
    eraseLine(pageSize + 3 + topY);
    if (pageCount > 1) {
      addPageButtons(
          y: pageSize + 3 + topY, x: 0, current: page + 1, max: pageCount);
      if (showBackButton) {
        addBackButton(y: pageSize + 3 + topY, x: 40);
      }
    } else {
      if (showBackButton) {
        addBackButton(y: pageSize + 3 + topY, x: 0, text: backButtonText);
      }
    }

    int c = await getKey();
    if (isPageUp(c) && page > 0) page--;
    if (isPageDown(c) && (page + 1) * pageSize < count) page++;
    if (c >= Key.a && c < Key.a + pageSize) {
      int index = page * pageSize ~/ linesPerOption + c - Key.a;
      if (index < count) {
        if (await onChoice(index)) {
          return;
        } else {
          continue;
        }
      }
    }
    if (onOtherKey != null && onOtherKey(c)) return;
    if (isBackKey(c)) return;
  }
}

String capitalize(String str) => str[0].toUpperCase() + str.substring(1);

Future<void> defeatMessages(String bright, String medium, String dark) async {
  erase();
  mvaddstrc(12, 10, white, bright);
  await getKey();

  erase();
  mvaddstrc(12, 12, lightGray, medium);
  await getKey();

  erase();
  mvaddstrc(12, 14, darkGray, dark);
  await getKey();
}
