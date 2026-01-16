import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:mobile_pos/Screens/Purchase/Model/purchase_transaction_model.dart';
import 'package:mobile_pos/Screens/invoice%20return/repo/invoice_return_repo.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../../model/add_to_cart_model.dart';
import '../../model/sale_transaction_model.dart';
import '../../service/check_user_role_permission_provider.dart';
import '../../widgets/multipal payment mathods/multi_payment_widget.dart';

class InvoiceReturnScreen extends StatefulWidget {
  const InvoiceReturnScreen({super.key, this.saleTransactionModel, this.purchaseTransaction});

  final SalesTransactionModel? saleTransactionModel;
  final PurchaseTransaction? purchaseTransaction;

  @override
  State<InvoiceReturnScreen> createState() => _InvoiceReturnScreenState();
}

class _InvoiceReturnScreenState extends State<InvoiceReturnScreen> {
  final GlobalKey<MultiPaymentWidgetState> _paymentKey = GlobalKey<MultiPaymentWidgetState>();
  final TextEditingController _totalReturnAmountController = TextEditingController();

  List<SaleCartModel> returnList = [];
  List<TextEditingController> controllers = [];
  List<FocusNode> focus = [];

  // Helper to check context
  bool get isSale => widget.saleTransactionModel != null;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (isSale && widget.saleTransactionModel?.salesDetails != null) {
      for (var element in widget.saleTransactionModel!.salesDetails!) {
        // Sales Calculation Logic
        num unitPrice = calculateDiscountForEachProduct(
          productPrice: (element.price ?? 0) - (element.discount ?? 0),
          quantity: (element.quantities ?? 0),
          totalDiscount:
              (widget.saleTransactionModel?.discountAmount ?? 0) - (widget.saleTransactionModel?.roundingAmount ?? 0),
          totalPrice:
              ((widget.saleTransactionModel?.totalAmount ?? 0) + (widget.saleTransactionModel?.discountAmount ?? 0)) -
                  ((widget.saleTransactionModel?.vatAmount ?? 0) + (widget.saleTransactionModel?.shippingCharge ?? 0)),
        );
        _addItemToList(element.product?.productName, element.stock?.batchNo, element.stock?.id, unitPrice, element.id,
            element.product?.id, element.quantities, element.lossProfit);
      }
    } else if (!isSale && widget.purchaseTransaction?.details != null) {
      for (var element in widget.purchaseTransaction!.details!) {
        // Purchase Calculation Logic
        num unitPrice = calculateDiscountForEachProduct(
          productPrice: (element.productPurchasePrice ?? 0),
          quantity: (element.quantities ?? 0),
          totalDiscount: (widget.purchaseTransaction?.discountAmount ?? 0),
          totalPrice:
              ((widget.purchaseTransaction?.totalAmount ?? 0) + (widget.purchaseTransaction?.discountAmount ?? 0)) -
                  ((widget.purchaseTransaction?.vatAmount ?? 0) + (widget.purchaseTransaction?.shippingCharge ?? 0)),
        );
        _addItemToList(element.product?.productName, element.stock?.batchNo, element.stock?.id, unitPrice, element.id,
            element.product?.id, element.quantities, 0);
      }
    }
    _updateTotalController();
  }

  void _addItemToList(String? name, String? batch, num? stockId, num unitPrice, num? detailId, num? productId,
      num? stockQty, num? lossProfit) {
    returnList.add(SaleCartModel(
      productName: name,
      batchName: batch ?? '',
      stockId: stockId ?? 0,
      unitPrice: unitPrice,
      productId: detailId ?? 0,
      quantity: 0,
      productCode: productId.toString(),
      stock: stockQty ?? 0,
      lossProfit: lossProfit,
    ));
    controllers.add(TextEditingController());
    focus.add(FocusNode());
  }

  void _updateTotalController() {
    _totalReturnAmountController.text = getTotalReturnAmount().toStringAsFixed(2);
  }

  num calculateDiscountForEachProduct(
      {required num totalDiscount, required num productPrice, required num totalPrice, required num quantity}) {
    if (totalPrice == 0) return productPrice;
    num thisProductDiscount = (totalDiscount * (productPrice * quantity)) / totalPrice;
    return productPrice - (thisProductDiscount / (quantity == 0 ? 1 : quantity));
  }

  num getTotalReturnAmount() {
    num returnAmount = 0;
    for (var element in returnList) {
      if (element.quantity > 0) {
        returnAmount += element.quantity * (num.tryParse(element.unitPrice.toString()) ?? 0);
      }
    }
    return returnAmount;
  }

  /// ___________________ MAIN SUBMISSION LOGIC ___________________
  Future<void> _submitReturn(WidgetRef ref, PermissionService permissionService, BuildContext context) async {
    EasyLoading.show();

    // 1. Filter Items
    final validReturnItems = returnList.where((element) => element.quantity > 0).toList();

    if (validReturnItems.isEmpty) {
      EasyLoading.dismiss();
      EasyLoading.showError(lang.S.of(context).pleaseSelectForProductReturn);
      return;
    }

    // 2. Permission Check
    String requiredPermission = isSale ? Permit.saleReturnsCreate.value : Permit.purchaseReturnsCreate.value;
    if (!permissionService.hasPermission(requiredPermission)) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(backgroundColor: Colors.red, content: Text(lang.S.of(context).permissionDenied)));
      return;
    }

    try {
      // 4. Create Model
      ReturnDataModel data = ReturnDataModel(
          saleId: isSale ? widget.saleTransactionModel?.id.toString() : widget.purchaseTransaction?.id.toString(),
          returnQty: [],
          payments: []);
      for (var item in validReturnItems) {
        data.returnQty.add(item.quantity);
      }

      List<PaymentEntry> payments = _paymentKey.currentState?.getPaymentEntries() ?? [];
      data.payments = payments.map((e) => e.toJson()).toList();

      // 6. Call API
      InvoiceReturnRepo repo = InvoiceReturnRepo();
      bool? result;
      if (isSale) {
        result = await repo.createSalesReturn(ref: ref, context: context, salesReturn: data);
      } else {
        result = await repo.createPurchaseReturn(ref: ref, context: context, returnData: data);
      }

      EasyLoading.dismiss();
      if (result ?? false) {
        if (mounted) Navigator.pop(context);
      } else {
        EasyLoading.showError(lang.S.of(context).failedToProcessReturn);
      }
    } catch (e) {
      EasyLoading.dismiss();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final _lang = lang.S.of(context);

    // Unified Data Getters
    final invoiceNumber =
        isSale ? widget.saleTransactionModel!.invoiceNumber : widget.purchaseTransaction!.invoiceNumber;
    final dateString = isSale ? widget.saleTransactionModel!.saleDate! : widget.purchaseTransaction!.purchaseDate!;
    final partyName = isSale ? widget.saleTransactionModel!.party?.name : widget.purchaseTransaction!.user?.name;
    final vatAmount = isSale
        ? ((widget.saleTransactionModel?.vatAmount ?? 0) + (widget.saleTransactionModel?.shippingCharge ?? 0))
        : ((widget.purchaseTransaction?.vatAmount ?? 0) + (widget.purchaseTransaction?.shippingCharge ?? 0));

    return Consumer(builder: (context, consumerRef, __) {
      final permissionService = PermissionService(consumerRef);
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(isSale ? _lang.salesReturn : _lang.purchaseReturn),
            centerTitle: true,
            elevation: 0.0,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Invoice Header Info
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          textFieldType: TextFieldType.NAME,
                          readOnly: true,
                          initialValue: invoiceNumber,
                          decoration: InputDecoration(
                              labelText: _lang.invoiceNumber,
                              border: OutlineInputBorder(),
                              floatingLabelBehavior: FloatingLabelBehavior.always),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: AppTextField(
                          textFieldType: TextFieldType.NAME,
                          readOnly: true,
                          initialValue: DateFormat.yMMMd().format(DateTime.parse(dateString)),
                          decoration: InputDecoration(
                              labelText: lang.S.of(context).date,
                              border: const OutlineInputBorder(),
                              floatingLabelBehavior: FloatingLabelBehavior.always),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  AppTextField(
                    textFieldType: TextFieldType.NAME,
                    readOnly: true,
                    initialValue: partyName,
                    decoration: InputDecoration(
                        labelText: lang.S.of(context).customerName,
                        border: const OutlineInputBorder(),
                        floatingLabelBehavior: FloatingLabelBehavior.always),
                  ),
                  const SizedBox(height: 20),

                  // Return Items List
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      color: theme.colorScheme.primaryContainer,
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xff000000).withValues(alpha: 0.08),
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                            blurRadius: 24)
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xffFEF0F1),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(5), topRight: Radius.circular(5)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(lang.S.of(context).itemAdded, style: const TextStyle(fontSize: 16)),
                                Text(lang.S.of(context).quantity, style: const TextStyle(fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: returnList.length,
                          itemBuilder: (context, index) {
                            focus[index].addListener(() {
                              if (!focus[index].hasFocus) setState(() {});
                            });
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                        child: Text(returnList[index].productName.toString(),
                                            maxLines: 2, overflow: TextOverflow.ellipsis)),
                                    Text(_lang.returnQuantity),
                                  ],
                                ),
                                subtitle: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                        '${formatPointNumber((returnList[index].stock ?? 0) - returnList[index].quantity)} X ${formatPointNumber(returnList[index].unitPrice ?? 0)}'),
                                    SizedBox(
                                      width: 100,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          _buildQtyBtn(Icons.remove, () {
                                            setState(() {
                                              if (returnList[index].quantity > 0) {
                                                returnList[index].quantity--;
                                                controllers[index].text = returnList[index].quantity.toString();
                                                _updateTotalController();
                                              }
                                            });
                                          }),
                                          SizedBox(
                                            width: 50,
                                            child: TextFormField(
                                              controller: controllers[index],
                                              focusNode: focus[index],
                                              textAlign: TextAlign.center,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
                                              ],
                                              onChanged: (value) {
                                                num stock = returnList[index].stock ?? 1;
                                                num newVal = num.tryParse(value) ?? 0;
                                                if (newVal <= stock) {
                                                  returnList[index].quantity = newVal;
                                                  _updateTotalController();
                                                } else {
                                                  controllers[index].text = '0';
                                                  EasyLoading.showError(lang.S.of(context).outOfStock);
                                                }
                                              },
                                              decoration: InputDecoration(
                                                  border: InputBorder.none,
                                                  hintText: focus[index].hasFocus
                                                      ? null
                                                      : returnList[index].quantity.toString()),
                                            ),
                                          ),
                                          _buildQtyBtn(Icons.add, () {
                                            if (returnList[index].quantity < (returnList[index].stock ?? 0)) {
                                              setState(() {
                                                returnList[index].quantity++;
                                                controllers[index].text = returnList[index].quantity.toString();
                                                _updateTotalController();
                                              });
                                            } else {
                                              EasyLoading.showError(_lang.outOfStock);
                                            }
                                          }),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ).visible(returnList.isNotEmpty),
                  ),
                  const SizedBox(height: 20),

                  // Total Amount Box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xff000000).withValues(alpha: 0.08),
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                            blurRadius: 24)
                      ],
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: const BorderRadius.all(Radius.circular(5.0)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${_lang.totalReturnAmount}:', style: TextStyle(fontSize: 16)),
                            Text('$currency ${getTotalReturnAmount().toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Flexible(child: Text('${_lang.nonFoundableDiscount}:', style: TextStyle(fontSize: 16))),
                            Text('$currency ${vatAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Payment Widget
                  MultiPaymentWidget(
                    key: _paymentKey,
                    totalAmountController: _totalReturnAmountController,
                    showWalletOption: true,
                    hideAddButton: true,
                  ),
                ],
              ),
            ),
          ),
          bottomNavigationBar: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      lang.S.of(context).cancel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    onPressed: () => _submitReturn(consumerRef, permissionService, context),
                    child: Text(
                      _lang.confirmReturn,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 20,
        width: 20,
        decoration: const BoxDecoration(color: kMainColor, borderRadius: BorderRadius.all(Radius.circular(10))),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}
