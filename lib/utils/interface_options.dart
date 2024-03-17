import 'package:lcs_new_age/engine/engine.dart';

String interfacePgUp = "[";

String aOrAn(String word) {
  switch (word[0].toLowerCase()) {
    case 'a':
    case 'e':
    case 'i':
    case 'o':
    case 'u':
      return "an";
    default:
      return "a";
  }
}

bool isPageUp(int c) {
  if (interfacePgUp == "[") {
    return c == "[".codePoint;
  } else if (interfacePgUp == ".") {
    return c == ":".codePoint;
  } else {
    return false; // c == "PGUP";
  }
}

bool isPageDown(int c) {
  if (interfacePgUp == "[") {
    return c == "]".codePoint;
  } else if (interfacePgUp == ".") {
    return c == ";".codePoint;
  } else {
    return false; // c == "PGDN";
  }
}

String get previousPageStr {
  String str;
  if (interfacePgUp == "[") {
    str = "[";
  } else if (interfacePgUp == ".") {
    str = ";";
  } else {
    str = "PGUP";
  }
  return "$str - Previous";
}

String get nextPageStr {
  String str;
  if (interfacePgUp == "[") {
    str = "]";
  } else if (interfacePgUp == ".") {
    str = ":";
  } else {
    str = "PGDN";
  }
  return "$str - Next";
}

String get pageStr {
  String str;
  if (interfacePgUp == "[") {
    str = "[]";
  } else if (interfacePgUp == ".") {
    str = ";:";
  } else {
    str = "PGUP/PGDN";
  }
  return "$str to view other Liberal pages";
}

String get pageStrShort {
  String str;
  if (interfacePgUp == "[") {
    str = "[]";
  } else if (interfacePgUp == ".") {
    str = ";:";
  } else {
    str = "PGUP/PGDN";
  }
  return "$str for other pages";
}

bool isBackKey(int c) =>
    c == Key.x || c == Key.enter || c == Key.escape || c == Key.space;
