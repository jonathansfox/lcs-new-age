import 'dart:math';

import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/saveload/load_xml_data.dart';
import 'package:lcs_new_age/title_screen/stack_trace/convert_stack_trace.dart';
import 'package:lcs_new_age/title_screen/title_screen.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/game_options.dart';

class EndGameException implements Exception {
  EndGameException();
}

Future<void> launchGame() async {
  await loadXmlData();
  await loadCpcGraphics();
  await gameOptions.load();
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
  String message = e.toString();
  mvaddstrc(1, 0, yellow, message);
  StackTrace? trace = await convertStackTrace(e.stackTrace);
  List<String> stack = trace.toString().split("\n").toList();
  int y = 2;
  for (int i = 0; i < min(stack.length, 22); i++) {
    if (stack[i] == message) continue;
    List<String> parts = stack[i].split(" ");
    for (int i = parts.length - 1; i >= 0; i--) {
      if (parts[i].isEmpty || parts[i] == "at") parts.removeAt(i);
    }
    if (parts.length > 1) {
      if (parts[0].contains("_age/") ||
          parts[1].contains("_age/") ||
          parts[0].contains("../") ||
          parts[1].contains("../")) {
        if (parts[0].contains(".g.") || parts[1].contains(".g.")) {
          setColor(darkRed);
        } else {
          setColor(lightGray);
        }
      } else {
        setColor(darkGray);
      }
      String both = "${parts[0]} ${parts[1]}";
      if (both.length > 49 && parts.length > 2) {
        both = both.substring(both.length - 49);
      }
      mvaddstr(y, 0, both);
      if (parts.length > 2) {
        mvaddstr(y, 50, parts.sublist(2).join(" "));
      }
    } else if (parts.isNotEmpty) {
      mvaddstrc(y, 0, lightGray, parts[0]);
    }
    y++;
  }
  if (willContinue) {
    mvaddstrc(24, 0, lightGreen,
        "Press any key to continue the game after this Conservative interruption.");
  } else {
    mvaddstrc(24, 0, lightGreen,
        "Press any key to restart the game after this Conservative interruption.");
  }
  checkKey();
  await Future.delayed(const Duration(milliseconds: 250));
  await getKey();
}

void endGame() {
  throw EndGameException();
}
