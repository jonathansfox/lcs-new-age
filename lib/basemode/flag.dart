import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:lcs_new_age/common_actions/common_actions.dart';
import 'package:lcs_new_age/common_actions/equipment.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/engine/console.dart';
import 'package:lcs_new_age/engine/console_graphic.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/items/flag.dart';
import 'package:lcs_new_age/items/flag_type.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart' hide Alignment;
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart' as lcs;
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:pixel_snap/material.dart' hide Key;

Future<void> prideOrProtest(Site loc) async {
  bool sieged = loc.siege.underSiege;
  bool policeSiege = sieged && loc.siege.activeSiegeType == SiegeType.police;
  if (policeSiege && loc.hasFlag) {
    FlagType flag = loc.flyingFlag!;
    if (flag.burns) {
      if (!loc.siege.flagBurnUsed) {
        await burnFlag(loc);
        return;
      }
    } else {
      // Non-US flags can be waved as often as you like; only the first wave of
      // the siege has any impact.
      await waveFlag(loc);
      return;
    }
    // The flag's protest is spent; only allow swapping to owned flags.
    await selectAndFlyFlag(loc, ownedOnly: true);
    return;
  }
  // Out of a siege you can buy/craft any flag; during a siege only inventory
  // flags may be raised.
  await selectAndFlyFlag(loc, ownedOnly: sieged);
}

bool flagOwned(Site loc, FlagType flag) =>
    loc.loot.any((i) => i is Flag && i.type.idName == flag.idName);

(String, Color) flagSecrecyText(FlagType flag, {bool enabled = true}) {
  int s = -flagSecrecyWhenFlying(flag);
  Color c;
  if (!enabled) {
    c = darkGray;
  } else if (s > 0) {
    c = red;
  } else if (s < 0) {
    c = lightGreen;
  } else {
    c = lightGray;
  }
  if (s > 0) {
    return ("+$s", c);
  } else if (s < 0) {
    return ("$s", c);
  } else {
    return ("0", c);
  }
}

void flagMenuDetail(
  FlagType flag, {
  int? difficulty,
  required String costLine,
  required Color costColor,
}) {
  const int x = 40;
  int row = 18;
  if (flag.description.isNotEmpty) {
    setColor(darkGray);
    addparagraph(row, x, flag.description, y2: 21, x2: CONSOLE_WIDTH - 1);
    row = console.y + 1;
  }
  row = 20;
  mvaddstrx(row, x, "&wIssue: &G${flag.view.label}");
  row++;
  mvaddstrc(row, x, lightGray, "Heat: ");
  var (secrecyText, secrecyColor) = flagSecrecyText(flag);
  addstrc(secrecyColor, secrecyText);
  if (difficulty != null) {
    mvaddstrc(row, x, lightGray, "Difficulty: ");
    addDifficultyText(row, x + 12, difficulty);
  }
  row++;
  mvaddstrc(row, x, lightGray, "Cost: ");
  addstrc(costColor, costLine);
}

Future<void> selectAndFlyFlag(Site loc, {bool ownedOnly = false}) async {
  List<FlagType> flags = flagTypes.values
      .where(
        (f) =>
            flagOwned(loc, f) ||
            f.buyable ||
            (loc.hasFlag && f.idName == loc.flyingFlagId),
      )
      .toList();
  if (flags.isEmpty) return;

  bool isFlying(FlagType flag) =>
      loc.hasFlag && flag.idName == loc.flyingFlagId;
  bool lawBanned(FlagType flag) => !flagOwned(loc, flag) && flagLawBanned(flag);
  bool enabled(FlagType flag) {
    if (isFlying(flag)) return false;
    bool owned = flagOwned(loc, flag);
    if (ownedOnly && !owned) return false;
    if (lawBanned(flag)) return false;
    if (!owned && !flag.buyable) return false;
    if (!owned && ledger.funds < 20) return false;
    return true;
  }

  String costText(FlagType flag) {
    if (isFlying(flag)) return "Flying";
    if (flagOwned(loc, flag)) return "Free";
    if (lawBanned(flag)) return "Banned";
    return "\$20";
  }

  Color costColor(FlagType flag) {
    if (lawBanned(flag)) return red;
    if (!enabled(flag)) return darkGray;
    if (flagOwned(loc, flag)) return lightGreen;
    if (ledger.funds < 20) return red;
    return lightGray;
  }

  String costLine(FlagType flag) {
    if (isFlying(flag)) return "Currently flying";
    if (flagOwned(loc, flag)) return "Cost: Free (in storage)";
    if (lawBanned(flag)) return "Cost: Banned";
    return "Cost: \$20";
  }

  Color costLineColor(FlagType flag) {
    if (isFlying(flag)) return yellow;
    if (flagOwned(loc, flag)) return lightGreen;
    if (lawBanned(flag)) return red;
    return lightGray;
  }

  int selected = 0;
  if (loc.hasFlag) {
    int idx = flags.indexWhere((f) => f.idName == loc.flyingFlagId);
    if (idx >= 0) selected = idx;
  }
  bool confirmed = false;

  String prompt;
  if (loc.hasFlag) {
    prompt = "Change the flag flying over the ${loc.getName(short: true)}:";
  } else {
    prompt = "Fly a flag over the ${loc.getName(short: true)}:";
  }
  String footer;
  if (ownedOnly) {
    footer = "Under siege: only flags already in your inventory can be raised.";
  } else {
    footer =
        "Only a few flags can be bought. Many more can be made by the LCS.";
  }

  await pagedInterface(
    headerPrompt: prompt,
    headerKey: const {0: "FLAG", 40: "ISSUE", 57: "HEAT", 70: "COST"},
    footerPrompt: footer,
    pageSize: 12,
    count: flags.length,
    showBackButton: false,
    lineBuilder: (y, key, index) {
      FlagType flag = flags[index];
      bool en = enabled(flag);
      addOptionText(
        y,
        0,
        key,
        "$key - ${flag.name}",
        baseColorKey: index == selected ? ColorKey.white : ColorKey.lightGray,
        enabledWhen: en,
      );
      mvaddstrc(y, 40, lightGray, flag.view.label);
      var (secrecyText, secrecyColor) = flagSecrecyText(flag);
      mvaddstrc(y, 57, secrecyColor, secrecyText);
      mvaddstrc(y, 70, costColor(flag), costText(flag));
      // pagedInterface clears graphics on every redraw, so re-draw the preview
      // (including the flag image) once per frame, on the first row.
      if (key == letterAPlus(0)) {
        FlagType preview = flags[selected];
        renderFlagPreview(
          preview,
          costLine: costLine(preview),
          costColor: costLineColor(preview),
          cancelText: "Escape - Cancel",
        );
        flush();
      }
    },
    onChoice: (index) async {
      if (!enabled(flags[index])) return false;
      selected = index;
      return false;
    },
    onOtherKey: (key) {
      if (key == Key.enter && enabled(flags[selected])) {
        confirmed = true;
        return true;
      }
      return false;
    },
  );
  if (!confirmed) return;

  FlagType chosen = flags[selected];
  // Stow the flag currently on the pole in the safehouse inventory.
  if (loc.hasFlag) {
    loc.loot.add(Flag.fromType(loc.flyingFlag!));
  }
  if (flagOwned(loc, chosen)) {
    Flag inStock = loc.loot.whereType<Flag>().firstWhere(
      (f) => f.type.idName == chosen.idName,
    );
    if (inStock.stackSize > 1) {
      inStock.stackSize--;
    } else {
      loc.loot.remove(inStock);
    }
  } else if (flagCanBePurchased(chosen)) {
    ledger.subtractFunds(20, Expense.compoundUpgrades);
    stats.flagsBought++;
  }
  consolidateLoot(loc.loot);
  loc.hasFlag = true;
  loc.flyingFlagId = chosen.idName;
}

/// Draws the highlighted flag's preview graphic on the left, its stats on the
/// right, and a centered confirm/cancel prompt — the flag-menu equivalent of
/// the clothing screen's detail footer. Called every frame from the menu's
/// lineBuilder because pagedInterface clears graphics on each redraw.
void renderFlagPreview(
  FlagType flag, {
  int? difficulty,
  required String costLine,
  required Color costColor,
  required String cancelText,
}) {
  eraseArea(startY: 16);
  makeDelimiter(y: 16);
  _drawFlagGraphic(flag, top: 17, left: 10);
  mvaddstrc(17, 40, white, flag.name);
  flagMenuDetail(
    flag,
    difficulty: difficulty,
    costLine: costLine,
    costColor: costColor,
  );
  setColor(white);
  String enterText = "Enter - Confirm Selection";
  String fullText = "$enterText   $cancelText";
  move(23, centerString(fullText));
  addInlineOptionText("Enter", enterText);
  addstr("  ");
  addInlineOptionText("Escape", cancelText);
}

Future<void> burnFlag(Site loc) async {
  FlagType flag = loc.flyingFlag!;
  if (laws[Law.flagBurning]! <= DeepAlignment.moderate) {
    criminalizeAll(loc.creaturesPresent, Crime.flagBurning);
  }

  if (loc.siege.underSiege && loc.siege.activeSiegeType == SiegeType.police) {
    int impact = 2;
    int notoriety = 0;
    if (laws[Law.flagBurning]! <= DeepAlignment.moderate) {
      impact += 2;
    }
    if (laws[Law.flagBurning]! <= DeepAlignment.conservative) {
      impact += 4;
      notoriety += 6;
    }
    if (laws[Law.flagBurning]! <= DeepAlignment.archConservative) {
      impact += 10;
      notoriety += 20;
    }
    changePublicOpinion(lcs.View.lcsKnown, impact + notoriety);
    changePublicOpinion(flag.view, impact, coloredByLcsOpinions: true);
    loc.siege.flagBurnUsed = true;
  }
  await burnFlagAnimation(flag);
  loc.hasFlag = false;
  stats.flagsBurned++;
}

Future<void> waveFlag(Site loc) async {
  if (!(loc.siege.underSiege &&
      loc.siege.activeSiegeType == SiegeType.police)) {
    return;
  }
  FlagType flag = loc.flyingFlag!;
  // Only the first wave of a siege has an impact; afterwards waving just
  // replays the animation for the player.
  if (!loc.siege.flagWaveUsed) {
    int impact = 4;
    changePublicOpinion(lcs.View.lcsKnown, impact);
    changePublicOpinion(flag.view, impact, coloredByLcsOpinions: true);
    for (Creature p in pool.where((p) => p.location == loc)) {
      addjuice(p, 10, 100);
    }
    loc.siege.flagWaveUsed = true;
  }
  await waveFlagAnimation(flag);
}

// The footprint a flag is given on screen (the base-mode US flag area).
const double _flagSpaceWidth = 24.5;
const double _flagHeight = 5.5;

void _drawFlagGraphic(
  FlagType flag, {
  required double top,
  required double left,
  double width = _flagSpaceWidth,
  Widget? child,
  Widget Function(SvgPicture svg)? wrap,
}) {
  Widget graphic =
      child ??
      (wrap != null
          ? wrap(SvgPicture.asset(flag.assetPath, fit: BoxFit.contain))
          : SvgPicture.asset(flag.assetPath, fit: BoxFit.contain));
  console.addGraphic(
    ConsoleGraphic(top, left, top + _flagHeight, left + width, graphic),
  );
}

Future<void> burnFlagAnimation(FlagType flag) async {
  Duration duration = const Duration(milliseconds: 1500);
  _drawFlagGraphic(
    flag,
    top: 10,
    left: 27.25,
    wrap: (svg) =>
        FlagBurningAnimation(svg, BurnData(29, 15), duration: duration),
  );
  console.flush();
  await Future.delayed(duration);
}

Future<void> waveFlagAnimation(FlagType flag) async {
  Duration duration = const Duration(milliseconds: 4000);
  Duration period = const Duration(milliseconds: 500);
  _drawFlagGraphic(
    flag,
    top: 10,
    left: 27.25,
    child: FlagGleamAnimation(
      assetPath: flag.assetPath,
      duration: duration,
      period: period,
    ),
  );
  console.flush();
  await Future.delayed(duration);
}

/// Renders the flag flying over the safehouse on the base mode screen.
void printFlag([FlagType? flag]) {
  flag ??= flagTypes['FLAG_US'];
  if (flag == null) return;
  _drawFlagGraphic(flag, top: 10, left: 27.25);
}

class FlagGlyph {
  FlagGlyph(this.fg, this.bg, this.char, this.ignitionState);
  Color fg;
  Color bg;
  String char;
  int ignitionState;
}

class FlagBurningAnimation extends StatefulWidget {
  const FlagBurningAnimation(
    this.flag,
    this.burnData, {
    this.duration = const Duration(seconds: 5),
    super.key,
  });
  final SvgPicture flag;
  final BurnData burnData;
  final Duration duration;

  @override
  State createState() => _FlagBurningAnimationState();
}

class _FlagBurningAnimationState extends State<FlagBurningAnimation>
    with TickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> animation = CurvedAnimation(
    parent: animationController,
    curve: Curves.easeIn,
  );

  @override
  void initState() {
    super.initState();
    unawaited(animationController.forward());
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned.fill(child: widget.flag),
      Positioned.fill(
        child: AnimatedBuilder(
          animation: animationController,
          builder: (context, child) => CustomPaint(
            painter: BurnPainter(widget.burnData..tickUntil(animation.value)),
          ),
        ),
      ),
    ],
  );
}

/// A gleam of light sweeping across the flag, played when a flag is waved in
/// defiance during a siege.
class FlagGleamAnimation extends StatefulWidget {
  const FlagGleamAnimation({
    required this.assetPath,
    required this.duration,
    required this.period,
    super.key,
  });
  final String assetPath;

  /// Total time the gleam plays; the sweep repeats for this whole span.
  final Duration duration;

  /// Time for one sweep of the bands across the flag.
  final Duration period;

  @override
  State createState() => _FlagGleamAnimationState();
}

class _FlagGleamAnimationState extends State<FlagGleamAnimation>
    with TickerProviderStateMixin {
  late final AnimationController animationController = AnimationController(
    vsync: this,
    duration: widget.duration,
  );

  @override
  void initState() {
    super.initState();
    unawaited(animationController.forward());
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: animationController,
    // BlendMode.srcATop clips the gleam to the flag's painted pixels, so the
    // shine only crosses the flag itself and never the transparent letterbox
    // around it. This avoids having to know the flag's aspect ratio.
    builder: (context, child) {
      double v = animationController.value;
      double cycles =
          widget.duration.inMilliseconds / widget.period.inMilliseconds;
      double phase = (v * cycles) % 1.0;
      return ShaderMask(
        blendMode: BlendMode.srcATop,
        shaderCallback: (bounds) => gleamShader(bounds, phase, _gleamFade(v)),
        child: child,
      );
    },
    child: SvgPicture.asset(widget.assetPath, fit: BoxFit.contain),
  );
}

/// Opacity envelope for the gleam: fades in over the first fifth, holds, then
/// fades out over the last fifth.
double _gleamFade(double v) {
  const double edge = 0.2;
  if (v < edge) return v / edge;
  if (v > 1 - edge) return (1 - v) / edge;
  return 1;
}

Shader gleamShader(Rect bounds, double phase, double fade) {
  // Repeating soft black/white bands that brighten and darken the flag as if it
  // were rippling in the wind. The bands are tilted ~15 degrees (tops further
  // right than bottoms) and slide horizontally as `phase` advances, looping
  // seamlessly. `fade` scales their opacity so the effect eases in and out.
  // Drawn with BlendMode.srcATop by the ShaderMask, so it only affects the
  // flag's own pixels.
  double angle = 5 * pi / 180;
  Offset axis = Offset(cos(angle), sin(angle));
  double period = bounds.width / 2;
  // Slide horizontally; advancing a full period keeps the loop seamless.
  Offset from = bounds.topLeft + Offset(phase * period / cos(angle), 0);
  Offset to = from + axis * period;
  double a = 0.3 * fade;
  return ui.Gradient.linear(
    from,
    to,
    [
      Colors.black.withValues(alpha: 0),
      Colors.black.withValues(alpha: a / 2),
      Colors.black.withValues(alpha: a),
      Colors.black.withValues(alpha: a / 2),
      Colors.black.withValues(alpha: 0),
      Colors.white.withValues(alpha: 0),
      Colors.white.withValues(alpha: a / 2),
      Colors.white.withValues(alpha: a),
      Colors.white.withValues(alpha: a / 2),
      Colors.white.withValues(alpha: 0),
    ],
    const [0.0, 0.05, 0.25, 0.45, 0.5, 0.5, 0.55, 0.75, 0.95, 1.0],
    TileMode.repeated,
  );
}

enum BurnState {
  unburned,
  ignition,
  ignition2,
  burning,
  burning2,
  burned,
  burned2,
  burned3,
  gone;

  bool get ignited => this != unburned;
  Color get color {
    switch (this) {
      case unburned:
        return Colors.transparent;
      case ignition:
        return yellow.withValues(alpha: 0.5);
      case ignition2:
        return yellow;
      case burning:
        return red;
      case burning2:
        return darkRed;
      case burned:
        return darkGray;
      case burned2:
        return const Color(0xFF333333);
      case burned3:
        return const Color(0xFF222222);
      case gone:
        return black;
    }
  }
}

class BurnPainter extends CustomPainter {
  BurnPainter(this.burnData);
  BurnData burnData;

  @override
  void paint(Canvas canvas, Size size) {
    double tileWidth = size.width / burnData.width;
    double tileHeight = size.height / burnData.height;
    for (int y = 0; y < burnData.height; y++) {
      for (int x = 0; x < burnData.width; x++) {
        if (burnData.burnNodes[y][x] != BurnState.unburned) {
          canvas.drawRect(
            Rect.fromLTRB(
              (x * tileWidth).floorToDouble(),
              (y * tileHeight).floorToDouble(),
              ((x + 1) * tileWidth).ceilToDouble(),
              ((y + 1) * tileHeight).ceilToDouble(),
            ),
            Paint()
              ..color = burnData.burnNodes[y][x].color
              ..style = PaintingStyle.fill,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class BurnData {
  BurnData(int x, int y) {
    burnNodes = [
      for (int i = 0; i < y; i++)
        [for (int j = 0; j < x; j++) BurnState.unburned],
    ];
  }
  late final List<List<BurnState>> burnNodes;
  int get height => burnNodes.length;
  int get width => burnNodes[0].length;
  int get remaining => burnNodes.fold(
    0,
    (sum, row) =>
        sum +
        row.fold(
          0,
          (sum, state) => sum + (state == BurnState.unburned ? 1 : 0),
        ),
  );

  double get stage => 1 - remaining / (height * width);

  bool get burned =>
      burnNodes.every((row) => row.every((state) => state == BurnState.gone));
  bool get burning =>
      !burned && burnNodes.any((row) => row.any((state) => state.ignited));
  Iterable<BurnState> neighbors(int x, int y) sync* {
    if (x > 0) yield burnNodes[y][x - 1];
    if (x < burnNodes[0].length - 1) yield burnNodes[y][x + 1];
    if (y > 0) yield burnNodes[y - 1][x];
    if (y < burnNodes.length - 1) yield burnNodes[y + 1][x];
  }

  Iterable<(int, int)> nodesThatCanIgnite() sync* {
    bool all = !burning;
    for (int y = 0; y < burnNodes.length; y++) {
      for (int x = 0; x < burnNodes[y].length; x++) {
        BurnState node = burnNodes[y][x];
        if (node == BurnState.unburned &&
            (neighbors(x, y).any((e) => e.ignited) || all)) {
          yield (y, x);
        }
      }
    }
  }

  void tick([bool fast = false]) {
    for (int i = 0; i < burnNodes.length; i++) {
      for (int j = 0; j < burnNodes[i].length; j++) {
        burnNodes[i][j] =
            BurnState.values[min(
              BurnState.gone.index,
              burnNodes[i][j].index + burnNodes[i][j].index.sign,
            )];
      }
    }
    List<(int, int)> toBurn = nodesThatCanIgnite().toList();
    int burnCount = 1;
    if (burning) {
      burnCount = min(fast ? 16 : 11, toBurn.length);
    }
    if (toBurn.isNotEmpty) {
      while (burnCount-- > 0) {
        int y, x;
        int index = lcsRandom(toBurn.length);
        (y, x) = toBurn[index];
        burnNodes[y][x] = BurnState.ignition;
      }
    }
  }

  void tickUntil(double t) {
    tick((t + 0.05) > stage);
  }
}
