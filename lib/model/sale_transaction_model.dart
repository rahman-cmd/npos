import '../widgets/multipal payment mathods/model/payment_transaction_model.dart';

class SaleModel {
  SaleModel(this.message, this.totalAmount, this.totalReturnedAmount, this.data);
  SaleModel.fromJson(dynamic json) {
    message = json['message'];
    totalAmount = json['total_amount'];
    totalReturnedAmount = json['total_return_amount'];
    data = json['data'] != null ? SalesTransactionModel.fromJson(json['data']) : null;
  }

  String? message;
  num? totalAmount;
  num? totalReturnedAmount;
  SalesTransactionModel? data;
}

class SalesTransactionModel {
  SalesTransactionModel({
    this.id,
    this.businessId,
    this.partyId,
    this.userId,
    this.discountAmount,
    this.discountPercent,
    this.shippingCharge,
    this.dueAmount,
    this.isPaid,
    this.vatAmount,
    this.vatPercent,
    this.paidAmount,
    this.changeAmount,
    this.totalAmount,
    this.paymentTypeId,
    this.paymentType,
    this.discountType,
    this.invoiceNumber,
    this.saleDate,
    this.createdAt,
    this.updatedAt,
    this.detailsSumLossProfit,
    this.user,
    this.party,
    this.salesDetails,
    this.salesReturns,
    this.transactions, // NEW: List of transactions
    this.meta,
    this.vatId,
    this.vat,
    this.image,
    this.roundingAmount,
    this.actualTotalAmount,
    this.roundingOption,
    this.branch,
  });

  SalesTransactionModel.fromJson(dynamic json) {
    id = num.tryParse(json['id'].toString());
    businessId = num.tryParse(json['business_id'].toString());
    partyId = num.tryParse(json['party_id'].toString()) ?? 0;
    userId = num.tryParse(json['user_id'].toString());
    discountAmount = num.tryParse(json['discountAmount'].toString());
    discountPercent = num.tryParse(json['discount_percent'].toString()) ?? 0;
    shippingCharge = num.tryParse(json['shipping_charge'].toString()) ?? 0;
    dueAmount = num.tryParse(json['dueAmount'].toString());
    isPaid = json['isPaid'];
    vatAmount = num.tryParse(json['vat_amount'].toString());
    vatPercent = num.tryParse(json['vat_percent'].toString());
    vatId = num.tryParse(json['vat_id'].toString());
    paidAmount = num.tryParse(json['paidAmount'].toString());
    changeAmount = num.tryParse(json['change_amount'].toString());
    totalAmount = num.tryParse(json['totalAmount'].toString());
    paymentTypeId = int.tryParse(json['payment_type_id'].toString()) ?? 0;
    discountType = json['discount_type'];
    invoiceNumber = json['invoiceNumber'];
    saleDate = json['saleDate'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    roundingOption = json['rounding_option'].toString();
    roundingAmount = num.tryParse(json['rounding_amount'].toString()) ?? 0;
    actualTotalAmount = num.tryParse(json['actual_total_amount'].toString()) ?? 0;
    detailsSumLossProfit = num.tryParse(json['lossProfit'].toString());
    user = json['user'] != null ? User.fromJson(json['user']) : null;
    vat = json['vat'] != null ? SalesVat.fromJson(json['vat']) : null;
    paymentType = json['payment_type'] != null ? PaymentType.fromJson(json['payment_type']) : null;
    branch = json['branch'] != null ? Branch.fromJson(json['branch']) : null;
    meta = json['meta'] != null ? Meta.fromJson(json['meta']) : null;
    party = json['party'] != null ? SalesParty.fromJson(json['party']) : SalesParty(name: 'Guest', type: 'Guest');

    if (json['details'] != null) {
      salesDetails = [];
      json['details'].forEach((v) {
        salesDetails?.add(SalesDetails.fromJson(v));
      });
    }
    if (json['sale_returns'] != null) {
      salesReturns = [];
      json['sale_returns'].forEach((v) {
        salesReturns?.add(SalesReturn.fromJson(v));
      });
    }

    // NEW: Parsing the transactions list
    if (json['transactions'] != null) {
      transactions = [];
      json['transactions'].forEach((v) {
        transactions?.add(PaymentsTransaction.fromJson(v));
      });
    }

    image = json['image'];
  }

  num? id;
  num? businessId;
  num? partyId;
  num? userId;
  num? discountAmount;
  num? discountPercent;
  num? shippingCharge;
  num? dueAmount;
  bool? isPaid;
  num? vatAmount;
  num? vatPercent;
  num? vatId;
  num? paidAmount;
  num? changeAmount;
  num? totalAmount;
  num? roundingAmount;
  num? actualTotalAmount;
  String? roundingOption;
  PaymentType? paymentType;
  Branch? branch;
  int? paymentTypeId;
  String? discountType;
  String? invoiceNumber;
  String? saleDate;
  String? createdAt;
  String? updatedAt;
  num? detailsSumLossProfit;
  User? user;
  SalesParty? party;
  Meta? meta;
  SalesVat? vat;
  List<SalesDetails>? salesDetails;
  List<SalesReturn>? salesReturns;
  List<PaymentsTransaction>? transactions; // NEW Variable
  String? image;
}

// class PaymentType {
//   int? id;
//   int? name;
//   PaymentType(this.id, this.name);
//
//   PaymentType.fromJson(dynamic json) {
//     id = json['id'];
//     name = json['name'];
//   }
//
//   Map<String, dynamic> toJson(dynamic json) {
//     final Map<String, dynamic> data = {};
//     data['id'] = id;
//     data['name'] = name;
//     return data;
//   }
// }

class SalesDetails {
  SalesDetails({
    this.id,
    this.saleId,
    this.productId,
    this.price,
    this.discount, // NEW
    this.lossProfit,
    this.quantities,
    this.productPurchasePrice,
    this.mfgDate,
    this.expireDate,
    this.stockId,
    this.stock,
    this.warrantyInfo, // NEW
    this.createdAt,
    this.updatedAt,
    this.product,
  });

  SalesDetails.fromJson(dynamic json) {
    id = num.tryParse(json['id'].toString());
    saleId = num.tryParse(json['sale_id'].toString());
    productId = num.tryParse(json['product_id'].toString());
    price = num.tryParse(json['price'].toString());
    discount = num.tryParse(json['discount'].toString()); // NEW
    lossProfit = num.tryParse(json['lossProfit'].toString());
    quantities = num.tryParse(json['quantities'].toString());
    productPurchasePrice = num.tryParse(json['productPurchasePrice'].toString());
    mfgDate = json['mfg_date'];
    expireDate = json['expire_date'];
    stockId = num.tryParse(json['stock_id'].toString());

    // NEW: Warranty Info parsing
    warrantyInfo = json['warranty_guarantee_info'] != null
        ? WarrantyGuaranteeInfo.fromJson(json['warranty_guarantee_info'])
        : null;

    stock = json['stock'] != null ? SalesStock.fromJson(json['stock']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    product = json['product'] != null ? SalesProduct.fromJson(json['product']) : null;
  }

  num? id;
  num? saleId;
  num? productId;
  num? price;
  num? discount; // NEW Variable
  num? lossProfit;
  num? quantities;
  num? productPurchasePrice;
  String? mfgDate;
  String? expireDate;
  num? stockId;
  SalesStock? stock;
  WarrantyGuaranteeInfo? warrantyInfo; // NEW Variable
  String? createdAt;

  String? updatedAt;
  SalesProduct? product;
}

// NEW CLASS: Handles Warranty and Guarantee details
class WarrantyGuaranteeInfo {
  String? warrantyDuration;
  String? warrantyUnit;
  String? guaranteeDuration;
  String? guaranteeUnit;

  WarrantyGuaranteeInfo({
    this.warrantyDuration,
    this.warrantyUnit,
    this.guaranteeDuration,
    this.guaranteeUnit,
  });

  WarrantyGuaranteeInfo.fromJson(dynamic json) {
    warrantyDuration = json['warranty_duration']?.toString();
    warrantyUnit = json['warranty_unit'];
    guaranteeDuration = json['guarantee_duration']?.toString();
    guaranteeUnit = json['guarantee_unit'];
  }
}

class SalesProduct {
  SalesProduct({
    this.id,
    this.productName,
    this.categoryId,
    this.category,
    this.productPurchasePrice,
    this.productCode,
    this.productType,
  });

  SalesProduct.fromJson(dynamic json) {
    id = json['id'];
    productName = json['productName'];
    productCode = json['productCode'];
    categoryId = json['category_id'];
    productType = json['product_type'];
    productPurchasePrice = json['productPurchasePrice'];
    category = json['category'] != null ? Category.fromJson(json['category']) : null;
  }

  num? id;
  String? productName;
  String? productCode;
  num? categoryId;
  num? productPurchasePrice;
  String? productType;
  Category? category;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['productName'] = productName;
    map['category_id'] = categoryId;
    if (category != null) {
      map['category'] = category?.toJson();
    }
    return map;
  }
}

class Category {
  Category({
    this.id,
    this.categoryName,
  });

  Category.fromJson(dynamic json) {
    id = json['id'];
    categoryName = json['categoryName'];
  }

  num? id;
  String? categoryName;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['categoryName'] = categoryName;
    return map;
  }
}

class SalesParty {
  SalesParty({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.type,
    this.address,
  });

  SalesParty.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    email = json['email'];
    phone = json['phone'];
    type = json['type'];
    address = json['address'];
  }

  num? id;
  String? name;
  dynamic email;
  String? phone;
  String? type;
  String? address;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['email'] = email;
    map['phone'] = phone;
    map['type'] = type;
    map['address'] = address;
    return map;
  }
}

class User {
  User({
    this.id,
    this.name,
    this.role,
  });

  User.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    role = json['role'];
  }

  num? id;
  String? name;
  String? role;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['name'] = name;
    map['role'] = role;
    return map;
  }
}

class Meta {
  Meta({
    this.customerPhone,
    this.note,
  });

  Meta.fromJson(dynamic json) {
    customerPhone = json['customer_phone'];
    note = json['note'];
  }

  String? customerPhone;
  String? note;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['customer_phone'] = customerPhone;
    map['note'] = note;
    return map;
  }
}

class SalesReturn {
  SalesReturn({
    this.id,
    this.businessId,
    this.saleId,
    this.invoiceNo,
    this.returnDate,
    this.createdAt,
    this.updatedAt,
    this.salesReturnDetails,
  });

  SalesReturn.fromJson(dynamic json) {
    id = num.tryParse(json['id'].toString());
    businessId = num.tryParse(json['business_id'].toString());
    saleId = num.tryParse(json['sale_id'].toString());
    invoiceNo = json['invoice_no'];
    returnDate = json['return_date'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    if (json['details'] != null) {
      salesReturnDetails = [];
      json['details'].forEach((v) {
        salesReturnDetails?.add(SalesReturnDetails.fromJson(v));
      });
    }
  }

  num? id;
  num? businessId;
  num? saleId;
  String? invoiceNo;
  String? returnDate;
  String? createdAt;
  String? updatedAt;
  List<SalesReturnDetails>? salesReturnDetails;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['business_id'] = businessId;
    map['sale_id'] = saleId;
    map['invoice_no'] = invoiceNo;
    map['return_date'] = returnDate;
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    if (salesReturnDetails != null) {
      map['details'] = salesReturnDetails?.map((v) => v.toJson()).toList();
    }
    return map;
  }
}

class SalesReturnDetails {
  SalesReturnDetails({
    this.id,
    this.businessId,
    this.saleReturnId,
    this.saleDetailId,
    this.returnAmount,
    this.returnQty,
  });

  SalesReturnDetails.fromJson(dynamic json) {
    id = num.tryParse(json['id'].toString());
    businessId = num.tryParse(json['business_id'].toString());
    saleReturnId = num.tryParse(json['sale_return_id'].toString());
    saleDetailId = num.tryParse(json['sale_detail_id'].toString());
    returnAmount = num.tryParse(json['return_amount'].toString());
    returnQty = num.tryParse(json['return_qty'].toString());
  }

  num? id;
  num? businessId;
  num? saleReturnId;
  num? saleDetailId;
  num? returnAmount;
  num? returnQty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['business_id'] = businessId;
    map['sale_return_id'] = saleReturnId;
    map['sale_detail_id'] = saleDetailId;
    map['return_amount'] = returnAmount;
    map['return_qty'] = returnQty;
    return map;
  }
}

class SalesVat {
  SalesVat({
    this.id,
    this.name,
    this.rate,
  });

  SalesVat.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    rate = json['rate'];
  }

  num? id;
  String? name;
  num? rate;
}

class Branch {
  Branch({
    this.id,
    this.name,
    this.phone,
    this.address,
  });

  Branch.fromJson(dynamic json) {
    id = json['id'];
    name = json['name'];
    phone = json['phone'];
    address = json['address'];
  }

  num? id;
  String? name;
  String? phone;
  String? address;
}

class SalesStock {
  SalesStock({
    this.id,
    this.batchNo,
    this.productCurrentStock,
  });

  SalesStock.fromJson(dynamic json) {
    id = json['id'];
    batchNo = json['batch_no'] ?? 'N/A';
    productCurrentStock = json['productStock'];
  }

  num? id;
  String? batchNo;
  num? productCurrentStock;
}
