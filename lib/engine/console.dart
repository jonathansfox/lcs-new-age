// ignore_for_file: constant_identifier_names

import 'dart:async';

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
    for (int y = startY; y < endY; y++) {
      for (int x = startX; x < endX; x++) {
        buffer[y][x] = ConsoleChar.blank();
      }
    }
    graphics.removeWhere((g) =>
        (g.right >= startX || g.left <= endX) &&
        (g.top >= startY || g.bottom <= endY));
  }

  void eraseLine(int y) => eraseArea(startY: y, endY: y + 1);

  void addchar(String c) {
    if (y >= buffer.length) return;
    if (x >= buffer[y].length) return;
    if (c == '█') {
      buffer[y][x] = ConsoleChar(' ', currentForeground, currentForeground);
    } else {
      buffer[y][x] = ConsoleChar(c, currentForeground, currentBackground);
    }
    x++;
  }

  void mvaddchar(int y, int x, String c) {
    move(y, x);
    addchar(c);
  }

  void addstr(String s) {
    for (var i = 0; i < s.length; i++) {
      addchar(s[i]);
    }
  }

  void mvaddstr(int y, int x, String s) {
    move(y, x);
    addstr(s);
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
