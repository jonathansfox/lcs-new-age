import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/location/location_type.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';

String squadStoryTextLocation(NewsStory ns, bool liberalguardian, bool ccs) {
  String story = "  The events took place ";
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
    switch (ns.loc!.type) {
      case SiteType.upscaleApartment:
        story += "University Dormitory.  ";
      case SiteType.barAndGrill:
        story += "Gay Nightclub.  ";
      case SiteType.cosmeticsLab:
        story += "Animal Shelter.  ";
      case SiteType.geneticsLab:
        story += "Research Ethics Commission HQ.  ";
      case SiteType.policeStation:
        story += "Police Reform Office.  ";
      case SiteType.courthouse:
        story += "Abortion Clinic.  ";
      case SiteType.prison:
        story += "Rehabilitation Center.  ";
      case SiteType.intelligenceHQ:
        story += "Media Independence Office.  ";
      case SiteType.sweatshop:
        story += "Labor Union HQ.  ";
      case SiteType.dirtyIndustry:
        story += "Greenpeace Offices.  ";
      case SiteType.nuclearPlant:
        story += "Whirled Peas Museum.  ";
      case SiteType.corporateHQ:
        story += "Welfare Assistance Agency.  ";
      case SiteType.ceoHouse:
        story += "Tax Collection Agency.  ";
      case SiteType.amRadioStation:
        story += "Public Radio Station.  ";
      case SiteType.cableNewsStation:
        story += "Network News Station.  ";
      case SiteType.armyBase:
        story += "Greenpeace Offices.  ";
      case SiteType.fireStation:
        story += "ACLU Branch Office.  ";
      case SiteType.bank:
        story += "Richard Dawkins Food Bank.  ";
      default:
        story += placename;
        story += ".  ";
    }
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
  } else if (!ccs) {
    story += ".  ";
  }
  return story;
}

String squadStoryTextOpening(NewsStory ns, bool liberalguardian, bool ccs) {
  String story = "";
  if (ns.type == NewsStories.squadSiteAction) {
    if (!lcscherrybusted && !liberalguardian) {
      if (ns.positive > 0) {
        story += "A group calling itself the Liberal Crime Squad ";
        story +=
            "burst onto the scene of political activism yesterday, according ";
        story += "to a spokesperson from the police department.";
        story += "&r";
      } else {
        story +=
            "A group of terrorists calling itself the Liberal Crime Squad ";
        story += "went on a rampage yesterday, according ";
        story += "to a spokesperson from the police department.";
      }
    } else {
      if (ns.positive > 0 || liberalguardian) {
        story += "The Liberal Crime Squad has struck again.  ";
        story += "&r";
      } else {
        story += "The Liberal Crime Squad has gone on a rampage.  ";
        story += "&r";
      }
    }
  } else if (ns.type == NewsStories.ccsSiteAction) {
    if (!ccscherrybusted) {
      if (ns.positive > 0 && !liberalguardian) {
        story +=
            "A group of M16-wielding vigilantes calling itself the Conservative Crime Squad ";
        story +=
            "burst onto the scene of political activism yesterday, according ";
        story += "to a spokesperson from the police department.";
        story += "&r";
      } else {
        story +=
            "A gang of worthless M16-toting hicks calling itself the Conservative Crime Squad ";
        story += "went on a rampage yesterday, according ";
        story += "to a spokesperson from the police department.";
      }
    } else {
      if (ns.positive > 0 && !liberalguardian) {
        story += "The Conservative Crime Squad has struck again.  ";
        story += "&r";
      } else {
        story += "The Conservative Crime Squad has gone on another rampage.  ";
        story += "&r";
      }
    }
  } else if (ns.type == NewsStories.ccsKilledInSiteAction) {
    if (!ccscherrybusted) {
      if (ns.positive > 0 && !liberalguardian) {
        story +=
            "A group of M16-wielding vigilantes calling themselves the Conservative Crime Squad ";
        story +=
            "burst briefly onto the scene of political activism yesterday, according ";
        story += "to a spokesperson from the police department.  ";
        story += "&r";
      } else {
        story += "A gang of worthless M16-toting hicks ";
        story +=
            "calling themselves the Conservative Crime Squad went on a suicidal ";
        story +=
            "rampage yesterday, according to a spokesperson from the police department.  ";
        story += "&r";
      }
    } else {
      if (ns.positive > 0 && !liberalguardian) {
        story +=
            "The Conservative Crime Squad has struck again, albeit with a tragic end.  ";
        story += "&r";
      } else {
        story +=
            "The Conservative Crime Squad has gone on another rampage, and they got what they deserved.  ";
        story += "&r";
      }
    }
  } else {
    if (!lcscherrybusted && !liberalguardian) {
      if (ns.positive > 0) {
        story += "A group calling itself the Liberal Crime Squad ";
        story +=
            "burst briefly onto the scene of political activism yesterday, according ";
        story += "to a spokesperson from the police department.  ";
        story += "&r";
      } else {
        story +=
            "A group of would-be terrorists calling itself the Liberal Crime Squad ";
        story += "went on a suicidal rampage yesterday, according ";
        story += "to a spokesperson from the police department.  ";
        story += "&r";
      }
    } else {
      if (ns.positive > 0 || liberalguardian) {
        story +=
            "The Liberal Crime Squad has struck again, albeit with a tragic end.  ";
        story += "&r";
      } else {
        story +=
            "The Liberal Crime Squad has gone on a rampage, and they got what they deserved.  ";
        story += "&r";
      }
    }
  }

  story += squadStoryTextLocation(ns, liberalguardian, ccs);

  if (ns.type == NewsStories.squadKilledInSiteAction) {
    if (liberalguardian) {
      story +=
          "Unfortunately, the LCS group was defeated by the forces of evil.  ";
    } else if (ns.positive > 0) {
      story += "Everyone in the LCS group was arrested or killed.  ";
    } else {
      story += "Fortunately, the LCS thugs were stopped by brave citizens.  ";
    }
  }
  if (ns.type == NewsStories.ccsKilledInSiteAction) {
    if (ns.positive > 0 && !liberalguardian) {
      story += "Everyone in the CCS group was arrested or killed.  ";
    } else {
      story += "Fortunately, the CCS thugs were stopped by brave citizens.  ";
    }
  }
  story += "&r";

  return story;
}
