// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart';

void enterFullscreen() {
  document.documentElement?.requestFullscreen();
}

void exitFullscreen() {
  document.exitFullscreen();
}

bool get fullscreen => document.fullscreenElement != null;
