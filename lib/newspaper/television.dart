import 'package:lcs_new_age/creature/gender.dart';
import 'package:lcs_new_age/creature/name.dart';
import 'package:lcs_new_age/engine/engine.dart';
import 'package:lcs_new_age/gamestate/game_state.dart';
import 'package:lcs_new_age/newspaper/display_news.dart';
import 'package:lcs_new_age/newspaper/news_story.dart';
import 'package:lcs_new_age/politics/views.dart';
import 'package:lcs_new_age/saveload/load_cmv_movies.dart';
import 'package:lcs_new_age/utils/colors.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

Future<void> runTelevisionNewsStories() async {
  for (int n = newsStories.length - 1; n >= 0; n--) {
    bool del = false;
    Map<View, double> beforeOpinion =
        Map.from(gameState.politics.publicOpinion);
    if (newsStories[n].type == NewsStories.majorEvent) {
      if (newsStories[n].liberalSpin) {
        switch (newsStories[n].view) {
          case View.policeBehavior:
            newsStories[n].headline = "POLICE BRUTALITY";
            newsStories[n].body =
                "The police have brutally beaten a black man in Los Angeles.  "
                "The entire thing is caught on video by a passerby and it "
                "saturates the news.";
            await movie.loadmovie("lacops.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);

            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     The police have brutally beaten a black man   │");
            mvaddstr(21, 13,
                "│   in Los Angeles.  The entire thing is caught on  │");
            mvaddstr(22, 13,
                "│   video by a passerby and it saturates the news.  │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");

            await getKey();

            del = true;
          case View.cableNews:
            newsStories[n].publication = Publication.cableNews;
            String str = "Tonight on a Cable News channel: ";
            String showName =
                ["Inside", "Hard", "Lightning", "Washington", "Capital"].random;
            showName +=
                [" Record", " Night", " Talk", " Insider", " Report"].random;
            showName += " with ";
            String bname =
                generateFullName(Gender.whiteMalePatriarch).firstLast;
            showName += bname;
            str += showName;
            newsStories[n].headline = showName.toUpperCase();
            newsStories[n].body =
                "A Cable News anchor just accidentally let a Liberal guest "
                "finish a sentence.  Many viewers across the nation were "
                "listening.";
            erase();
            mvaddstrc(0, 39 - ((str.length - 1) >> 1), white, str);
            mvaddstr(16, 20, bname);
            move(17, 20);
            switch (lcsRandom(3)) {
              case 0:
                addstr("Washington, DC");
              case 1:
                addstr("New York, NY");
              case 2:
                addstr("Atlanta, GA");
            }
            move(16, 41);
            addstr(generateFullName(Gender.nonbinary).firstLast);
            move(17, 41);
            switch (lcsRandom(4)) {
              case 0:
                addstr("Eugene, OR");
              case 1:
                addstr("San Francisco, CA");
              case 2:
                addstr("Cambridge, MA");
              case 3:
                addstr("Ithaca, NY");
            }
            await movie.loadmovie("newscast.cmv");
            await movie.playmovie(1, 1, remapSkinTones: true);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A Cable News anchor just accidentally let a   │");
            mvaddstr(21, 13,
                "│   bright Liberal guest finish a sentence.  Many   │");
            mvaddstr(22, 13,
                "│   viewers across the nation were listening.       │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          default:
        }
      } else {
        switch (newsStories[n].view) {
          case View.ceoSalary:
            newsStories[n].publication = Publication.cableNews;
            newsStories[n].headline = "THE AMERICAN DREAM";
            newsStories[n].body =
                "A new show glamorizing the lives of the rich begins "
                "airing this week.  With the nationwide advertising "
                "blitz, it's bound to be popular.";
            await movie.loadmovie("glamshow.cmv");
            await movie.playmovie(0, 0);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A new show glamorizing the lives of the rich  │");
            mvaddstr(21, 13,
                "│   begins airing this week.  With the nationwide   │");
            mvaddstr(22, 13,
                "│   advertising blitz, it's bound to be popular.    │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          case View.cableNews:
            newsStories[n].publication = Publication.cableNews;
            newsStories[n].headline = "NEW ANCHOR";
            newsStories[n].body =
                "A major Cable News channel has hired a slick new anchor "
                "for one of its news shows.  Guided by impressive "
                "advertising, America tunes in.";
            await movie.loadmovie("anchor.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);
            mvaddstrc(19, 13, white,
                "┌───────────────────────────────────────────────────┐");
            mvaddstr(20, 13,
                "│     A major Cable News channel has hired a slick  │");
            mvaddstr(21, 13,
                "│   new anchor for one of its news shows.  Guided   │");
            mvaddstr(22, 13,
                "│   by impressive advertising, America tunes in.    │");
            mvaddstr(23, 13,
                "└───────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          case View.nuclearPower:
            newsStories[n].publication = Publication.cableNews;
            newsStories[n].headline = "GENIUS MUTANT";
            newsStories[n].body =
                "A mutant affected by nuclear power appears on a popular "
                "talk show and demonstrates his superhuman intelligence and "
                "charisma, showcasing the upsides of consuming nuclear waste.";
            erase();
            await movie.loadmovie("abort.cmv");
            await movie.playmovie(0, 0, remapSkinTones: true);
            mvaddstrc(18, 11, white,
                "┌───────────────────────────────────────────────────────┐");
            mvaddstr(19, 11,
                "│     A mutant affected by nuclear power appears on a   │");
            mvaddstr(20, 11,
                "│   popular talk show and demonstrates his superhuman   │");
            mvaddstr(21, 11,
                "│   intelligence and charisma, showcasing the upsides   │");
            mvaddstr(22, 11,
                "│   of consuming nuclear waste.                         │");
            mvaddstr(23, 11,
                "└───────────────────────────────────────────────────────┘");
            await getKey();
            del = true;
          default:
        }
      }
    }
    if (del) {
      if (newsStories[n].liberalSpin) {
        changePublicOpinion(newsStories[n].view!, 20);
      } else {
        changePublicOpinion(newsStories[n].view!, -20);
      }
      newsStories[n].effects = Map.fromEntries(gameState
          .politics.publicOpinion.entries
          .where((entry) => entry.value != beforeOpinion[entry.key])
          .map((entry) =>
              MapEntry(entry.key, entry.value - beforeOpinion[entry.key]!)));

      newsStories[n].unread = false;
      archiveNewsStory(newsStories[n]);
      newsStories.removeAt(n);
    }
  }
}
