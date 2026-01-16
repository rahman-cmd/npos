num? _parseNum(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

class LossProfitModel {
  final List<IncomeSummaryModel>? incomeSummary;
  final List<ExpenseSummaryModel>? expenseSummary;
  final num? grossSalProfit;
  final num? grossIncomeProfit;
  final num? totalExpenses;
  final num? netProfit;
  final num? cartGrossProfit;
  final num? totalCardExpense;
  final num? cardNetProfit;

  LossProfitModel({
    this.incomeSummary,
    this.expenseSummary,
    this.grossSalProfit,
    this.grossIncomeProfit,
    this.totalExpenses,
    this.netProfit,
    this.cartGrossProfit,
    this.totalCardExpense,
    this.cardNetProfit,
  });

  factory LossProfitModel.fromJson(Map<String, dynamic> json) {
    return LossProfitModel(
      incomeSummary: json["mergedIncomeSaleData"] == null
          ? []
          : List<IncomeSummaryModel>.from(json["mergedIncomeSaleData"]!.map((x) => IncomeSummaryModel.fromJson(x))),
      expenseSummary: json["mergedExpenseData"] == null
          ? []
          : List<ExpenseSummaryModel>.from(json["mergedExpenseData"]!.map((x) => ExpenseSummaryModel.fromJson(x))),
      grossSalProfit: _parseNum(json["grossSaleProfit"]),
      grossIncomeProfit: _parseNum(json['grossIncomeProfit']),
      totalExpenses: _parseNum(json['totalExpenses']),
      netProfit: _parseNum(json['netProfit']),
      cartGrossProfit: _parseNum(json['cardGrossProfit']),
      totalCardExpense: _parseNum(json['totalCardExpenses']),
      cardNetProfit: _parseNum(json['cardNetProfit']),
    );
  }
}

class IncomeSummaryModel {
  final String? type;
  final String? date;
  final num? totalIncome;

  IncomeSummaryModel({this.type, this.date, this.totalIncome});

  factory IncomeSummaryModel.fromJson(Map<String, dynamic> json) {
    return IncomeSummaryModel(
      type: json["type"],
      date: json["date"],
      totalIncome: _parseNum(json["total_incomes"]),
    );
  }
}

class ExpenseSummaryModel {
  final String? type;
  final String? date;
  final num? totalExpense;

  ExpenseSummaryModel({this.type, this.date, this.totalExpense});

  factory ExpenseSummaryModel.fromJson(Map<String, dynamic> json) {
    return ExpenseSummaryModel(
      type: json["type"],
      date: json["date"],
      totalExpense: _parseNum(json["total_expenses"]),
    );
  }
}
