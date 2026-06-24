import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lcs_new_age/map_editor/editor_tools.dart';
import 'package:lcs_new_age/map_editor/map_editor_controller.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';

// Draws the current floor of the map. Repaints are driven by the controller
// (a Listenable), so there is no polling redraw loop.
class MapPainter extends CustomPainter {
  MapPainter(this.controller) : super(repaint: controller);

  final MapEditorController controller;

  static const Color _bg = Color(0xFF15171C);
  static const Color _grid = Color(0x14FFFFFF);
  static const Color _player = Color(0xFF7AC77A);
  static const Color _hover = Color(0xCCFFFFFF);

  @override
  void paint(Canvas canvas, Size size) {
    if (controller.previewMode) {
      _paintPreview(canvas, size);
      return;
    }
    final double cell = size.width / MAPX;
    final int z = controller.currentFloor;
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);

    final Paint fill = Paint();
    for (int y = 0; y < MAPY; y++) {
      for (int x = 0; x < MAPX; x++) {
        final SiteTile tile = levelMap[x][y][z];
        fill.color = _cellColor(tile);
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), fill);
        if (tile.special != TileSpecial.none) {
          _drawSpecial(canvas, x, y, cell, tile.special);
        }
      }
    }

    final Paint gridPaint = Paint()
      ..color = _grid
      ..strokeWidth = 1;
    for (int x = 0; x <= MAPX; x += 5) {
      canvas.drawLine(
        Offset(x * cell, 0),
        Offset(x * cell, MAPY * cell),
        gridPaint,
      );
    }
    for (int y = 0; y <= MAPY; y += 5) {
      canvas.drawLine(
        Offset(0, y * cell),
        Offset(MAPX * cell, y * cell),
        gridPaint,
      );
    }

    if (z == 0) _drawPlayerStart(canvas, cell);

    final (int, int)? start = controller.dragStart;
    final (int, int)? current = controller.dragCurrent;
    if (controller.tool == EditorTool.rectangle &&
        start != null &&
        current != null) {
      _drawRectPreview(canvas, cell, start, current);
    }
    if (controller.tool == EditorTool.line &&
        start != null &&
        current != null) {
      _drawLinePreview(canvas, cell, start, current);
    }
    if (controller.tool == EditorTool.select) {
      final (int, int)? selA = controller.selectionStart;
      final (int, int)? selB = controller.selectionEnd;
      if (selA != null && selB != null) {
        _drawSelectionRect(canvas, cell, selA, selB);
      } else if (start != null && current != null) {
        _drawSelectionRect(canvas, cell, start, current);
      }
    }

    final (int, int)? hov = controller.hover;
    if (hov != null) {
      canvas.drawRect(
        Rect.fromLTWH(hov.$1 * cell, hov.$2 * cell, cell, cell),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = _hover,
      );
    }
  }

  // Cell fill color. Matches the palette swatch (terrainColor) for everything
  // except doors, which are colored by their modifiers so locked/alarmed/metal
  // variants stay distinguishable on the map.
  Color _cellColor(SiteTile tile) {
    if (tile.door) return doorColor(tile);
    return terrainColor(terrainKindOf(tile));
  }

  void _drawSpecial(Canvas canvas, int x, int y, double cell, TileSpecial s) {
    final double inset = cell * 0.18;
    final Rect r = Rect.fromLTWH(
      x * cell + inset,
      y * cell + inset,
      cell - 2 * inset,
      cell - 2 * inset,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, Radius.circular(cell * 0.15)),
      Paint()..color = specialColor(s),
    );
    if (cell >= 9) {
      _drawGlyph(canvas, specialGlyph(s), r.center, cell * 0.62, _bg);
    }
  }

  void _drawGlyph(
    Canvas canvas,
    String ch,
    Offset center,
    double fontSize,
    Color color,
  ) {
    final TextPainter tp = TextPainter(
      text: TextSpan(
        text: ch,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawPlayerStart(Canvas canvas, double cell) {
    final double cx = (MAPX >> 1) * cell + cell / 2;
    final double cy = cell * 1.5;
    canvas.drawCircle(
      Offset(cx, cy),
      cell * 0.42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = max(1.5, cell * 0.16)
        ..color = _player,
    );
    canvas.drawCircle(Offset(cx, cy), cell * 0.16, Paint()..color = _player);
  }

  void _drawRectPreview(
    Canvas canvas,
    double cell,
    (int, int) start,
    (int, int) current,
  ) {
    final int sx = min(start.$1, current.$1).clamp(0, MAPX - 1);
    final int ex = max(start.$1, current.$1).clamp(0, MAPX - 1);
    final int sy = min(start.$2, current.$2).clamp(0, MAPY - 1);
    final int ey = max(start.$2, current.$2).clamp(0, MAPY - 1);
    final Rect r = Rect.fromLTWH(
      sx * cell,
      sy * cell,
      (ex - sx + 1) * cell,
      (ey - sy + 1) * cell,
    );
    final Color c = controller.brush?.color ?? Colors.white;
    canvas.drawRect(r, Paint()..color = c.withValues(alpha: 0.25));
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = c,
    );
  }

  void _drawLinePreview(
    Canvas canvas,
    double cell,
    (int, int) start,
    (int, int) current,
  ) {
    final Color c = controller.brush?.color ?? Colors.white;
    final Paint p = Paint()..color = c.withValues(alpha: 0.5);
    int x = start.$1;
    int y = start.$2;
    final int x1 = current.$1;
    final int y1 = current.$2;
    final int dx = (x1 - x).abs();
    final int dy = (y1 - y).abs();
    final int sx = x < x1 ? 1 : -1;
    final int sy = y < y1 ? 1 : -1;
    int err = dx - dy;
    while (true) {
      canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), p);
      if (x == x1 && y == y1) break;
      final int e2 = 2 * err;
      if (e2 > -dy) {
        err -= dy;
        x += sx;
      }
      if (e2 < dx) {
        err += dx;
        y += sy;
      }
    }
  }

  void _drawSelectionRect(
    Canvas canvas,
    double cell,
    (int, int) a,
    (int, int) b,
  ) {
    final int sx = min(a.$1, b.$1).clamp(0, MAPX - 1);
    final int ex = max(a.$1, b.$1).clamp(0, MAPX - 1);
    final int sy = min(a.$2, b.$2).clamp(0, MAPY - 1);
    final int ey = max(a.$2, b.$2).clamp(0, MAPY - 1);
    final Rect r = Rect.fromLTWH(
      sx * cell,
      sy * cell,
      (ex - sx + 1) * cell,
      (ey - sy + 1) * cell,
    );
    canvas.drawRect(r, Paint()..color = const Color(0x3355C9FF));
    canvas.drawRect(
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF55C9FF),
    );
  }

  // Read-only walk-through: only explored tiles show; tiles outside current
  // line of sight are dimmed; specials show when in sight; the player is "@".
  void _paintPreview(Canvas canvas, Size size) {
    final double cell = size.width / MAPX;
    final int z = controller.currentFloor;
    canvas.drawRect(Offset.zero & size, Paint()..color = _bg);
    final Paint fill = Paint();
    for (int y = 0; y < MAPY; y++) {
      for (int x = 0; x < MAPX; x++) {
        if (!controller.explored.contains((x, y, z))) continue;
        final SiteTile tile = levelMap[x][y][z];
        final bool visible = controller.visibleInPreview(x, y);
        Color base = _cellColor(tile);
        if (!visible) base = Color.lerp(base, _bg, 0.55) ?? base;
        fill.color = base;
        canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell, cell), fill);
        if (visible && tile.special != TileSpecial.none) {
          _drawSpecial(canvas, x, y, cell, tile.special);
        }
      }
    }
    final double px = controller.playerX * cell + cell / 2;
    final double py = controller.playerY * cell + cell / 2;
    if (cell >= 9) {
      _drawGlyph(canvas, '@', Offset(px, py), cell * 0.85, _player);
    } else {
      canvas.drawCircle(Offset(px, py), cell * 0.35, Paint()..color = _player);
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) => false;
}
