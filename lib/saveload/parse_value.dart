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
