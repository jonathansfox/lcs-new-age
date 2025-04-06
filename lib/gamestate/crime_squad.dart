import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

part 'crime_squad.g.dart';

@JsonSerializable()
class CrimeSquad {
  CrimeSquad();
  factory CrimeSquad.fromJson(Map<String, dynamic> json) =>
      _$CrimeSquadFromJson(json);
  Map<String, dynamic> toJson() => _$CrimeSquadToJson(this);
  List<Creature> pool = [];
  List<Squad> squads = [];
  List<Vehicle> vehiclePool = [];
  String slogan = lcsRandomWeighted({
    "We need a slogan!": 10,
    "We really need a slogan!": 1,
    "This is a slogan!": 1,
    "We don't need no stinky slogan!": 1,
    "I can't think of a slogan!": 1,
    "Is this a slogan?": 1,
    "We are the 99%": 1,
    "Hell yes, LCS!": 1,
    "Revolution never comes with a warning!": 1,
    "Left Makes Might": 1,
    "True Liberal Justice!": 1,
    "Laissez ain't fair!": 1,
    "I'm here to chew bubblegum and kick ass, and they just banned bubblegum.":
        1,
    "Liberal Powers Activate!": 1,
    "Respect existence or expect resistance!": 1,
    "We don't want your crumbs, we want the damn bakery!": 1,
    "If you're not at the table, you're on the menu.": 1,
    "The world for who? The world for us!": 1,
    "Be queer, strike fear!": 1,
    "Be careful with each other so we can be dangerous together": 1,
    "We are all antifascists!": 1,
    "Rome Wasn't Burned in a Day": 1,
    "Death to fascism, freedom to the people!": 1,
    "No gods, no masters!": 1,
    "No war but class war!": 1,
    "Throwing the first brick": 1,
    "Everything for everyone!": 1,
    "An army of lovers cannot lose!": 1,
    "Demand the Impossible": 1,
    "Who, if not you? When, if not now?": 1,
    "I believe in a better world!": 1,
    "Power to the people!": 1,
    "Racist Lives Don't Matter": 1,
    "The only minority destroying this country are the billionaires!": 1,
    "When injustice becomes law, resistance becomes duty!": 1,
    "Black Trans Lives Matter": 1,
    "No one is illegal on stolen land": 1,
    "Because the oligarchy grows tiresome": 1,
    "Get in loser, we're disrupting systems of oppression!": 1,
    "Eat the rich!": 1,
    "All power to the people!": 1,
    "I dissent.": 1,
    "Keep the immigrants, deport the racists": 1,
    "We're actually leftists, not liberals": 1,
  });
}
