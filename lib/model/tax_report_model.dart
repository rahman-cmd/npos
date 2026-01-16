class TaxReportModel {
  final List<InvoiceModel>? sales;
  final List<InvoiceModel>? purchases;
  final List<OverviewModel>? overviews;

  TaxReportModel({
    this.sales,
    this.purchases,
    this.overviews,
  });

  factory TaxReportModel.fromJson(Map<String, dynamic> json) {
    return TaxReportModel(
      sales: json['sales'] == null ? null : List<InvoiceModel>.from(json["sales"].map((x) => InvoiceModel.fromJson(x))),
      purchases: json['purchases'] == null
          ? null
          : List<InvoiceModel>.from(json["purchases"].map((x) => InvoiceModel.fromJson(x))),
      overviews: [
        // Sales
        OverviewModel(
          totalAmount: json['sales_total_amount'] ?? 0,
          totalDiscount: json['sales_total_discount'] ?? 0,
          totalVat: json['sales_total_vat'] ?? 0,
        ),

        // Purchase
        OverviewModel(
          totalAmount: json['purchases_total_amount'] ?? 0,
          totalDiscount: json['purchases_total_discount'] ?? 0,
          totalVat: json['purchases_total_vat'] ?? 0,
        ),
      ],
    );
  }
}

class InvoiceModel {
  final int? id;
  final String? partyName;
  final String? invoiceNumber;
  final DateTime? transactionDate;
  final num? amount;
  final num? discountAmount;
  final String? vatName;
  final num? vatAmount;

  InvoiceModel({
    this.id,
    this.partyName,
    this.invoiceNumber,
    this.transactionDate,
    this.amount,
    this.discountAmount,
    this.vatName,
    this.vatAmount,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    final _dateKey = json["saleDate"] ?? json["purchaseDate"];

    return InvoiceModel(
      id: json['id'],
      partyName: json['party']?['name'],
      invoiceNumber: json['invoiceNumber'],
      transactionDate: _dateKey == null ? null : DateTime.parse(_dateKey),
      amount: json['totalAmount'],
      discountAmount: json['discountAmount'],
      vatName: json['vat']?['name'],
      vatAmount: json['vat_amount'],
    );
  }
}

class OverviewModel {
  final num totalAmount;
  final num totalDiscount;
  final num totalVat;

  OverviewModel({
    required this.totalAmount,
    required this.totalDiscount,
    required this.totalVat,
  });
}
