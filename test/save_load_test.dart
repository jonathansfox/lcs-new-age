import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/saveload/save_load.dart';

import 'test_support.dart';

/// Regression test for the project's standing promise that saves are always
/// backwards-compatible. Each fixture in test/saves is a real exported save
/// from an older release; loading them here mirrors the in-app load path
/// (`loadGameFromSave`) so a save-format change that breaks an old save fails
/// the build instead of crashing a player mid-load.
///
/// To add coverage for a new release, drop an exported save into test/saves and
/// list its filename below. Files are named `<founder>_<version>` by convention.
void main() {
  setUpAll(ensureGameDataLoaded);

  const saveFixtures = <String>[
    'felix_1_0.json', // 1.0.0 (saveData stored as a JSON-encoded string)
    'EQ_1_1.json', // 1.1.0
    'ebony_1_2_9.json', // 1.2.9
    'eevee_1_4_5.json', // 1.4.5
    'moe_1_5.json', // 1.5.0
  ];

  group('Older saves load', () {
    for (final fileName in saveFixtures) {
      test('loads $fileName', () async {
        final File file = File('test/saves/$fileName');
        expect(file.existsSync(), isTrue,
            reason: 'Missing save fixture: ${file.path}');

        // SaveFile.fromJson handles both the modern nested-object saveData and
        // the pre-1.0.2 JSON-encoded-string form.
        final Map<String, dynamic> raw =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final SaveFile saveFile = SaveFile.fromJson(raw);

        // Mirror loadGameFromSave: deserialize into the global gameState and run
        // the version-gated migrations/bug fixes.
        gameState = GameState.fromJson(saveFile.saveData);
        applyBugFixes(saveFile.version);

        // Confirm the world actually deserialized, rather than just not throwing
        // on a half-empty object.
        expect(gameState.cities, isNotEmpty,
            reason: 'No cities loaded from $fileName');
        expect(pool, isNotEmpty,
            reason: 'No LCS members loaded from $fileName');
      });
    }
  });
}
