import 'package:lcs_new_age/basemode/activities.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/utils/colors.dart';

void _body(String s) {
  setColor(lightGray);
  addparagraph(3, 1, s);
}

void _head(String s) => mvaddstrc(1, 1, lightGreen, s);

void _footer() =>
    addOptionText(console.y + 1, 1, "any key", "Press any key to continue.");

Future<void> helpOnActivity(ActivityType type) async {
  erase();
  switch (type) {
    case ActivityType.communityService:
      _head("=== Community Service ===");
      _body("Community service is a safe way to improve public opinion of the "
          "LCS, assuming anyone has heard of you and cares what you're doing. "
          "Planting trees and handing out food to the homeless is not going to "
          "get you into the news and make you a household name if you're not "
          "giving people another reason to care.\n\n"
          "The other power community service has is that it can forge civilians "
          "into activists, steadily increasing Juice up to a maximum of 10.");
    case ActivityType.trouble:
      _head("=== Liberal Disobedience ===");
      _body("Liberal Disobedience is an occasionally illegal "
          "form of Liberal Activism which has a modest Liberalizing effect on "
          "Public Opinion on a handful of issues. Although not without risk, "
          "it is not as dangerous as some other activities, and Liberals who "
          "are caught will usually face only small amounts of jail time.\n\n"
          "Liberal Disobedience can be used to gain up to 50 juice.\n\n"
          "Art and Street Smarts are the most important skills for this "
          "activity, and will improve the impact on public opinion. Street "
          "Smarts will also reduce the chance of being hassled by the cops "
          "or jumped by vigilantes.");
    case ActivityType.graffiti:
      _head("=== Graffiti ===");
      _body("Spraying political graffiti is a misdemeanor, carrying with it "
          "relatively short jail sentences. Liberals with low art will spread "
          "LCS tags around town, increasing public awareness of the Liberal "
          "Crime Squad. Liberals with greater Art skills will occasionally work on "
          "politically charged murals that can influence public opinion on "
          "various issues. The size of this impact is not large, however.\n\n"
          "Your artists will put their own names out there and gain in street "
          "credibility, gaining juice over time. Tagging caps out at 50 "
          "juice, while murals by very skilled artists can potentially raise "
          "Liberals to higher levels, if they're good enough.\n\n"
          "Art and Street Smarts are the most important skills for this "
          "activity. Art will make murals more frequent and more effective, "
          "while Street Smarts is essential for avoiding the cops.\n\n"
          "Liberals need to equip spraypaint to do graffiti. Those without "
          "will spend the first day buying some.");
    case ActivityType.hacking:
      _head("=== Hacking ===");
      _body("Hacking is a highly illegal form of Liberal Activism, which has "
          "a Liberalizing effect on public opinion and can be used to "
          "collect secret documents to publish in the Liberal Guardian.  "
          "Although there is no chance of the cops showing up mid-hack, "
          "the heat your hackers bring onto their safehouse can be very "
          "significant, and may lead to your bases being raided.\n\n"
          "Computers is necessary for both making a successful hacking attempt "
          "and avoiding the crime being traced back to your hackers.\n\n"
          "Due to its high risk, hacking can increase Juice up to a cap of 200.");
    case ActivityType.writeGuardian:
      _head("=== Write for the Liberal Guardian ===");
      _body("The Liberal Guardian is the LCS's media presence. In another era, "
          "it would have been a printed newspaper, but in New Age you have a "
          "multimedia website.\n\n"
          "Writing for the Liberal Guardian puts articles up on the website.  "
          "That's fine. It's is a safe but slow way to influence public "
          "opinion on a wide variety of issues. It costs nothing to throw "
          "some blog posts up on the internet, but it will take a long time "
          "to make any real difference.\n\n"
          "For a 4x more effective version of this activity, consider setting up "
          "a streaming room in an abandoned warehouse to do some video "
          "streaming.\n\n"
          "The greatest power of the Liberal Guardian comes when you publish "
          "a special edition. This requires you to have collected "
          "some secret documents to leak. Once you've dug something up, "
          "you'll get the opportunity to run a special edition at the end of "
          "the month. You don't NEED to have "
          "anyone write or stream regularly to publish a special edition, but "
          "there isn't much point without them. Writers are better than "
          "streamers for maximizing the impact of a special edition.");
    case ActivityType.streamGuardian:
      _head("=== Stream for the Liberal Guardian ===");
      _body("The Liberal Guardian is the LCS's media presence. In another era, "
          "it would have been a printed newspaper, but in New Age you have a "
          "multimedia website.\n\n"
          "Streaming for the Liberal Guardian uses the platform to host "
          "video streams where you engage directly with the audience while "
          "debating issues. It's four times as effective as writing articles, "
          "but you'll still need to defang the Conservative Media Machine "
          "before your message can really cut through the propaganda.\n\n"
          "The greatest power of the Liberal Guardian comes when you publish "
          "a special edition. This requires you to have collected "
          "some secret documents to leak. Once you've dug something up, "
          "you'll get the opportunity to run a special edition at the end of "
          "the month. You don't NEED to have "
          "anyone write or stream regularly to publish a special edition, but "
          "there isn't much point without them. Writers are better than "
          "streamers for maximizing the impact of a special edition.");
    case ActivityType.donations:
      _head("=== Solicit Donations ===");
      _body("Soliciting donations is a safe way to raise funds for the LCS.  "
          "It is much more lucrative when the public is very Conservative, "
          "because it's not about how many people agree with you, it's about "
          "how willing the Liberals you hit up are to donate to an extremist "
          "cause.\n\n"
          "This really doesn't do much if the public is Liberal. They're "
          "donating to politicians or whatever instead.\n\n"
          "Persuasion and Street Smarts are essential when soliciting "
          "donations. Also, try wearing a suit. For some reason, people give "
          "more money if you look trustworthy, and trustworthy means rich. "
          "Honestly disgusting, but that's the system.");
    case ActivityType.sellTshirts:
      _head("=== Sell Clothing ===");
      _body("Selling Clothing is a safe way to raise funds for the LCS. It is "
          "more lucrative when the public is very Conservative, because it's "
          "not about how many people have your back, it's about how radical "
          "and edgy your merch is. You're just not cool enough for your merch "
          "to take off in Liberal society. This is less important than it is "
          "if you're just soliciting donations though. If your fashion isn't "
          "counterculture anymore, you can always just sell Che Guevara "
          "prints to hipsters who think undermining capitalism is buying "
          "a t-shirt.\n\n"
          "Tailoring and Business will improve revenues.");
    case ActivityType.sellMusic:
      _head("=== Perform Music ===");
      _body("Performing Music is a safe way to raise funds for the LCS. It is "
          "more lucrative when the public is very Conservative, because it's "
          "not about how many people have your back, it's about how radical "
          "and edgy your music is. You're just not cool enough for your music "
          "to turn heads in Liberal society. This is less important than it "
          "is if you're just soliciting donations though. If protest songs "
          "don't hit like they used to, you can always just play covers of "
          "John Lennon's \"Imagine\".\n\n"
          "Music and Business will improve revenues. Make sure to equip a "
          "guitar. Drumming on buckets makes a lot less money.");
    case ActivityType.sellArt:
      _head("=== Sell Art ===");
      _body("Selling Art is a safe way to raise funds for the LCS. It is more "
          "lucrative when the public is very Conservative, because it's not "
          "about how many people have your back, it's about how radical and "
          "edgy your art is. You're just not cool enough for your art to draw "
          "big buyers in Liberal society. This is less important than it "
          "is if you're just soliciting donations though. If rebel art goes "
          "out of style, you can always just draw people's fursonas.\n\n"
          "Art and Business will improve revenues.");
    case ActivityType.sellDrugs:
      _head("=== Selling Weed Brownies ===");
      _body("Selling Brownies on the street is an illegal but rewarding "
          "way to make money. Money earned is based on the activist's "
          "Persuasion, Street Smarts, and Business. It is significantly more "
          "lucrative when drug laws are very Conservative, but so are the "
          "risks.\n\n"
          "Street Smarts is essential for avoiding the cops. If you're "
          "busted, the consequences can vary greatly depending on drug laws.");
    case ActivityType.prostitution:
      _head("=== Prostitution ===");
      _body("Prostitution is an illegal but rewarding way to make money. "
          "The amount of money is based primarily on Seduction, but also "
          "on Street Smarts and Business.\n\n"
          "Sometimes your clients will be cops. Some of those cops are "
          "out to get you. Street Smarts is essential to avoid this.\n\n"
          "You are very vulnerable while doing this activity. If you get "
          "caught in a police sting, you won't have a chance to fight your "
          "way or out or run, you're going straight to the lockup.");
    case ActivityType.ccfraud:
      _head("=== Credit Card Fraud ===");
      _body("Credit Card Fraud is an illegal but rewarding way to make money.  "
          "The more computer skill you bring to the table, the more money "
          "you will make. Computer skill helps protect you from getting "
          "caught, but the bigger paydays from high skill offset this by "
          "exposing you to increased law enforcement scrutiny.\n\n"
          "Your hackers will work together, and assigning many people to "
          "Credit Card Fraud will have diminishing returns.\n\n"
          "You do this from your hacker den, so the suits won't arrest you "
          "in the middle of the act, even if they figure out what you're "
          "doing. Charges will instead accumulate and bring heat down on the "
          "safehouse, eventually leading to a police raid.");
    case ActivityType.stealCars:
      _head("=== Stealing Cars ===");
      _body("Stealing a car will have the Liberal attempt to steal a car from "
          "the street. If successful, the car will be added to your garage.  "
          "Street Smarts determines the chances of finding a specific type of "
          "car, Security determines the chances of jimmying the lock or hotwiring "
          "the car. Strength is used to smash open the car window if you "
          "want to take that route.\n\n"
          "If you run into the The Viper, understand that it's just some silly "
          "aftermarket car alarm with a proximity sensor and a voice module. "
          "The car is not actually venomous, it does not have fangs, the snake "
          "isn't real and it can't hurt you. You can disable the annoying "
          "voice module once you get the engine started.\n\n"
          "It's the cops you have to worry about. Unfortunately, cops love car "
          "alarms and broken windows.");
    case ActivityType.bury:
      _head("=== Corpse Disposal ===");
      _body("Bodies piling up generates a lot of heat. Taking some time to "
          "get rid of them is important to keeping the cops off your back.\n\n"
          "Street Smarts helps to avoid any police attention.");
    case ActivityType.clinic:
      _head("=== Get To The Hospital ===");
      _body("Injuries can be healed slowly at home, but for anything serious "
          "you're going to need professional care. This activity hauls a "
          "Liberal off to get medical attention.");
    case ActivityType.makeClothing:
      _head("=== Make Clothing or Armor ===");
      _body("Tailoring skill is used to make clothing and armor. The first "
          "step is choosing a disguise, and then you select how much armor "
          "you want to integrate into the kit, which may affect the cost and "
          "difficulty of crafting the kit. Most disguises can only support "
          "wearing well-concealed soft armor underneath, but "
          "some clothes allow you to add hard armor over the top without "
          "looking out of place. Obvious displays of heavier armor are "
          "generally only allowed when crafting police and military "
          "disguises.\n\n"
          "Wearing darker colored clothing also helps with stealth. Don't "
          "think about that too much, it just works.");
    case ActivityType.wheelchair:
      _head("=== Get a Wheelchair ===");
      _body("Wheelchairs are used to help the disabled get around. If you "
          "have this option available, you need one.");
    case ActivityType.recruiting:
      _head("=== Recruit ===");
      _body("Recruiting is a safe way to meet people of a specific job.  Not "
          "all jobs are available in the recruiting interface, but many "
          "valuable, important, or just iconic jobs are.");
    case ActivityType.study:
      _head("=== Practice ===");
      _body(
          "Practicing is slower than taking classes, but it's free and has no "
          "cap on how much you can learn. People with higher skill caps "
          "will learn faster.");
    case ActivityType.takeClass:
      _head("=== Take Classes ===");
      _body("Taking a class is faster than practicing, but it costs money and "
          "has a cap on how much you can learn. People with higher skill "
          "caps will learn faster.");
    case ActivityType.teachFighting:
    case ActivityType.teachCovert:
    case ActivityType.teachLiberalArts:
      _head("=== Teaching ===");
      _body("Teaching is a way to pass on your skills to others. Every LCS "
          "member in the city who has something to learn will attend your "
          "class, and you will teach them all.\n\n"
          "Expenses scale with the number of students and skills being "
          "taught, up to a point, and then the rate of learning will slow.\n\n"
          "The Teaching skill will greatly speed up the learning process, "
          "and teachers more proficient in a skill will also teach it faster.  "
          "Teachers can only teach what they know, so if you want to reach "
          "higher levels, you'll need to improve the teacher's skills.");
    case ActivityType.none:
      _head("=== Laying Low ===");
      _body("Doing nothing is a safe way to avoid trouble. It is not a "
          "particularly effective way to change the world.\n\n"
          "Liberals who hang out at the safehouse will still pitch in and "
          "do some laundry and mending as needed.");
    case ActivityType.visit:
      _head("=== Site Visit ===");
      _body("Liberals acting with their squad to visit a location will not "
          "be able to do anything else that day.");
    case ActivityType.interrogation:
      _head("=== Interrogation ===");
      _body("You're trying to do what? Yeah, I don't know. Interrogating "
          "people you locked up in a back room sounds like *cop shit*. You're "
          "on your own for this one.");
    default:
      _head("=== Unknown Activity ===");
      _body("This activity is not yet documented.");
  }
  _footer();
  await getKey();
}

Future<void> helpOnSitemode() async {
  erase();
  _head("=== Direct Action ===");
  _body("You are taking direct action against the Conservative Menace.\n\n"
      "If you commit enough crimes, the media will usually report on your "
      "actions. This is generally a good thing. The more crimes you commit, "
      "and the more media attention you can attract, the greater the potential "
      "positive impact on public opinion.\n\n"
      "If you start causing trouble, people may call the cops or other "
      "reinforcements. Getting out quickly is safer than an occupation.\n\n"
      "Killing anyone during direct action will draw a lot of heat and cause "
      "the news coverage to skew hostile to the LCS. Frequent negative "
      "media coverage will eventually alienate everyone against you, limiting "
      "your ability to influence public opinion in the future. Mix up your "
      "tactics to maintain positive sentiment toward your squad.");
  _footer();
  await getKey();
}
