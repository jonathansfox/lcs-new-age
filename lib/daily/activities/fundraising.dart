import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/creature/creature.dart';
import 'package:lcs_new_age/creature/dice.dart';
import 'package:lcs_new_age/creature/difficulty.dart';
import 'package:lcs_new_age/creature/skills.dart';
import 'package:lcs_new_age/daily/activities/arrest.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/gamestate/ledger.dart';
import 'package:lcs_new_age/justice/crimes.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> doActivitySolicitDonations(List<Creature> solicit) async {
  for (Creature solicitor in solicit) {
    if (await checkForArrest(solicitor, "soliciting donations")) continue;
    _earnMoney(
        solicitor,
        Income.donations,
        (_roll(solicitor, [Skill.persuasion, Skill.streetSmarts]) *
                _multiplierFromPublicMood(highImpact: true) *
                (solicitor.clothing.type.professionalism + 1) *
                0.5)
            .round());
  }
}

Future<void> doActivitySellTshirts(List<Creature> tshirts) async {
  for (Creature seller in tshirts) {
    if (await checkForArrest(seller, "selling shirts")) continue;
    _backgroundInfluenceCheck(seller, Skill.tailoring);
    _earnMoney(
      seller,
      Income.tshirts,
      (_roll(seller, [Skill.tailoring, Skill.business]) *
              _multiplierFromPublicMood())
          .round(),
    );
  }
}

Future<void> doActivitySellArt(List<Creature> art) async {
  for (Creature artist in art) {
    if (await checkForArrest(artist, "selling art")) continue;
    _backgroundInfluenceCheck(artist, Skill.art);
    _earnMoney(
      artist,
      Income.artSales,
      (_roll(artist, [Skill.art, Skill.business]) * _multiplierFromPublicMood())
          .round(),
    );
  }
}

Future<void> doActivitySellMusic(List<Creature> music) async {
  for (Creature musician in music) {
    if (await checkForArrest(musician, "playing music")) continue;
    _backgroundInfluenceCheck(musician, Skill.music);
    _earnMoney(
      musician,
      Income.busking,
      (_roll(musician, [Skill.music, Skill.streetSmarts]) *
              _multiplierFromPublicMood() *
              (musician.weapon.type.instrument ? 1 : 0.25))
          .round(),
    );
  }
}

Future<void> doActivitySellBrownies(List<Creature> brownies) async {
  for (Creature baker in brownies) {
    //Check for police search
    if (laws[Law.drugs]! <= DeepAlignment.moderate) {
      bool busted = oneIn(1 + 30 * laws[Law.drugs]!.index + 3);
      if (busted && !baker.skillCheck(Skill.streetSmarts, Difficulty.average)) {
        sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);
        criminalize(baker, Crime.drugDistribution);
        await attemptArrest(baker, "selling brownies");
      }
    }

    int cash = _roll(
      baker,
      [Skill.persuasion, Skill.business, Skill.streetSmarts],
    );
    cash = (cash * _multiplierFromBan(Law.drugs) * 3).round();
    _earnMoney(baker, Income.brownies, cash);
  }
}

Future<void> doActivityProstitution(List<Creature> prostitutes) async {
  for (Creature prostitute in prostitutes) {
    // Business once every three days or so
    if (!oneIn(3)) continue;

    // Skill determies how much money you get
    int performance = _roll(prostitute,
        [Skill.seduction, Skill.seduction, Skill.streetSmarts, Skill.business]);
    int fundgain = lcsRandom(2 * performance) + 2 * performance;

    if (oneIn(50)) {
      // Police sting!
      // Street Smarts to avoid
      if (prostitute.skillCheck(Skill.streetSmarts, Difficulty.average)) {
        await showMessage(
            "${prostitute.name} avoided getting caught a prostitution sting.");
        prostitute.train(Skill.streetSmarts, 25);
      } else {
        await showMessage(
            "${prostitute.name} has been arrested in a prostitution sting!");
        prostitute.squad = null;
        prostitute.carId = null;
        prostitute.location =
            findSiteInSameCity(prostitute.base!.city, SiteType.policeStation);
        prostitute.dropWeaponAndAmmo();
        prostitute.activity = Activity.none();
        criminalize(prostitute, Crime.prostitution);
      }
    } else {
      // Regular business
      ledger.addFunds(fundgain, Income.prostitution);
      prostitute.income = fundgain;
    }
  }
}

void _backgroundInfluenceCheck(Creature c, Skill skill) {
  if (c.skillCheck(skill, Difficulty.formidable)) {
    politics.addBackgroundInfluence(View.issues.random, 5);
  }
}

void _earnMoney(Creature c, Income incomeType, int money) {
  c.income += money;
  ledger.addFunds(money, incomeType);
}

int _roll(Creature c, List<Skill> skills) {
  return (skills.map((skill) {
                c.train(skill, 5);
                return c.skill(skill);
              }).reduce((a, b) => a + b) /
              skills.length)
          .round() +
      Dice.r2d6.roll();
}

double _multiplierFromPublicMood({bool highImpact = false}) {
  return switch (politics.publicMood()) {
    > 90 => highImpact ? 1 / 16 : 1 / 4,
    > 65 => highImpact ? 1 / 8 : 1 / 4,
    > 35 => highImpact ? 1 / 4 : 1 / 2,
    > 10 => highImpact ? 1 / 2 : 1,
    _ => 1,
  };
}

double _multiplierFromBan(Law law) {
  return switch (laws[law]!) {
    DeepAlignment.archConservative => 4,
    DeepAlignment.conservative => 2,
    DeepAlignment.moderate => 1,
    DeepAlignment.liberal => 1 / 2,
    DeepAlignment.eliteLiberal => 1 / 4,
  };
}
