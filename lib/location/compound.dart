import 'package:json_annotation/json_annotation.dart';

part 'compound.g.dart';

@JsonSerializable()
class Compound {
  Compound();
  factory Compound.fromJson(Map<String, dynamic> json) =>
      _$CompoundFromJson(json);
  Map<String, dynamic> toJson() => _$CompoundToJson(this);
  bool fortified = false;
  bool videoRoom = false;
  bool hackerDen = false;
  bool boobyTraps = false;
  bool aaGun = false;
  bool bollards = false;
  bool generator = false;
  bool solarPanels = false;
  bool cameras = false;
  int diesel = 0;
  int rations = 0;
}
