import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lcs_new_age/map_editor/editor_tools.dart';
import 'package:lcs_new_age/map_editor/map_editor_controller.dart';
import 'package:lcs_new_age/map_editor/map_painter.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';

// The drawable map area: sizes itself to fit, converts pointer positions to map
// cells, and dispatches to the controller based on the active tool. Zoom/pan is
// handled by an InteractiveViewer sharing [transform]; because the paint
// Listener lives inside the transformed child, Flutter delivers already-inverse-
// transformed local coordinates, so cell math is unaffected by zoom.
class MapCanvas extends StatelessWidget {
  const MapCanvas(this.controller, this.transform, {super.key});

  final MapEditorController controller;
  final TransformationController transform;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final double maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : maxW * MAPY / MAPX;
        final double cell = min(maxW / MAPX, maxH / MAPY);
        final double w = cell * MAPX;
        final double h = cell * MAPY;
        final bool panning = controller.tool == EditorTool.pan;
        final bool interactive = !panning && !controller.previewMode;
        return Center(
          child: SizedBox(
            width: w,
            height: h,
            child: InteractiveViewer(
              transformationController: transform,
              panEnabled: panning,
              scaleEnabled: panning,
              minScale: 1,
              maxScale: 6,
              boundaryMargin: EdgeInsets.zero,
              child: MouseRegion(
                cursor: interactive
                    ? SystemMouseCursors.precise
                    : (panning
                          ? SystemMouseCursors.grab
                          : SystemMouseCursors.basic),
                onExit: (_) => controller.clearHover(),
                child: Listener(
                  onPointerDown: (event) {
                    if (interactive) _down(event.localPosition, cell);
                  },
                  onPointerMove: (event) {
                    if (interactive) {
                      _move(event.localPosition, cell, event.buttons != 0);
                    }
                  },
                  onPointerHover: (event) {
                    if (interactive) _hover(event.localPosition, cell);
                  },
                  onPointerUp: (_) {
                    if (interactive) _up();
                  },
                  onPointerCancel: (_) {
                    if (interactive) _up();
                  },
                  child: CustomPaint(
                    painter: MapPainter(controller),
                    size: Size(w, h),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  (int, int) _cell(Offset p, double cell) {
    final int x = (p.dx / cell).floor().clamp(0, MAPX - 1);
    final int y = (p.dy / cell).floor().clamp(0, MAPY - 1);
    return (x, y);
  }

  void _down(Offset p, double cell) {
    final (int x, int y) = _cell(p, cell);
    if (controller.tool == EditorTool.rectangle ||
        controller.tool == EditorTool.line) {
      controller.beginRect(x, y);
    } else if (controller.tool == EditorTool.fill) {
      controller.fillAt(x, y);
    } else if (controller.tool == EditorTool.eyedropper) {
      controller.pickAt(x, y);
    } else if (controller.tool == EditorTool.select) {
      controller.beginSelect(x, y);
    } else {
      controller.beginStroke(x, y);
    }
  }

  void _move(Offset p, double cell, bool pressed) {
    final (int x, int y) = _cell(p, cell);
    controller.setHover(x, y);
    if (!pressed) return;
    if (controller.tool == EditorTool.pencil ||
        controller.tool == EditorTool.eraser) {
      controller.extendStroke(x, y);
    } else if (controller.tool == EditorTool.rectangle ||
        controller.tool == EditorTool.line ||
        controller.tool == EditorTool.select) {
      controller.updateRect(x, y);
    }
  }

  void _hover(Offset p, double cell) {
    final (int x, int y) = _cell(p, cell);
    controller.setHover(x, y);
  }

  void _up() {
    if (controller.tool == EditorTool.pencil ||
        controller.tool == EditorTool.eraser) {
      controller.endStroke();
    } else if (controller.tool == EditorTool.rectangle) {
      controller.commitRect();
    } else if (controller.tool == EditorTool.line) {
      controller.commitLine();
    } else if (controller.tool == EditorTool.select) {
      controller.commitSelection();
    }
  }
}
