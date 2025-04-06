import 'package:lcs_new_age/politics/alignment.dart';

bool? parseBool(String value) {
  bool? result = bool.tryParse(value);
  if (result != null) return result;
  int? intResult = int.tryParse(value);
  if (intResult == 1) return true;
  if (intResult == 0) return false;
  return null;
}

(int, int)? parseRange(String value) {
  List<String> parts = value.split("-");
  int? min = int.tryParse(parts[0]);
  int? max;
  if (parts.length > 1) {
    max = int.tryParse(parts[1]);
  }
  max = max ?? min;
  if (min != null && max != null) {
    return (min, max);
  }
  return null;
}

DeepAlignment? parseAlignment(String value) {
  return switch (value.toLowerCase()) {
    "l+" || "elite liberal" => DeepAlignment.eliteLiberal,
    "l" || "liberal" => DeepAlignment.liberal,
    "m" || "moderate" => DeepAlignment.moderate,
    "c" || "conservative" => DeepAlignment.conservative,
    "c+" || "arch conservative" => DeepAlignment.archConservative,
    _ => null
  };
}
