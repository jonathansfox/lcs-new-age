import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/saveload/load_cpc_images.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

// ignore: constant_identifier_names
const int CM_FRAMEFLAG_OVERLAY = 1;

CursesMovie movie = CursesMovie();

class CursesMovieFrame {
  int frame = 0;
  int start = 0;
  int stop = 0;
  int sound = -1;
  int song = -1;
  int effect = -1;
  int flag = 0;
}

class CursesMovie {
  late List<List<List<List<int>>>> picture;
  int picnum = 1;
  int dimx = 80;
  int dimy = 25;
  List<String> songlist = [];
  List<String> soundlist = [];
  List<CursesMovieFrame> frame = [];

  Future<void> loadmovie(String filename) async {
    frame = [];

    ByteData h = await rootBundle.load("assets/art/$filename");
    debugPrint("loading movie: $filename");

    picnum = h.getUint32(0, Endian.little);
    dimx = h.getUint32(4, Endian.little);
    dimy = h.getUint32(8, Endian.little);
    debugPrint("picnum: $picnum, dimx: $dimx, dimy: $dimy");
    picture = readCPCData(h, 0);
    int pos = 12 + picnum * dimx * dimy * 4;
    int frameCount = h.getUint32(pos, Endian.little);
    pos = pos + 4;
    for (int f = 0; f < frameCount; f++) {
      CursesMovieFrame frm = CursesMovieFrame();
      frm.frame = h.getUint16(pos, Endian.little);
      frm.start = h.getUint32(pos + 2, Endian.little);
      frm.stop = h.getUint32(pos + 6, Endian.little);
      frm.sound = h.getUint16(pos + 10, Endian.little);
      frm.song = h.getUint16(pos + 12, Endian.little);
      frm.effect = h.getUint16(pos + 14, Endian.little);
      frm.flag = h.getUint16(pos + 16, Endian.little);
      frame.add(frm);
      pos += 18;
    }

    //songlist.open_diskload(h);
    //soundlist.open_diskload(h);
  }

  Future<void> playmovie(int x, int y, {bool remapSkinTones = false}) async {
    int timer = 0;
    int finalframe =
        frame.fold(0, (ff, frame) => ff > frame.stop ? ff : frame.stop);
    bool pted;
    List<CursesMovieFrame> lastFramesPainted = [];

    eraseArea(startY: y, startX: x, endY: y + movie.dimy, endX: x + movie.dimx);

    Stopwatch sw = Stopwatch()..start();
    do {
      pted = false;

      List<CursesMovieFrame> framesToPaint =
          frame.where((f) => f.start <= timer && f.stop >= timer).toList();
      if (framesToPaint.any((e) => !lastFramesPainted.contains(e)) ||
          lastFramesPainted.any((e) => !framesToPaint.contains(e))) {
        lastFramesPainted = framesToPaint;
        for (CursesMovieFrame f in framesToPaint) {
          for (int fx = 0; fx < movie.dimx && fx + x < 80; fx++) {
            for (int fy = 0; fy < movie.dimy && fy + y < 25; fy++) {
              if ((movie.picture[f.frame][fx][fy][0] == ' '.codePoint ||
                      movie.picture[f.frame][fx][fy][0] == 0) &&
                  f.flag & CM_FRAMEFLAG_OVERLAY > 0) {
                continue;
              }

              move(fy + y, fx + x);
              drawCPCGlyph(movie.picture[f.frame][fx][fy],
                  remapSkinTones: remapSkinTones);
            }
          }
          pted = true;
        }
      }

      if (pted) refresh();

      timer++;
      //while(time+10>GetTickCount);
      if (timer * 10 > sw.elapsedMilliseconds) {
        await Future.delayed(const Duration(milliseconds: 10));
      }

      int c = checkKey().codePoint;

      if (isBackKey(c)) timer = finalframe;
    } while (timer <= finalframe);
  }
}
