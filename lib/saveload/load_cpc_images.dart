import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/saveload/load_xml_data.dart';
import 'package:lcs_new_age/utils/colors.dart';

late List<List<List<List<int>>>> bigletters;
late List<List<List<List<int>>>> newstops;
late List<List<List<List<int>>>> newspic;

Future<void> loadCpcGraphics() async {
  loadingFeedback("largecap.cpc");
  bigletters = await readCPCFile("assets/art/largecap.cpc");
  loadingFeedback("newstops.cpc");
  newstops = await readCPCFile("assets/art/newstops.cpc");
  loadingFeedback("newspic.cpc");
  newspic = await readCPCFile("assets/art/newspic.cpc");
}

Future<List<List<List<List<int>>>>> readCPCFile(String s) async {
  return readCPCData(await rootBundle.load(s));
}

List<List<List<List<int>>>> readCPCData(ByteData h, [int pos = 0]) {
  int picnum = h.getUint32(pos, Endian.little);
  int dimx = h.getUint32(pos + 4, Endian.little);
  int dimy = h.getUint32(pos + 8, Endian.little);
  pos = pos + 12;
  return List.generate(
    picnum,
    (p) => List.generate(
      dimx,
      (x) => List.generate(
        dimy,
        (y) => List.generate(
          4,
          (z) => h.getUint8(pos++),
          growable: false,
        ),
        growable: false,
      ),
      growable: false,
    ),
    growable: false,
  );
}

Color translateGraphicsColor(int c, bool bright,
        {bool remapSkinTones = false}) =>
    switch ((c, bright)) {
      (0, true) => darkGray,
      (0, false) => black,
      (1, true) => blue,
      (1, false) => darkBlue,
      (2, true) => lightGreen,
      (2, false) => green,
      (3, true) => lightBlue,
      (3, false) => blue,
      (4, true) => red,
      (4, false) => darkRed,
      (5, true) => pink,
      (5, false) => purple,
      (6, true) => remapSkinTones ? Skin.f : yellow,
      (6, false) => remapSkinTones ? Skin.b : halfYellow,
      (7, true) => white,
      (7, false) => lightGray,
      _ => purple,
    };

void drawCPCGlyph(List<int> glyph, {bool remapSkinTones = false}) {
  bool bright = glyph[3] > 0;
  Color fgColor =
      translateGraphicsColor(glyph[1], bright, remapSkinTones: remapSkinTones);
  Color bgColor =
      translateGraphicsColor(glyph[2], false, remapSkinTones: remapSkinTones);
  String char = String.fromCharCode(convert437ToUTF(glyph[0]));
  if (char == '█') {
    Color swap = fgColor;
    fgColor = bgColor;
    bgColor = swap;
    char = ' ';
  }
  setColor(fgColor, background: bgColor);
  addchar(char);
}

int convert437ToUTF(int code) => switch (code) {
      0 || (>= 32 && <= 126) => code,
      1 => 0x263A,
      2 => 0x263B,
      3 => 0x2665,
      4 => 0x2666,
      5 => 0x2663,
      6 => 0x2660,
      7 => 0x2022,
      8 => 0x25D8,
      9 => 0x25CB,
      10 => 0x25D9,
      11 => 0x2642,
      12 => 0x2640,
      13 => 0x266A,
      14 => 0x266B,
      15 => 0x263C,
      16 => 0x25BA,
      17 => 0x25C4,
      18 => 0x2195,
      19 => 0x203C,
      20 => 0x00B6,
      21 => 0x00A7,
      22 => 0x25AC,
      23 => 0x21A8,
      24 => 0x2191,
      25 => 0x2193,
      26 => 0x2192,
      27 => 0x2190,
      28 => 0x221F,
      29 => 0x2194,
      30 => 0x25B2,
      31 => 0x25BC,
      127 => 0x2302,
      128 => 0x00C7,
      129 => 0x00FC,
      130 => 0x00E9,
      131 => 0x00E2,
      132 => 0x00E4,
      133 => 0x00E0,
      134 => 0x00E5,
      135 => 0x00E7,
      136 => 0x00EA,
      137 => 0x00EB,
      138 => 0x00E8,
      139 => 0x00EF,
      140 => 0x00EE,
      141 => 0x00EC,
      142 => 0x00C4,
      143 => 0x00C5,
      144 => 0x00C9,
      145 => 0x00E6,
      146 => 0x00C6,
      147 => 0x00F4,
      148 => 0x00F6,
      149 => 0x00F2,
      150 => 0x00FB,
      151 => 0x00F9,
      152 => 0x00FF,
      153 => 0x00D6,
      154 => 0x00DC,
      155 => 0x00A2,
      156 => 0x00A3,
      157 => 0x00A5,
      158 => 0x20A7,
      159 => 0x0192,
      160 => 0x00E1,
      161 => 0x00ED,
      162 => 0x00F3,
      163 => 0x00FA,
      164 => 0x00F1,
      165 => 0x00D1,
      166 => 0x00AA,
      167 => 0x00BA,
      168 => 0x00BF,
      169 => 0x2310,
      170 => 0x00AC,
      171 => 0x00BD,
      172 => 0x00BC,
      173 => 0x00A1,
      174 => 0x00AB,
      175 => 0x00BB,
      176 => 0x2591,
      177 => 0x2592,
      178 => 0x2593,
      179 => 0x2502,
      180 => 0x2524,
      181 => 0x2561,
      182 => 0x2562,
      183 => 0x2556,
      184 => 0x2555,
      185 => 0x2563,
      186 => 0x2551,
      187 => 0x2557,
      188 => 0x255D,
      189 => 0x255C,
      190 => 0x255B,
      191 => 0x2510,
      192 => 0x2514,
      193 => 0x2534,
      194 => 0x252C,
      195 => 0x251C,
      196 => 0x2500,
      197 => 0x253C,
      198 => 0x255E,
      199 => 0x255F,
      200 => 0x255A,
      201 => 0x2554,
      202 => 0x2569,
      203 => 0x2566,
      204 => 0x2560,
      205 => 0x2550,
      206 => 0x255C,
      207 => 0x2567,
      208 => 0x2568,
      209 => 0x2564,
      210 => 0x2565,
      211 => 0x2559,
      212 => 0x2558,
      213 => 0x2552,
      214 => 0x2553,
      215 => 0x256B,
      216 => 0x256A,
      217 => 0x2518,
      218 => 0x250C,
      219 => 0x2588,
      220 => 0x2584,
      221 => 0x258C,
      222 => 0x2590,
      223 => 0x2580,
      224 => 0x03B1,
      225 => 0x00DF,
      226 => 0x0393,
      227 => 0x03C0,
      228 => 0x03A3,
      229 => 0x03C3,
      230 => 0x00B5,
      231 => 0x03C4,
      232 => 0x03A6,
      233 => 0x0398,
      234 => 0x03A9,
      235 => 0x03B4,
      236 => 0x221E,
      237 => 0x03C6,
      238 => 0x03B5,
      239 => 0x2229,
      240 => 0x2261,
      241 => 0x00B1,
      242 => 0x2265,
      243 => 0x2264,
      244 => 0x2320,
      245 => 0x2321,
      246 => 0x00F7,
      247 => 0x2248,
      248 => 0x00B0,
      249 => 0x2219,
      250 => 0x00B7,
      251 => 0x221A,
      252 => 0x207F,
      253 => 0x00B2,
      254 => 0x25A0,
      255 => 0x00A0,
      _ => code,
    };
