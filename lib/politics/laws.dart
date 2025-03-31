import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/politics/alignment.dart';

enum Law {
  abortion("Abortion Rights", [
    "Use of contraception and abortion are capital offenses.",
    "Abortion is a felony equal to murder.",
    "Abortion is only permitted in the event of rape or incest.",
    "Abortion is legal in some states.",
    "Abortion is legal in most states.",
    "Abortion is legal.",
    "Free abortions are easily available at any time during pregnancy.",
  ]),
  animalRights("Animal Rights", [
    "All manner of human experimentation on the poor is encouraged.",
    "Animals on farms and in research labs are effectively tortured to death.",
    "Minimal animal welfare laws stop only the most extravagant abuses.",
    "Use of animals in farming and research is governed by animal welfare laws.",
    "A bill of animal rights is in place governing their treatment.",
    "Animals may own property, speak, marry, and become US citizens.",
    "All species of life have equal rights, even bacteria.",
  ]),
  policeReform("Police Regulation", [
    "Policing is administered by corporations and has a draft.",
    "Law enforcement is given carte blanche to administer violent justice.",
    "Even the worst police misconduct only earns slap-on-the-wrist punishments.",
    "Law enforcement is regulated to prevent extreme misconduct.",
    "Law enforcement has heavy oversight and freedom-of-information requirements.",
    "The police are demilitarized and funding has been shifted to community aid.",
    "With no police, criminals follow the honor system and turn themselves in.",
  ]),
  privacy("Privacy Rights", [
    "Extensive files on each citizen are provided to corporations.",
    "Corporations have no limits on their ability to access private information.",
    "Privacy laws are nominal and weakly enforced.",
    "Basic safeguards for medical and financial privacy are in place.",
    "All areas of privacy are protected with strong safeguards.",
    "Individual privacy is sacred.",
    "All large organizations are prohibited from keeping any data about anyone.",
  ]),
  deathPenalty("Death Penalty", [
    "Poor criminals receive mandatory death sentences.",
    "People are regularly put to death for minor offenses.",
    "The death penalty is actively enforced in many states.",
    "The death penalty is permitted but only rarely applied.",
    "The death penalty has been abolished in most states.",
    "The death penalty has been abolished in all fifty states.",
    "The death penalty, like all other punishments, has been abolished.",
  ]),
  nuclearPower("Nuclear Power", [
    "Slums are used as nuclear waste dumping sites.",
    "Nuclear power is proliferating with no controls.",
    "Nuclear power is a preferred energy source.",
    "Nuclear power is allowed, but other options are preferred.",
    "Nuclear power is intensely regulated and seldom used.",
    "Nuclear power is illegal.",
    "A global ban on nuclear power and nuclear weapons is enforced by UN inspectors.",
  ]),
  pollution("Pollution", [
    "Deformed children are the norm in industrial zones.",
    "Industry may pollute as much as they like.",
    "Industry is subject to minimal pollution regulations.",
    "Industry is subject to moderate pollution regulations.",
    "Industry is subject to strict pollution regulations.",
    "Industry is subject to zero-tolerance pollution regulations.",
    "Pollution is unheard of, and nature has reclaimed much of the land.",
  ]),
  labor("Labor Rights", [
    "People are bred in pens to be farmed out to corporations like beasts.",
    "There is no weekend and children are forced to work.",
    "Working conditions are miserable and the minimum wage is low.",
    "Workers still require some benefits.",
    "Workers are fairly compensated and have benefits.",
    "There are universal workers' rights and high wages.",
    "All work is voluntary and unpaid, and people are free to pursue their passions.",
  ]),
  lgbtRights("LGBT Rights", [
    "Sexual minorities are lined up and shot.",
    "Gender and sexual deviants are rounded up and forced into conversion camps.",
    "Sodomy is a crime and all discrimination against LGBT people is legal.",
    "Same sex marriages are not legally recognized.",
    "Same sex marriage is legal, but trans rights vary widely from state to state.",
    "Transgender and nonbinary identities are legally recognized nationwide.",
    "All sexual minorities are embraced, and most people are polyamorous.",
  ]),
  corporate("Corporate Law", [
    "Corporations under the King run the country in a feudal system.",
    "Corporations essentially run the country in a feudal system.",
    "Corporate culture is corrupt and there is a great disparity in wages.",
    "Corporations are moderately regulated, although wages are still unfair.",
    "Corporations are stiffly regulated, and executives are fairly compensated.",
    "Corporations are subject to intense regulation, and there is a maximum wage law.",
    "Corporations are illegal, and all businesses are worker-owned cooperatives.",
  ]),
  freeSpeech("Free Speech", [
    "Opening your mouth is a capital crime.",
    "Intelligence agents are tasked with suppressing unacceptable speech.",
    "The government has extensive content guidelines for the media.",
    "The government censors some offensive content in the media.",
    "Government censorship is kept to a minimum.",
    "The government does not censor speech.",
    "Free speech is sacrosanct and diverse points of view are celebrated.",
  ]),
  flagBurning("Flag Burning", [
    "Images or words describing flag burning are punished by death.",
    "Burning the flag is a crime on par with murder.",
    "Burning the flag is a felony.",
    "Flag burning is a misdemeanor.",
    "Flag burning is legal when done as political speech.",
    "Flag burning is legal.",
    "Flag burning is traditionally done on July 4th to celebrate freedom.",
  ]),
  gunControl("Gun Control", [
    "Gangs of young children carrying AK-47s roam the streets.",
    "All manner of military weapons can be bought and sold freely.",
    "Semi-automatic versions of military rifles are widely available.",
    "A comprehensive ban on military-style weapons is in effect.",
    "Handguns cannot be sold to anyone outside of law enforcement.",
    "It is illegal to buy, sell, or carry a gun in public.",
    "All gun manufacturers have been shut down and all existing guns destroyed.",
  ]),
  taxes("Tax Structure", [
    "The only tax is a poverty tax, and nobody has any money to pay it.",
    "The tax code is a nightmare designed to maintain class structure.",
    "A flat tax is in effect, and there is no capital gains or inheritance tax.",
    "Taxes are moderate, but the code is full of loopholes.",
    "The wealthy are heavily taxed under a progressive taxation system.",
    "Rich people are virtually unheard of, due to taxation.",
    "Money no longer exists, everything is free, and everyone enjoys lives of luxury.",
  ]),
  genderEquality("Gender Equality", [
    "Women are treated as property and rape has been legalized.",
    "Women are second-class citizens.",
    "Most non-discrimination laws do not apply to gender.",
    "Though nominally equal, women are paid significantly less than men.",
    "Women have substantial recourse against discrimination.",
    "Gender equality is universally respected.",
    "Binary gender identities no longer exist, and gender segregation has ended.",
  ]),
  civilRights("Civil Rights", [
    "Slavery has been reintroduced and is practiced on a large scale.",
    "Racial discrimination is prohibited in name only.",
    "Civil rights laws are inconsistently enforced.",
    "Pervasive racial inequality exists.",
    "Affirmative action is in place to counteract discrimination.",
    "Racial equality is guaranteed and vigorously enforced.",
    "The very idea of \"race\" has been universally discarded as pseudoscience.",
  ]),
  drugs("Drug Laws", [
    "Thinking about recreational drugs is punishable by death.",
    "Violent criminals are released to make room for drug offenders.",
    "Prisons are filled with the targets of the war on drugs.",
    "Marijuana is decriminalized in some states.",
    "Marijuana is regulated and taxed.",
    "Recreational drugs are regulated and taxed.",
    "The government distributes free recreational drugs to anyone who wants them.",
  ]),
  immigration("Immigration", [
    "Border guards shoot suspected foreigners on sight.",
    "Immigration is illegal, and noncitizens are shipped to Mexico at gunpoint.",
    "The military has been deployed to the borders to slow immigration.",
    "Great expense is taken to slow immigration, without success.",
    "The government works to accommodate potential immigrants.",
    "Immigration is unregulated.",
    "Borders are open and anyone can come and go as they please.",
  ]),
  elections("Election Reform", [
    "Anyone who challenges the ruling oligarchy is sentenced to death.",
    "Politicians routinely alter election tallies when they don't like the results.",
    "Politicians try to get votes thrown out when they don't like the results.",
    "Election rules make it harder for poor people to vote in the name of security.",
    "Elections are run fairly, though they remain heavily influenced by big money.",
    "Election expenses are publicly funded, and voting is by ranked list.",
    "There is proportional representation, and over a dozen major political parties.",
  ]),
  military("Military Spending", [
    "The purpose of the massive military is domestic political oppression.",
    "The massive military is utterly choked with graft and corruption.",
    "Massive investment is put into maintaining an overwhelming military.",
    "Military spending is growing each year.",
    "Military spending has stabilized.",
    "Military spending has been cut in favor of domestic programs.",
    "The military has been abolished, and the entire world is at peace.",
  ]),
  prisons("Prison Reform", [
    "Prisoners are not considered people by the law.",
    "Prisoners are often subject to torture and slave labor.",
    "Prisoners suffer from horrible conditions and lack many basic rights.",
    "Prisoners receive basic rights and services.",
    "The prisons are regulated to protect prisoners' rights.",
    "The prisons are targeted at rehabilitation, rather than punishment.",
    "Instead of prison, criminals voluntarily attend free support groups.",
  ]),
  torture("Torture", [
    "Police torture innocents to death if they don't give false confessions.",
    "Police interrogators torture suspects to extract false confessions.",
    "Military interrogation manuals openly encourage torturing prisoners.",
    "\"Enhanced interrogation practices\" are sometimes used on noncitizens.",
    "The government insists that it does not torture anyone.",
    "The government consistently enforces a ban on torture.",
    "Terrorism ended after the government formally apologized to terrorist leaders.",
  ]);

  const Law(this.label, this.description);
  final String label;
  final List<String> description;
}

String billName(Law l, bool liberal) {
  switch (l) {
    case Law.animalRights:
      if (liberal) {
        return "Protect Animal Welfare";
      } else {
        return "Deregulate Animal Research";
      }
    case Law.policeReform:
      if (liberal) {
        return "Stop Police Misconduct";
      } else {
        return "Expand Law Enforcement";
      }
    case Law.privacy:
      if (liberal) {
        return "Protect Individual Privacy";
      } else {
        return "Deregulate Infotech Industry";
      }
    case Law.deathPenalty:
      if (liberal) {
        return "Stop Barbaric Executions";
      } else {
        return "Expand Capital Punishment";
      }
    case Law.nuclearPower:
      if (liberal) {
        return "Promote Green Energy";
      } else {
        return "Promote Nuclear Power";
      }
    case Law.pollution:
      if (liberal) {
        return "Protect our Environment";
      } else {
        return "Deregulate Manufacturing";
      }
    case Law.labor:
      if (liberal) {
        return "Protect Workers' Rights";
      } else {
        return "Restrict Corrupt Union Organizing";
      }
    case Law.lgbtRights:
      if (liberal) {
        return "Protect LGBT Rights";
      } else {
        return "Save Children from the LGBT Agenda";
      }
    case Law.corporate:
      if (liberal) {
        return "Stop Corporate Criminals";
      } else {
        return "Lower Corporate Tax Rates";
      }
    case Law.freeSpeech:
      if (liberal) {
        return "Protect Free Speech";
      } else {
        return "Save Children from Harmful Speech";
      }
    case Law.taxes:
      if (liberal) {
        return "Raise Taxes on Higher Incomes";
      } else {
        return "Flatten the Tax Structure";
      }
    case Law.flagBurning:
      if (liberal) {
        return "Limit Prohibitions on Flag Burning";
      } else {
        return "Protect the Symbol of Our Nation";
      }
    case Law.gunControl:
      if (liberal) {
        return "Restrict Access to Guns";
      } else {
        return "Protect our Second Amendment Rights";
      }
    case Law.genderEquality:
      if (liberal) {
        return "Promote Gender Equality";
      } else {
        return "Stop Feminist Overreach";
      }
    case Law.abortion:
      if (liberal) {
        return "Strengthen Abortion Rights";
      } else {
        return "Protect the Unborn Child";
      }
    case Law.civilRights:
      if (liberal) {
        return "Promote Racial Equality";
      } else {
        return "Stop Reverse Discrimination";
      }
    case Law.drugs:
      if (liberal) {
        return "Repeal Oppressive Drug Laws";
      } else {
        return "Fight Drug Trafficking";
      }
    case Law.immigration:
      if (liberal) {
        return "Protect Immigrant Rights";
      } else {
        return "Protect our Borders";
      }
    case Law.elections:
      if (liberal) {
        return "Fight Political Corruption";
      } else {
        return "Deregulate Political Fundraising";
      }
    case Law.military:
      if (liberal) {
        return "Regulate Defense Industries";
      } else {
        return "Subsidize Defense Industries";
      }
    case Law.torture:
      if (liberal) {
        return "Ban Torture Techniques";
      } else {
        return "Permit New Interrogation Tactics";
      }
    case Law.prisons:
      if (liberal) {
        if (laws[Law.prisons] == DeepAlignment.liberal) {
          return "Focus Prisons on Rehabilitation";
        } else {
          return "Improve Prison Conditions";
        }
      } else {
        return "Enhance Prison Security";
      }
  }
}
