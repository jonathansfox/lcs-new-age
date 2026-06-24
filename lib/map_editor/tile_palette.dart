import 'package:flutter/material.dart';
import 'package:lcs_new_age/map_editor/editor_tools.dart';
import 'package:lcs_new_age/map_editor/map_editor_controller.dart';

const Color editorBg = Color(0xFF15171C);
const Color editorPanelBg = Color(0xFF1E2128);
const Color editorChipBg = Color(0xFF272B33);
const Color editorChipActiveBg = Color(0xFF2D3B52);
const Color editorAccent = Color(0xFF5B9BDD);
const Color editorBorder = Color(0xFF353A44);
const Color editorTextPrimary = Color(0xFFE6E8EC);
const Color editorTextSecondary = Color(0xFF9AA0AB);
const Color editorTextTertiary = Color(0xFF6B7079);

// The brush palette: terrain on the left, specials on the right with a filter
// box and its own scrollable, category-grouped list.
class TilePalette extends StatefulWidget {
  const TilePalette(this.controller, {super.key});

  final MapEditorController controller;

  @override
  State<TilePalette> createState() => _TilePaletteState();
}

class _TilePaletteState extends State<TilePalette> {
  final TextEditingController _filter = TextEditingController();
  final ScrollController _scroll = ScrollController();
  String _query = '';

  MapEditorController get controller => widget.controller;

  @override
  void dispose() {
    _filter.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _terrainColumn()),
        const SizedBox(width: 18),
        Expanded(flex: 2, child: _specialsColumn()),
      ],
    );
  }

  Widget _terrainColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Terrain'),
        const SizedBox(height: 6),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final TerrainBrush b in terrainBrushes) _chip(b)
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 10, bottom: 4),
                  child: Text('Door modifiers',
                      style: TextStyle(
                          color: editorTextTertiary,
                          fontSize: 11,
                          letterSpacing: 0.4)),
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _modifierChip('Locked', const Color(0xFFFF4136),
                        controller.doorLocked, controller.toggleDoorLocked),
                    _modifierChip('Alarmed', const Color(0xFFE0683A),
                        controller.doorAlarmed, controller.toggleDoorAlarmed),
                    _modifierChip('Metal', const Color(0xFF8FB0E0),
                        controller.doorMetal, controller.toggleDoorMetal),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _modifierChip(
      String label, Color color, bool active, VoidCallback onToggle) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? editorChipActiveBg : editorChipBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? color : editorBorder, width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
                active
                    ? Icons.check_box_outlined
                    : Icons.check_box_outline_blank,
                size: 14,
                color: active ? color : editorTextTertiary),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: active ? editorTextPrimary : editorTextSecondary,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _specialsColumn() {
    final String q = _query.trim().toLowerCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _label('Specials'),
            const SizedBox(width: 12),
            Expanded(child: _filterField()),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RawScrollbar(
            controller: _scroll,
            thumbVisibility: true,
            thumbColor: const Color(0xFF4A4E57),
            thickness: 7,
            radius: const Radius.circular(4),
            child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.only(right: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final SpecialCategory cat in SpecialCategory.values)
                    ..._categoryBlock(cat, q),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _categoryBlock(SpecialCategory cat, String query) {
    final List<SpecialBrush> matches = [
      for (final SpecialBrush b in specialBrushes)
        if (b.category == cat &&
            (query.isEmpty || b.label.toLowerCase().contains(query)))
          b,
    ];
    if (matches.isEmpty) return const <Widget>[];
    return [
      Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Text(
          _categoryLabel(cat),
          style: const TextStyle(
              color: editorTextTertiary, fontSize: 11, letterSpacing: 0.4),
        ),
      ),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [for (final SpecialBrush b in matches) _chip(b)],
      ),
    ];
  }

  Widget _filterField() {
    return SizedBox(
      height: 30,
      child: TextField(
        controller: _filter,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(color: editorTextPrimary, fontSize: 13),
        cursorColor: editorAccent,
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Filter specials…',
          hintStyle: const TextStyle(color: editorTextTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.search,
              size: 16, color: editorTextTertiary),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 30, minHeight: 30),
          contentPadding: const EdgeInsets.symmetric(vertical: 6),
          filled: true,
          fillColor: editorChipBg,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: editorBorder, width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: editorAccent),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          color: editorTextSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500));

  Widget _chip(EditorBrush brush) {
    final bool active = identical(controller.brush, brush);
    return GestureDetector(
      onTap: () => controller.selectBrush(brush),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: active ? editorChipActiveBg : editorChipBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: active ? editorAccent : editorBorder,
              width: active ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: brush.color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF55585F), width: 0.5),
              ),
            ),
            const SizedBox(width: 7),
            Text(brush.label,
                style: TextStyle(
                    color: active ? editorAccent : editorTextPrimary,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  String _categoryLabel(SpecialCategory c) => switch (c) {
        SpecialCategory.navigation => 'Navigation',
        SpecialCategory.objective => 'Objectives',
        SpecialCategory.security => 'Security',
        SpecialCategory.containment => 'Containment',
        SpecialCategory.industry => 'Industry',
        SpecialCategory.furniture => 'Furniture',
      };
}
