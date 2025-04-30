import 'package:json_annotation/json_annotation.dart';

part 'ledger.g.dart';

@JsonSerializable()
class Ledger {
  Ledger();
  factory Ledger.fromJson(Map<String, dynamic> json) => _$LedgerFromJson(json);
  Map<String, dynamic> toJson() => _$LedgerToJson(this);

  @JsonKey(includeToJson: true, includeFromJson: true)
  int _funds = 0;
  @JsonKey(includeToJson: false)
  int get funds => _funds;
  Map<Income, int> income = {for (Income i in Income.values) i: 0};
  Map<Income, int> dailyIncome = {for (Income i in Income.values) i: 0};
  Map<Expense, int> expense = {for (Expense e in Expense.values) e: 0};
  Map<Expense, int> dailyExpense = {for (Expense e in Expense.values) e: 0};
  int totalIncome = 0;
  int totalExpense = 0;

  void forceSetFunds(int funds) => _funds = funds;

  void addFunds(int amount, Income incomeType) {
    _funds += amount;
    income[incomeType] = (income[incomeType] ?? 0) + amount;
    dailyIncome[incomeType] = (dailyIncome[incomeType] ?? 0) + amount;
    totalIncome += amount;
  }

  void subtractFunds(int amount, Expense expenseType) {
    _funds -= amount;
    expense[expenseType] = (expense[expenseType] ?? 0) + amount;
    dailyExpense[expenseType] = (dailyExpense[expenseType] ?? 0) + amount;
    totalExpense += amount;
  }

  void resetMonthlyAmounts() {
    income = {for (Income i in Income.values) i: 0};
    expense = {for (Expense e in Expense.values) e: 0};
  }

  void resetDailyAmounts() {
    dailyIncome = {for (Income i in Income.values) i: 0};
    dailyExpense = {for (Expense e in Expense.values) e: 0};
  }
}

enum Income {
  brownies,
  cars,
  creditCardFraud,
  donations,
  artSales,
  embezzlement,
  extortion,
  hustling,
  pawn,
  prostitution,
  busking,
  thievery,
  tshirts,
  ransom;
}

enum Expense {
  activism,
  confiscated,
  dating,
  artSupplies,
  sewingSupplies,
  groceries,
  hostageTending,
  legalFees,
  cars,
  shopping,
  recruitment,
  rent,
  compoundUpgrades,
  training,
  travel,
  augmentation;
}
