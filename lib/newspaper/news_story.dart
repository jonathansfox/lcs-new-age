import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';

part 'news_story.g.dart';

@JsonSerializable(ignoreUnannotated: true)
class NewsStory {
  NewsStory();
  NewsStory.unpublished(this.type);
  NewsStory.prepare(this.type) {
    newsStories.add(this);
  }
  factory NewsStory.fromJson(Map<String, dynamic> json) =>
      _$NewsStoryFromJson(json);
  Map<String, dynamic> toJson() => _$NewsStoryToJson(this);
  NewsStories type = NewsStories.majorEvent;
  View? view;
  int claimed = 1;
  Creature? cr;
  int leadersex = 0;
  String leaderName = "";
  List<Drama> drama = [];
  @JsonKey(includeFromJson: true, includeToJson: true, defaultValue: -1)
  int locId = -1;
  Site? get loc => sites.firstWhereOrNull((element) => element.id == locId);
  set loc(Site? l) => locId = l?.id ?? -1;
  int priority = 0;
  int page = 0;
  int guardianpage = 0;
  @JsonKey(includeFromJson: true, includeToJson: true, defaultValue: 0)
  int positive = 0;
  SiegeType siegetype = SiegeType.none;
  int siegebodycount = 0;
  bool legalGunUsed = false;
  bool illegalGunUsed = false;
  @JsonKey(includeFromJson: true, includeToJson: true)
  String publicationName = "";
  @JsonKey(includeFromJson: true, includeToJson: true)
  DeepAlignment publicationAlignment = DeepAlignment.moderate;
  @JsonKey(includeFromJson: true, includeToJson: true)
  DateTime? _date;
  DateTime get date => _date ?? gameState.date;
  set date(DateTime d) => _date = d;
  @JsonKey(includeFromJson: true, includeToJson: true)
  String headline = "";
  @JsonKey(includeFromJson: true, includeToJson: true)
  String body = "";
  @JsonKey(includeFromJson: true, includeToJson: true)
  String? byline;
  @JsonKey(includeFromJson: true, includeToJson: true)
  Map<View, double> effects = {};
  @JsonKey(includeFromJson: true, includeToJson: true)
  int? newspaperPhotoId;
  @JsonKey(includeFromJson: true, includeToJson: true)
  bool remapSkinTones = false;
  @JsonKey(includeFromJson: true, includeToJson: true)
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
