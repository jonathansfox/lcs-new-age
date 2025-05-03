import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/engine/console_widget.dart';
import 'package:lcs_new_age/utils/colors.dart';

class ChangelogWidget extends StatefulWidget {
  const ChangelogWidget({super.key});

  static final GlobalKey<ChangelogWidgetState> globalKey =
      GlobalKey<ChangelogWidgetState>();

  @override
  State<ChangelogWidget> createState() => ChangelogWidgetState();
}

class ChangelogWidgetState extends State<ChangelogWidget> {
  String? _content;
  bool _show = false;
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  void show(String content) {
    setState(() {
      _content = content;
      _show = true;
    });
    _focusNode.requestFocus();
  }

  void hide() {
    setState(() {
      _show = false;
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
    if (!_show || _content == null) return const SizedBox();

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
                      child: Text(
                        _content!,
                        style: const TextStyle(
                          color: lightGray,
                          fontSize: 16,
                          fontFamily: 'SourceCodePro',
                        ),
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
