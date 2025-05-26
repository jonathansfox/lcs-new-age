import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/changelog.dart';
import 'package:lcs_new_age/engine/console.dart';
import 'package:lcs_new_age/engine/console_char.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/game_options.dart';
import 'package:pixel_snap/material.dart';

class ConsoleWidget extends StatefulWidget {
  const ConsoleWidget(this.console, {super.key});
  static final GlobalKey<State<ConsoleWidget>> globalKey =
      GlobalKey<State<ConsoleWidget>>();
  final Console console;

  void requestFocus() {
    (globalKey.currentState as _ConsoleWidgetState?)?.focusNode.requestFocus();
  }

  @override
  State<ConsoleWidget> createState() => _ConsoleWidgetState();
}

class _ConsoleWidgetState extends State<ConsoleWidget> {
  late final FocusNode focusNode;
  late final FocusAttachment focusAttachment;
  bool hasFocus = false;
  final TextEditingController textEditingController = TextEditingController();
  int? hoverX;
  int? hoverY;
  final GlobalKey mobileKeyboardLayerKey = GlobalKey();

  void updateHoverPosition(double dx, double dy) {
    double cellWidth = textSpanWidth / console.width;
    double cellHeight = textSpanHeight / console.height;
    int newX = (dx / cellWidth).floor();
    int newY = (dy / cellHeight).floor();

    if (newX >= 0 &&
        newX < console.width &&
        newY >= 0 &&
        newY < console.height) {
      if (newX != hoverX || newY != hoverY) {
        setState(() {
          hoverX = newX;
          hoverY = newY;
          console.hoverX = newX;
          console.hoverY = newY;
        });
      }
    } else {
      if (hoverX != null || hoverY != null) {
        debugPrint("Hover position cleared");
        setState(() {
          hoverX = null;
          hoverY = null;
          console.hoverX = null;
          console.hoverY = null;
        });
      }
    }
  }

  @override
  void initState() {
    focusNode = FocusNode(onKeyEvent: _onKeyEvent);
    focusNode.addListener(_handleFocusChange);
    focusAttachment = focusNode.attach(context);
    widget.console.flush = () {
      console.stale = true;
      setState(() {});
    };
    textEditingController.addListener(() {
      if (textEditingController.text == " ") return;
      onTextChanged(textEditingController.text);
      textEditingController.text = " ";
    });
    super.initState();
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent value) {
    if ((value is KeyDownEvent || value is KeyRepeatEvent) &&
        ![
          LogicalKeyboardKey.altLeft,
          LogicalKeyboardKey.altRight,
          LogicalKeyboardKey.tab,
          LogicalKeyboardKey.shiftLeft,
          LogicalKeyboardKey.shiftRight,
          LogicalKeyboardKey.controlLeft,
          LogicalKeyboardKey.controlRight,
          LogicalKeyboardKey.metaLeft,
          LogicalKeyboardKey.metaRight,
          LogicalKeyboardKey.altGraph,
        ].contains(value.logicalKey)) {
      //debugPrint("Key event: $value");
      console.keyEvent(value);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleFocusChange() {
    if (focusNode.hasFocus != hasFocus) {
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
        Color cellColor = line[x].background;
        // If the cursor is over a cell with the same mouseClickKey, lighten its color
        if (gameOptions.mouseInput && hoverX != null && hoverY != null) {
          String? hoverKey = console.buffer[hoverY!][hoverX!].mouseClickKey;
          if (line[x].mouseClickKey != null &&
              line[x].mouseClickKey == hoverKey &&
              !line[x].noHighlight) {
            cellColor = Color.lerp(cellColor, Colors.white, 0.2)!;
          }
        }

        if (x == 0) {
          startPoint = x;
          currentColor = cellColor;
        } else if (currentColor != cellColor) {
          intervals.add((y, startPoint, x, currentColor));
          startPoint = x;
          currentColor = cellColor;
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
        if (glyph.codeUnitAt(0) < 32) {
          // ignore control characters
          glyph = " ";
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
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Material(
            color: black,
            child: SizedBox(
              width: textSpanWidth,
              height: textSpanHeight,
              child: mouseInputLayer(
                child: Stack(
                  children: [
                    background(),
                    Positioned.fill(
                      child: CustomPaint(painter: BlockPainter(console)),
                    ),
                    richText(fg),
                    ...graphics(),
                    mobileKeyboardLayer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget mouseInputLayer({Widget? child}) {
    return MouseRegion(
      onHover: (event) {
        updateHoverPosition(event.localPosition.dx, event.localPosition.dy);
      },
      onExit: (event) {
        setState(() {
          hoverX = null;
          hoverY = null;
        });
      },
      child: GestureDetector(
        onTapDown: (details) {
          // Convert tap coordinates to console coordinates
          double cellWidth = textSpanWidth / console.width;
          double cellHeight = textSpanHeight / console.height;
          int x = (details.localPosition.dx / cellWidth).floor();
          int y = (details.localPosition.dy / cellHeight).floor();
          console.handleMouseClick(y, x);
          console.handleMouseEvent(y, x, true);
        },
        onPanUpdate: (details) {
          // Convert pan coordinates to console coordinates
          double cellWidth = textSpanWidth / console.width;
          double cellHeight = textSpanHeight / console.height;
          int x = (details.localPosition.dx / cellWidth).floor();
          int y = (details.localPosition.dy / cellHeight).floor();
          console.handleMouseEvent(y, x, true);
        },
        onTapUp: (details) {
          double cellWidth = textSpanWidth / console.width;
          double cellHeight = textSpanHeight / console.height;
          int x = (details.localPosition.dx / cellWidth).floor();
          int y = (details.localPosition.dy / cellHeight).floor();
          console.handleMouseEvent(y, x, false);
        },
        onTapCancel: () {
          if (console.hoverX != null && console.hoverY != null) {
            console.handleMouseEvent(console.hoverY!, console.hoverX!, false);
          }
        },
        onTap: () {
          if (ChangelogWidget.globalKey.currentState?.showing != true) {
            focusNode.requestFocus();
          }
        },
        child: child,
      ),
    );
  }

  Widget richText(TextSpan fg) {
    return RichText(
      text: fg,
      softWrap: false,
      textHeightBehavior: const TextHeightBehavior(
        applyHeightToFirstAscent: false,
        applyHeightToLastDescent: false,
        leadingDistribution: TextLeadingDistribution.even,
      ),
    );
  }

  Widget mobileKeyboardLayer() {
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return Positioned.fill(
        key: mobileKeyboardLayerKey,
        child: Visibility(
          visible: false,
          maintainState: true,
          maintainAnimation: true,
          maintainSize: true,
          maintainInteractivity: true,
          child: TextField(
            minLines: 2,
            maxLines: 80,
            controller: textEditingController,
            showCursor: false,
            autocorrect: false,
            enableSuggestions: false,
            enableInteractiveSelection: false,
            smartDashesType: SmartDashesType.disabled,
            smartQuotesType: SmartQuotesType.disabled,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            onChanged: onTextChanged,
          ),
        ),
      );
    } else {
      return Container();
    }
  }

  void onTextChanged(String text) {
    textEditingController.text = " ";
    if (text.isEmpty) {
      console.keyEvent(const KeyDownEvent(
        logicalKey: LogicalKeyboardKey.backspace,
        physicalKey: PhysicalKeyboardKey.backspace,
        character: 'Backspace',
        timeStamp: Duration(),
      ));
    } else if (text.contains("\n")) {
      console.keyEvent(const KeyDownEvent(
        logicalKey: LogicalKeyboardKey.enter,
        physicalKey: PhysicalKeyboardKey.enter,
        character: 'Enter',
        timeStamp: Duration(),
      ));
    } else {
      List<String> characters = text.split("").sublist(1);
      for (String character in characters) {
        if (character.codePoint >= 32 && character.codePoint <= 126) {
          console.keyEvent(KeyDownEvent(
            logicalKey: LogicalKeyboardKey.keyA,
            physicalKey: PhysicalKeyboardKey.keyA,
            character: character,
            timeStamp: const Duration(),
          ));
        }
      }
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
