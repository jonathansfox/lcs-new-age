import 'package:flutter/material.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/console.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

Future<int> getKey() async => (await console.getkey()).codePoint;
Future<String> getKeyCaseSensitive() async => console.getkey();
String checkKey() => console.checkkey().toLowerCase();
String checkKeyCaseSensitive() => console.checkkey();
void setColor(Color foreground, {Color background = black}) =>
    console.setColor(foreground, background);
void addchar(String c) => console.addchar(c);
void mvaddchar(int y, int x, String c) => console.mvaddchar(y, x, c);

void addstr(String s) => console.addstr(s);
void addstrc(Color fg, String s) {
  setColor(fg);
  addstr(s);
}

void addparagraph(int y1, int x1, int y2, int x2, String s) {
  console.move(y1, x1);
  List<String> lines = s.split("\n");
  for (int i = 0; i < lines.length; i++) {
    List<String> words = lines[i].split(" ");
    for (int j = 0; j < words.length; j++) {
      if (console.x + words[j].length + 1 > x2) {
        console.move(console.y + 1, x1);
        if (console.y > y2) return;
        if (words[j].isEmpty) continue;
      } else if (j != 0) {
        addstr(" ");
      }
      addstr(words[j]);
    }
    move(console.y + 1, x1);
    if (console.y > y2) return;
  }
}

void addInlineOptionText(
  String key,
  String text, {
  bool enabledWhen = true,
  String baseColorKey = "w",
  String highlightColorKey = "B",
  String disabledColorKey = "K",
}) {
  key = key.toUpperCase();
  String beforeKey = "";
  String afterKey = "";
  int keyIndex = text.toUpperCase().indexOf(key);
  if (keyIndex == -1) {
    key = text[0];
    keyIndex = 0;
  }
  key = text.substring(keyIndex, keyIndex + key.length);
  beforeKey = text.substring(0, keyIndex);
  afterKey = text.substring(keyIndex + key.length);
  if (enabledWhen) {
    addstrx(
        "&$baseColorKey$beforeKey&$highlightColorKey$key&$baseColorKey$afterKey");
  } else {
    addstrx("&$disabledColorKey$text");
  }
}

void addOptionText(
  int y,
  int x,
  String key,
  String text, {
  bool enabledWhen = true,
  String baseColorKey = "w",
  String highlightColorKey = "B",
  String disabledColorKey = "K",
}) {
  move(y, x);
  addInlineOptionText(key, text,
      enabledWhen: enabledWhen,
      baseColorKey: baseColorKey,
      highlightColorKey: highlightColorKey,
      disabledColorKey: disabledColorKey);
}

void addCenteredOptionText(
  int y,
  String key,
  String text, {
  bool enabledWhen = true,
  String baseColorKey = "w",
  String highlightColorKey = "B",
  String disabledColorKey = "K",
}) {
  int x = centerString(text);
  move(y, x);
  addInlineOptionText(key, text,
      enabledWhen: enabledWhen,
      baseColorKey: baseColorKey,
      highlightColorKey: highlightColorKey,
      disabledColorKey: disabledColorKey);
}

void mvaddstr(int y, int x, String s) => console.mvaddstr(y, x, s);
void mvaddstrc(int y, int x, Color fg, String s) {
  setColor(fg);
  mvaddstr(y, x, s);
}

void addstrx(String s) => console.addstrx(s);
void mvaddstrx(int y, int x, String s) => console.mvaddstrx(y, x, s);

void mvaddstrCenter(int y, String s, {int x = 39}) =>
    mvaddstr(y, centerString(s, x: x), s);
void move(int y, int x) => console.move(y, x);
void flush() => console.flush();
void refresh() => flush();
void erase() {
  console.erase();
  clearScreenOnNextMessage = true;
}

void eraseArea({
  int startY = 0,
  int startX = 0,
  int endY = CONSOLE_HEIGHT,
  int endX = CONSOLE_WIDTH,
}) =>
    console.eraseArea(startY: startY, startX: startX, endY: endY, endX: endX);
void eraseLine(int y) => console.eraseLine(y);
int centerString(String s, {int x = 39}) => (x - s.length / 2).round();
void moveCenterString(int y, String s) => move(y, centerString(s));
Future<void> pressAnyKey() => getKey();
void setColorConditional(bool active,
        {Color ifTrue = lightGray, Color ifFalse = darkGray}) =>
    setColor(active ? ifTrue : ifFalse);

Future<void> pause(int milliseconds) async {
  refresh();
  await Future.delayed(Duration(milliseconds: milliseconds));
}

Console console = Console();

abstract class Key {
  static const int enter = 13;
  static const int backspace = 8;
  static const int tab = 9;
  static const int escape = 27;
  static const int space = 32;
  static const int shift = 16;
  static const int upArrow = 17;
  static const int downArrow = 18;
  static const int rightArrow = 19;
  static const int leftArrow = 20;
  static const int a = 97;
  static const int b = 98;
  static const int c = 99;
  static const int d = 100;
  static const int e = 101;
  static const int f = 102;
  static const int g = 103;
  static const int h = 104;
  static const int i = 105;
  static const int j = 106;
  static const int k = 107;
  static const int l = 108;
  static const int m = 109;
  static const int n = 110;
  static const int o = 111;
  static const int p = 112;
  static const int q = 113;
  static const int r = 114;
  static const int s = 115;
  static const int t = 116;
  static const int u = 117;
  static const int v = 118;
  static const int w = 119;
  static const int x = 120;
  static const int y = 121;
  static const int z = 122;
  static const int num0 = 48;
  static const int num1 = 49;
  static const int num2 = 50;
  static const int num3 = 51;
  static const int num4 = 52;
  static const int num5 = 53;
  static const int num6 = 54;
  static const int num7 = 55;
  static const int num8 = 56;
  static const int num9 = 57;
  static const int questionMark = 63;
  static const int plus = 43;
  static const int minus = 45;
  static const int rightAngleBracket = 62;
  static const int leftAngleBracket = 60;
}

extension CodePointExtension on String {
  int get codePoint {
    if (this == "Enter") return Key.enter;
    if (this == "Backspace") return Key.backspace;
    if (this == "Tab") return Key.tab;
    if (this == "Escape") return Key.escape;
    if (this == "Up") return Key.upArrow;
    if (this == "Down") return Key.downArrow;
    if (this == "Right") return Key.rightArrow;
    if (this == "Left") return Key.leftArrow;
    if (this == "Shift") return Key.shift;
    if (isEmpty) return 0;
    return toLowerCase().codeUnitAt(0);
  }
}

Future<String> mvgetstr(int y, int x, {String? starting}) async {
  String s = starting ?? "";
  mvaddstr(y, x, "$s▂");
  while (true) {
    String c = await getKeyCaseSensitive();
    if (isBackKey(c.codePoint) &&
        c.codePoint != Key.space &&
        c.codePoint != Key.x) {
      return s;
    } else if (c.codePoint == Key.backspace) {
      if (s.isNotEmpty) {
        s = s.substring(0, s.length - 1);
        mvaddstr(y, x + s.length, "▂ ");
      }
    } else if (c.length == 1) {
      s += c;
      mvaddstr(y, x, "$s▂");
    }
  }
}

Future<String> enterName(int y, int x, String fallback,
    {bool prefill = false}) async {
  String s = await mvgetstr(y, x, starting: prefill ? fallback : null);
  if (s.isEmpty) return fallback;
  return s;
}
