import 'package:flutter/material.dart';
import 'package:lcs_new_age/utils/colors.dart';

class ConsoleChar {
  ConsoleChar(this.glyph, this.foreground, this.background,
      {this.mouseClickKey});
  factory ConsoleChar.blank() => ConsoleChar(" ", lightGray, black);
  String glyph = " ";
  Color foreground = lightGray;
  Color background = black;
  String? mouseClickKey;
  bool noHighlight = false;
}
