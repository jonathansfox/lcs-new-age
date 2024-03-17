import 'package:json_annotation/json_annotation.dart';

part 'stats.g.dart';

@JsonSerializable()
class Stats {
  Stats();
  factory Stats.fromJson(Map<String, dynamic> json) => _$StatsFromJson(json);
  Map<String, dynamic> toJson() => _$StatsToJson(this);
  int recruits = 0;
  int kidnappings = 0;
  int martyrs = 0;
  int kills = 0;
  int flagsBought = 0;
  int flagsBurned = 0;
}
