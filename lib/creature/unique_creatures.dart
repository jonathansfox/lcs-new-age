import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'unique_creatures.g.dart';

@JsonSerializable()
class UniqueCreatures {
  UniqueCreatures();
  factory UniqueCreatures.fromJson(Map<String, dynamic> json) =>
      _$UniqueCreaturesFromJson(json);
  Map<String, dynamic> toJson() => _$UniqueCreaturesToJson(this);

  @JsonKey(includeToJson: true, includeFromJson: true)
  Creature? _ceo;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get ceo {
    _ceo ??= Creature.fromId(CreatureTypeIds.corporateCEO)
      ..location = sites.firstWhere((s) => s.type == SiteType.ceoHouse)
      ..workLocation = sites.firstWhere((s) => s.type == SiteType.ceoHouse);
    return _ceo!;
  }

  @JsonKey(includeToJson: true, includeFromJson: true)
  Creature? _president;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get president {
    _president ??= Creature.fromId(CreatureTypeIds.president)
      ..properName = politics.execName[Exec.president]!.firstLast
      ..name = "President ${politics.execName[Exec.president]!.last}"
      ..gender = politics.execName[Exec.president]!.gender
      ..genderAssignedAtBirth = politics.execName[Exec.president]!.gender
      ..align = politics.exec[Exec.president]!.shallow
      ..alreadyNamed = true
      ..infiltration = 1
      ..juice = 1000
      ..location = sites.firstWhere((s) => s.type == SiteType.whiteHouse)
      ..workLocation = sites.firstWhere((s) => s.type == SiteType.whiteHouse);
    return _president!;
  }

  @JsonKey(includeToJson: true, includeFromJson: true)
  Creature? _aceLiberalAttorney;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get aceLiberalAttorney {
    _aceLiberalAttorney ??= Creature.fromId(CreatureTypeIds.lawyer)
      ..name =
          "${[
            "Huang", "Astraea", "Saleem", "Imani", //
          ].random} ${[
            "Truth", "Justice", "Liberty", "Peace", //
          ].random}";
    return _aceLiberalAttorney!;
  }

  @JsonKey(includeToJson: true, includeFromJson: true)
  Creature? _aceAttorneyArchRival;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Creature get aceAttorneyArchRival {
    _aceAttorneyArchRival ??= Creature.fromId(CreatureTypeIds.lawyer)
      ..name = generateFullName(Gender.whiteMalePatriarch).firstLast;
    return _aceAttorneyArchRival!;
  }

  @JsonKey(includeToJson: true, includeFromJson: true)
  final Map<String, Map<String, Creature>> _siteCreatures = {};
  Map<String, Creature> get currentSiteCreatures {
    Location? site = gameState.activeSite;
    if (site == null) return {};
    return siteCreatures(site);
  }

  Map<String, Creature> siteCreatures(Location site) {
    Map<String, Creature>? creatures = _siteCreatures[site.idString];
    if (creatures == null) {
      creatures = {};
      _siteCreatures[site.idString] = creatures;
    }
    return creatures;
  }

  Creature currentSiteCreature(String typeId) {
    Location? site = gameState.activeSite;
    if (site == null) return Creature.fromId(typeId);
    return siteCreature(typeId, site);
  }

  Creature siteCreature(String typeId, Location site) {
    Map<String, Creature> creatures = siteCreatures(site);
    Creature? creature = creatures[typeId];
    if (creature == null) {
      creature = Creature.fromId(typeId);
      creature.location = gameState.activeSite;
      creature.workLocation = gameState.activeSite;
      creatures[typeId] = creature;
    }
    return creature;
  }

  void newCEO() => _ceo = null;
  void newPresident() => _president = null;

  void syncWithPool() {
    if (_ceo != null) {
      _ceo = poolAndProspects.firstWhere(
        (p) => p.id == _ceo!.id,
        orElse: () => _ceo!,
      );
    }
    if (_president != null) {
      _president = poolAndProspects.firstWhere(
        (p) => p.id == _president!.id,
        orElse: () => _president!,
      );
    }
    for (var siteCreatureList in _siteCreatures.values) {
      for (var entry in siteCreatureList.entries) {
        siteCreatureList[entry.key] = poolAndProspects.firstWhere(
          (p) => p.id == entry.value.id,
          orElse: () => entry.value,
        );
      }
    }
  }

  void resetWillingToTalk() {
    for (var c in allCreatures()) {
      c.isWillingToTalk = true;
    }
  }

  void replace(Creature cr) {
    if (cr == ceo) newCEO();
    if (cr == president) {
      politics.promoteVP();
    }
    for (var siteCreatureList in _siteCreatures.values) {
      for (var entry in siteCreatureList.entries) {
        if (entry.value.id == cr.id) {
          siteCreatureList.remove(entry.key);
        }
      }
    }
  }

  Iterable<Creature> allCreatures() {
    return [
      ceo,
      president,
    ].followedBy(_siteCreatures.values.expand((e) => e.values));
  }
}
