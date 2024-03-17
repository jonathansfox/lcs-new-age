import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'unique_creatures.g.dart';

@JsonSerializable()
class UniqueCreatures {
  UniqueCreatures();
  factory UniqueCreatures.fromJson(Map<String, dynamic> json) =>
      _$UniqueCreaturesFromJson(json);
  Map<String, dynamic> toJson() => _$UniqueCreaturesToJson(this);

  @JsonKey()
  Creature? _ceo;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get ceo {
    _ceo ??= Creature.fromId(CreatureTypeIds.corporateCEO);
    return _ceo!;
  }

  @JsonKey()
  Creature? _president;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get president {
    _president ??= Creature.fromId(CreatureTypeIds.president)
      ..name = "President ${politics.execName[Exec.president]}"
      ..align = politics.exec[Exec.president]!.shallow;
    return _president!;
  }

  @JsonKey()
  Creature? _aceLiberalAttorney;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get aceLiberalAttorney {
    _aceLiberalAttorney ??= Creature.fromId(CreatureTypeIds.lawyer)
      ..name = "${[
        "Huang", "Astraea", "Saleem", "Imani", //
      ].random} ${[
        "Truth", "Justice", "Liberty", "Peace", //
      ].random}";
    return _aceLiberalAttorney!;
  }

  @JsonKey()
  Creature? _aceAttorneyArchRival;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get aceAttorneyArchRival {
    _aceAttorneyArchRival ??= Creature.fromId(CreatureTypeIds.lawyer)
      ..name = generateFullName(Gender.whiteMalePatriarch).firstLast;
    return _aceAttorneyArchRival!;
  }

  void newCEO() => _ceo = null;
  void newPresident() => _president = null;
}
