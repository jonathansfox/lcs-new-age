import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/colors.dart';

part 'news_story.g.dart';

enum Publication {
  times("The Times", DeepAlignment.moderate, lightGray),
  herald("The Herald", DeepAlignment.moderate, lightGray),
  post("The Post", DeepAlignment.moderate, lightGray),
  globe("The Globe", DeepAlignment.moderate, lightGray),
  daily("The Daily", DeepAlignment.moderate, lightGray),
  liberalGuardian("Liberal Guardian", DeepAlignment.eliteLiberal,
      liberalGuardianBackground),
  cableNews("Cable News", DeepAlignment.archConservative, cableNewsBackground),
  amRadio("AM Radio", DeepAlignment.archConservative, amRadioBackground),
  conservativeStar("Conservative Star", DeepAlignment.archConservative,
      conservativeCrusaderBackground);

  const Publication(this.name, this.alignment, this.backgroundColor);

  final String name;
  final DeepAlignment alignment;
  final Color backgroundColor;
}

@JsonSerializable()
class NewsStory {
  NewsStory();
  NewsStory.unpublished(this.type);
  NewsStory.prepare(this.type) {
    newsStories.add(this);
  }
  factory NewsStory.fromJson(Map<String, dynamic> json) =>
      _$NewsStoryFromJson(json);
  Map<String, dynamic> toJson() => _$NewsStoryToJson(this);
  @JsonKey(defaultValue: NewsStories.majorEvent)
  NewsStories type = NewsStories.majorEvent;
  View? view;
  @JsonKey(defaultValue: 1)
  int claimed = 1;
  Creature? cr;
  @JsonKey(defaultValue: [])
  List<Drama> drama = [];
  @JsonKey(defaultValue: -1)
  int locId = -1;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get loc => sites.firstWhereOrNull((element) => element.id == locId);
  set loc(Site? l) => locId = l?.id ?? -1;
  @JsonKey(defaultValue: 0)
  int priority = 0;
  @JsonKey(defaultValue: 0)
  int page = 0;
  @JsonKey(defaultValue: 0)
  int guardianpage = 0;
  @JsonKey(defaultValue: false)
  bool liberalSpin = false;
  @JsonKey(defaultValue: SiegeType.none)
  SiegeType siegetype = SiegeType.none;
  @JsonKey(defaultValue: 0)
  int siegebodycount = 0;
  @JsonKey(defaultValue: false)
  bool legalGunUsed = false;
  @JsonKey(defaultValue: false)
  bool illegalGunUsed = false;
  @JsonKey(defaultValue: "")
  String publicationName = "";
  @JsonKey(defaultValue: DeepAlignment.moderate)
  DeepAlignment publicationAlignment = DeepAlignment.moderate;
  Publication? _publication;
  @JsonKey(includeToJson: false, includeFromJson: false)
  Publication get publication {
    _publication ??= Publication.values
            .firstWhereOrNull((element) => element.name == publicationName) ??
        Publication.times;
    return _publication!;
  }

  set publication(Publication p) {
    _publication = p;
    publicationName = p.name;
    publicationAlignment = p.alignment;
  }

  @JsonKey(includeToJson: true, includeFromJson: true)
  DateTime? _date;
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date => _date ?? gameState.date;
  set date(DateTime d) => _date = d;
  @JsonKey(defaultValue: "")
  String headline = "";
  @JsonKey(defaultValue: "")
  String body = "";
  String? byline;
  @JsonKey(defaultValue: {})
  Map<View, double> effects = {};
  int? newspaperPhotoId;
  @JsonKey(defaultValue: false)
  bool remapSkinTones = false;
  @JsonKey(defaultValue: true)
  bool unread = true;
}

String newsprintToWebFormat(String text) {
  return text.splitMapJoin(RegExp(r'(&r)+'), onMatch: (m) {
    return "\n\n";
  }, onNonMatch: (n) {
    if (n.contains("~")) return "";
    return n.trim().replaceAll(RegExp(r'\s+'), " ");
  }).trimRight();
}

// For things not covered by the crimes list that are still newsworthy
enum Drama {
  freeRabbits,
  freeMonsters,
  shutDownReactor,
  carChase,
  carCrash,
  footChase,
  stoleSomething,
  unlockedDoor,
  brokeDownDoor,
  attacked,
  killedSomebody,
  openedPoliceLockup,
  openedCourthouseLockup,
  releasedPrisoners,
  juryTampering,
  hackedIntelSupercomputer,
  brokeSweatshopEquipment,
  brokeFactoryEquipment,
  openedCEOSafe,
  stoleCorpFiles,
  arson,
  tagging,
  openedArmory,
  vandalism,
  bankVaultRobbery,
  bankTellerRobbery,
  bankStickup,
  hijackedBroadcast,
  legalGunUsed,
  illegalGunUsed,
  musicalRampage,
}

enum NewsStories {
  majorEvent,
  squadSiteAction,
  squadEscapedSiege,
  squadFledAttack,
  squadDefended,
  squadBrokeSiege,
  squadKilledInSiegeAttack,
  squadKilledInSiegeEscape,
  squadKilledInSiteAction,
  ccsSiteAction,
  ccsDefended,
  ccsKilledInSiegeAttack,
  ccsKilledInSiteAction,
  carTheft,
  massacre,
  kidnapReport,
  arrestGoneWrong,
  raidCorpsesFound,
  raidGunsFound,
  hostageRescued,
  hostageEscapes,
  ccsNoBackers,
  ccsDefeated,
  presidentImpeached,
  presidentBelievedDead,
  presidentFoundDead,
  presidentFound,
  presidentKidnapped,
  presidentMissing,
  presidentAssassinated,
}

enum NewsStoryEvent {
  stoleFromGround,
  unlockedDoor,
  brokeDownDoor,
  attackedNonConservative,
  attackedConservative,
  carChase,
  carCrash,
  footChase,
  killedSomebody,
  shutDownReactor,
  openedPoliceLockup,
  openedCourthouseLockup,
  releasedPrisoners,
  juryTampering,
  hackedIntelSupercomputer,
  brokeSweatshopEquipment,
  brokeFactoryEquipment,
  stoleHousePhotos,
  stoleCorpFiles,
  freeRabbits,
  freeBeasts,
  arson,
  tagging,
  openedArmory,
  vandalism,
  bankVaultRobbery,
  bankTellerRobbery,
  bankStickup,
}
