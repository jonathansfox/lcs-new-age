// ignore_for_file: avoid_web_libraries_in_flutter

import 'package:http/http.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:source_map_stack_trace/source_map_stack_trace.dart';
import 'package:source_maps/source_maps.dart';

Future<StackTrace?> convertStackTrace(StackTrace? trace) async {
  if (trace == null) return null;
  try {
    var map = await read(Uri.parse('main.dart.js.map'));
    var parsedMap = parse(map);
    return mapStackTrace(parsedMap, trace, minified: true);
  } catch (e) {
    debugPrint(e.toString());
    return trace;
  }
}
