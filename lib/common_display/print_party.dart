import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/common_display/print_creature_info.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_mode.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/utils/colors.dart';

void printParty({
  bool fullParty = false,
  ShowCarPrefs? showCarPrefs,
}) {
  showCarPrefs ??= mode == GameMode.base
      ? ShowCarPrefs.showPreferences
      : ShowCarPrefs.showActualCar;
  List<Creature> party = activeSquad?.members ?? [];
  setColor(lightGray);
  eraseArea(startY: 2, endY: 8);
  if (activeSquadMember != null && !fullParty) {
    printCreatureInfo(activeSquadMember!, showCarPrefs: showCarPrefs);
    mvaddstrc(1, 0, white, (activeSquadMemberIndex + 1).toString());
  } else {
    addHeader({
      0: "#",
      2: "CODE NAME",
      23: "SKILL",
      29: "WEAPON",
      44: "ARMOR",
      59: "HEALTH",
      70: "TRANSPORT",
    });
    for (int p = 0; p < party.length; p++) {
      addOptionText(p + 2, 0, String.fromCharCode('1'.codePoint + p),
          "${String.fromCharCode('1'.codePoint + p)} ${party[p].name}",
          baseColorKey: ColorKey.white);
      if (party[p].isHoldingBody) addstrc(pink, "+H");
      printSkillSummary(p + 2, 23, party[p], showWeaponSkill: true);
      move(p + 2, 29);
      setWeaponColor(party[p]);
      printWeapon(party[p]);
      setColorForArmor(party[p]);
      mvaddstr(p + 2, 44, party[p].clothing.shortName);
      printHealthStat(p + 2, 59, party[p], small: true);
      setColor(lightGray);
      move(p + 2, 70);
      printTransportation(party[p], showCarPrefs);
    }
  }
  makeDelimiter();
}

void printSkillSummary(
  int y,
  int x,
  Creature c, {
  bool showWeaponSkill = true,
}) {
  int skill = 0;
  bool bright = false;
  for (Skill sk in Skill.values) {
    skill += c.rawSkill[sk]!;
    if (c.rawSkillXP[sk]! >= 100 + (10 * c.rawSkill[sk]!) &&
        c.rawSkill[sk]! < c.skillCap(sk)) {
      bright = true;
    }
  }
  setColor(bright ? white : lightGray);
  mvaddstr(y, x, "$skill");
  if (showWeaponSkill) addstr("/${c.weaponSkill}");
}
