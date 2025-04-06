import 'dart:math';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:lcs_new_age/engine/console_graphic.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart' as lcs;
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:pixel_snap/material.dart';

Future<void> prideOrProtest(Site loc) async {
  if (loc.hasFlag) {
    await burnFlag(loc);
  } else if (ledger.funds >= 20 && !loc.siege.underSiege) {
    ledger.subtractFunds(20, Expense.compoundUpgrades);
    loc.hasFlag = true;
    stats.flagsBought++;
  }
}

Future<void> burnFlag(Site loc) async {
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
    changePublicOpinion(lcs.View.freeSpeech, impact,
        coloredByLcsOpinions: true);
  }
  await burnFlagAnimation();
  loc.hasFlag = false;
  stats.flagsBurned++;
}

Future<void> burnFlagAnimation() async {
  Duration duration = const Duration(milliseconds: 3000);
  console.addGraphic(
    ConsoleGraphic(
      10.5,
      27.25,
      16,
      51.75,
      FlagBurningAnimation(
        SvgPicture.asset('assets/flags/Flag_of_the_United_States.svg'),
        BurnData(29, 15),
        duration: duration,
      ),
    ),
  );
  console.flush();
  await Future.delayed(duration);
}

class FlagGlyph {
  FlagGlyph(this.fg, this.bg, this.char, this.ignitionState);
  Color fg;
  Color bg;
  String char;
  int ignitionState;
}

class FlagBurningAnimation extends StatefulWidget {
  const FlagBurningAnimation(this.flag, this.burnData,
      {this.duration = const Duration(seconds: 5), super.key});
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
    animationController.forward();
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: widget.flag),
        Positioned.fill(
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) => CustomPaint(
                painter:
                    BurnPainter(widget.burnData..tickUntil(animation.value))),
          ),
        ),
      ]);
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
        [for (int j = 0; j < x; j++) BurnState.unburned]
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
              0, (sum, state) => sum + (state == BurnState.unburned ? 1 : 0)));

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
        burnNodes[i][j] = BurnState.values[min(BurnState.gone.index,
            burnNodes[i][j].index + burnNodes[i][j].index.sign)];
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

void printFlag() {
  console.addGraphic(ConsoleGraphic(10.5, 27.25, 16, 51.75,
      SvgPicture.asset('assets/flags/Flag_of_the_United_States.svg')));
}
