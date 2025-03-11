import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';

import '../Screens/Purchase/Repo/purchase_repo.dart';
import '../Screens/vat_&_tax/model/vat_model.dart';

final cartNotifierPurchaseNew = ChangeNotifierProvider((ref) => CartNotifierPurchase());

class CartNotifierPurchase extends ChangeNotifier {
  List<CartProductModelPurchase> cartItemList = [];
  TextEditingController discountTextControllerFlat = TextEditingController();
  TextEditingController vatAmountController = TextEditingController();

  ///_________NEW_________________________________
  num totalAmount = 0;
  num discountAmount = 0;
  num totalPayableAmount = 0;
  VatModel? selectedVat;
  num vatAmount = 0;
  bool isFullPaid = false;
  num receiveAmount = 0;
  num changeAmount = 0;
  num dueAmount = 0;

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

  void calculateDiscount({required String value, bool? rebuilding}) {
    if (value == '') {
      discountAmount = 0;
      discountTextControllerFlat.clear();
    } else {
      if ((num.tryParse(value) ?? 0) <= totalAmount) {
        discountAmount = num.parse(value);
      } else {
        discountTextControllerFlat.clear();
        discountAmount = 0;
        EasyLoading.showError('Enter a valid discount');
      }
    }
    if (rebuilding == false) return;
    calculatePrice();
  }

  void updateProduct({required num productId, required num price, required String qty}) {
    int index = cartItemList.indexWhere((element) => element.productId == productId);
    cartItemList[index].productPurchasePrice = price;
    cartItemList[index].quantities = qty.toInt();
    calculatePrice();
  }

  void calculatePrice({String? receivedAmount, bool? stopRebuild}) {
    totalAmount = 0;
    totalPayableAmount = 0;
    dueAmount = 0;
    for (var element in cartItemList) {
      totalAmount += (element.quantities ?? 0) * (element.productPurchasePrice ?? 0);
    }
    totalPayableAmount = totalAmount;

    if (discountAmount > totalAmount) {
      calculateDiscount(value: discountAmount.toString(), rebuilding: false);
    }
    if (discountAmount >= 0) {
      totalPayableAmount -= discountAmount;
    }
    if (selectedVat?.rate != null) {
      vatAmount = (totalPayableAmount * selectedVat!.rate!) / 100;
      vatAmountController.text = vatAmount.toStringAsFixed(2);
    }

    totalPayableAmount += vatAmount;
    if (!receivedAmount.isEmptyOrNull) {
      receiveAmount = num.tryParse(receivedAmount!) ?? 0;
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
      totalAmountOfCart = totalAmountOfCart + ((element.productPurchasePrice ?? 0) * (element.quantities ?? 0));
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
    cartItemList[index].quantities = (cartItemList[index].quantities ?? 0) + 1;
    calculatePrice();
  }

  quantityDecrease(int index) {
    if ((cartItemList[index].quantities ?? 0) > 1) {
      cartItemList[index].quantities = (cartItemList[index].quantities ?? 0) - 1;
    }
    calculatePrice();
  }

  addToCartRiverPod({required CartProductModelPurchase cartItem, bool? fromEditSales}) {
    if (!cartItemList.any((element) => element.productId == cartItem.productId)) {
      cartItemList.add(cartItem);
    } else {
      int index = cartItemList.indexWhere(
        (element) => element.productId == cartItem.productId,
      );
      cartItemList[index] = cartItem;
    }
    (fromEditSales ?? false) ? null : calculatePrice();
  }

  deleteToCart(int index) {
    cartItemList.removeAt(index);
    calculatePrice();
  }
}
