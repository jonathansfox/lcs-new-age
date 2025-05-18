import 'dart:ui';

import 'package:lcs_new_age/utils/colors.dart';

enum Alignment {
  liberal,
  moderate,
  conservative;

  Color get color {
    switch (this) {
      case liberal:
        return lightGreen;
      case moderate:
        return yellow;
      case conservative:
        return red;
    }
  }

  String get label => name;
  String get ism {
    switch (this) {
      case liberal:
        return "Liberalism";
      case moderate:
        return "moderation";
      case conservative:
        return "Conservatism";
    }
  }
}

enum DeepAlignment implements Comparable<DeepAlignment> {
  archConservative,
  conservative,
  moderate,
  liberal,
  eliteLiberal;

  Color get color {
    switch (this) {
      case eliteLiberal:
        return lightGreen;
      case liberal:
        return lightBlue;
      case moderate:
        return yellow;
      case conservative:
        return purple;
      case archConservative:
        return red;
    }
  }

  String get colorKey {
    switch (this) {
      case eliteLiberal:
        return ColorKey.lightGreen;
      case liberal:
        return ColorKey.lightBlue;
      case moderate:
        return ColorKey.yellow;
      case conservative:
        return ColorKey.purple;
      case archConservative:
        return ColorKey.red;
    }
  }

  String get label {
    switch (this) {
      case eliteLiberal:
        return "Elite Liberal";
      case liberal:
        return "Liberal";
      case moderate:
        return "moderate";
      case conservative:
        return "Conservative";
      case archConservative:
        return "Arch Conservative";
    }
  }

  String get short {
    switch (this) {
      case eliteLiberal:
        return "Lib+";
      case liberal:
        return "Lib";
      case moderate:
        return "mod";
      case conservative:
        return "Con";
      case archConservative:
        return "Con+";
    }
  }

  String get veryShort {
    switch (this) {
      case eliteLiberal:
        return "L+";
      case liberal:
        return "L ";
      case moderate:
        return "m ";
      case conservative:
        return "C ";
      case archConservative:
        return "C+";
    }
  }

  Alignment get shallow {
    switch (this) {
      case eliteLiberal:
      case liberal:
        return Alignment.liberal;
      case moderate:
        return Alignment.moderate;
      case conservative:
      case archConservative:
        return Alignment.conservative;
    }
  }

  bool operator >(DeepAlignment other) => index > other.index;
  bool operator <(DeepAlignment other) => index < other.index;
  bool operator >=(DeepAlignment other) => index >= other.index;
  bool operator <=(DeepAlignment other) => index <= other.index;
  @override
  int compareTo(DeepAlignment other) => index.compareTo(other.index);
}
