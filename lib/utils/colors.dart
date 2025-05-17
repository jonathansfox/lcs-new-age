import 'package:flutter/material.dart';

const Color black = Color(0xFF111111);
const Color darkGray = Color(0xFF555555);
const Color midGray = Color(0xFF999999);
const Color lightGray = Color(0xFFC0C0C0);
const Color white = Color(0xFFFFFFFF);
const Color brown = Color(0xFF613915); // not used
const Color darkRed = Color(0xFF661008);
const Color red = Color(0xFFFF1B13);
const Color orange = Color(0xFFFFA000);
const Color yellow = Color(0xFFEEFF00);
const Color halfYellow = Color(0xFF808000); // only used in movies
const Color green = Color(0xFF028121);
const Color lightGreen = Color(0xFF02FF21);
const Color darkBlue = Color(0xFF0000FF);
const Color blue = Color(0xFF16B8FF);
const Color lightBlue = Color(0xFF73D7EE);
const Color purple = Color(0xFFDD37E6);
const Color pink = Color(0xFFFA98FF); // not used

const Color transparent = Color(0x00000000);

const Color amRadioBackground = Color(0xFFE8DACC);
const Color cableNewsBackground = Color(0xFFf7e0e9);
const Color liberalGuardianBackground = Color(0xFFe0f7e0);
const Color conservativeCrusaderBackground = Color(0xFFf7e0e0);

// Reversed colorMap
class ColorKey {
  static const String green = 'g';
  static const String lightGreen = 'G';
  static const String darkBlue = 'b';
  static const String blue = 'B';
  static const String lightBlue = 'C';
  static const String darkCyan = 'c';
  static const String cyan = 'C';
  static const String darkRed = 'r';
  static const String red = 'R';
  static const String brown = 'o';
  static const String orange = 'O';
  static const String halfYellow = 'y';
  static const String yellow = 'Y';
  static const String darkMagenta = 'p';
  static const String magenta = 'p';
  static const String purple = 'p';
  static const String pink = 'P';
  static const String black = 'k';
  static const String darkGray = 'K';
  static const String midGray = 'm';
  static const String lightGray = 'w';
  static const String white = 'W';
  static const String transparent = 'x';

  static String fromColor(Color color) {
    // Create a reverse mapping from color to key
    final reverseMap = colorMap.map((key, value) => MapEntry(value, key));
    return reverseMap[color] ?? 'p';
  }
}

const colorMap = {
  ColorKey.green: green,
  ColorKey.lightGreen: lightGreen,
  ColorKey.darkBlue: darkBlue,
  ColorKey.blue: blue,
  ColorKey.darkCyan: blue,
  ColorKey.cyan: lightBlue,
  ColorKey.darkRed: darkRed,
  ColorKey.red: red,
  ColorKey.brown: brown,
  ColorKey.orange: orange,
  ColorKey.halfYellow: halfYellow,
  ColorKey.yellow: yellow,
  ColorKey.purple: purple,
  ColorKey.pink: pink,
  ColorKey.black: black,
  ColorKey.darkGray: darkGray,
  ColorKey.midGray: midGray,
  ColorKey.lightGray: lightGray,
  ColorKey.white: white,
  ColorKey.transparent: transparent,
};

class Skin {
  static const Color a = Color(0xFF3f2c28);
  static const Color b = Color(0xFF905336); // used in movies
  static const Color c = Color(0xFFbb7752);
  static const Color d = Color(0xFFb68564);
  static const Color e = Color(0xFFdbb094);
  static const Color f = Color(0xFFf6b4a4); // used in movies
  static const Color g = Color(0xFFe7c3b7);
}

class RainbowFlag {
  static const Color red = Color(0xFFE50000);
  static const Color orange = Color(0xFFFF8D00);
  static const Color yellow = Color(0xFFFFEE00);
  static const Color green = Color(0xFF028121);
  static const Color blue = Color(0xFF004CFF);
  static const Color purple = Color(0xFF770088);

  // Progress variation
  static const Color white = Color(0xFFFFFFFF);
  static const Color pink = Color(0xFFFFAFC7);
  static const Color lightBlue = Color(0xFF73D7EE);
  static const Color brown = Color(0xFF613915);
  static const Color black = Color(0xFF000000);
}

class TransgenderFlag {
  static const Color blue = Color(0xFF5BCFFB);
  static const Color pink = Color(0xFFF5ABB9);
  static const Color white = Color(0xFFFFFFFF);
}

class BisexualFlag {
  static const Color pink = Color(0xFFD60270);
  static const Color plum = Color(0xFF9B4F96);
  static const Color blue = Color(0xFF0038A8);
}

class PansexualFlag {
  static const Color pink = Color(0xFFFF1C8D);
  static const Color yellow = Color(0xFFFFD700);
  static const Color blue = Color(0xFF1AB3FF);
}

class GenderNonbinaryFlag {
  static const Color yellow = Color(0xFFFCF431);
  static const Color white = Color(0xFFFCFCFC);
  static const Color purple = Color(0xFF9D59D2);
  static const Color black = Color(0xFF282828);
}

class LesbianFlag {
  static const Color darkOrange = Color(0xFFD62800);
  static const Color lightOrange = Color(0xFFFF9B56);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightPink = Color(0xFFD462A6);
  static const Color darkPink = Color(0xFFA40062);
}

class AgenderFlag {
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFBABABA);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFFBAF484);
}

class AsexualFlag {
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFA4A4A4);
  static const Color white = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF810081);
}

class DemisexualFlag {
  static const Color black = Color(0xFF000000);
  static const Color gray = Color(0xFFD3D3D3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFF6E0071);
}

class GenderqueerFlag {
  static const Color purple = Color(0xFFB57FDD);
  static const Color white = Color(0xFFFFFFFF);
  static const Color green = Color(0xFF49821E);
}

class GenderfluidFlag {
  static const Color pink = Color(0xFFFE76A2);
  static const Color white = Color(0xFFFFFFFF);
  static const Color purple = Color(0xFFBF12D7);
  static const Color black = Color(0xFF000000);
  static const Color blue = Color(0xFF303CBE);
}

class IntersexFlag {
  static const Color purple = Color(0xFF7902AA);
  static const Color yellow = Color(0xFFFFD800);
}

class AromanticFlag {
  static const Color darkGreen = Color(0xFF3BA740);
  static const Color lightGreen = Color(0xFFA8D47A);
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray = Color(0xFFABABAB);
  static const Color black = Color(0xFF000000);
}

class UnitedStatesFlag {
  static const Color red = Color(0xFFB31942);
  static const Color white = Color(0xFFFFFFFF);
  static const Color blue = Color(0xFF0A3161);
}
