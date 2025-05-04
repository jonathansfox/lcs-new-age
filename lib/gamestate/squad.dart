import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/location/site.dart';

part 'squad.g.dart';

@JsonSerializable()
class Squad {
  Squad({int? id}) : id = id ?? gameState.nextSquadId++;
  factory Squad.temporary() => Squad(id: -1);
  factory Squad.fromJson(Map<String, dynamic> json) => _$SquadFromJson(json);
  Map<String, dynamic> toJson() => _$SquadToJson(this);
  int id = -1;
  String name = "";

  List<Creature>? _members;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Creature> get members {
    _members ??= __memberIds
            ?.map((id) => pool.firstWhereOrNull((e) => e.id == id))
            .nonNulls
            .toList() ??
        [];
    return _members!;
  }

  List<int>? __memberIds;
  @JsonKey(includeFromJson: true, includeToJson: true, name: "members")
  List<int> get _memberIds => members.map((e) => e.id).toList();
  set _memberIds(List<int> value) => __memberIds = value;

  Activity activity = Activity.none();
  List<Item> loot = [];

  @JsonKey(includeToJson: false)
  Site? get site => members.firstOrNull?.site;
  @JsonKey(includeToJson: false)
  Iterable<Creature> get livingMembers => members.where((m) => m.alive);
}

void cleanGoneSquads() {
  for (int i = squads.length - 1; i >= 0; i--) {
    Squad squad = squads[i];
    for (int j = squad.members.length - 1; j >= 0; j--) {
      Creature creature = squad.members[j];
      if (!creature.alive) creature.squad = null;
    }
    if (squad.members.isEmpty) {
      squads.remove(squad);
    } else if (mode != GameMode.site) {
      squad.site?.addLootAndProcessMoney(squad.loot);
    }
  }
}
