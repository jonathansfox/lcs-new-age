import 'package:lcs_new_age/engine/changelog.dart';
import 'package:lcs_new_age/engine/console_widget.dart';
import 'package:lcs_new_age/engine/engine.dart' as engine;
import 'package:lcs_new_age/title_screen/launch_game.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:pixel_snap/material.dart';

void main() {
  runApp(const MainApp());
  // ignore: discarded_futures
  Future.delayed(const Duration(seconds: 1)).then((_) async {
    await launchGame();
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Scaffold(
        backgroundColor: Color.lerp(darkGray, black, 0.8),
        body: Stack(
          children: [
            ConsoleWidget(engine.console, key: ConsoleWidget.globalKey),
            ChangelogWidget(key: ChangelogWidget.globalKey),
          ],
        ),
      ),
    );
  }
}
