import 'package:flutter/material.dart';
import 'package:lcs_new_age/sitemode/sitemap.dart';

// The drawing tools available in the map editor. `pan` is a navigation mode
// (drag to pan, ctrl+scroll to zoom) rather than a paint tool.
enum EditorTool {
  pencil,
  line,
  rectangle,
  fill,
  eraser,
  eyedropper,
  select,
  pan
}

// The mutually-exclusive terrain identities a tile can have. These map onto the
// SITEBLOCK_* flag bits and onto the CSV tile ids on export.
enum TerrainKind {
  floor,
  wall,
  metalWall,
  door,
  exit,
  grass,
  chainlink,
  restricted,
}

// Grouping used to organize the specials palette into readable sections.
enum SpecialCategory {
  navigation,
  objective,
  security,
  containment,
  industry,
  furniture,
}

// Terrain kinds that an objective/special can never sit on. Painting one of
// these clears any special on the tile, so a special can never be hidden
// beneath (and silently exported under) an opaque tile.
const Set<TerrainKind> _opaqueKinds = {
  TerrainKind.wall,
  TerrainKind.metalWall,
  TerrainKind.chainlink,
  TerrainKind.door,
  TerrainKind.exit,
};

// Sets a tile's terrain to [kind], clearing every conflicting terrain bit first
// so contradictory tiles (e.g. wall+door) can't be produced.
void applyTerrain(SiteTile tile, TerrainKind kind) {
  const int clearMask = SITEBLOCK_BLOCK |
      SITEBLOCK_DOOR |
      SITEBLOCK_LOCKED |
      SITEBLOCK_EXIT |
      SITEBLOCK_GRASSY |
      SITEBLOCK_CHAINLINK |
      SITEBLOCK_METAL |
      SITEBLOCK_ALARMED |
      SITEBLOCK_RESTRICTED;
  tile.flag &= ~clearMask;
  tile.flag |= switch (kind) {
    TerrainKind.floor => 0,
    TerrainKind.wall => SITEBLOCK_BLOCK,
    TerrainKind.metalWall => SITEBLOCK_BLOCK | SITEBLOCK_METAL,
    TerrainKind.door => SITEBLOCK_DOOR,
    TerrainKind.exit => SITEBLOCK_EXIT,
    TerrainKind.grass => SITEBLOCK_GRASSY,
    TerrainKind.chainlink => SITEBLOCK_CHAINLINK,
    TerrainKind.restricted => SITEBLOCK_RESTRICTED,
  };
  if (_opaqueKinds.contains(kind)) tile.special = TileSpecial.none;
}

// Paints a door with independently-combinable modifiers. Locked, alarmed and
// metal are separate flag bits (matching the game), not mutually exclusive.
void applyDoor(SiteTile tile,
    {required bool locked, required bool alarmed, required bool metal}) {
  const int clearMask = SITEBLOCK_BLOCK |
      SITEBLOCK_DOOR |
      SITEBLOCK_LOCKED |
      SITEBLOCK_EXIT |
      SITEBLOCK_GRASSY |
      SITEBLOCK_CHAINLINK |
      SITEBLOCK_METAL |
      SITEBLOCK_ALARMED |
      SITEBLOCK_RESTRICTED;
  tile.flag &= ~clearMask;
  tile.flag |= SITEBLOCK_DOOR;
  if (locked) tile.flag |= SITEBLOCK_LOCKED;
  if (alarmed) tile.flag |= SITEBLOCK_ALARMED;
  if (metal) tile.flag |= SITEBLOCK_METAL;
  tile.special = TileSpecial.none;
}

// Resets a tile to plain floor with no special.
void applyEraser(SiteTile tile) {
  applyTerrain(tile, TerrainKind.floor);
  tile.special = TileSpecial.none;
}

// The terrain identity of a tile, used for flood-fill region matching, hover
// labels and palette highlighting.
TerrainKind terrainKindOf(SiteTile tile) {
  if (tile.wall) return tile.metal ? TerrainKind.metalWall : TerrainKind.wall;
  if (tile.door) return TerrainKind.door;
  if (tile.exit) return TerrainKind.exit;
  if (tile.grass) return TerrainKind.grass;
  if (tile.chainlink) return TerrainKind.chainlink;
  if (tile.restricted) return TerrainKind.restricted;
  return TerrainKind.floor;
}

String terrainLabel(TerrainKind kind) => switch (kind) {
      TerrainKind.floor => 'Floor',
      TerrainKind.wall => 'Wall',
      TerrainKind.metalWall => 'Metal wall',
      TerrainKind.door => 'Door',
      TerrainKind.exit => 'Exit',
      TerrainKind.grass => 'Grass',
      TerrainKind.chainlink => 'Chainlink fence',
      TerrainKind.restricted => 'Restricted area',
    };

// Hover/status label including a door's modifiers (e.g. "Locked alarmed door").
String tileTerrainLabel(SiteTile tile) {
  if (tile.door) {
    final List<String> mods = <String>[
      if (tile.locked) 'locked',
      if (tile.alarm) 'alarmed',
      if (tile.metal) 'metal',
    ];
    if (mods.isEmpty) return 'Door';
    final String joined = mods.join(' ');
    return '${joined[0].toUpperCase()}${joined.substring(1)} door';
  }
  return terrainLabel(terrainKindOf(tile));
}

// Swatch/marker color for a terrain kind. Used for BOTH the palette swatch and
// the canvas cell so they always match. Floor/exit/restricted are deliberately
// dark to read well on the black map; the palette swatch adds a border so dark
// colors stay visible on the panel.
Color terrainColor(TerrainKind kind) => switch (kind) {
      TerrainKind.floor => const Color(0xFF24262C),
      TerrainKind.wall => const Color(0xFF6B7079),
      TerrainKind.metalWall => const Color(0xFF4F7FC0),
      TerrainKind.door => const Color(0xFFFFA000),
      TerrainKind.exit => const Color(0xFF31363F),
      TerrainKind.grass => const Color(0xFF5F9F43),
      TerrainKind.chainlink => const Color(0xFF3FA890),
      TerrainKind.restricted => const Color(0xFF2A3A57),
    };

// Door cell color by its modifiers (priority metal > alarmed > locked > plain),
// so the distinct door variants remain visually distinguishable on the map.
Color doorColor(SiteTile tile) {
  if (tile.metal) return const Color(0xFF8FB0E0);
  if (tile.alarm) return const Color(0xFFE0683A);
  if (tile.locked) return const Color(0xFFFF4136);
  return const Color(0xFFFFA000);
}

// Marker color for a special, keyed by its palette category.
Color specialCategoryColor(SpecialCategory category) => switch (category) {
      SpecialCategory.navigation => const Color(0xFF5B9BDD),
      SpecialCategory.objective => const Color(0xFF9A8CF0),
      SpecialCategory.security => const Color(0xFFE2706F),
      SpecialCategory.containment => const Color(0xFFE08A5E),
      SpecialCategory.industry => const Color(0xFFE0A23A),
      SpecialCategory.furniture => const Color(0xFFB6BAC2),
    };

// A selectable brush in the palette. Terrain brushes set the tile's terrain;
// special brushes stamp an objective/feature without touching terrain.
sealed class EditorBrush {
  const EditorBrush();
  String get label;
  Color get color;
  String get glyph;
  void apply(SiteTile tile);
}

class TerrainBrush extends EditorBrush {
  const TerrainBrush(this.kind, this.label, this.glyph);
  final TerrainKind kind;
  @override
  final String label;
  @override
  final String glyph;
  @override
  Color get color => terrainColor(kind);
  @override
  void apply(SiteTile tile) => applyTerrain(tile, kind);
}

class SpecialBrush extends EditorBrush {
  const SpecialBrush(this.special, this.category, this.label, this.glyph);
  final TileSpecial special;
  final SpecialCategory category;
  @override
  final String label;
  @override
  final String glyph;
  @override
  Color get color => specialCategoryColor(category);
  @override
  void apply(SiteTile tile) => tile.special = special;
}

// The curated palette. Terrain covers everything the CSV tile format can store;
// specials are the placeable subset of the canonical id table (see
// sitemap_from_dame.dart). Specials with no CSV id are intentionally absent so
// they can't be painted and then silently dropped on export.
const List<TerrainBrush> terrainBrushes = <TerrainBrush>[
  TerrainBrush(TerrainKind.floor, 'Floor', '.'),
  TerrainBrush(TerrainKind.wall, 'Wall', '#'),
  TerrainBrush(TerrainKind.door, 'Door', '+'),
  TerrainBrush(TerrainKind.metalWall, 'Metal wall', 'H'),
  TerrainBrush(TerrainKind.chainlink, 'Chainlink', '|'),
  TerrainBrush(TerrainKind.grass, 'Grass', '"'),
  TerrainBrush(TerrainKind.restricted, 'Restricted', '%'),
  TerrainBrush(TerrainKind.exit, 'Exit', 'X'),
];

const List<SpecialBrush> specialBrushes = <SpecialBrush>[
  SpecialBrush(
      TileSpecial.stairsUp, SpecialCategory.navigation, 'Stairs up', '^'),
  SpecialBrush(
      TileSpecial.stairsDown, SpecialCategory.navigation, 'Stairs down', 'v'),
  SpecialBrush(TileSpecial.bankVault, SpecialCategory.objective, 'Vault', 'V'),
  SpecialBrush(TileSpecial.bankTeller, SpecialCategory.objective, 'Teller', 'T'),
  SpecialBrush(TileSpecial.bankMoney, SpecialCategory.objective, 'Money', '\$'),
  SpecialBrush(TileSpecial.armory, SpecialCategory.objective, 'Armory', 'A'),
  SpecialBrush(TileSpecial.ceoSafe, SpecialCategory.objective, 'CEO safe', 'S'),
  SpecialBrush(
      TileSpecial.ceoOffice, SpecialCategory.objective, 'CEO office', 'O'),
  SpecialBrush(
      TileSpecial.corporateFiles, SpecialCategory.objective, 'Files', 'F'),
  SpecialBrush(TileSpecial.radioBroadcastStudio, SpecialCategory.objective,
      'Radio studio', 'R'),
  SpecialBrush(TileSpecial.cableBroadcastStudio, SpecialCategory.objective,
      'Cable studio', 'C'),
  SpecialBrush(TileSpecial.intelSupercomputer, SpecialCategory.objective,
      'Intel computer', 'I'),
  SpecialBrush(TileSpecial.nuclearControlRoom, SpecialCategory.objective,
      'Nuclear control', 'N'),
  SpecialBrush(TileSpecial.securityCheckpoint, SpecialCategory.security,
      'Checkpoint', 'K'),
  SpecialBrush(TileSpecial.securityMetalDetectors, SpecialCategory.security,
      'Metal detectors', 'M'),
  SpecialBrush(
      TileSpecial.clubBouncer, SpecialCategory.security, 'Bouncer', 'B'),
  SpecialBrush(TileSpecial.apartmentLandlord, SpecialCategory.security,
      'Landlord', 'L'),
  SpecialBrush(TileSpecial.policeStationLockup, SpecialCategory.containment,
      'Police lockup', 'P'),
  SpecialBrush(TileSpecial.courthouseLockup, SpecialCategory.containment,
      'Courthouse lockup', 'H'),
  SpecialBrush(TileSpecial.courthouseJuryRoom, SpecialCategory.containment,
      'Jury room', 'J'),
  SpecialBrush(TileSpecial.prisonControl, SpecialCategory.containment,
      'Prison control', 'G'),
  SpecialBrush(TileSpecial.cagedRabbits, SpecialCategory.containment,
      'Caged rabbits', 'r'),
  SpecialBrush(TileSpecial.cagedMonsters, SpecialCategory.containment,
      'Caged monsters', 'm'),
  SpecialBrush(TileSpecial.sweatshopEquipment, SpecialCategory.industry,
      'Sweatshop equip.', 'E'),
  SpecialBrush(TileSpecial.polluterEquipment, SpecialCategory.industry,
      'Polluter equip.', 'Q'),
  SpecialBrush(TileSpecial.table, SpecialCategory.furniture, 'Table', '='),
  SpecialBrush(
      TileSpecial.computer, SpecialCategory.furniture, 'Computer', 'c'),
  SpecialBrush(
      TileSpecial.parkBench, SpecialCategory.furniture, 'Park bench', 'b'),
  SpecialBrush(TileSpecial.signOne, SpecialCategory.furniture, 'Sign 1', '1'),
  SpecialBrush(TileSpecial.signTwo, SpecialCategory.furniture, 'Sign 2', '2'),
  SpecialBrush(TileSpecial.signThree, SpecialCategory.furniture, 'Sign 3', '3'),
];

final Map<TileSpecial, SpecialBrush> _specialBrushIndex =
    <TileSpecial, SpecialBrush>{
  for (final SpecialBrush b in specialBrushes) b.special: b,
};

// Marker color for any special on the map. Specials outside the curated palette
// (oval office, "second visit" variants, etc.) still render with a fallback so
// loaded maps display correctly even though they aren't offered as brushes.
Color specialColor(TileSpecial special) =>
    _specialBrushIndex[special]?.color ?? const Color(0xFFCFD3DB);

String specialGlyph(TileSpecial special) =>
    _specialBrushIndex[special]?.glyph ?? '?';

// Display name for a special, used in hover/status. Falls back to the enum name
// for specials that aren't offered as brushes.
String specialLabel(TileSpecial special) =>
    _specialBrushIndex[special]?.label ?? special.name;

// The palette brush that best matches an existing tile, for the eyedropper:
// its special if it has a palette-known one, otherwise its terrain.
EditorBrush? brushForTile(SiteTile tile) {
  if (tile.special != TileSpecial.none) {
    final SpecialBrush? special = _specialBrushIndex[tile.special];
    if (special != null) return special;
  }
  final TerrainKind kind = terrainKindOf(tile);
  for (final TerrainBrush brush in terrainBrushes) {
    if (brush.kind == kind) return brush;
  }
  return null;
}
