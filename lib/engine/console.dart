// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/console_char.dart';
import 'package:lcs_new_age/engine/console_graphic.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/game_options.dart';

const CONSOLE_WIDTH = 80;
const CONSOLE_HEIGHT = 25;

class Console {
  Color currentForeground = lightGray;
  Color currentBackground = black;
  int y = 0;
  int x = 0;
  int? hoverX;
  int? hoverY;
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

  // Mouse event handling
  bool mouseEventMode = false;
  void Function(int y, int x, bool isDown)? onMouseEvent;

  void enableMouseEvents(void Function(int y, int x, bool isDown) callback) {
    mouseEventMode = true;
    onMouseEvent = callback;
  }

  void disableMouseEvents() {
    mouseEventMode = false;
    onMouseEvent = null;
  }

  void handleMouseEvent(int y, int x, bool isDown) {
    if (mouseEventMode && onMouseEvent != null) {
      onMouseEvent!(y, x, isDown);
    }
  }

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

  void registerMouseRegion(int y, int x, int width, int height, String key,
      {bool noHighlight = false}) {
    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        buffer[y + i][x + j].mouseClickKey = key;
        buffer[y + i][x + j].noHighlight = noHighlight;
      }
    }
  }

  void handleMouseClick(int y, int x) {
    if (y >= buffer.length || x >= buffer[y].length) return;
    if (!gameOptions.mouseInput) return;
    String? key = buffer[y][x].mouseClickKey;
    key ??= "`";
    keyEvent(KeyDownEvent(
      logicalKey: LogicalKeyboardKey.keyA,
      physicalKey: PhysicalKeyboardKey.keyA,
      character: key,
      timeStamp: const Duration(),
    ));
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
    String character = '';
    while (character == '') {
      while (lastKey == null) {
        nextKeyEvent = Completer<KeyEvent>();
        await nextKeyEvent!.future;
        nextKeyEvent = null;
      }
      character = keyEventToString(lastKey!);
      lastKey = null;
    }
    return character;
  }

  Future<KeyEvent> getKeyEvent() async {
    flush();
    KeyEvent? result = lastKey;
    while (result == null || keyEventToString(result) == '') {
      while (lastKey == null) {
        nextKeyEvent = Completer<KeyEvent>();
        await nextKeyEvent!.future;
        nextKeyEvent = null;
      }
      result = lastKey;
      lastKey = null;
    }
    return result;
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

String keyEventToString(KeyEvent event) {
  switch (event.logicalKey) {
    case LogicalKeyboardKey.arrowUp:
      return "Up";
    case LogicalKeyboardKey.arrowDown:
      return "Down";
    case LogicalKeyboardKey.arrowLeft:
      return "Left";
    case LogicalKeyboardKey.arrowRight:
      return "Right";
    case LogicalKeyboardKey.tab:
      return "Tab";
    case LogicalKeyboardKey.escape:
      return "Escape";
    case LogicalKeyboardKey.backspace:
      return "Backspace";
    case LogicalKeyboardKey.enter:
      return "Enter";
    case LogicalKeyboardKey.shift:
      return "Shift";
    case LogicalKeyboardKey.less:
      return "<";
    case LogicalKeyboardKey.greater:
      return ">";
    default:
      return event.character ?? '';
  }
}
