import 'dart:async';

import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/console.dart';
import 'package:lcs_new_age/engine/console_char.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/engine/fullscreen/fullscreen.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:pixel_snap/material.dart';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget(this.console, {super.key});
  final Console console;

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  late final FocusNode focusNode;
  late final FocusAttachment focusAttachment;
  bool hasFocus = false;
  bool fullscreen = false;

  @override
  void initState() {
    focusNode = FocusNode(onKeyEvent: _onKeyEvent);
    focusNode.addListener(_handleFocusChange);
    focusAttachment = focusNode.attach(context);
    widget.console.flush = () {
      console.stale = true;
      setState(() {});
    };
    super.initState();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent value) {
    if (value is KeyDownEvent && value.logicalKey == LogicalKeyboardKey.f11) {
      setState(() {
        if (!fullscreen) {
          enterFullscreen();
          fullscreen = true;
        } else {
          exitFullscreen();
          fullscreen = false;
        }
      });
      return KeyEventResult.handled;
    }
    if ((value is KeyDownEvent || value is KeyRepeatEvent) &&
        ![
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
          LogicalKeyboardKey.tab
        ].contains(value.logicalKey)) {
      //debugPrint("Key event: $value");
      console.keyEvent(value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleFocusChange() {
    if (focusNode.hasFocus != hasFocus) {
      debugPrint("Focus changed: ${focusNode.hasFocus}");
      setState(() {
        hasFocus = focusNode.hasFocus;
      });
    }
  }

  @override
  void dispose() {
    focusNode.removeListener(_handleFocusChange);
    focusNode.dispose();
    super.dispose();
  }

  double textSpanWidth = 1;
  double textSpanHeight = 1;

  @override
  void didChangeDependencies() {
    widget.console.flush = () => setState(() {});
    super.didChangeDependencies();
    TextSpan fg = consoleDataToTextSpan(false);
    TextPainter textPainter = TextPainter(
      strutStyle: const StrutStyle(
        forceStrutHeight: true,
        height: 1,
        leading: 0,
        fontSize: 20,
      ),
      text: fg,
      textDirection: TextDirection.ltr,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
      ),
    );
    textPainter.layout();
    setState(() {
      textSpanWidth = textPainter.width.roundToDouble();
      textSpanHeight = textPainter.height.roundToDouble();
    });
  }

  Iterable<Widget> graphics() => console.graphics.map(
        (g) => Positioned(
          left: g.left * textSpanWidth / console.width,
          width: (g.right - g.left) * textSpanWidth / console.width,
          top: g.top * textSpanHeight / console.height,
          height: (g.bottom - g.top) * textSpanHeight / console.height,
          child: g.graphic,
        ),
      );

  Widget background() {
    List<(int, int, int, Color)> intervals = [];
    int startPoint = 0;
    Color currentColor = console.buffer[0][0].background;
    for (int y = 0; y < console.buffer.length; y++) {
      List<ConsoleChar> line = console.buffer[y];
      for (int x = 0; x < line.length; x++) {
        if (x == 0) {
          startPoint = x;
          currentColor = line[x].background;
        } else if (currentColor != line[x].background) {
          intervals.add((y, startPoint, x, currentColor));
          startPoint = x;
          currentColor = line[x].background;
        }
        if (x == line.length - 1) {
          intervals.add((y, startPoint, line.length, currentColor));
        }
      }
    }

    return Stack(
        children: List.generate(intervals.length, (i) {
      Rect rect = Rect.fromLTRB(
        (intervals[i].$2 * textSpanWidth / console.width).roundToDouble(),
        (intervals[i].$1 * textSpanHeight / console.height).roundToDouble(),
        (intervals[i].$3 * textSpanWidth / console.width).roundToDouble(),
        ((intervals[i].$1 + 1) * textSpanHeight / console.height)
            .roundToDouble(),
      );
      return Positioned(
        top: rect.top,
        height: rect.height,
        left: rect.left,
        width: rect.width,
        child: Container(color: intervals[i].$4),
      );
    }));
  }

  TextSpan consoleDataToTextSpan(bool bg) {
    List<TextSpan> spans = [];
    Color foreground = lightGray;
    Color background = black;
    String text = "";
    void addSpan() {
      TextSpan span = TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: "SourceCodePro",
          fontSize: 16,
          color: foreground,
          backgroundColor: bg ? background : null,
          //leadingDistribution: TextLeadingDistribution.even,
          textBaseline: TextBaseline.ideographic,
          letterSpacing: 0,
          height: 1.4,
        ),
      );
      spans.add(span);
      text = "";
    }

    for (List<ConsoleChar> line in console.buffer) {
      for (ConsoleChar char in line) {
        if (text.isNotEmpty &&
            (foreground != char.foreground || background != char.background)) {
          addSpan();
        }
        String glyph = char.glyph;
        if (['░', '▒', '▓', '▀', '▌', '▐', '▄', '█'].contains(glyph)) {
          glyph = ' '; // leave these to the BlockPainter
        }
        text += bg ? "." : glyph;
        foreground = bg ? char.background : char.foreground;
        background = bg ? char.background : Colors.transparent;
      }
      if (line != console.buffer.last) text += "\n";
    }
    addSpan();
    return TextSpan(children: spans);
  }

  @override
  Widget build(BuildContext context) {
    focusAttachment.reparent();
    TextSpan fg = consoleDataToTextSpan(false);
    return Material(
      color: Color.lerp(darkGray, black, 0.8),
      child: scalingFrame(
        child: Material(
          color: black,
          child: SizedBox(
            width: textSpanWidth,
            height: textSpanHeight,
            child: GestureDetector(
              onTap: () {
                debugPrint("Requesting focus");
                focusNode.requestFocus();
                debugPrint("Widget has focus: ${focusNode.hasFocus}");
                SystemChannels.textInput
                    // ignore: discarded_futures
                    .invokeMethod("TextInput.show")
                    .ignore();
              },
              child: Stack(
                children: [
                  background(),
                  Positioned.fill(
                    child: CustomPaint(painter: BlockPainter(console)),
                  ),
                  RichText(
                    text: fg,
                    softWrap: false,
                    textHeightBehavior: const TextHeightBehavior(
                      applyHeightToFirstAscent: false,
                      applyHeightToLastDescent: false,
                      leadingDistribution: TextLeadingDistribution.even,
                    ),
                  ),
                  ...graphics(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget scalingFrame({required Widget child}) {
    if (fullscreen) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: child,
        ),
      );
    } else {
      return Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: child,
        ),
      );
    }
  }
}

class BlockPainter extends CustomPainter {
  BlockPainter(this.console);
  final Console console;

  @override
  void paint(Canvas canvas, Size size) {
    console.stale = false;
    Rect rectFromCoordinates(num x1, num y1, num x2, num y2) => Rect.fromLTRB(
          (x1 * size.width / console.width).roundToDouble(),
          (y1 * size.height / console.height).roundToDouble(),
          (x2 * size.width / console.width).roundToDouble(),
          (y2 * size.height / console.height).roundToDouble(),
        );
    Paint paint = Paint()..style = PaintingStyle.fill;
    for (int y = 0; y < console.buffer.length; y++) {
      for (int x = 0; x < console.buffer[y].length; x++) {
        ConsoleChar char = console.buffer[y][x];
        switch (char.glyph) {
          case '░':
            Rect paintArea = rectFromCoordinates(x, y, x + 1, y + 1);
            paint.color = Color.alphaBlend(
                char.foreground.withAlpha(0x40), char.background);
            canvas.drawRect(paintArea, paint);
          case '▒':
            Rect paintArea = rectFromCoordinates(x, y, x + 1, y + 1);
            paint.color = Color.alphaBlend(
                char.foreground.withAlpha(0x80), char.background);
            canvas.drawRect(paintArea, paint);
          case '▓':
            Rect paintArea = rectFromCoordinates(x, y, x + 1, y + 1);
            paint.color = Color.alphaBlend(
                char.foreground.withAlpha(0xC0), char.background);
            canvas.drawRect(paintArea, paint);
          case '▀':
            paint.color = char.foreground;
            Rect paintArea = rectFromCoordinates(x, y, x + 1, y + 0.5);
            canvas.drawRect(paintArea, paint);
          case '▌':
            paint.color = char.foreground;
            Rect paintArea = rectFromCoordinates(x, y, x + 0.5, y + 1);
            canvas.drawRect(paintArea, paint);
          case '▐':
            paint.color = char.foreground;
            Rect paintArea = rectFromCoordinates(x + 0.5, y, x + 1, y + 1);
            canvas.drawRect(paintArea, paint);
          case '▄':
            paint.color = char.foreground;
            Rect paintArea = rectFromCoordinates(x, y + 0.5, x + 1, y + 1);
            canvas.drawRect(paintArea, paint);
          case '█':
            Rect paintArea = rectFromCoordinates(x, y, x + 1, y + 1);
            paint.color = char.foreground;
            canvas.drawRect(paintArea, paint);
          default:
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return console.stale;
  }
}
