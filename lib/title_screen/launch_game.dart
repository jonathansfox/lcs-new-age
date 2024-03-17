import 'dart:math';

import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/saveload/load_xml_data.dart';
import 'package:lcs_new_age/title_screen/title_screen.dart';
import 'package:lcs_new_age/utils/colors.dart';

class EndGameException implements Exception {
  EndGameException();
}

Future<void> launchGame() async {
  await loadXmlData();
  await loadCpcGraphics();
  while (true) {
    try {
      await titleScreen();
    } on Error catch (e) {
      await errorScreen(e);
    } on EndGameException catch (_) {}
  }
}

Future<void> errorScreen(Error e, {bool willContinue = false}) async {
  erase();
  mvaddstrc(0, 0, red,
      "CRASH REPORT:  A screenshot of this will help the developer fix this bug.");
  mvaddstrc(1, 0, yellow, e.toString());
  List<String> stack = e.stackTrace.toString().split("\n").toList();
  for (int i = 0; i < min(stack.length, 22); i++) {
    List<String> parts = stack[i].split(" ");
    for (int i = parts.length - 1; i >= 0; i--) {
      if (parts[i].isEmpty) parts.removeAt(i);
    }
    if (parts.length > 1) {
      if (parts[0].contains("_age/")) {
        if (parts[0].contains(".g.")) {
          setColor(darkRed);
        } else {
          setColor(lightGray);
        }
      } else {
        setColor(darkGray);
      }
      if (parts.isNotEmpty && parts[0].length > 41) {
        parts[0] = parts[0].substring(parts[0].length - 41);
      }
      mvaddstr(i + 2, 0, "${parts[0]} ${parts[1]}");
      if (parts.length > 2) {
        mvaddstr(i + 2, 50, parts.sublist(2).join(" "));
      }
    } else if (parts.isNotEmpty) {
      mvaddstrc(i + 2, 0, lightGray, parts[0]);
    }
  }
  if (willContinue) {
    mvaddstrc(24, 0, lightGreen,
        "Press any key to continue the game after this Conservative interruption.");
  } else {
    mvaddstrc(24, 0, lightGreen,
        "Press any key to restart the game after this Conservative interruption.");
  }
  await getKey();
}

void endGame() {
  throw EndGameException();
}
