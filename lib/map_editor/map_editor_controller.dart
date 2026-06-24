import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/map_editor/editor_tools.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_dame.dart';

// One reversible change to a single tile, recorded for undo/redo.
class _CellEdit {
  _CellEdit(
    this.x,
    this.y,
    this.z,
    this.oldFlag,
    this.oldSpecial,
    this.newFlag,
    this.newSpecial,
  );
  final int x;
  final int y;
  final int z;
  final int oldFlag;
  final TileSpecial oldSpecial;
  final int newFlag;
  final TileSpecial newSpecial;
}

// A rectangular block of copied tiles (flags + specials), row-major.
class _Clip {
  _Clip(this.width, this.height, this.flags, this.specials);
  final int width;
  final int height;
  final List<int> flags;
  final List<TileSpecial> specials;
}

// Holds all map-editor state and drives repaints via [ChangeNotifier]. The
// editor works directly on the global [levelMap]; every mutation is recorded as
// a stroke so it can be undone.
class MapEditorController extends ChangeNotifier {
  MapEditorController(this.siteType);

  SiteType siteType;
  String mapBaseName = '';
  int floorCount = 1;
  int currentFloor = 0;
  EditorTool tool = EditorTool.pencil;
  EditorBrush? brush;
  bool dirty = false;

  // Door modifiers applied by the Door brush. Independent, not exclusive.
  bool doorLocked = false;
  bool doorAlarmed = false;
  bool doorMetal = false;

  (int, int)? hover;
  (int, int)? dragStart;
  (int, int)? dragCurrent;

  final List<List<_CellEdit>> _undo = [];
  final List<List<_CellEdit>> _redo = [];
  List<_CellEdit>? _active;
  int _lastX = 0;
  int _lastY = 0;

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  bool get canAddFloor => floorCount < MAPZ;

  // Loads the map for a site type into [levelMap], or a blank map if the site
  // has no custom map file.
  Future<void> loadSiteType(SiteType type) async {
    siteType = type;
    final String name = dameMapNameForSiteType(type);
    bool loaded = false;
    if (name.isNotEmpty) {
      loaded = await readDAMEMap(name);
    }
    if (!loaded) {
      for (final SiteTile tile in levelMap.all) {
        tile.flag = 0;
        tile.special = TileSpecial.none;
        tile.siegeflag = 0;
      }
    }
    mapBaseName = name.isNotEmpty ? name : 'CustomMap';
    floorCount = _detectFloorCount();
    currentFloor = 0;
    _undo.clear();
    _redo.clear();
    dirty = false;
    hover = null;
    dragStart = null;
    dragCurrent = null;
    notifyListeners();
  }

  // Loads externally-supplied CSV content (keyed by floor) into [levelMap],
  // replacing the current map. Content is applied through the same callbacks the
  // runtime asset loader uses, so imported maps behave identically in-game.
  void loadImportedCsv(
    String baseName,
    Map<int, String> tilesByFloor,
    Map<int, String> specialsByFloor,
  ) {
    for (final SiteTile tile in levelMap.all) {
      tile.flag = 0;
      tile.special = TileSpecial.none;
      tile.siegeflag = 0;
    }
    tilesByFloor.forEach(
      (z, content) => applyMapCsv(content, z, readMapCBTiles),
    );
    specialsByFloor.forEach(
      (z, content) => applyMapCsv(content, z, readMapCBSpecials),
    );
    mapBaseName = baseName.isNotEmpty ? baseName : 'CustomMap';
    floorCount = _detectFloorCount();
    currentFloor = 0;
    _undo.clear();
    _redo.clear();
    dirty = false;
    _clearDragSilently();
    notifyListeners();
  }

  int _detectFloorCount() {
    for (int z = MAPZ - 1; z >= 1; z--) {
      for (final SiteTile tile in levelMap.allOnFloor(z)) {
        if (tile.flag != 0 || tile.special != TileSpecial.none) {
          return z + 1;
        }
      }
    }
    return 1;
  }

  // Clears every floor to blank floor tiles, keeping the current site type.
  void newBlankMap() {
    for (final SiteTile tile in levelMap.all) {
      tile.flag = 0;
      tile.special = TileSpecial.none;
      tile.siegeflag = 0;
    }
    floorCount = 1;
    currentFloor = 0;
    _undo.clear();
    _redo.clear();
    _clearDragSilently();
    dirty = true;
    notifyListeners();
  }

  void toggleDoorLocked() {
    doorLocked = !doorLocked;
    notifyListeners();
  }

  void toggleDoorAlarmed() {
    doorAlarmed = !doorAlarmed;
    notifyListeners();
  }

  void toggleDoorMetal() {
    doorMetal = !doorMetal;
    notifyListeners();
  }

  // Authoring sanity checks. Returns human-readable warnings (empty == clean).
  List<String> validate() {
    final List<String> issues = <String>[];
    final SiteTile entrance = levelMap[MAPX >> 1][1][0];
    if (entrance.wall ||
        entrance.door ||
        entrance.chainlink ||
        entrance.metal) {
      issues.add(
        'Entrance at (${MAPX >> 1}, 1) is blocked — squads cannot enter.',
      );
    }
    int upOn(int z) => levelMap
        .allOnFloor(z)
        .where((t) => t.special == TileSpecial.stairsUp)
        .length;
    int downOn(int z) => levelMap
        .allOnFloor(z)
        .where((t) => t.special == TileSpecial.stairsDown)
        .length;
    if (downOn(0) > 0) {
      issues.add('Floor 1 has stairs down, but it is the ground floor.');
    }
    if (upOn(floorCount - 1) > 0) {
      issues.add('Floor $floorCount has stairs up, but it is the top floor.');
    }
    for (int z = 0; z < floorCount - 1; z++) {
      final bool up = upOn(z) > 0;
      final bool down = downOn(z + 1) > 0;
      if (up && !down) {
        issues.add(
          'Floor ${z + 1} has stairs up, but floor ${z + 2} has no stairs down.',
        );
      } else if (!up && down) {
        issues.add(
          'Floor ${z + 2} has stairs down, but floor ${z + 1} has no stairs up.',
        );
      } else if (!up && !down) {
        issues.add(
          'Floors ${z + 1} and ${z + 2} have no stairs connecting them.',
        );
      }
    }
    final TileSpecial? objective = _objectiveSpecialFor(siteType);
    if (objective != null && !levelMap.all.any((t) => t.special == objective)) {
      issues.add(
        'This ${siteType.name} map has no '
        '${specialLabel(objective)} (the site objective).',
      );
    }
    final bool entranceImpassable =
        entrance.wall || entrance.metal || entrance.chainlink;
    if (!entranceImpassable) {
      final Set<(int, int, int)> reachable = _reachableTiles();
      for (int z = 0; z < floorCount; z++) {
        for (final SiteTile tile in levelMap.allOnFloor(z)) {
          if (tile.special != TileSpecial.none &&
              !reachable.contains((tile.x, tile.y, z))) {
            issues.add(
              '${specialLabel(tile.special)} at (${tile.x}, '
              '${tile.y}) on floor ${z + 1} is unreachable from the entrance.',
            );
          }
        }
      }
    }
    return issues;
  }

  // The objective special a site type is expected to contain, if any.
  TileSpecial? _objectiveSpecialFor(SiteType type) => switch (type) {
    SiteType.bank => TileSpecial.bankVault,
    SiteType.nuclearPlant => TileSpecial.nuclearControlRoom,
    SiteType.policeStation => TileSpecial.policeStationLockup,
    SiteType.courthouse => TileSpecial.courthouseLockup,
    SiteType.prison => TileSpecial.prisonControl,
    SiteType.intelligenceHQ => TileSpecial.intelSupercomputer,
    SiteType.corporateHQ => TileSpecial.corporateFiles,
    SiteType.ceoHouse => TileSpecial.ceoSafe,
    SiteType.armyBase => TileSpecial.armory,
    SiteType.amRadioStation => TileSpecial.radioBroadcastStudio,
    SiteType.cableNewsStation => TileSpecial.cableBroadcastStudio,
    SiteType.sweatshop => TileSpecial.sweatshopEquipment,
    SiteType.dirtyIndustry => TileSpecial.polluterEquipment,
    _ => null,
  };

  // Flood fill of tiles reachable on foot from the entrance, walking through
  // doors and following stairs between floors. Used to flag sealed-off specials.
  Set<(int, int, int)> _reachableTiles() {
    // Doors (incl. metal/alarmed) are passable; metal walls are blocked via
    // `wall`. Don't treat `metal` as impassable or metal doors get sealed off.
    bool passable(SiteTile t) => !t.wall && !t.chainlink;
    final Set<(int, int, int)> visited = <(int, int, int)>{};
    final List<(int, int, int)> queue = <(int, int, int)>[(MAPX >> 1, 1, 0)];
    while (queue.isNotEmpty) {
      final (int, int, int) p = queue.removeLast();
      if (visited.contains(p)) continue;
      final SiteTile tile = levelMap[p.$1][p.$2][p.$3];
      if (!passable(tile)) continue;
      visited.add(p);
      if (p.$1 + 1 < MAPX) queue.add((p.$1 + 1, p.$2, p.$3));
      if (p.$1 - 1 >= 0) queue.add((p.$1 - 1, p.$2, p.$3));
      if (p.$2 + 1 < MAPY) queue.add((p.$1, p.$2 + 1, p.$3));
      if (p.$2 - 1 >= 0) queue.add((p.$1, p.$2 - 1, p.$3));
      if (tile.special == TileSpecial.stairsUp && p.$3 + 1 < floorCount) {
        queue.add((p.$1, p.$2, p.$3 + 1));
      }
      if (tile.special == TileSpecial.stairsDown && p.$3 - 1 >= 0) {
        queue.add((p.$1, p.$2, p.$3 - 1));
      }
    }
    return visited;
  }

  void selectTool(EditorTool value) {
    tool = value;
    _clearDragSilently();
    notifyListeners();
  }

  void selectBrush(EditorBrush value) {
    brush = value;
    if (tool == EditorTool.eraser) tool = EditorTool.pencil;
    notifyListeners();
  }

  void setFloor(int z) {
    if (z < 0 || z >= floorCount || z == currentFloor) return;
    currentFloor = z;
    _clearDragSilently();
    notifyListeners();
  }

  void addFloor() {
    if (floorCount >= MAPZ) return;
    floorCount++;
    currentFloor = floorCount - 1;
    dirty = true;
    notifyListeners();
  }

  void setHover(int x, int y) {
    if (hover != null && hover!.$1 == x && hover!.$2 == y) return;
    hover = (x, y);
    notifyListeners();
  }

  void clearHover() {
    if (hover == null) return;
    hover = null;
    notifyListeners();
  }

  // --- Walk-through preview --------------------------------------------------

  bool previewMode = false;
  int playerX = MAPX >> 1;
  int playerY = 1;
  final Set<(int, int, int)> explored = <(int, int, int)>{};

  void enterPreview() {
    previewMode = true;
    currentFloor = 0;
    playerX = MAPX >> 1;
    playerY = 1;
    explored.clear();
    _revealAround();
    _clearDragSilently();
    notifyListeners();
  }

  void exitPreview() {
    if (!previewMode) return;
    previewMode = false;
    notifyListeners();
  }

  void movePlayer(int dx, int dy) {
    if (!previewMode) return;
    final int nx = playerX + dx;
    final int ny = playerY + dy;
    if (nx < 0 || nx >= MAPX || ny < 0 || ny >= MAPY) return;
    final SiteTile target = levelMap[nx][ny][currentFloor];
    // Walls and chainlink block movement; doors (incl. metal/alarmed) are
    // passable. Metal walls are caught by `wall`, so checking `metal` here would
    // wrongly block metal doors.
    if (target.wall || target.chainlink) return;
    playerX = nx;
    playerY = ny;
    if (target.special == TileSpecial.stairsUp &&
        currentFloor + 1 < floorCount) {
      currentFloor++;
    } else if (target.special == TileSpecial.stairsDown && currentFloor > 0) {
      currentFloor--;
    }
    _revealAround();
    notifyListeners();
  }

  int _diff(int a, int b) => a > b ? a - b : b - a;

  // Mirrors the game's line-of-sight (site_display.dart `_lineOfSight`): visible
  // within 1 tile; out to 2 tiles only if not blocked on both diagonal corners.
  // Uses `losObstructed` (wall/door/exit) exactly as the game does.
  bool visibleInPreview(int x, int y) {
    final int lx = playerX;
    final int ly = playerY;
    final int z = currentFloor;
    if (x < 0 || y < 0 || x >= MAPX || y >= MAPY) return false;
    if (_diff(x, lx) > 2 || _diff(y, ly) > 2) return false;
    if (_diff(x, lx) <= 1 && _diff(y, ly) <= 1) return true;
    int x1;
    int x2;
    int y1;
    int y2;
    if (_diff(x, lx) == 1) {
      x1 = lx;
      x2 = x;
    } else {
      x1 = x2 = (x + lx) ~/ 2;
    }
    if (_diff(y, ly) == 1) {
      y1 = ly;
      y2 = y;
    } else {
      y1 = y2 = (y + ly) ~/ 2;
    }
    if (levelMap[x1][y2][z].losObstructed &&
        levelMap[x2][y1][z].losObstructed) {
      return false;
    }
    return true;
  }

  void _revealAround() {
    for (int y = 0; y < MAPY; y++) {
      for (int x = 0; x < MAPX; x++) {
        if (visibleInPreview(x, y)) explored.add((x, y, currentFloor));
      }
    }
  }

  // --- Selection & clipboard -------------------------------------------------

  (int, int)? selectionStart;
  (int, int)? selectionEnd;
  _Clip? _clipboard;

  bool get hasSelection => selectionStart != null && selectionEnd != null;
  bool get hasClipboard => _clipboard != null;

  (int, int, int, int)? get _normSelection {
    final (int, int)? a = selectionStart;
    final (int, int)? b = selectionEnd;
    if (a == null || b == null) return null;
    return (min(a.$1, b.$1), min(a.$2, b.$2), max(a.$1, b.$1), max(a.$2, b.$2));
  }

  void beginSelect(int x, int y) {
    selectionStart = null;
    selectionEnd = null;
    dragStart = (x, y);
    dragCurrent = (x, y);
    notifyListeners();
  }

  void commitSelection() {
    final (int, int)? a = dragStart;
    final (int, int)? b = dragCurrent;
    dragStart = null;
    dragCurrent = null;
    if (a == null || b == null) {
      notifyListeners();
      return;
    }
    selectionStart = (a.$1.clamp(0, MAPX - 1), a.$2.clamp(0, MAPY - 1));
    selectionEnd = (b.$1.clamp(0, MAPX - 1), b.$2.clamp(0, MAPY - 1));
    notifyListeners();
  }

  void clearSelection() {
    if (!hasSelection) return;
    selectionStart = null;
    selectionEnd = null;
    notifyListeners();
  }

  void copySelection() {
    final (int, int, int, int)? sel = _normSelection;
    if (sel == null) return;
    final (int sx, int sy, int ex, int ey) = sel;
    final List<int> flags = <int>[];
    final List<TileSpecial> specials = <TileSpecial>[];
    for (int y = sy; y <= ey; y++) {
      for (int x = sx; x <= ex; x++) {
        flags.add(levelMap[x][y][currentFloor].flag);
        specials.add(levelMap[x][y][currentFloor].special);
      }
    }
    _clipboard = _Clip(ex - sx + 1, ey - sy + 1, flags, specials);
    notifyListeners();
  }

  void cutSelection() {
    copySelection();
    deleteSelection();
  }

  void deleteSelection() {
    final (int, int, int, int)? sel = _normSelection;
    if (sel == null) return;
    final (int sx, int sy, int ex, int ey) = sel;
    final List<_CellEdit> stroke = <_CellEdit>[];
    for (int y = sy; y <= ey; y++) {
      for (int x = sx; x <= ex; x++) {
        _setCell(x, y, 0, TileSpecial.none, stroke);
      }
    }
    _pushStroke(stroke);
  }

  void pasteClipboard() {
    final _Clip? clip = _clipboard;
    if (clip == null) return;
    final (int, int, int, int)? sel = _normSelection;
    final int ox = sel?.$1 ?? 1;
    final int oy = sel?.$2 ?? 1;
    final List<_CellEdit> stroke = <_CellEdit>[];
    for (int j = 0; j < clip.height; j++) {
      for (int i = 0; i < clip.width; i++) {
        final int x = ox + i;
        final int y = oy + j;
        if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) continue;
        _setCell(
          x,
          y,
          clip.flags[j * clip.width + i],
          clip.specials[j * clip.width + i],
          stroke,
        );
      }
    }
    _pushStroke(stroke);
  }

  void mirrorSelection({required bool horizontal}) {
    final (int, int, int, int)? sel = _normSelection;
    if (sel == null) return;
    final (int sx, int sy, int ex, int ey) = sel;
    final int w = ex - sx + 1;
    final int h = ey - sy + 1;
    final List<int> flags = <int>[];
    final List<TileSpecial> specials = <TileSpecial>[];
    for (int y = sy; y <= ey; y++) {
      for (int x = sx; x <= ex; x++) {
        flags.add(levelMap[x][y][currentFloor].flag);
        specials.add(levelMap[x][y][currentFloor].special);
      }
    }
    final List<_CellEdit> stroke = <_CellEdit>[];
    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        final int si = horizontal ? w - 1 - i : i;
        final int sj = horizontal ? j : h - 1 - j;
        _setCell(
          sx + i,
          sy + j,
          flags[sj * w + si],
          specials[sj * w + si],
          stroke,
        );
      }
    }
    _pushStroke(stroke);
  }

  // Rotates the selection 90 degrees clockwise about its top-left corner. The
  // selection rectangle is updated to the rotated bounds.
  void rotateSelection() {
    final (int, int, int, int)? sel = _normSelection;
    if (sel == null) return;
    final (int sx, int sy, int ex, int ey) = sel;
    final int w = ex - sx + 1;
    final int h = ey - sy + 1;
    final List<int> flags = <int>[];
    final List<TileSpecial> specials = <TileSpecial>[];
    for (int y = sy; y <= ey; y++) {
      for (int x = sx; x <= ex; x++) {
        flags.add(levelMap[x][y][currentFloor].flag);
        specials.add(levelMap[x][y][currentFloor].special);
      }
    }
    final List<_CellEdit> stroke = <_CellEdit>[];
    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        _setCell(sx + i, sy + j, 0, TileSpecial.none, stroke);
      }
    }
    for (int j = 0; j < h; j++) {
      for (int i = 0; i < w; i++) {
        final int ni = h - 1 - j;
        final int nj = i;
        final int x = sx + ni;
        final int y = sy + nj;
        if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) continue;
        _setCell(x, y, flags[j * w + i], specials[j * w + i], stroke);
      }
    }
    _pushStroke(stroke);
    selectionStart = (sx, sy);
    selectionEnd = (
      (sx + h - 1).clamp(0, MAPX - 1),
      (sy + w - 1).clamp(0, MAPY - 1),
    );
    notifyListeners();
  }

  void _setCell(
    int x,
    int y,
    int flag,
    TileSpecial special,
    List<_CellEdit> stroke,
  ) {
    final SiteTile tile = levelMap[x][y][currentFloor];
    final int oldFlag = tile.flag;
    final TileSpecial oldSpecial = tile.special;
    if (oldFlag == flag && oldSpecial == special) return;
    tile.flag = flag;
    tile.special = special;
    stroke.add(
      _CellEdit(x, y, currentFloor, oldFlag, oldSpecial, flag, special),
    );
  }

  // --- Stroke-based painting -------------------------------------------------

  void beginStroke(int x, int y) {
    _active = <_CellEdit>[];
    _applyAt(x, y, _active!);
    _lastX = x;
    _lastY = y;
    notifyListeners();
  }

  void extendStroke(int x, int y) {
    final List<_CellEdit>? stroke = _active;
    if (stroke == null) return;
    _plotLine(_lastX, _lastY, x, y, stroke);
    _lastX = x;
    _lastY = y;
    notifyListeners();
  }

  void endStroke() {
    final List<_CellEdit>? stroke = _active;
    _active = null;
    if (stroke == null || stroke.isEmpty) {
      notifyListeners();
      return;
    }
    _undo.add(stroke);
    _redo.clear();
    dirty = true;
    notifyListeners();
  }

  void beginRect(int x, int y) {
    dragStart = (x, y);
    dragCurrent = (x, y);
    notifyListeners();
  }

  void updateRect(int x, int y) {
    if (dragStart == null) return;
    dragCurrent = (x, y);
    notifyListeners();
  }

  void commitRect() {
    final (int, int)? start = dragStart;
    final (int, int)? end = dragCurrent;
    dragStart = null;
    dragCurrent = null;
    if (start == null || end == null) {
      notifyListeners();
      return;
    }
    final int sx = min(start.$1, end.$1).clamp(0, MAPX - 1);
    final int ex = max(start.$1, end.$1).clamp(0, MAPX - 1);
    final int sy = min(start.$2, end.$2).clamp(0, MAPY - 1);
    final int ey = max(start.$2, end.$2).clamp(0, MAPY - 1);
    final List<_CellEdit> stroke = <_CellEdit>[];
    for (int yy = sy; yy <= ey; yy++) {
      for (int xx = sx; xx <= ex; xx++) {
        _applyAt(xx, yy, stroke);
      }
    }
    _pushStroke(stroke);
  }

  void commitLine() {
    final (int, int)? start = dragStart;
    final (int, int)? end = dragCurrent;
    dragStart = null;
    dragCurrent = null;
    if (start == null || end == null) {
      notifyListeners();
      return;
    }
    final List<_CellEdit> stroke = <_CellEdit>[];
    _plotLine(start.$1, start.$2, end.$1, end.$2, stroke);
    _pushStroke(stroke);
  }

  // Eyedropper: adopt the brush matching the tile under the cursor, then return
  // to the pencil so the picked brush can be used immediately.
  void pickAt(int x, int y) {
    if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) return;
    final SiteTile tile = levelMap[x][y][currentFloor];
    final EditorBrush? picked = brushForTile(tile);
    if (picked == null) return;
    brush = picked;
    if (picked is TerrainBrush && picked.kind == TerrainKind.door) {
      doorLocked = tile.locked;
      doorAlarmed = tile.alarm;
      doorMetal = tile.metal;
    }
    tool = EditorTool.pencil;
    notifyListeners();
  }

  void fillAt(int x, int y) {
    if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) return;
    final TerrainKind seed = terrainKindOf(levelMap[x][y][currentFloor]);
    final List<_CellEdit> stroke = <_CellEdit>[];
    final Set<(int, int)> visited = <(int, int)>{};
    final List<(int, int)> queue = <(int, int)>[(x, y)];
    while (queue.isNotEmpty) {
      final (int, int) point = queue.removeLast();
      final int px = point.$1;
      final int py = point.$2;
      if (px < 0 || px >= MAPX || py < 0 || py >= MAPY) continue;
      if (visited.contains(point)) continue;
      if (terrainKindOf(levelMap[px][py][currentFloor]) != seed) continue;
      visited.add(point);
      _applyAt(px, py, stroke);
      queue.add((px + 1, py));
      queue.add((px - 1, py));
      queue.add((px, py + 1));
      queue.add((px, py - 1));
    }
    _pushStroke(stroke);
  }

  void undo() {
    if (_undo.isEmpty) return;
    final List<_CellEdit> stroke = _undo.removeLast();
    for (final _CellEdit edit in stroke) {
      final SiteTile tile = levelMap[edit.x][edit.y][edit.z];
      tile.flag = edit.oldFlag;
      tile.special = edit.oldSpecial;
    }
    _redo.add(stroke);
    dirty = true;
    notifyListeners();
  }

  void redo() {
    if (_redo.isEmpty) return;
    final List<_CellEdit> stroke = _redo.removeLast();
    for (final _CellEdit edit in stroke) {
      final SiteTile tile = levelMap[edit.x][edit.y][edit.z];
      tile.flag = edit.newFlag;
      tile.special = edit.newSpecial;
    }
    _undo.add(stroke);
    dirty = true;
    notifyListeners();
  }

  void _pushStroke(List<_CellEdit> stroke) {
    if (stroke.isEmpty) {
      notifyListeners();
      return;
    }
    _undo.add(stroke);
    _redo.clear();
    dirty = true;
    notifyListeners();
  }

  void _applyAt(int x, int y, List<_CellEdit> stroke) {
    if (x < 0 || x >= MAPX || y < 0 || y >= MAPY) return;
    final SiteTile tile = levelMap[x][y][currentFloor];
    final int oldFlag = tile.flag;
    final TileSpecial oldSpecial = tile.special;
    final EditorBrush? b = brush;
    if (tool == EditorTool.eraser) {
      applyEraser(tile);
    } else if (b is TerrainBrush && b.kind == TerrainKind.door) {
      applyDoor(
        tile,
        locked: doorLocked,
        alarmed: doorAlarmed,
        metal: doorMetal,
      );
    } else {
      b?.apply(tile);
    }
    if (tile.flag != oldFlag || tile.special != oldSpecial) {
      stroke.add(
        _CellEdit(
          x,
          y,
          currentFloor,
          oldFlag,
          oldSpecial,
          tile.flag,
          tile.special,
        ),
      );
    }
  }

  // Bresenham line so fast drags don't leave gaps between sampled points.
  void _plotLine(int x0, int y0, int x1, int y1, List<_CellEdit> stroke) {
    int dx = (x1 - x0).abs();
    int dy = (y1 - y0).abs();
    int sx = x0 < x1 ? 1 : -1;
    int sy = y0 < y1 ? 1 : -1;
    int err = dx - dy;
    int x = x0;
    int y = y0;
    while (true) {
      _applyAt(x, y, stroke);
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

  void _clearDragSilently() {
    dragStart = null;
    dragCurrent = null;
  }
}
