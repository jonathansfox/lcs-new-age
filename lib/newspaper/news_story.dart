import 'package:collection/collection.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/siege.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/views.dart';

part 'news_story.g.dart';

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
  int claimed = 1;
  Creature? cr;
  List<Drama> drama = [];
  int locId = -1;
  @JsonKey(includeFromJson: false, includeToJson: false)
  Site? get loc => sites.firstWhereOrNull((element) => element.id == locId);
  set loc(Site? l) => locId = l?.id ?? -1;
  int priority = 0;
  int page = 0;
  int guardianpage = 0;
  int positive = 0;
  SiegeType siegetype = SiegeType.none;
  int siegebodycount = 0;
  bool legalGunUsed = false;
  bool illegalGunUsed = false;
  String publicationName = "";
  DeepAlignment publicationAlignment = DeepAlignment.moderate;
  DateTime? _date;
  @JsonKey(includeFromJson: false, includeToJson: false)
  DateTime get date => _date ?? gameState.date;
  set date(DateTime d) => _date = d;
  String headline = "";
  String body = "";
  String? byline;
  Map<View, double> effects = {};
  int? newspaperPhotoId;
  bool remapSkinTones = false;
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
