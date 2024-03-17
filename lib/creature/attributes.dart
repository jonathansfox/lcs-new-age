enum Attribute {
  strength,
  agility,
  intelligence,
  charisma,
  wisdom,
  heart;

  bool get isPhysical => this == strength || this == agility;
}
