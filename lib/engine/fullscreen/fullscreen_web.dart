import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';

void enterFullscreen() {
  unawaited(document.documentElement?.requestFullscreen());
}

void exitFullscreen() {
  document.exitFullscreen();
}

bool get fullscreen => document.fullscreenElement != null;
