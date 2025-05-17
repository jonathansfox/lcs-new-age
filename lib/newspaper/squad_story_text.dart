import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/location/site.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/alignment.dart';

String squadStoryTextLocation(NewsStory ns, bool liberalguardian, bool ccs,
    {bool includeOpening = true}) {
  String story = "";
  if (includeOpening) story += "  The events took place ";
  String placename = ns.loc!.getName();
  if (placename.substring(0, 4) == "The ") {
    placename = placename.substring(4);
  }
  int posand = placename.indexOf('&');
  if (posand != -1) {
    placename =
        "${placename.substring(0, posand)}and${placename.substring(posand + 1)}";
  }
  switch (ns.loc!.type) {
    //case SiteType.city:
    //   story += "in ";
    case SiteType.downtown:
    case SiteType.universityDistrict:
    case SiteType.outOfTown:
    case SiteType.industrialDistrict:
      if (placename == "Shopping") {
        placename = "Shopping Mall";
        story += "at the ";
      } else if (placename == "Travel") {
        placename = "Travel Agency";
        story += "at the ";
      } else if (placename == "Outskirts and Orange County") {
        placename = "Orange County";
        story += "in ";
      } else if (placename == "Brooklyn and Queens") {
        placename = "Long Island";
        story += "on ";
      } else if (placename == "Greater Hollywood") {
        placename = "Hollywood";
        story += "in ";
      } else if (placename == "Manhattan Island") {
        placename = "Manhattan";
        story += "in ";
      } else if (placename == "Arlington") {
        story += "in ";
      } else if (placename == "National Mall") {
        story += "on the ";
      } else if (placename != "Downtown") {
        story += "in the ";
      }
    case SiteType.pawnShop:
      if (placename.contains("'s")) {
        story += "at ";
        if (liberalguardian && !ccs) story += "the notorious ";
      } else {
        story += "at the ";
        if (liberalguardian && !ccs) story += "notorious ";
      }
    case SiteType.apartment:
    case SiteType.carDealership:
    case SiteType.departmentStore:
    case SiteType.publicPark:
      story += "at ";
      if (liberalguardian && !ccs) story += "the notorious ";
    default:
      story += "at the ";
      if (liberalguardian && !ccs) story += "notorious ";
  }
  if (ccs) {
    story += mapCCSPlace(ns.loc!, placename);
  } else {
    story += placename;
  }
  if (liberalguardian && !ccs) {
    switch (ns.loc!.type) {
      case SiteType.upscaleApartment:
        story += ", known for its rich and snooty residents.  ";
      case SiteType.barAndGrill:
        story += ", a spawning ground of Wrong Conservative Ideas.  ";
      case SiteType.cosmeticsLab:
        story += ", a Conservative animal rights abuser.  ";
      case SiteType.geneticsLab:
        story += ", a dangerous Conservative genetic research lab.  ";
      case SiteType.policeStation:
        story +=
            ", headquarters of one of the most oppressive and Conservative police forces in the country.  ";
      case SiteType.courthouse:
        story += ", site of numerous Conservative Injustices.  ";
      case SiteType.prison:
        story +=
            ", where innocent people are regularly beaten by Conservative guards.  ";
      case SiteType.intelligenceHQ:
        story +=
            ", the Conservative headquarters of one of the biggest privacy violators in the world.  ";
      case SiteType.armyBase:
        story +=
            ", pride of Conservative torturers and warmongers everywhere.  ";
      case SiteType.sweatshop:
        story += ", a Conservative sweatshop and human rights abuser.  ";
      case SiteType.dirtyIndustry:
        story +=
            ", a factory whose Conservative smokestacks choke the city with deadly pollutants.  ";
      case SiteType.nuclearPlant:
        story +=
            ", also known to be a Conservative storage facility for radioactive waste.  ";
      case SiteType.corporateHQ:
        story += ", where evil and Conservatism coagulate in the hallways.  ";
      case SiteType.ceoHouse:
        story +=
            ", a building with enough square footage enough to house a hundred people if it weren't in Conservative Hands.  ";
      case SiteType.amRadioStation:
      case SiteType.cableNewsStation:
        story += ", known for its Extreme Conservative Bias.  ";
      case SiteType.bank:
        story += ", the very symbol of economic inequality.  ";
      default:
        story += ".  ";
    }
  } else if (includeOpening) {
    story += ".  ";
  }
  return story;
}

String squadStoryTextOpening(NewsStory ns, bool liberalguardian, bool ccs) {
  String story = "";
  if (ns.type == NewsStories.squadSiteAction ||
      ns.type == NewsStories.squadKilledInSiteAction) {
    if (!lcscherrybusted && !liberalguardian) {
      if (ns.positive > 0) {
        String briefly =
            ns.type == NewsStories.squadKilledInSiteAction ? "briefly " : "";
        story += "A group calling itself the Liberal Crime Squad ";
        story +=
            "burst ${briefly}onto the scene of political activism yesterday, according ";
        story += "to a spokesperson from the police department.";
        story += "&r";
      } else {
        story +=
            "A group of terrorists calling themselves the Liberal Crime Squad ";
        story += "went on a rampage yesterday, according ";
        story += "to a spokesperson from the police department.";
      }
    } else {
      if (ns.positive > 0 || liberalguardian) {
        String albietWithTragicEnd =
            ns.type == NewsStories.squadKilledInSiteAction
                ? ", albiet with a tragic end"
                : "";
        story +=
            "The Liberal Crime Squad has struck again$albietWithTragicEnd.&r";
      } else {
        String notorious =
            ns.publicationAlignment == DeepAlignment.archConservative
                ? "notorious "
                : "";
        String terrorists =
            ns.publicationAlignment == DeepAlignment.archConservative
                ? "terrorists "
                : "";
        String another =
            ns.publicationAlignment == DeepAlignment.archConservative
                ? "another"
                : "a violent";
        String butTheyGotWhatTheyDeserved =
            ns.type == NewsStories.squadKilledInSiteAction
                ? ", but they got what they deserved"
                : "";
        story +=
            "The ${notorious}Liberal Crime Squad ${terrorists}went on $another rampage$butTheyGotWhatTheyDeserved.&r";
      }
    }
  } else if (ns.type == NewsStories.ccsSiteAction ||
      ns.type == NewsStories.ccsKilledInSiteAction) {
    if (!ccscherrybusted) {
      if (ns.positive > 0) {
        String wouldBe =
            ns.type == NewsStories.ccsKilledInSiteAction ? "would-be " : "";
        String vigilantes =
            ns.publicationAlignment == DeepAlignment.archConservative
                ? "patriots"
                : "heavily armed vigilantes";
        String briefly =
            ns.type == NewsStories.ccsKilledInSiteAction ? "briefly " : "";
        String accordingToThePolice =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? ""
                : ", according to a spokesperson from the police department";
        story +=
            "A group of $wouldBe$vigilantes calling themselves the Conservative Crime Squad ";
        story +=
            "burst ${briefly}onto the scene of political activism yesterday$accordingToThePolice.&r";
      } else {
        String wouldBe =
            ns.type == NewsStories.ccsKilledInSiteAction ? "would-be " : "";
        String terrorists =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? "terrorists"
                : "heavily armed vigilantes";
        String accordingToThePolice =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? ""
                : ", according to a spokesperson from the police department";
        String violent = ns.type == NewsStories.ccsKilledInSiteAction
            ? "violent "
            : "suicidal";
        story +=
            "A gang of $wouldBe$terrorists calling themselves the Conservative Crime Squad ";
        story += "went on a $violent rampage yesterday$accordingToThePolice.&r";
      }
    } else {
      if (ns.positive > 0 && !liberalguardian) {
        String patriotsHave =
            ns.publicationAlignment == DeepAlignment.archConservative
                ? "patriots have"
                : "has";
        story += "The Conservative Crime Squad $patriotsHave struck again.&r";
      } else {
        String terroristsHave =
            ns.publicationAlignment == DeepAlignment.eliteLiberal
                ? "terrorists"
                : "";
        story +=
            "The Conservative Crime Squad $terroristsHave went on another rampage.&r";
      }
    }
  }

  story += squadStoryTextLocation(ns, liberalguardian, ccs);

  if (ns.type == NewsStories.squadKilledInSiteAction) {
    if (liberalguardian) {
      story +=
          "Unfortunately, the LCS group was defeated by the forces of evil.";
    } else if (ns.positive > 0) {
      story += "Everyone in the LCS group was arrested or killed.";
    } else {
      story += "Fortunately, the LCS thugs were stopped by brave citizens.";
    }
  }
  if (ns.type == NewsStories.ccsKilledInSiteAction) {
    if (ns.publicationAlignment == DeepAlignment.archConservative) {
      story +=
          "Unfortunately, the CCS patriots were defeated by the forces of evil.";
    } else if (ns.positive > 0 && !liberalguardian) {
      story += "Everyone in the CCS group was arrested or killed.";
    } else {
      story += "Fortunately, the CCS brutes were stopped by brave citizens.";
    }
  }
  story += "&r";

  return story;
}

String mapCCSPlace(Site loc, String placename) {
  return {
        SiteType.upscaleApartment: "University Dormitory",
        SiteType.barAndGrill: "Gay Nightclub",
        SiteType.cosmeticsLab: "Animal Shelter",
        SiteType.geneticsLab: "Research Ethics Commission HQ",
        SiteType.policeStation: "Police Reform Office",
        SiteType.courthouse: "Abortion Clinic",
        SiteType.prison: "Rehabilitation Center",
        SiteType.intelligenceHQ: "Media Independence Office",
        SiteType.sweatshop: "Labor Union HQ",
        SiteType.dirtyIndustry: "Sustainable Energy Research Center",
        SiteType.nuclearPlant: "Whirled Peas Museum",
        SiteType.corporateHQ: "Welfare Assistance Agency",
        SiteType.ceoHouse: "Tax Collection Agency",
        SiteType.amRadioStation: "Public Radio Station",
        SiteType.cableNewsStation: "Network News Station",
        SiteType.armyBase: "Greenpeace Offices",
        SiteType.fireStation: "ACLU Branch Office",
        SiteType.bank: "Richard Dawkins Food Bank",
        SiteType.whiteHouse: "Progressive Lobbying Office",
      }[loc.type] ??
      placename;
}
