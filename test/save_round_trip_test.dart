import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/saveload/save_load.dart';

import 'test_support.dart';

/// Test #1: a load followed by a save must be a fixed point.
///
/// The existing save_load_test proves old saves *load*. This proves a
/// load -> save -> load cycle doesn't silently drop or mutate any field: the
/// failure mode where data survives `fromJson` but is lost or changed by
/// `toJson`, which would corrupt a player's game on their very next autosave.
void main() {
  setUpAll(ensureGameDataLoaded);

  const saveFixtures = <String>[
    'felix_1_0.json',
    'EQ_1_1.json',
    'ebony_1_2_9.json',
    'eevee_1_4_5.json',
    'moe_1_5.json',
  ];

  group('Save round-trip is stable', () {
    for (final fileName in saveFixtures) {
      test('round-trips $fileName', () async {
        final Map<String, dynamic> raw =
            jsonDecode(await File('test/saves/$fileName').readAsString())
                as Map<String, dynamic>;
        final Map<String, dynamic> saveData = SaveFile.fromJson(raw).saveData;

        // Mirror autoSaveGame, which serializes the global gameState. Assigning
        // the global keeps any serialization that reads global getters
        // consistent across both passes.
        gameState = GameState.fromJson(saveData);
        final String json1 = jsonEncode(gameState.toJson());

        gameState =
            GameState.fromJson(jsonDecode(json1) as Map<String, dynamic>);
        final String json2 = jsonEncode(gameState.toJson());

        expect(json2, equals(json1),
            reason: 'A load/save cycle changed the serialized data for '
                '$fileName — a field is being dropped or mutated on save.');
      });
    }
  });
}
