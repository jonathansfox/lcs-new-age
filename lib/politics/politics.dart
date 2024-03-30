import 'dart:math';

import 'package:json_annotation/json_annotation.dart';
import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/politics/alignment.dart';
import 'package:lcs_new_age/politics/laws.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

part 'politics.g.dart';

@JsonSerializable()
class Politics {
  Politics();
  factory Politics.newGame() {
    Politics p = Politics();
    p.publicOpinion[View.lcsKnown] = 0;
    p.publicOpinion[View.lcsLiked] = 5;
    p.laws[Law.abortion] = DeepAlignment.moderate;
    p.laws[Law.animalRights] = DeepAlignment.archConservative;
    p.laws[Law.policeReform] = DeepAlignment.conservative;
    p.laws[Law.privacy] = DeepAlignment.conservative;
    p.laws[Law.deathPenalty] = DeepAlignment.moderate;
    p.laws[Law.nuclearPower] = DeepAlignment.moderate;
    p.laws[Law.pollution] = DeepAlignment.conservative;
    p.laws[Law.labor] = DeepAlignment.conservative;
    p.laws[Law.lgbtRights] = DeepAlignment.liberal;
    p.laws[Law.corporate] = DeepAlignment.conservative;
    p.laws[Law.freeSpeech] = DeepAlignment.liberal;
    p.laws[Law.flagBurning] = DeepAlignment.eliteLiberal;
    p.laws[Law.gunControl] = DeepAlignment.conservative;
    p.laws[Law.taxes] = DeepAlignment.moderate;
    p.laws[Law.genderEquality] = DeepAlignment.moderate;
    p.laws[Law.civilRights] = DeepAlignment.moderate;
    p.laws[Law.drugs] = DeepAlignment.moderate;
    p.laws[Law.immigration] = DeepAlignment.moderate;
    p.laws[Law.elections] = DeepAlignment.liberal;
    p.laws[Law.military] = DeepAlignment.conservative;
    p.laws[Law.prisons] = DeepAlignment.conservative;
    p.laws[Law.torture] = DeepAlignment.liberal;
    return p;
  }
  factory Politics.fromJson(Map<String, dynamic> json) =>
      _$PoliticsFromJson(json);
  Map<String, dynamic> toJson() => _$PoliticsToJson(this);

  Map<View, double> publicOpinion = {
    for (View v in View.values) v: 35 + lcsRandomDouble(20)
  };
  Map<View, int> publicInterest = {for (View v in View.values) v: 0};
  Map<View, int> backgroundInfluence = {for (View v in View.values) v: 0};
  Map<Law, DeepAlignment> laws = {
    for (Law l in Law.values) l: DeepAlignment.conservative
  };
  List<DeepAlignment> senate = List.generate(100, (s) {
    if (s < 40) return DeepAlignment.archConservative;
    if (s < 55) return DeepAlignment.conservative;
    if (s < 65) return DeepAlignment.moderate;
    if (s < 80) return DeepAlignment.liberal;
    return DeepAlignment.eliteLiberal;
  });
  List<DeepAlignment> house = List.generate(435, (h) {
    if (h < 170) return DeepAlignment.archConservative;
    if (h < 230) return DeepAlignment.conservative;
    if (h < 260) return DeepAlignment.moderate;
    if (h < 310) return DeepAlignment.liberal;
    return DeepAlignment.eliteLiberal;
  });
  List<DeepAlignment> court = List.generate(9, (j) {
    if (j < 2) return DeepAlignment.archConservative;
    if (j < 6) return DeepAlignment.conservative;
    if (j < 8) return DeepAlignment.liberal;
    return DeepAlignment.eliteLiberal;
  });
  late List<FullName> courtName = court.map<FullName>((c) {
    if (c == DeepAlignment.archConservative) {
      return generateFullName(Gender.whiteMalePatriarch);
    } else {
      return generateFullName(Gender.nonbinary);
    }
  }).toList();
  Map<Exec, DeepAlignment> exec = {
    for (Exec e in Exec.values) e: DeepAlignment.archConservative
  };
  Map<Exec, FullName> execName = {
    for (Exec e in Exec.values) e: generateFullName(Gender.whiteMalePatriarch)
  };
  int execTerm = 1;
  PoliticalParty presidentParty = PoliticalParty.republican;
  String oldPresidentName = "Donald J. Trump";
  bool termLimitsPassed = false;
  bool supremeCourtPurged = false;
  int constitutionalAmendments = 27;
  @JsonKey(defaultValue: 6)
  int timeSinceLastConstitutionRepealAttempt = 0;

  void promoteVP() {
    exec[Exec.president] = exec[Exec.vicePresident]!;
    execName[Exec.president] = execName[Exec.vicePresident]!;
    if ([DeepAlignment.archConservative, DeepAlignment.conservative]
        .contains(exec[Exec.president])) {
      presidentParty = PoliticalParty.republican;
    } else if ([DeepAlignment.eliteLiberal, DeepAlignment.liberal]
        .contains(exec[Exec.president])) {
      presidentParty = PoliticalParty.democrat;
    }
  }

  void fillCabinetPost(Exec position) {
    // Set alignment
    DeepAlignment presAlign = exec[Exec.president] ?? DeepAlignment.moderate;
    DeepAlignment appointee = switch (presAlign) {
      DeepAlignment.archConservative => DeepAlignment.archConservative,
      DeepAlignment.eliteLiberal => DeepAlignment.eliteLiberal,
      _ => DeepAlignment.values[presAlign.index + lcsRandom(3) - 1],
    };
    exec[position] = appointee;
    // Set name
    execName[position] = generateFullName(switch (appointee) {
      DeepAlignment.archConservative => Gender.whiteMalePatriarch,
      DeepAlignment.conservative => Gender.male,
      DeepAlignment.eliteLiberal => Gender.nonbinary,
      _ => Gender.maleBias,
    });
  }

  void changePublicOpinion(
    View view,
    num power, {
    bool coloredByLcsOpinions = false,
    bool coloredByCcsOpinions = false,
  }) {
    double existingView = publicOpinion[view]!;
    int existingInterest = publicInterest[view]!;
    if (view.index < View.amRadio.index) {
      backgroundInfluence[view] =
          ((backgroundInfluence[view] ?? 0) + power * 10).round();
    }
    if (coloredByLcsOpinions) {
      // Power from people who haven't heard of the LCS or don't care
      double rawPower = power * ((100 - publicOpinion[View.lcsKnown]!) / 100);
      // Power from people who have opinions about the LCS
      double affectedPower = power - rawPower;
      double lcsPopularity = publicOpinion[View.lcsLiked]!;
      double moralAuthority = lcsPopularity - existingView;
      affectedPower = affectedPower * (100 + moralAuthority) / 100;
      power = rawPower + affectedPower;
    } else if (coloredByCcsOpinions) {
      power = power * (100 - publicOpinion[View.ccsLiked]! / 100);
    }
    if (view == View.lcsKnown) {
      power = power.clamp(-5, 50);
    } else if (view == View.lcsLiked || view == View.ccsLiked) {
      power = power.clamp(-50, 5);
    }
    power = (power * (1 + existingInterest / 50)).round();
    publicInterest[view] = (existingInterest + power.abs()).round();
    power = power.clamp(-75, 75);
    if (power > 0) {
      publicOpinion[view] = existingView + ((100 - existingView) * power / 100);
    } else {
      publicOpinion[view] = existingView + (existingView * power / 100);
    }
    if (publicOpinion[view]! > 100) publicOpinion[view] = 100;
    if (publicOpinion[view]! < 0) publicOpinion[view] = 0;
  }

  double publicMood() =>
      publicOpinion.entries
          .where((v) => v.key.index < View.amRadio.index)
          .fold<double>(0, (value, element) => value + element.value) /
      View.amRadio.index;

  Alignment rollAlignment() {
    int index = 0;
    double threshold = publicMood();
    if (lcsRandom(100) > threshold) index++;
    if (lcsRandom(100) > threshold) index++;
    return Alignment.values[index];
  }

  DeepAlignment rollDeepAlignment() {
    int index = 0;
    double threshold = publicMood();
    for (int i = 0; i < 5; i++) {
      if (lcsRandom(100) < threshold) index++;
    }
    return DeepAlignment.values[index];
  }

  bool rollIncumbentAutowin() {
    if (termLimitsPassed) return false;
    return switch (laws[Law.elections]) {
      DeepAlignment.archConservative => !oneIn(3),
      DeepAlignment.conservative => oneIn(2),
      DeepAlignment.moderate => oneIn(3),
      DeepAlignment.liberal => oneIn(5),
      DeepAlignment.eliteLiberal => oneIn(8),
      _ => false,
    };
  }

  Map<DeepAlignment, double> voterSpread(double percentLiberal) {
    double normalized = percentLiberal / 100;
    double eliteLiberal = pow(normalized, 4).toDouble();
    double liberal = pow(normalized, 3) - eliteLiberal;
    double moderate = pow(normalized, 2) - eliteLiberal - liberal;
    double conservative = normalized - eliteLiberal - liberal - moderate;
    double archConservative = 1 - normalized;
    return {
      DeepAlignment.archConservative: archConservative,
      DeepAlignment.conservative: conservative,
      DeepAlignment.moderate: moderate,
      DeepAlignment.liberal: liberal,
      DeepAlignment.eliteLiberal: eliteLiberal,
    };
  }

  int approvalForAlign(DeepAlignment align, bool partisan) {
    Map<DeepAlignment, double> voters = voterSpread(publicMood());
    Iterable<MapEntry<DeepAlignment, double>> possibleSupporters;
    if (partisan) {
      if (presidentParty == PoliticalParty.democrat) {
        possibleSupporters = voters.entries
            .where((e) => e.key.index >= DeepAlignment.moderate.index);
      } else {
        possibleSupporters = voters.entries
            .where((e) => e.key.index <= DeepAlignment.moderate.index);
      }
    } else {
      possibleSupporters = voters.entries;
    }
    double accumulateSupport(
            double value, MapEntry<DeepAlignment, double> voter) =>
        value + voter.value / ((voter.key.index - align.index).abs() + 1);

    double actualSupport =
        possibleSupporters.fold<double>(0, accumulateSupport);
    return (actualSupport * 100).round();
  }

  int presidentialApproval() => approvalForAlign(exec[Exec.president]!, true);

  double lcsApproval() {
    double mood = publicMood();
    double lcsPopularity = publicOpinion[View.lcsLiked]!;
    double totalSupport = (lcsPopularity + mood) / 2;
    double heardOfLcs = publicOpinion[View.lcsKnown]!;
    return voterSpread(totalSupport)[DeepAlignment.eliteLiberal]! * heardOfLcs;
  }

  double ccsApproval() {
    double mood = 100 - publicMood();
    double ccsPopularity = publicOpinion[View.ccsLiked]!;
    double totalSupport = (ccsPopularity + mood) / 2;
    return voterSpread(totalSupport)[DeepAlignment.archConservative]! * 100;
  }

  List<View> viewsForLaw(Law law) => switch (law) {
        Law.abortion => [View.womensRights],
        Law.animalRights => [View.animalResearch],
        Law.policeReform => [View.policeBehavior],
        Law.privacy => [View.intelligence],
        Law.deathPenalty => [View.deathPenalty],
        Law.nuclearPower => [View.nuclearPower],
        Law.pollution => [View.pollution],
        Law.labor => [View.sweatshops],
        Law.lgbtRights => [View.lgbtRights],
        Law.corporate => [View.corporateCulture],
        Law.freeSpeech => [View.freeSpeech],
        Law.flagBurning => [View.freeSpeech],
        Law.gunControl => [View.gunControl],
        Law.taxes => [View.taxes],
        Law.genderEquality => [View.womensRights],
        Law.civilRights => [View.civilRights],
        Law.drugs => [View.drugs],
        Law.immigration => [View.immigration],
        Law.elections => [View.freeSpeech, View.justices],
        Law.military => [View.military],
        Law.prisons => [View.prisons],
        Law.torture => [View.intelligence, View.policeBehavior],
      };

  double publicSupportForLaw(Law law) {
    List<View> views = viewsForLaw(law);
    return views
            .map((v) => publicOpinion[v]!)
            .reduce((value, element) => value + element) /
        views.length;
  }

  int publicInterestForLaw(Law law) {
    List<View> views = viewsForLaw(law);
    return views
            .map((v) => publicInterest[v]!)
            .reduce((value, element) => value + element) ~/
        views.length;
  }
}

enum Exec {
  president,
  vicePresident,
  secretaryOfState,
  attorneyGeneral,
}

enum PoliticalParty {
  democrat,
  republican,
}
