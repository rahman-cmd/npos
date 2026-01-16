import 'package:mobile_pos/model/sale_transaction_model.dart';

class Party {
  Party({
    this.id,
    this.name,
    this.businessId,
    this.email,
    this.branchId,
    this.type,
    this.phone,
    this.due,
    this.openingBalanceType,
    this.openingBalance,
    this.wallet,
    this.loyaltyPoints,
    this.creditLimit,
    this.address,
    this.image,
    this.status,
    this.meta,
    this.sales,
    this.shippingAddress,
    this.billingAddress,
    this.createdAt,
    this.updatedAt,
  });

  Party.fromJson(dynamic json) {
    id = num.tryParse(json['id'].toString());
    name = json['name'];
    businessId = num.tryParse(json['business_id'].toString());
    email = json['email'];
    type = json['type'];
    phone = json['phone'];
    branchId = num.tryParse(json['branch_id'].toString());
    due = num.tryParse(json['due'].toString());
    saleCount = num.tryParse(json['sales_count'].toString());
    purchaseCount = num.tryParse(json['purchases_count'].toString());
    totalSaleAmount = num.tryParse(json['total_sale_amount'].toString());
    totalSalePaid = num.tryParse(json['total_sale_paid'].toString());
    totalPurchaseAmount = num.tryParse(json['total_purchase_amount'].toString());
    totalPurchasePaid = num.tryParse(json['total_purchase_paid'].toString());
    totalSaleProfit = num.tryParse(json['total_sale_profit'].toString());
    totalSaleLoss = num.tryParse(json['total_sale_loss'].toString());
    openingBalanceType = json['opening_balance_type'];
    openingBalance = num.tryParse(json['opening_balance'].toString());
    wallet = num.tryParse(json['wallet'].toString());
    loyaltyPoints = num.tryParse(json['loyalty_points'].toString());
    creditLimit = num.tryParse(json['credit_limit'].toString());
    address = json['address'];
    image = json['image'];
    status = num.tryParse(json['status'].toString());
    meta = json['meta'];
    shippingAddress = json['shipping_address'] != null ? ShippingAddress.fromJson(json['shipping_address']) : null;
    if (json['sales'] != null) {
      sales = [];
      json['sales'].forEach((v) {
        sales!.add(SalesTransactionModel.fromJson(v));
      });
    }
    billingAddress = json['billing_address'] != null ? BillingAddress.fromJson(json['billing_address']) : null;
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
  }

  num? id;
  String? name;
  num? businessId;
  String? email;
  String? type;
  String? phone;
  num? branchId;
  num? due;
  num? saleCount;
  num? purchaseCount;
  num? totalSaleAmount;
  num? totalSalePaid;
  num? totalPurchaseAmount;
  num? totalPurchasePaid;
  // num? totalSaleLossProfit;
  num? totalSaleProfit;
  num? totalSaleLoss;
  String? openingBalanceType;
  num? openingBalance;
  num? wallet;
  num? loyaltyPoints;
  num? creditLimit;
  String? address;
  String? image;
  num? status;
  dynamic meta;
  ShippingAddress? shippingAddress;
  BillingAddress? billingAddress;
  List<SalesTransactionModel>? sales;
  String? createdAt;
  String? updatedAt;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['id'] = id;
    map['branch_id'] = branchId;
    map['name'] = name;
    map['business_id'] = businessId;
    map['email'] = email;
    map['type'] = type;
    map['phone'] = phone;
    map['due'] = due;
    map['sales_count'] = saleCount;
    map['purchases_count'] = purchaseCount;
    map['total_sale_amount'] = totalSaleAmount;
    map['total_sale_paid'] = totalSalePaid;
    map['total_purchase_amount'] = totalPurchaseAmount;
    map['total_purchase_paid'] = totalPurchasePaid;
    map['total_sale_profit'] = totalSaleProfit;
    map['total_sale_loss'] = totalSaleLoss;
    map['opening_balance_type'] = openingBalanceType;
    map['opening_balance'] = openingBalance;
    map['wallet'] = wallet;
    map['loyalty_points'] = loyaltyPoints;
    map['credit_limit'] = creditLimit;
    map['address'] = address;
    map['image'] = image;
    map['status'] = status;
    map['meta'] = meta;
    map['sales'] = sales;
    if (shippingAddress != null) {
      map['shipping_address'] = shippingAddress?.toJson();
    }
    if (billingAddress != null) {
      map['billing_address'] = billingAddress?.toJson();
    }
    map['created_at'] = createdAt;
    map['updated_at'] = updatedAt;
    return map;
  }
}

class BillingAddress {
  BillingAddress({
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  BillingAddress.fromJson(dynamic json) {
    address = json['address'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    country = json['country'];
  }
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? country;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = address;
    map['city'] = city;
    map['state'] = state;
    map['zip_code'] = zipCode;
    map['country'] = country;
    return map;
  }
}

class ShippingAddress {
  ShippingAddress({
    this.address,
    this.city,
    this.state,
    this.zipCode,
    this.country,
  });

  ShippingAddress.fromJson(dynamic json) {
    address = json['address'];
    city = json['city'];
    state = json['state'];
    zipCode = json['zip_code'];
    country = json['country'];
  }
  String? address;
  String? city;
  String? state;
  String? zipCode;
  String? country;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['address'] = address;
    map['city'] = city;
    map['state'] = state;
    map['zip_code'] = zipCode;
    map['country'] = country;
    return map;
  }
}

extension PartyListExt on List<Party> {
  List<Party> getTopFiveCustomers() {
    final _customerTypes = {'customer', 'dealer', 'wholesaler', 'retailer'};

    final _customers = where((p) => _customerTypes.contains(p.type?.trim().toLowerCase())).toList();

    if (_customers.isEmpty) return const <Party>[];

    final _hasSaleAmount = _customers.any((p) => (p.totalSaleAmount ?? 0) > 0);

    final _filteredList = _customers.where((p) {
      if (_hasSaleAmount) {
        return (p.totalSaleAmount ?? 0) > 0;
      }

      return (p.saleCount ?? 0) > 0;
    }).toList();

    if (_filteredList.isEmpty) return const <Party>[];

    _filteredList.sort((a, b) {
      if (_hasSaleAmount) {
        return (b.totalSaleAmount ?? 0).compareTo(a.totalSaleAmount ?? 0);
      }

      return (b.saleCount ?? 0).compareTo(a.saleCount ?? 0);
    });

    return _filteredList.length > 5 ? _filteredList.sublist(0, 5) : _filteredList;
  }

  List<Party> getTopFiveSuppliers() {
    final _suppliers = where((p) => p.type?.trim().toLowerCase() == 'supplier').toList();

    if (_suppliers.isEmpty) return const <Party>[];

    final _hasPurchaseAmount = _suppliers.any((p) => (p.totalPurchaseAmount ?? 0) > 0);

    final _filteredList = _suppliers.where((p) {
      if (_hasPurchaseAmount) {
        return (p.totalPurchaseAmount ?? 0) > 0;
      }

      return (p.purchaseCount ?? 0) > 0;
    }).toList();

    if (_filteredList.isEmpty) return const <Party>[];

    _filteredList.sort((a, b) {
      if (_hasPurchaseAmount) {
        return (b.totalPurchaseAmount ?? 0).compareTo(a.totalPurchaseAmount ?? 0);
      }

      return (b.purchaseCount ?? 0).compareTo(a.purchaseCount ?? 0);
    });

    return _filteredList.length > 5 ? _filteredList.sublist(0, 5) : _filteredList;
  }
}
