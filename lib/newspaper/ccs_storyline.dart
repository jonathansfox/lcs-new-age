import 'dart:math';

import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/sitemode/fight.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

NewsStory ccsStrikesStory() {
  return NewsStory.prepare(
      oneIn(10) ? NewsStories.ccsKilledInSiteAction : NewsStories.ccsSiteAction)
    ..positive = 1
    ..loc = sites.where((s) => s.controller != SiteController.ccs).random;
}

Future<void> advanceCCSDefeatStoryline() async {
  switch (ccsExposure) {
    case CCSExposure.none:
    case CCSExposure.lcsGotData:
      break;
    case CCSExposure.exposed:
      ccsBackerArrestStory();
    case CCSExposure.nobackers:
      await ccsFbiRaidStory();
  }
}

NewsStory ccsBackerArrestStory() {
  NewsStory ns = NewsStory.prepare(NewsStories.ccsNoBackers)..priority = 8000;
  ccsExposure = CCSExposure.nobackers;
  // arrest seventeen representatives and eight senators
  int arrestsleft = 8;
  for (int i = 0; i < senate.length; i++) {
    if ((senate[i] == DeepAlignment.archConservative ||
            senate[i] == DeepAlignment.conservative) &&
        oneIn(4)) {
      senate[i] = DeepAlignment.eliteLiberal;
      arrestsleft--;
      if (arrestsleft <= 0) break;
    }
  }
  arrestsleft = 17;
  for (int i = 0; i < house.length; i++) {
    if ((house[i] == DeepAlignment.archConservative ||
            house[i] == DeepAlignment.conservative) &&
        oneIn(4)) {
      house[i] = DeepAlignment.eliteLiberal;
      arrestsleft--;
      if (arrestsleft <= 0) break;
    }
  }
  // change police regulation issue to be more liberal
  laws.update(
      Law.policeReform,
      (v) => DeepAlignment
          .values[min(DeepAlignment.values.length - 1, v.index + 2)]);
  changePublicOpinion(View.policeBehavior, 50);
  changePublicOpinion(View.ccsHated, 50);

  return ns;
}

Future<NewsStory> ccsFbiRaidStory() async {
  NewsStory ns = NewsStory.prepare(NewsStories.ccsDefeated)..priority = 8000;
  ccsState = CCSStrength.defeated;
  // arrest or kill ccs sleepers
  for (Creature p in pool.where((p) => p.sleeperAgent && p.type.ccsMember)) {
    p.sleeperAgent = false;
    criminalize(p, Crime.racketeering);
    await captureCreature(p);
  }
  // hide ccs safehouses
  for (Site l in sites.where((l) => l.controller == SiteController.ccs)) {
    l.controller = SiteController.unaligned;
    l.hidden = true;
  }
  // the government will protect you, you don't need the lcs
  changePublicOpinion(View.policeBehavior, -20);
  changePublicOpinion(View.intelligence, -20);
  changePublicOpinion(View.lcsLiked, -20);
  return ns;
}
