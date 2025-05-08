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
    _earnMoney(solicitor, Income.donations, estimateDonationsIncome(solicitor));
  }
}

Future<void> doActivitySellTshirts(List<Creature> tshirts) async {
  for (Creature seller in tshirts) {
    if (await checkForArrest(seller, "selling shirts")) continue;
    _backgroundInfluenceCheck(seller, Skill.tailoring);
    _earnMoney(seller, Income.tshirts, estimateTshirtIncome(seller));
  }
}

Future<void> doActivitySellArt(List<Creature> art) async {
  for (Creature artist in art) {
    if (await checkForArrest(artist, "selling art")) continue;
    _backgroundInfluenceCheck(artist, Skill.art);
    _earnMoney(artist, Income.artSales, estimateArtIncome(artist));
  }
}

Future<void> doActivitySellMusic(List<Creature> music) async {
  for (Creature musician in music) {
    if (await checkForArrest(musician, "playing music")) continue;
    _backgroundInfluenceCheck(musician, Skill.music);
    _earnMoney(musician, Income.busking, estimateMusicIncome(musician));
  }
}

Future<void> doActivitySellBrownies(List<Creature> brownies) async {
  for (Creature baker in brownies) {
    //Check for police search
    if (laws[Law.drugs]! <= DeepAlignment.moderate) {
      bool busted = oneIn(15 * (laws[Law.drugs]!.index + 1));
      if (busted && !baker.skillCheck(Skill.streetSmarts, Difficulty.average)) {
        sitestory = NewsStory.prepare(NewsStories.arrestGoneWrong);
        criminalize(baker, Crime.drugDistribution);
        await attemptArrest(baker, "selling brownies");
      }
    }

    _earnMoney(baker, Income.brownies, estimateBrownieIncome(baker));
  }
}

Future<void> doActivityProstitution(List<Creature> prostitutes) async {
  for (Creature prostitute in prostitutes) {
    // Business once every three days or so
    if (!oneIn(3)) continue;

    int fundgain = estimateProstitutionIncome(prostitute) *
        3; // Multiply by 3 since we only do business 1/3 of days

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

int _roll(Creature c, List<Skill> skills, {bool estimate = false}) {
  if (estimate) {
    // For estimation, use average skill values and average dice roll (7)
    return (skills.map((skill) => c.skill(skill)).reduce((a, b) => a + b) /
                skills.length)
            .round() +
        7;
  }
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

/// Calculates expected daily income from soliciting donations
int estimateDonationsIncome(Creature solicitor, {bool estimate = false}) {
  return (_roll(solicitor, [Skill.persuasion, Skill.streetSmarts],
              estimate: estimate) *
          _multiplierFromPublicMood(highImpact: true) *
          (solicitor.clothing.type.professionalism + 1) *
          0.5)
      .round();
}

/// Calculates expected daily income from selling t-shirts
int estimateTshirtIncome(Creature seller, {bool estimate = false}) {
  return (_roll(seller, [Skill.tailoring, Skill.business], estimate: estimate) *
          _multiplierFromPublicMood())
      .round();
}

/// Calculates expected daily income from selling art
int estimateArtIncome(Creature artist, {bool estimate = false}) {
  return (_roll(artist, [Skill.art, Skill.business], estimate: estimate) *
          _multiplierFromPublicMood())
      .round();
}

/// Calculates expected daily income from performing music
int estimateMusicIncome(Creature musician, {bool estimate = false}) {
  return (_roll(musician, [Skill.music, Skill.streetSmarts],
              estimate: estimate) *
          _multiplierFromPublicMood() *
          (musician.weapon.type.instrument ? 1 : 0.25))
      .round();
}

/// Calculates expected daily income from selling brownies
int estimateBrownieIncome(Creature baker, {bool estimate = false}) {
  int cash = _roll(
    baker,
    [Skill.persuasion, Skill.business, Skill.streetSmarts],
    estimate: estimate,
  );
  return (cash * _multiplierFromBan(Law.drugs) * 3).round();
}

/// Calculates expected daily income from prostitution
/// Note: This is an average over multiple days since prostitution only occurs ~1/3 of days
int estimateProstitutionIncome(Creature prostitute, {bool estimate = false}) {
  int performance = _roll(prostitute,
      [Skill.seduction, Skill.seduction, Skill.streetSmarts, Skill.business],
      estimate: estimate);
  // Average of 2d(2*performance) + 2*performance
  int averageRoll = (2 * performance + 1) + 2 * performance;
  // Only happens 1/3 of days
  return (averageRoll / 3).round();
}
