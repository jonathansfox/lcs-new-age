import 'package:collection/collection.dart';
import 'package:flutter/material.dart' as material;
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/basemode/base_mode.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/creature/sort_creatures.dart';
import 'package:lcs_new_age/creature/unique_creatures.dart';
import 'package:lcs_new_age/daily/dating.dart';
import 'package:lcs_new_age/daily/hostages/tend_hostage.dart';
import 'package:lcs_new_age/daily/recruitment.dart';
import 'package:lcs_new_age/gamestate/crime_squad.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/gamestate/squad.dart';
import 'package:lcs_new_age/gamestate/stats.dart';
import 'package:lcs_new_age/items/item.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/city.dart';
import 'package:lcs_new_age/location/district.dart';
import 'package:lcs_new_age/location/location.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/politics.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/chase_sequence.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';
import 'package:lcs_new_age/vehicles/vehicle.dart';

part 'game_state.g.dart';

@JsonSerializable()
class GameState {
  GameState();
  factory GameState.fromJson(Map<String, dynamic> json) =>
      _$GameStateFromJson(json);
  Map<String, dynamic> toJson() => _$GameStateToJson(this);

  int uniqueGameId = lcsRandom(10000000);
  List<City> cities = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<District> get districts =>
      cities.expand((city) => city.districts).toList();
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Site> get sites =>
      districts.expand((district) => district.sites).toList();
  Politics politics = Politics.newGame();
  CrimeSquad lcs = CrimeSquad();
  DateTime date = DateTime(2023, DateTime.january, 1);
  int disbandTime = 0;
  bool disbanding = false;
  Ledger ledger = Ledger();
  Stats stats = Stats();
  List<RecruitmentSession> recruitmentSessions = [];
  List<DatingSession> datingSessions = [];
  List<InterrogationSession> interrogationSessions = [];

  @JsonKey(defaultValue: false)
  bool offendedAngryRuralMobs = false;
  bool offendedCia = false;
  bool offendedCorps = false;

  bool ccscherrybusted = false;
  bool lcscherrybusted = false;

  int nextCreatureId = 0;
  int nextSquadId = 0;
  int nextSiteId = 0;
  int nextDistrictId = 0;
  int nextCityId = 1;
  int nextVehicleId = 0;

  int ccsBaseKills = 0;
  UniqueCreatures uniqueCreatures = UniqueCreatures();
  CCSStrength ccsState = CCSStrength.inHiding;
  CCSExposure ccsExposure = CCSExposure.none;
  bool lcsGotDeagle = false;
  bool lcsGotM249 = false;

  int activeSquadId = -1;
  int activeSafehouseId = -1;

  Map<SortingScreens, CreatureSortMethod> activeSortingChoice = {
    for (var screen in SortingScreens.values) screen: CreatureSortMethod.none
  };

  @JsonKey(defaultValue: [])
  List<NewsStory> newsArchive = [];

  // Non-persisting variables (don't include in to/from JSON)
  @JsonKey(includeFromJson: false, includeToJson: false)
  Squad? get activeSquad =>
      squads.firstWhereOrNull((squad) => squad.id == activeSquadId);
  set activeSquad(Squad? value) => activeSquadId = value?.id ?? -1;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get activeSafehouse =>
      sites.firstWhereOrNull((location) => location.id == activeSafehouseId);
  set activeSafehouse(Site? value) => activeSafehouseId = value?.id ?? -1;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? activeSite;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int? activeSquadMemberIndex;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool siteAlarm = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int siteAlarmTimer = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int postAlarmTimer = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  SiteAlienation siteAlienated = SiteAlienation.none;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool siteOnFire = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int siteCrime = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  GameMode mode = GameMode.base;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool showCarPrefs = false;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int ccsSiegeKills = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int ccsBossKills = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int ccsSiegeConverts = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  int ccsBossConverts = 0;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Creature> encounter = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  NewsStory? siteStory;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<Item> groundLoot = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  CantSeeReason cantSeeReason = CantSeeReason.none;
  @JsonKey(includeFromJson: false, includeToJson: false)
  List<NewsStory> newsStories = [];
  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, Site>? _siteMap;
  Map<String, Site> get siteMap {
    _siteMap ??= {for (var site in sites) site.idString: site};
    return _siteMap!;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  Map<String, Location>? _locationMap;
  Map<String, Location> get locationMap {
    _locationMap ??= {
      for (var location in allLocations) location.idString: location
    };
    return _locationMap!;
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  List<CrimeData> potentialCrimes = [];
}

enum CCSStrength {
  inHiding,
  active,
  attacks,
  sieges,
  defeated,
}

enum CCSExposure { none, lcsGotData, exposed, nobackers }

enum SiteAlienation {
  none,
  alienatedModerates,
  alienatedEveryone;

  bool get alienated => this != none;
}

GameState gameState = GameState();
List<Creature> get pool => gameState.lcs.pool;
Iterable<Creature> get poolAndProspects => pool
    .followedBy(datingSessions.expand((d) => d.dates))
    .followedBy(recruitmentSessions.map((r) => r.recruit));
List<Site> get sites => gameState.sites;
Map<String, Site> get siteMap => gameState.siteMap;

Iterable<Location> get allLocations =>
    Iterable.castFrom<Site, Location>(gameState.sites)
        .followedBy(gameState.districts)
        .followedBy(gameState.cities);
Map<String, Location> get locationMap => gameState.locationMap;

int get month => gameState.date.month;
int get day => gameState.date.day;
int get year => gameState.date.year;
DateTime get date => gameState.date;
int get disbandTime => gameState.disbandTime;
bool get disbanding => gameState.disbanding;
set disbanding(bool value) => gameState.disbanding = value;
Politics get politics => gameState.politics;
Map<Exec, DeepAlignment> get exec => politics.exec;
Map<Exec, FullName> get execName => politics.execName;
List<DeepAlignment> get house => politics.house;
List<DeepAlignment> get senate => politics.senate;
List<DeepAlignment> get court => politics.court;
Map<Law, DeepAlignment> get laws => politics.laws;
Map<View, double> get publicOpinion => politics.publicOpinion;
List<Squad> get squads => gameState.lcs.squads;
List<Vehicle> get vehiclePool => gameState.lcs.vehiclePool;
Ledger get ledger => gameState.ledger;
String get slogan => gameState.lcs.slogan;
set slogan(String value) => gameState.lcs.slogan = value;
List<District> get districts => gameState.districts;
List<City> get cities => gameState.cities;
bool get multipleCityMode => gameState.cities.length > 1;

Squad? get activeSquad => gameState.activeSquad;
set activeSquad(Squad? value) => gameState.activeSquad = value;
List<Creature> get squad => activeSquad?.members ?? [];
Site? get activeSafehouse => gameState.activeSafehouse;
set activeSafehouse(Site? value) => gameState.activeSafehouse = value;
Site? get activeSite => gameState.activeSite;
set activeSite(Site? value) => gameState.activeSite = value;
int get activeSquadMemberIndex {
  if (gameState.activeSquadMemberIndex == null) return -1;
  return gameState.activeSquadMemberIndex!;
}

bool get activeSiteUnderSiege => activeSite?.siege.underSiege ?? false;

set activeSquadMemberIndex(int? value) {
  if (value == -1) value = null;
  gameState.activeSquadMemberIndex = value;
}

Creature? get activeSquadMember {
  if (activeSquadMemberIndex == -1) return null;
  return gameState.activeSquad?.members.elementAtOrNull(activeSquadMemberIndex);
}

set activeSquadMember(Creature? value) {
  if (gameState.activeSquad?.members.contains(value) ?? false) {
    activeSquadMemberIndex = squad.indexOf(value!);
  } else {
    activeSquadMemberIndex = null;
  }
}

bool get siteAlarm => gameState.siteAlarm;
set siteAlarm(bool value) => gameState.siteAlarm = value;
SiteAlienation get siteAlienated => gameState.siteAlienated;
set siteAlienated(SiteAlienation value) => gameState.siteAlienated = value;
bool get siteOnFire => gameState.siteOnFire;
set siteOnFire(bool value) => gameState.siteOnFire = value;
int get siteCrime => gameState.siteCrime;
set siteCrime(int value) => gameState.siteCrime = value;
List<Creature> get encounter => gameState.encounter;
NewsStory? get sitestory => gameState.siteStory;
set sitestory(NewsStory? value) => gameState.siteStory = value;
void addDramaToSiteStory(Drama drama) => sitestory?.drama.add(drama);
List<Item> get groundLoot => gameState.groundLoot;

GameMode get mode => gameState.mode;
set mode(GameMode value) => gameState.mode = value;
bool get noProfanity => laws[Law.freeSpeech] == DeepAlignment.archConservative;
bool get gangUnitsActive =>
    laws[Law.policeReform]! <= DeepAlignment.conservative;
bool get deathSquadsActive =>
    laws[Law.policeReform] == DeepAlignment.archConservative &&
    laws[Law.deathPenalty] == DeepAlignment.archConservative;
bool get mutantsPossible =>
    laws[Law.pollution] == DeepAlignment.archConservative ||
    laws[Law.nuclearPower] == DeepAlignment.archConservative;
bool get mutantsCommon =>
    laws[Law.pollution] == DeepAlignment.archConservative &&
    laws[Law.nuclearPower] == DeepAlignment.archConservative;
bool get unionWorkers => laws[Law.labor]! >= DeepAlignment.moderate;
bool get nonUnionWorkers => laws[Law.labor]! < DeepAlignment.eliteLiberal;
bool get fahrenheit451 =>
    laws[Law.freeSpeech] == DeepAlignment.archConservative &&
    laws[Law.privacy] == DeepAlignment.archConservative &&
    laws[Law.policeReform] == DeepAlignment.archConservative;
bool get nineteenEightyFour =>
    laws[Law.prisons] == DeepAlignment.archConservative &&
    laws[Law.privacy] == DeepAlignment.archConservative &&
    laws[Law.military] == DeepAlignment.archConservative &&
    laws[Law.policeReform] == DeepAlignment.archConservative;
bool get animalsArePeopleToo =>
    laws[Law.animalRights] == DeepAlignment.eliteLiberal;
bool get corporateFeudalism =>
    laws[Law.corporate] == DeepAlignment.archConservative &&
    laws[Law.taxes] == DeepAlignment.archConservative &&
    laws[Law.labor] == DeepAlignment.archConservative;
bool get utterNightmare =>
    !laws.values.any((a) => a != DeepAlignment.archConservative);

bool get offendedAngryRuralMobs => gameState.offendedAngryRuralMobs;
set offendedAngryRuralMobs(bool value) =>
    gameState.offendedAngryRuralMobs = value;
bool get offendedCia => gameState.offendedCia;
set offendedCia(bool value) => gameState.offendedCia = value;
bool get offendedCorps => gameState.offendedCorps;
set offendedCorps(bool value) => gameState.offendedCorps = value;

Stats get stats => gameState.stats;
void changePublicOpinion(
  View view,
  int power, {
  bool coloredByLcsOpinions = false,
  bool coloredByCcsOpinions = false,
  int extraMoralAuthority = 0,
  bool noPublicInterest = false,
}) =>
    gameState.politics.changePublicOpinion(view, power,
        coloredByLcsOpinions: coloredByLcsOpinions,
        coloredByCcsOpinions: coloredByCcsOpinions,
        extraMoralAuthority: extraMoralAuthority,
        noPublicInterest: noPublicInterest);

UniqueCreatures get uniqueCreatures => gameState.uniqueCreatures;

CCSStrength get ccsState => gameState.ccsState;
set ccsState(CCSStrength value) => gameState.ccsState = value;
CCSExposure get ccsExposure => gameState.ccsExposure;
set ccsExposure(CCSExposure value) => gameState.ccsExposure = value;

bool get lcsGotDeagle => gameState.lcsGotDeagle;
set lcsGotDeagle(bool value) => gameState.lcsGotDeagle = value;
bool get lcsGotM249 => gameState.lcsGotM249;
set lcsGotM249(bool value) => gameState.lcsGotM249 = value;

bool get ccsActive =>
    ccsState != CCSStrength.inHiding && ccsState != CCSStrength.defeated;

bool get ccsInPublicEye => gameState.ccscherrybusted;
set ccsInPublicEye(bool value) => gameState.ccscherrybusted = value;
bool get lcsInPublicEye => gameState.lcscherrybusted;
set lcsInPublicEye(bool value) => gameState.lcscherrybusted = value;

List<RecruitmentSession> get recruitmentSessions =>
    gameState.recruitmentSessions;
List<DatingSession> get datingSessions => gameState.datingSessions;
List<InterrogationSession> get interrogationSessions =>
    gameState.interrogationSessions;

CantSeeReason get cantSeeReason => gameState.cantSeeReason;
set cantSeeReason(CantSeeReason value) => gameState.cantSeeReason = value;
bool get canSeeThings => gameState.cantSeeReason == CantSeeReason.none;

Map<SortingScreens, CreatureSortMethod> get activeSortingChoice =>
    gameState.activeSortingChoice;

ChaseSequence? chaseSequence;
SiteType get siteType => activeSite?.type ?? SiteType.homelessEncampment;
int get siteAlarmTimer => gameState.siteAlarmTimer;
set siteAlarmTimer(int value) => gameState.siteAlarmTimer = value;
int get postAlarmTimer => gameState.postAlarmTimer;
set postAlarmTimer(int value) => gameState.postAlarmTimer = value;
int get ccsBaseKills => gameState.ccsBaseKills;
set ccsBaseKills(int value) => gameState.ccsBaseKills = value;
int get ccsSiegeKills => gameState.ccsSiegeKills;
set ccsSiegeKills(int value) => gameState.ccsSiegeKills = value;
int get ccsBossKills => gameState.ccsBossKills;
set ccsBossKills(int value) => gameState.ccsBossKills = value;
int get ccsSiegeConverts => gameState.ccsSiegeConverts;
set ccsSiegeConverts(int value) => gameState.ccsSiegeConverts = value;
int get ccsBossConverts => gameState.ccsBossConverts;
set ccsBossConverts(int value) => gameState.ccsBossConverts = value;
List<NewsStory> get newsStories => gameState.newsStories;
int locx = 0;
int locy = 0;
int locz = 0;

void debugPrint(String message) => material.debugPrint(message);
