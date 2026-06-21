import 'dart:ui';

import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';

class _BlindLogEntry {
  _BlindLogEntry(this.text, this.month, this.year);
  final String text;
  final int month;
  final int year;
}

final List<_BlindLogEntry> _blindLog = [];
const int _maxBlindLogEntries = 50;
const int _blindLogTopRow = 11;

void clearBlindLog() => _blindLog.clear();

void logBlindEvent(String text) {
  _blindLog.add(_BlindLogEntry(text, month, year));
  if (_blindLog.length > _maxBlindLogEntries) {
    _blindLog.removeRange(0, _blindLog.length - _maxBlindLogEntries);
  }
}

Future<void> showMessageOrLog(
  String message, {
  Color color = lightGray,
  bool delimeter = true,
}) async {
  if (canSeeThings) {
    await showMessage(message, color: color, delimeter: delimeter);
  } else {
    logBlindEvent(message);
  }
}

void displayBlindLog() {
  if (_blindLog.isEmpty) return;
  int nowIndex = year * 12 + month;
  const int startX = 5;
  int maxRow = console.height - 1;
  int y = _blindLogTopRow;
  for (final entry in _blindLog.reversed) {
    if (y > maxRow) break;
    int ageMonths = nowIndex - (entry.year * 12 + entry.month);
    Color color = switch (ageMonths) {
      <= 0 => white,
      1 => lightGray,
      2 => midGray,
      _ => darkGray,
    };
    setColor(color);
    addparagraph(
      y,
      startX,
      "${entry.month}/${entry.year}: ${entry.text}",
      y2: maxRow,
    );
    y = console.y;
  }
}
