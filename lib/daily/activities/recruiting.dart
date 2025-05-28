import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/creature_type.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/talk/talk.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/interface_options.dart';

Future<void> doActivityRecruit(Creature cr) async {
  activeSite = cr.site;

  RecruitData recruit = cr.activity.recruitData ?? recruitableCreatures.first;
  int difficulty = recruit.difficulty;
  String name = recruit.type.name;

  cr.train(Skill.streetSmarts, 5);

  erase();
  mvaddstrc(0, 0, white, "Adventures in Liberal Recruitment");
  printCreatureInfo(cr, showCarPrefs: ShowCarPrefs.onFoot);
  makeDelimiter();

  mvaddstrc(10, 0, lightGray, "${cr.name} asks around for a $name...");

  await getKey();

  int recruitCount = 0;
  encounter.clear();

  if (difficulty < 10) {
    // Generate recruitment candidates
    recruitCount =
        (cr.skillRoll(Skill.streetSmarts, take10: true) / difficulty).round();
    if (recruitCount > 10) recruitCount = 10;
    for (int i = 0; i < recruitCount; i++) {
      encounter.add(Creature.fromId(recruit.type.id));
    }
  }

  if (recruitCount == 0) {
    mvaddstr(11, 0, "${cr.name} was unable to track down a $name.");
    await getKey();
    return;
  } else if (recruitCount == 1) {
    mvaddstr(11, 0, "${cr.name} managed to set up a meeting with ");
    addstrc(encounter[0].align.color,
        "${encounter[0].name} ${creatureAgeAndGender(encounter[0])}");
    addstrc(lightGray, ".");
    await getKey();

    erase();
    mvaddstrc(0, 0, white, "Adventures in Liberal Recruitment");
    printCreatureInfo(encounter[0], showCarPrefs: ShowCarPrefs.onFoot);
    makeDelimiter();
    await talk(cr, encounter[0]);
  } else {
    while (true) {
      erase();
      mvaddstrc(0, 0, white, "Adventures in Liberal Recruitment");
      printCreatureInfo(cr, showCarPrefs: ShowCarPrefs.onFoot);
      makeDelimiter();

      mvaddstrc(10, 0, lightGray,
          "${cr.name} was able to get information on multiple people.");
      for (int i = 0; i < recruitCount; i++) {
        String letter = letterAPlus(i);
        addOptionText(12 + i, 0, letter,
            "$letter - &${ColorKey.fromColor(encounter[i].align.color)}${encounter[i].name} ${creatureAgeAndGender(encounter[i])}");
      }
      addOptionText(12 + recruitCount + 1, 0, "Enter/Escape",
          "Enter/Escape - Call it a day");

      int c = await getKey();

      if (isBackKey(c)) break;
      c -= 'a'.codePoint;
      if (c >= 0 && c < encounter.length) {
        siteAlarm = false;
        siteAlienated = SiteAlienation.none;

        Creature target = encounter[c];
        erase();
        mvaddstrc(0, 0, white, "Adventures in Liberal Recruitment");
        printCreatureInfo(target, showCarPrefs: ShowCarPrefs.onFoot);
        makeDelimiter();

        await talk(cr, target);
        encounter.remove(target);
        recruitCount--;
        if (recruitCount <= 0) break;
      }
    }
    encounter.clear();
  }
}

class RecruitData {
  RecruitData(this.type, this.name, this.difficulty);
  final String name;
  final CreatureType type;
  int difficulty;
}

List<RecruitData>? _recruitData;
List<RecruitData> get recruitableCreatures {
  List<RecruitData>? recruitData = _recruitData;
  if (recruitData == null) {
    recruitData = creatureTypes.values
        .map<RecruitData?>((e) {
          int? difficulty = e.recruitActivityDifficulty;
          if (difficulty == null) return null;
          return RecruitData(e, e.name, difficulty);
        })
        .nonNulls
        .toList();
    _recruitData = recruitData;
  }
  for (int i = 0; i < recruitData.length; i++) {
    // Dynamic difficulty for certain creatures
    if (recruitData[i].type.id == CreatureTypeIds.mutant) {
      if (mutantsCommon) {
        recruitData[i].difficulty = 2;
      } else if (mutantsPossible) {
        recruitData[i].difficulty = 6;
      } else {
        recruitData.removeAt(i--);
      }
    }
  }
  recruitData.sort(
      (a, b) => (a.difficulty - b.difficulty) * 2 + a.name.compareTo(b.name));
  return recruitData;
}
