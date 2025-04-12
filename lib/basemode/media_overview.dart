import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/utils/colors.dart';

Future<void> mediaOverview() async {
  erase();
  setColor(white);
  mvaddstr(1, 1, "Media Overview");
  mvaddstr(2, 1, "-----------------");
  mvaddstr(3, 1, "Press any key to continue...");
  await getKey();
}
