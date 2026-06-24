import 'dart:async';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/main.dart';
import 'package:lcs_new_age/map_editor/editor_tools.dart';
import 'package:lcs_new_age/map_editor/map_canvas.dart';
import 'package:lcs_new_age/map_editor/map_editor_controller.dart';
import 'package:lcs_new_age/map_editor/tile_palette.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';
import 'package:lcs_new_age/sitemode/sitemap_from_dame.dart';

Future<void> mapEditor() async {
  final NavigatorState? nav = MainApp.navigatorKey.currentState;
  if (nav == null) return;
  await nav.push(
    MaterialPageRoute<void>(
      builder: (context) => const MapEditorScreen(),
      fullscreenDialog: true,
    ),
  );
}

class MapEditorScreen extends StatefulWidget {
  const MapEditorScreen({super.key, this.directLaunch = false});

  final bool directLaunch;

  @override
  State<MapEditorScreen> createState() => _MapEditorScreenState();
}

class _MapEditorScreenState extends State<MapEditorScreen> {
  late final MapEditorController controller;
  late final List<SiteType> sites;
  final FocusNode focusNode = FocusNode();
  final TransformationController _transform = TransformationController();
  Set<SiteType> _sitesWithMap = <SiteType>{};

  @override
  void initState() {
    super.initState();
    sites = SiteType.values
        .where(
          (t) =>
              t != SiteType.downtown &&
              t != SiteType.commercialDistrict &&
              t != SiteType.universityDistrict &&
              t != SiteType.industrialDistrict &&
              t != SiteType.outOfTown,
        )
        .toList();
    controller = MapEditorController(SiteType.bank);
    unawaited(controller.loadSiteType(SiteType.bank));
    unawaited(_loadMapStatus());
  }

  // Records which sites ship a bundled map, so the dropdown can flag them.
  Future<void> _loadMapStatus() async {
    final List<String> assets = (await assetManifest).listAssets();
    final Set<SiteType> withMap = <SiteType>{};
    for (final SiteType t in sites) {
      final String name = dameMapNameForSiteType(t);
      if (name.isNotEmpty &&
          assets.contains('assets/maps/mapCSV_${name}_Tiles.csv')) {
        withMap.add(t);
      }
    }
    if (!mounted) return;
    setState(() => _sitesWithMap = withMap);
  }

  @override
  void dispose() {
    controller.dispose();
    focusNode.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _resetView() {
    _transform.value = _transform.value.clone()..setIdentity();
  }

  void _togglePreview() {
    if (controller.previewMode) {
      controller.exitPreview();
    } else {
      controller.enterPreview();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: editorBg,
      body: SafeArea(
        child: Focus(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: _onKey,
          child: Column(
            children: [
              _live(_topBar),
              _live(_toolStrip),
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: editorBg,
                  padding: const EdgeInsets.all(10),
                  child: MapCanvas(controller, _transform),
                ),
              ),
              Container(
                height: 176,
                width: double.infinity,
                color: editorPanelBg,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: _live(_palette),
              ),
              _live(_statusBar),
            ],
          ),
        ),
      ),
    );
  }

  Widget _live(Widget Function() builder) =>
      ListenableBuilder(listenable: controller, builder: (_, __) => builder());

  Widget _palette() => TilePalette(controller);

  Widget _topBar() {
    return Container(
      color: editorPanelBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.map_outlined, size: 18, color: editorTextSecondary),
          const SizedBox(width: 8),
          const Text(
            'Map editor',
            style: TextStyle(
              color: editorTextPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          _siteDropdown(),
          const SizedBox(width: 16),
          _floorStepper(),
          const Spacer(),
          if (controller.dirty)
            const Padding(
              padding: EdgeInsets.only(right: 10),
              child: Text(
                'Unsaved',
                style: TextStyle(color: Color(0xFFE0A23A), fontSize: 12),
              ),
            ),
          _iconButton(
            Icons.undo,
            'Undo',
            enabled: controller.canUndo,
            onTap: controller.undo,
          ),
          _iconButton(
            Icons.redo,
            'Redo',
            enabled: controller.canRedo,
            onTap: controller.redo,
          ),
          const SizedBox(width: 8),
          _iconButton(
            controller.previewMode ? Icons.visibility_off : Icons.visibility,
            controller.previewMode ? 'Exit preview' : 'Preview (walk-through)',
            onTap: _togglePreview,
          ),
          _iconButton(Icons.checklist, 'Validate map', onTap: _validate),
          _iconButton(
            Icons.upload_file,
            'Import CSV map (.csv files)',
            onTap: () => unawaited(_import()),
          ),
          _iconButton(
            Icons.note_add_outlined,
            'New blank map',
            onTap: controller.newBlankMap,
          ),
          _iconButton(
            Icons.download,
            'Export all floors (.zip)',
            onTap: () => unawaited(_export()),
          ),
          if (!widget.directLaunch)
            _iconButton(
              Icons.close,
              'Close',
              onTap: () => unawaited(Navigator.maybePop(context)),
            ),
        ],
      ),
    );
  }

  Widget _siteDropdown() {
    // Fixed width with isExpanded so the menu is wide enough for the longest
    // "<site name> · has map" entry instead of clipping to the button width.
    return SizedBox(
      width: 300,
      child: DropdownButton<SiteType>(
        value: controller.siteType,
        isExpanded: true,
        dropdownColor: editorPanelBg,
        iconEnabledColor: editorTextSecondary,
        underline: const SizedBox.shrink(),
        style: const TextStyle(color: editorTextPrimary, fontSize: 13),
        // Closed button shows just the name (with its has/no-map dot).
        selectedItemBuilder: (context) => [
          for (final SiteType t in sites) _siteItem(t, compact: true),
        ],
        items: [
          for (final SiteType t in sites)
            DropdownMenuItem<SiteType>(value: t, child: _siteItem(t)),
        ],
        onChanged: (value) {
          if (value != null) unawaited(controller.loadSiteType(value));
        },
      ),
    );
  }

  Widget _siteItem(SiteType type, {bool compact = false}) {
    final bool hasMap = _sitesWithMap.contains(type);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          hasMap ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 13,
          color: hasMap ? const Color(0xFF5FA85A) : editorTextTertiary,
        ),
        const SizedBox(width: 8),
        Text(
          type.name,
          style: TextStyle(
            color: hasMap ? editorTextPrimary : editorTextSecondary,
            fontSize: 13,
          ),
        ),
        if (!compact && hasMap) ...[
          const SizedBox(width: 8),
          const Text(
            '· has map',
            style: TextStyle(color: Color(0xFF5FA85A), fontSize: 11),
          ),
        ],
      ],
    );
  }

  Widget _floorStepper() {
    return Row(
      children: [
        _iconButton(
          Icons.keyboard_arrow_down,
          'Lower floor',
          enabled: controller.currentFloor > 0,
          onTap: () => controller.setFloor(controller.currentFloor - 1),
        ),
        SizedBox(
          width: 78,
          child: Text(
            'Floor ${controller.currentFloor + 1} / ${controller.floorCount}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: editorTextPrimary, fontSize: 13),
          ),
        ),
        _iconButton(
          Icons.keyboard_arrow_up,
          'Higher floor',
          enabled: controller.currentFloor < controller.floorCount - 1,
          onTap: () => controller.setFloor(controller.currentFloor + 1),
        ),
        _iconButton(
          Icons.add,
          'Add floor',
          enabled: controller.canAddFloor,
          onTap: controller.addFloor,
        ),
      ],
    );
  }

  Widget _toolStrip() {
    final bool sel = controller.hasSelection;
    final bool clip = controller.hasClipboard;
    return Container(
      color: editorPanelBg,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolButton(Icons.edit, EditorTool.pencil, 'Pencil (P)'),
            _toolButton(Icons.timeline, EditorTool.line, 'Line (L)'),
            _toolButton(
              Icons.crop_square,
              EditorTool.rectangle,
              'Rectangle (R)',
            ),
            _toolButton(Icons.format_color_fill, EditorTool.fill, 'Fill (F)'),
            _toolButton(
              Icons.backspace_outlined,
              EditorTool.eraser,
              'Eraser (E)',
            ),
            _toolButton(
              Icons.colorize,
              EditorTool.eyedropper,
              'Eyedropper (I)',
            ),
            _toolButton(Icons.highlight_alt, EditorTool.select, 'Select (S)'),
            const SizedBox(width: 10),
            _toolButton(
              Icons.pan_tool_outlined,
              EditorTool.pan,
              'Pan / zoom — drag to pan, ctrl+scroll to zoom',
            ),
            _iconButton(Icons.fit_screen, 'Reset view', onTap: _resetView),
            if (controller.tool == EditorTool.select) ...[
              const SizedBox(width: 10),
              _iconButton(
                Icons.copy,
                'Copy (Ctrl+C)',
                enabled: sel,
                onTap: controller.copySelection,
              ),
              _iconButton(
                Icons.content_cut,
                'Cut (Ctrl+X)',
                enabled: sel,
                onTap: controller.cutSelection,
              ),
              _iconButton(
                Icons.content_paste,
                'Paste (Ctrl+V)',
                enabled: clip,
                onTap: controller.pasteClipboard,
              ),
              _iconButton(
                Icons.delete_outline,
                'Delete (Del)',
                enabled: sel,
                onTap: controller.deleteSelection,
              ),
              _iconButton(
                Icons.swap_horiz,
                'Mirror horizontal',
                enabled: sel,
                onTap: () => controller.mirrorSelection(horizontal: true),
              ),
              _iconButton(
                Icons.swap_vert,
                'Mirror vertical',
                enabled: sel,
                onTap: () => controller.mirrorSelection(horizontal: false),
              ),
              _iconButton(
                Icons.rotate_90_degrees_cw,
                'Rotate 90°',
                enabled: sel,
                onTap: controller.rotateSelection,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toolButton(IconData icon, EditorTool tool, String tip) {
    final bool active = controller.tool == tool;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Tooltip(
        message: tip,
        child: GestureDetector(
          onTap: () => controller.selectTool(tool),
          child: Container(
            width: 40,
            height: 34,
            decoration: BoxDecoration(
              color: active ? editorChipActiveBg : editorChipBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: active ? editorAccent : editorBorder),
            ),
            child: Icon(
              icon,
              size: 18,
              color: active ? editorAccent : editorTextSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(
    IconData icon,
    String tip, {
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Tooltip(
      message: tip,
      child: IconButton(
        icon: Icon(icon, size: 18),
        color: editorTextSecondary,
        disabledColor: editorBorder,
        splashRadius: 18,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        onPressed: enabled ? onTap : null,
      ),
    );
  }

  Widget _statusBar() {
    if (controller.previewMode) {
      return Container(
        color: editorChipActiveBg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.directions_walk, size: 14, color: editorAccent),
            const SizedBox(width: 6),
            Text(
              'Preview — arrow keys move, Esc exits · Floor '
              '${controller.currentFloor + 1}/${controller.floorCount} · '
              'pos (${controller.playerX}, ${controller.playerY})',
              style: const TextStyle(color: editorTextPrimary, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return Container(
      color: editorPanelBg,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.my_location, size: 14, color: editorTextTertiary),
          const SizedBox(width: 5),
          Text(
            _hoverText(),
            style: const TextStyle(color: editorTextSecondary, fontSize: 12),
          ),
          const SizedBox(width: 18),
          Text(
            'Paint: ${controller.brush?.label ?? 'none'}',
            style: const TextStyle(color: editorTextSecondary, fontSize: 12),
          ),
          const Spacer(),
          Text(
            '$MAPX × $MAPY · Floor ${controller.currentFloor + 1}/${controller.floorCount}',
            style: const TextStyle(color: editorTextTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _hoverText() {
    final (int, int)? hov = controller.hover;
    if (hov == null) return 'Hover the map';
    final SiteTile tile = levelMap[hov.$1][hov.$2][controller.currentFloor];
    final String desc = tile.special != TileSpecial.none
        ? specialLabel(tile.special)
        : tileTerrainLabel(tile);
    final int specialId = csvIdForSpecial(tile.special);
    final String ids = specialId > 0
        ? 'tile ${csvIdForTile(tile)}, special $specialId'
        : 'tile ${csvIdForTile(tile)}';
    return '(${hov.$1}, ${hov.$2}) — $desc  [$ids]';
  }

  // True when a text field (e.g. the specials filter) has focus, so editor
  // shortcuts must defer to it rather than swallowing the keystrokes.
  bool _isEditingText() {
    final BuildContext? ctx = FocusManager.instance.primaryFocus?.context;
    return ctx != null &&
        ctx.findAncestorStateOfType<EditableTextState>() != null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_isEditingText()) return KeyEventResult.ignored;
    final bool ctrl =
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final LogicalKeyboardKey key = event.logicalKey;
    if (controller.previewMode) {
      if (key == LogicalKeyboardKey.escape) {
        controller.exitPreview();
      } else if (key == LogicalKeyboardKey.arrowUp) {
        controller.movePlayer(0, -1);
      } else if (key == LogicalKeyboardKey.arrowDown) {
        controller.movePlayer(0, 1);
      } else if (key == LogicalKeyboardKey.arrowLeft) {
        controller.movePlayer(-1, 0);
      } else if (key == LogicalKeyboardKey.arrowRight) {
        controller.movePlayer(1, 0);
      } else {
        return KeyEventResult.ignored;
      }
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyZ) {
      controller.undo();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyY) {
      controller.redo();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyP) {
      controller.selectTool(EditorTool.pencil);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyR) {
      controller.selectTool(EditorTool.rectangle);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyF) {
      controller.selectTool(EditorTool.fill);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyE) {
      controller.selectTool(EditorTool.eraser);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyL) {
      controller.selectTool(EditorTool.line);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyI) {
      controller.selectTool(EditorTool.eyedropper);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyS && !ctrl) {
      controller.selectTool(EditorTool.select);
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyC) {
      controller.copySelection();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyX) {
      controller.cutSelection();
      return KeyEventResult.handled;
    }
    if (ctrl && key == LogicalKeyboardKey.keyV) {
      controller.pasteClipboard();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      controller.deleteSelection();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // Lets the author pick exported mapCSV_*.csv files and load them. Floors are
  // inferred from the filename suffix (e.g. WhiteHouse2 -> floor 2).
  Future<void> _import() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: <String>['csv'],
      withData: true,
    );
    if (result == null) return;
    final RegExp pattern = RegExp(
      r'^mapCSV_(.+?)(\d*)_(Tiles|Specials)\.csv$',
      caseSensitive: false,
    );
    final Map<int, String> tiles = <int, String>{};
    final Map<int, String> specials = <int, String>{};
    String base = '';
    for (final PlatformFile file in result.files) {
      final Uint8List? bytes = file.bytes;
      if (bytes == null) continue;
      final Match? match = pattern.firstMatch(file.name);
      if (match == null) continue;
      base = match.group(1)!;
      final String suffix = match.group(2)!;
      final int z = suffix.isEmpty ? 0 : (int.tryParse(suffix) ?? 1) - 1;
      if (z < 0 || z >= MAPZ) continue;
      final String content = utf8.decode(bytes);
      if (match.group(3)!.toLowerCase() == 'tiles') {
        tiles[z] = content;
      } else {
        specials[z] = content;
      }
    }
    if (!mounted) return;
    if (tiles.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('No mapCSV_*_Tiles.csv files in the selection.'),
        ),
      );
      return;
    }
    controller.loadImportedCsv(base, tiles, specials);
    messenger.showSnackBar(
      SnackBar(content: Text('Imported "$base" (${tiles.length} floor(s)).')),
    );
  }

  void _validate() {
    final List<String> issues = controller.validate();
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: editorPanelBg,
          title: Text(
            issues.isEmpty ? 'No issues found' : '${issues.length} issue(s)',
            style: const TextStyle(color: editorTextPrimary, fontSize: 16),
          ),
          content: issues.isEmpty
              ? const Text(
                  'The map passed all checks.',
                  style: TextStyle(color: editorTextSecondary),
                )
              : SizedBox(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final String issue in issues)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.warning_amber_rounded,
                                size: 16,
                                color: Color(0xFFE0A23A),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  issue,
                                  style: const TextStyle(
                                    color: editorTextSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  // Bundles every floor's Tiles + Specials CSVs into one .zip download. A single
  // download avoids the browser's "multiple automatic downloads" guard, which
  // otherwise silently drops all but the first file.
  Future<void> _export() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final String base = controller.mapBaseName;
      final Archive archive = Archive();
      for (int z = 0; z < controller.floorCount; z++) {
        final String suffix = z == 0 ? '' : (z + 1).toString();
        final List<int> tiles = utf8.encode(_floorCsv(z, specials: false));
        final List<int> specials = utf8.encode(_floorCsv(z, specials: true));
        archive.addFile(
          ArchiveFile('mapCSV_$base${suffix}_Tiles.csv', tiles.length, tiles),
        );
        archive.addFile(
          ArchiveFile(
            'mapCSV_$base${suffix}_Specials.csv',
            specials.length,
            specials,
          ),
        );
      }
      final List<int>? zipped = ZipEncoder().encode(archive);
      if (zipped == null) throw Exception('Zip encoding produced no data');
      await FileSaver.instance.saveFile(
        name: 'mapCSV_$base.zip',
        bytes: Uint8List.fromList(zipped),
        mimeType: MimeType.zip,
      );
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${controller.floorCount} floor(s) to mapCSV_$base.zip',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  String _floorCsv(int z, {required bool specials}) {
    final StringBuffer buffer = StringBuffer();
    for (int y = 0; y < MAPY; y++) {
      final List<String> row = <String>[];
      for (int x = 0; x < MAPX; x++) {
        final SiteTile tile = levelMap[x][y][z];
        row.add(
          (specials ? csvIdForSpecial(tile.special) : csvIdForTile(tile))
              .toString(),
        );
      }
      buffer.writeln(row.join(','));
    }
    return buffer.toString();
  }
}
