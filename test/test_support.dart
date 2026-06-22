import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/saveload/load_xml_data.dart';

bool _loaded = false;

/// Loads the game's XML data tables (items, weapons, creatures, shops, ...)
/// once per test process. The deserializers and data-integrity checks resolve
/// type ids against these global maps, so every test that touches game data
/// must `await` this in its `setUpAll`.
Future<void> ensureGameDataLoaded() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  if (_loaded) return;
  await loadXmlData();
  _loaded = true;
}
