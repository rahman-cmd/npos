import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../Screens/vat_&_tax/model/vat_model.dart';
import '../model/add_to_cart_model.dart';

final cartNotifier = ChangeNotifierProvider((ref) => CartNotifier());

class CartNotifier extends ChangeNotifier {
  List<AddToCartModel> cartItemList = [];
  TextEditingController discountTextControllerFlat = TextEditingController();
  TextEditingController vatAmountController = TextEditingController();
  TextEditingController shippingChargeController = TextEditingController();

  // final List<ProductModel> productList = [];

  ///_________NEW_________________________________
  num totalAmount = 0;
  num discountAmount = 0;
  num discountPercent = 0;
  num totalPayableAmount = 0;
  VatModel? selectedVat;
  num vatAmount = 0;
  bool isFullPaid = false;
  num receiveAmount = 0;
  num changeAmount = 0;
  num dueAmount = 0;
  num finalShippingCharge = 0;

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

  // void calculateDiscount({required String value, bool? rebuilding}) {
  //   if (value == '') {
  //     discountAmount = 0;
  //     discountTextControllerFlat.clear();
  //   } else {
  //     if ((num.tryParse(value) ?? 0) <= totalAmount) {
  //       discountAmount = num.parse(value);
  //     } else {
  //       discountTextControllerFlat.clear();
  //       discountAmount = 0;
  //       EasyLoading.showError('Enter a valid discount');
  //     }
  //   }
  //   if (rebuilding == false) return;
  //   calculatePrice();
  // }

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

  void updateProduct({required num productId, required String price, required String qty}) {
    int index = cartItemList.indexWhere((element) => element.productId == productId);
    cartItemList[index].unitPrice = price;
    cartItemList[index].quantity = qty.toInt();
    calculatePrice();
  }

  void calculatePrice({String? receivedAmount, String? shippingCharge, bool? stopRebuild}) {
    totalAmount = 0;
    totalPayableAmount = 0;
    dueAmount = 0;
    for (var element in cartItemList) {
      totalAmount += element.quantity * (num.tryParse(element.unitPrice) ?? 0);
    }
    totalPayableAmount = totalAmount;

    if (discountAmount > totalAmount) {
      calculateDiscount(
        value: discountAmount.toString(),
        rebuilding: false,
      );
    }
    if (discountAmount >= 0) {
      totalPayableAmount -= discountAmount;
    }
    if (selectedVat?.rate != null) {
      vatAmount = (totalPayableAmount * selectedVat!.rate!) / 100;
      vatAmountController.text = vatAmount.toStringAsFixed(2);
    }

    totalPayableAmount += vatAmount;
    if (shippingCharge != null && shippingCharge.isNotEmpty) {
      finalShippingCharge = num.tryParse(shippingCharge) ?? 0;
    }
    totalPayableAmount += finalShippingCharge;
    if (receivedAmount != null && receivedAmount.isNotEmpty) {
      receiveAmount = num.tryParse(receivedAmount) ?? 0;
    }

    changeAmount = totalPayableAmount < receiveAmount ? receiveAmount - totalPayableAmount : 0;
    dueAmount = totalPayableAmount < receiveAmount ? 0 : totalPayableAmount - receiveAmount;
    if (dueAmount <= 0) isFullPaid = true;
    if (stopRebuild ?? false) return;
    notifyListeners();
  }

  double getTotalAmount() {
    double totalAmountOfCart = 0;
    for (var element in cartItemList) {
      totalAmountOfCart = totalAmountOfCart + (double.parse(element.unitPrice.toString()) * double.parse(element.quantity.toString()));
    }

    // if (discount >= 0) {
    //   if (discountType == 'USD') {
    //     return totalAmountOfCart - discount;
    //   } else {
    //     return totalAmountOfCart - ((totalAmountOfCart * discount) / 100);
    //   }
    // }
    return totalAmountOfCart;
  }

  quantityIncrease(int index) {
    if (cartItemList[index].stock! > cartItemList[index].quantity) {
      cartItemList[index].quantity++;
      calculatePrice();
    } else {
      EasyLoading.showError('Stock Overflow');
    }
  }

  quantityDecrease(int index) {
    if (cartItemList[index].quantity > 1) {
      cartItemList[index].quantity--;
    }
    calculatePrice();
  }

  addToCartRiverPod({required AddToCartModel cartItem, bool? fromEditSales}) {
    bool isAlreadyInList = cartItemList.any((element) => element.productId == cartItem.productId);
    if (isAlreadyInList) {
      int index = cartItemList.indexWhere(
        (element) => element.productId == cartItem.productId,
      );
      cartItemList[index].quantity++;
    } else {
      cartItemList.add(cartItem);
    }
    (fromEditSales ?? false) ? null : calculatePrice();
  }

  addToCartRiverPodForEdit(List<AddToCartModel> cartItem) {
    cartItemList = cartItem;
  }

  deleteToCart(int index) {
    cartItemList.removeAt(index);
    calculatePrice();
  }
}
