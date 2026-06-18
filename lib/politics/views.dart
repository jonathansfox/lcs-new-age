import 'package:json_annotation/json_annotation.dart';

enum View {
  // political issues
  lgbtRights("LGBTQ+ Rights"),
  deathPenalty("Death Penalty"),
  taxes("Taxes"),
  nuclearPower("Nuclear Power"),
  animalResearch("Animal Research"),
  policeBehavior("Police Behavior"),
  torture("Torture"),
  intelligence("Intelligence"),
  freeSpeech("Free Speech"),
  genetics("Genetics"),
  justices("Justices"),
  gunControl("Gun Control"),
  sweatshops("Labor Rights"),
  pollution("Pollution"),
  corporateCulture("Corporations"),
  ceoSalary("Income Inequality"),
  womensRights("Women's Rights"),
  civilRights("Civil Rights"),
  drugs("Drugs"),
  immigration("Immigration"),
  military("Military"),
  prisons("Prisons"),
  housing("Housing"),
  healthcare("Healthcare"),
  retirement("Retirement"),
  // media
  amRadio("AM Radio"),
  cableNews("Cable News"),
  // crime squads
  lcsKnown("LCS Known"),
  lcsLiked("LCS Liked"),
  @JsonValue("ccsLiked")
  ccsHated("CCS Hated");

  const View(this.label);

  static final Iterable<View> all = View.values.where(
    (v) => ![View.torture].contains(v),
  );

  static final List<View> issues = [
    lgbtRights,
    deathPenalty,
    taxes,
    nuclearPower,
    animalResearch,
    policeBehavior,
    torture,
    intelligence,
    freeSpeech,
    genetics,
    justices,
    gunControl,
    sweatshops,
    pollution,
    corporateCulture,
    ceoSalary,
    womensRights,
    civilRights,
    drugs,
    immigration,
    military,
    prisons,
    housing,
    healthcare,
    retirement,
    amRadio,
    cableNews,
  ];

  final String label;
}
