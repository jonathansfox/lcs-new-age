import 'package:flutter/material.dart';
import 'package:lcs_new_age/map_editor/map_editor_screen.dart';
import 'package:lcs_new_age/map_editor/tile_palette.dart';

// Direct-launch entrypoint for the map editor, so it can be run and tested in
// isolation without booting the whole game:
//   fvm flutter run -d chrome -t lib/map_editor/main.dart
void main() {
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LCS Map Editor',
      home: ColoredBox(
        color: editorBg,
        child: MapEditorScreen(directLaunch: true),
      ),
    ),
  );
}
