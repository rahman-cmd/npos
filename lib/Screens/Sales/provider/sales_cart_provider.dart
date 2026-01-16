import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/model/business_info_model.dart';

import '../../Settings/sales settings/model/amount_rounding_dropdown_model.dart';
import '../../vat_&_tax/model/vat_model.dart';
import '../../../model/add_to_cart_model.dart';

final cartNotifier = ChangeNotifierProvider((ref) {
  return CartNotifier(businessInformation: ref.watch(businessInfoProvider).value);
});

class CartNotifier extends ChangeNotifier {
  final BusinessInformationModel? businessInformation;

  CartNotifier({required this.businessInformation});

  @override
  void addListener(VoidCallback listener) {
    super.addListener(listener);
    roundedOption = businessInformation?.data?.saleRoundingOption ?? roundingMethods[0].value;
  }

  List<SaleCartModel> cartItemList = [];
  TextEditingController discountTextControllerFlat = TextEditingController();
  TextEditingController vatAmountController = TextEditingController();
  TextEditingController shippingChargeController = TextEditingController();

  ///_________NEW_________________________________
  num totalAmount = 0;
  num discountAmount = 0;
  num discountPercent = 0;
  num roundingAmount = 0;
  num actualTotalAmount = 0;
  num totalPayableAmount = 0;
  VatModel? selectedVat;
  num vatAmount = 0;
  bool isFullPaid = false;
  num receiveAmount = 0;
  num changeAmount = 0;
  num dueAmount = 0;
  num finalShippingCharge = 0;
  String roundedOption = roundingMethods[0].value;

  void changeSelectedVat({VatModel? data}) {
    if (data != null) {
      selectedVat = data;
    } else {
      selectedVat = null;
      vatAmount = 0;
      vatAmountController.clear();
    }

    calculatePrice();
  }

  void calculateDiscount({required String value, bool? rebuilding, String? selectedTaxType}) {
    if (value.isEmpty) {
      discountAmount = 0;
      discountPercent = 0;
      discountTextControllerFlat.clear();
    } else {
      num discountValue = num.tryParse(value) ?? 0;

      if (selectedTaxType == null) {
        EasyLoading.showError('Please select a discount type');
        discountAmount = 0;
        discountPercent = 0;
      } else if (selectedTaxType == "Flat") {
        discountAmount = discountValue;
      } else if (selectedTaxType == "Percent") {
        discountPercent = num.tryParse(discountTextControllerFlat.text) ?? 0.0;
        discountAmount = (totalAmount * discountValue) / 100;

        if (discountAmount > totalAmount) {
          discountAmount = totalAmount;
        }
      } else {
        EasyLoading.showError('Invalid discount type selected');
        discountAmount = 0;
      }

      if (discountAmount > totalAmount) {
        discountTextControllerFlat.clear();
        discountAmount = 0;
        EasyLoading.showError('Enter a valid discount');
      }
    }

    if (rebuilding == false) return;
    calculatePrice();
  }

  void updateProduct({required num productId, required String price, required String qty, required num discount}) {
    int index = cartItemList.indexWhere((element) => element.productId == productId);
    if (index != -1) {
      cartItemList[index].unitPrice = num.tryParse(price);
      cartItemList[index].quantity = num.tryParse(qty) ?? 0;
      cartItemList[index].discountAmount = discount; // Store the product-wise discount
      calculatePrice();
    }
  }

  void calculatePrice({String? receivedAmount, String? shippingCharge, bool? stopRebuild}) {
    totalAmount = 0;
    totalPayableAmount = 0;
    dueAmount = 0;

    // Calculate Subtotal with Product-wise Discounts
    for (var element in cartItemList) {
      num unitPrice = element.unitPrice ?? 0;
      num productDiscount = element.discountAmount ?? 0;
      num quantity = element.quantity;

      // Formula: (Unit Price - Discount) * Quantity
      // Note: The validation in the form ensures Discount <= Unit Price
      totalAmount += (unitPrice - productDiscount) * quantity;
    }

    totalPayableAmount = totalAmount;

    // Apply Global Discount (on the already discounted subtotal)
    if (discountAmount > totalAmount) {
      calculateDiscount(
        value: discountAmount.toString(),
        rebuilding: false,
      );
    }
    if (discountAmount >= 0) {
      totalPayableAmount -= discountAmount;
    }

    // Apply VAT
    if (selectedVat?.rate != null) {
      vatAmount = (totalPayableAmount * selectedVat!.rate!) / 100;
      vatAmountController.text = vatAmount.toStringAsFixed(2);
    }
    totalPayableAmount += vatAmount;

    // Apply Shipping
    if (shippingCharge != null) {
      finalShippingCharge = num.tryParse(shippingCharge) ?? 0;
    }
    totalPayableAmount += finalShippingCharge;

    // Rounding
    actualTotalAmount = totalPayableAmount;
    num tempTotalPayable = roundNumber(value: totalPayableAmount, roundingType: roundedOption);
    roundingAmount = tempTotalPayable - totalPayableAmount;
    totalPayableAmount = tempTotalPayable;

    // Payment Calculation
    if (receivedAmount != null) {
      receiveAmount = num.tryParse(receivedAmount) ?? 0;
    }

    changeAmount = totalPayableAmount < receiveAmount ? receiveAmount - totalPayableAmount : 0;
    dueAmount = totalPayableAmount < receiveAmount ? 0 : totalPayableAmount - receiveAmount;
    if (dueAmount <= 0) isFullPaid = true;

    if (stopRebuild ?? false) return;
    notifyListeners();
  }

  void quantityIncrease(int index) {
    final item = cartItemList[index];
    final isCombo = item.productType?.toLowerCase().contains('combo') ?? false;
    final stock = item.stock ?? 0;
    final quantity = item.quantity;

    // Allow increase if it's a Combo OR if stock is available
    if (isCombo || stock > quantity) {
      // If not a combo, perform strict stock check
      if (!isCombo && stock < quantity + 1) {
        cartItemList[index].quantity = stock;
      } else {
        cartItemList[index].quantity++;
      }
      calculatePrice();
    } else {
      EasyLoading.showError('Stock Overflow');
    }
  }

  void quantityDecrease(int index) {
    if (cartItemList[index].quantity > 1) {
      cartItemList[index].quantity--;
    }
    calculatePrice();
  }

  void addToCartRiverPod({
    required SaleCartModel cartItem,
    bool? fromEditSales,
    bool? isVariant,
  }) {
    final variantMode = isVariant ?? false;

    final index = cartItemList.indexWhere((element) => variantMode ? element.stockId == cartItem.stockId : element.productId == cartItem.productId);

    if (index != -1) {
      variantMode ? cartItemList[index].quantity = cartItem.quantity : cartItemList[index].quantity++;
    } else {
      cartItemList.add(cartItem);
    }

    if (!(fromEditSales ?? false)) {
      calculatePrice();
    }
  }

  void deleteToCart(int index) {
    cartItemList.removeAt(index);
    calculatePrice();
  }

  void deleteAllVariant({required num productId}) {
    cartItemList.removeWhere(
      (element) => element.productId == productId,
    );
    calculatePrice();
  }
}
