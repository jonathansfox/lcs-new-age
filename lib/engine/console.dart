// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/console_char.dart';
import 'package:lcs_new_age/engine/console_graphic.dart';
import 'package:lcs_new_age/utils/colors.dart';

const CONSOLE_WIDTH = 80;
const CONSOLE_HEIGHT = 25;

class Console {
  Color currentForeground = lightGray;
  Color currentBackground = black;
  int y = 0;
  int x = 0;
  int get width => CONSOLE_WIDTH;
  int get height => CONSOLE_HEIGHT;
  final List<List<ConsoleChar>> buffer = List.generate(CONSOLE_HEIGHT,
      (y) => List.generate(CONSOLE_WIDTH, (x) => ConsoleChar.blank()));
  final List<KeyEvent> keyEvents = [];
  final List<ConsoleGraphic> graphics = [];
  Completer<KeyEvent>? nextKeyEvent;
  KeyEvent? lastKey;
  bool stale = true;
  void Function() flush = () {};

  void setColor(Color foreground, Color background) {
    currentForeground = foreground;
    currentBackground = background;
  }

  void move(int y, int x) {
    this.y = y;
    this.x = x;
  }

  void erase() {
    for (List<ConsoleChar> row in buffer) {
      row.fillRange(0, CONSOLE_WIDTH, ConsoleChar.blank());
    }
    graphics.clear();
  }

  void eraseArea({
    int startY = 0,
    int startX = 0,
    int endY = CONSOLE_HEIGHT,
    int endX = CONSOLE_WIDTH,
  }) {
    for (int y = max(startY, 0); y < min(endY, buffer.length); y++) {
      for (int x = max(startX, 0); x < min(endX, buffer[y].length); x++) {
        buffer[y][x] = ConsoleChar.blank();
      }
    }
    graphics.removeWhere((g) =>
        (g.right >= startX || g.left <= endX) &&
        (g.top >= startY || g.bottom <= endY));
  }

  void eraseLine(int y) => eraseArea(startY: y, endY: y + 1);

  void addchar(String c, {String? mouseClickKey}) {
    if (y >= buffer.length) return;
    if (x >= buffer[y].length) return;
    if (c == '█') {
      buffer[y][x] = ConsoleChar(' ', currentForeground, currentForeground,
          mouseClickKey: mouseClickKey);
    } else {
      buffer[y][x] = ConsoleChar(c, currentForeground, currentBackground,
          mouseClickKey: mouseClickKey);
    }
    x++;
  }

  void handleMouseClick(int y, int x) {
    if (y >= buffer.length || x >= buffer[y].length) return;
    String? key = buffer[y][x].mouseClickKey;
    if (key != null) {
      keyEvent(KeyDownEvent(
        logicalKey: LogicalKeyboardKey.keyA,
        physicalKey: PhysicalKeyboardKey.keyA,
        character: key,
        timeStamp: const Duration(),
      ));
    }
  }

  void mvaddchar(int y, int x, String c, {String? mouseClickKey}) {
    move(y, x);
    addchar(c, mouseClickKey: mouseClickKey);
  }

  void addstr(String s, {String? mouseClickKey}) {
    for (var i = 0; i < s.length; i++) {
      addchar(s[i]);
    }
  }

  void mvaddstr(int y, int x, String s, {String? mouseClickKey}) {
    move(y, x);
    addstr(s);
  }

  void addstrx(String s, {bool restoreOldColor = true, String? mouseClickKey}) {
    const Color dummy = Color(0x00000000);
    bool validColorKey(int i) {
      return i < s.length - 1 && colorMap.containsKey(s[i + 1]);
    }

    Color oldBackground = currentBackground;
    Color oldForeground = currentForeground;
    for (var i = 0; i < s.length; i++) {
      if (s[i] == '&' && validColorKey(i)) {
        Color newColor = colorMap[s[++i]]!;
        if (newColor == dummy) newColor = oldForeground;
        setColor(newColor, currentBackground);
      } else if (s[i] == '^' && validColorKey(i)) {
        Color newColor = colorMap[s[++i]]!;
        if (newColor == dummy) newColor = oldBackground;
        setColor(currentForeground, newColor);
      } else {
        addchar(s[i], mouseClickKey: mouseClickKey);
      }
    }
    if (restoreOldColor) {
      setColor(oldForeground, oldBackground);
    }
  }

  void mvaddstrx(int y, int x, String s,
      {bool restoreOldColor = true, String? mouseClickKey}) {
    move(y, x);
    addstrx(s, restoreOldColor: restoreOldColor, mouseClickKey: mouseClickKey);
  }

  void keyEvent(KeyEvent event) {
    lastKey = event;
    nextKeyEvent?.complete(event);
  }

  Future<String> getkey() async {
    flush();
    if (lastKey == null) {
      nextKeyEvent = Completer<KeyEvent>();
      await nextKeyEvent!.future;
      nextKeyEvent = null;
    }
    String character;
    switch (lastKey?.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        character = "Up";
      case LogicalKeyboardKey.arrowDown:
        character = "Down";
      case LogicalKeyboardKey.arrowLeft:
        character = "Left";
      case LogicalKeyboardKey.arrowRight:
        character = "Right";
      case LogicalKeyboardKey.tab:
        character = "Tab";
      case LogicalKeyboardKey.escape:
        character = "Escape";
      case LogicalKeyboardKey.backspace:
        character = "Backspace";
      case LogicalKeyboardKey.enter:
        character = "Enter";
      case LogicalKeyboardKey.shift:
        character = "Shift";
      case LogicalKeyboardKey.less:
        character = "<";
      case LogicalKeyboardKey.greater:
        character = ">";
      default:
        character = lastKey?.character ?? '';
    }
    lastKey = null;
    return character;
  }

  String checkkey() {
    flush();
    String character = lastKey?.character ?? '';
    lastKey = null;
    return character;
  }

  void addGraphic(ConsoleGraphic graphic) {
    graphics.add(graphic);
  }
}
