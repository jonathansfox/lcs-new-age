/* news - make some filler junk */
import 'package:lcs_new_age/common_display/common_display.dart';
import 'package:lcs_new_age/utils/lcsrandom.dart';

String generateFiller(int amount) {
  String fillerStory = "&r${randomCityName()} - ";
  for (int par = 0; amount > 0; amount--) {
    par++;
    for (int i = 0; i < lcsRandom(10) + 3; i++) {
      fillerStory += "~";
    }
    if (amount > 1) fillerStory += " ";
    if (par >= 50 && oneIn(5) && amount > 20) {
      par = 0;
      fillerStory += "&r  ";
    }
  }
  fillerStory += "&r";
  return fillerStory;
}
