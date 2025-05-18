import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/console_widget.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:markdown_widget/markdown_widget.dart';

class ChangelogWidget extends StatefulWidget {
  const ChangelogWidget({super.key});

  static final GlobalKey<ChangelogWidgetState> globalKey =
      GlobalKey<ChangelogWidgetState>();

  @override
  State<ChangelogWidget> createState() => ChangelogWidgetState();
}

class ChangelogWidgetState extends State<ChangelogWidget> {
  String? _content;
  bool showing = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  void show(String content) {
    setState(() {
      _content = content;
      showing = true;
    });
    _focusNode.requestFocus();
  }

  void hide() {
    setState(() {
      showing = false;
      _content = null;
    });
    _focusNode.unfocus();
    // Return focus to console
    (ConsoleWidget.globalKey.currentWidget as ConsoleWidget?)?.requestFocus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!showing || _content == null) return const SizedBox();

    return Center(
      child: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (event) {
          if (event is KeyDownEvent || event is KeyRepeatEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              hide();
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              unawaited(_scrollController.animateTo(
                _scrollController.offset - 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              ));
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              unawaited(_scrollController.animateTo(
                _scrollController.offset + 50,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOut,
              ));
            }
          }
        },
        child: Container(
          width: 800,
          height: 600,
          decoration: BoxDecoration(
            color: black,
            border: Border.all(color: green, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: green.withAlpha(128),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(6),
                    topRight: Radius.circular(6),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Liberal Crime Squad: New Age Changelog',
                      style: TextStyle(
                        color: lightGreen,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'SourceCodePro',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: lightGreen),
                      onPressed: hide,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RawScrollbar(
                  controller: _scrollController,
                  thumbVisibility: true,
                  trackVisibility: true,
                  thickness: 16,
                  radius: const Radius.circular(8),
                  thumbColor: lightGray,
                  child: GestureDetector(
                    onVerticalDragUpdate: (details) {
                      _scrollController.jumpTo(
                        _scrollController.offset - details.delta.dy,
                      );
                    },
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      child: MarkdownBlock(
                        selectable: false,
                        data: _content!,
                        config: MarkdownConfig.darkConfig.copy(configs: [
                          const H1Config(),
                          const H2Config(),
                          const H3Config(),
                          MyPConfig(),
                          const MyListConfig(),
                        ]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class H1Config extends HeadingConfig {
  const H1Config(
      {this.style = const TextStyle(
        fontFamily: 'SourceCodePro',
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: lightGreen,
      )});

  @override
  final TextStyle style;

  @nonVirtual
  @override
  String get tag => MarkdownTag.h1.name;
}

class H2Config extends HeadingConfig {
  const H2Config(
      {this.style = const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: lightGray,
        fontFamily: 'SourceCodePro',
      )});

  @override
  final TextStyle style;

  @nonVirtual
  @override
  String get tag => MarkdownTag.h2.name;
}

class H3Config extends HeadingConfig {
  const H3Config(
      {this.style = const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: lightGray,
        fontFamily: 'SourceCodePro',
      )});

  @override
  final TextStyle style;

  @nonVirtual
  @override
  String get tag => MarkdownTag.h3.name;
}

class MyPConfig extends PConfig {
  MyPConfig(
      {super.textStyle = const TextStyle(
        fontSize: 16,
        color: lightGray,
        fontFamily: 'SourceCodePro',
      )});
}

class MyListConfig extends ListConfig {
  const MyListConfig({
    super.marker = _defaultMarker,
  });

  static Widget? _defaultMarker(bool isOrdered, int depth, int index) =>
      const Text(
        ' •',
        style: TextStyle(
          color: lightGreen,
          fontFamily: 'SourceCodePro',
        ),
      );
}
