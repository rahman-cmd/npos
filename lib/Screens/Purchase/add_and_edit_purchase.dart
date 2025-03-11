import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/Purchase/Model/purchase_transaction_model.dart';
import 'package:mobile_pos/Screens/Purchase/purchase_products.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/add_to_cart_purchase.dart';
import '../../Repository/API/future_invoice.dart';
import '../../constant.dart';
import '../../currency.dart';
import '../Customers/Model/parties_model.dart' as party;
import '../Home/home.dart';
import '../Purchase List/purchase_list_screen.dart';
import '../invoice_details/purchase_invoice_details.dart';
import '../vat_&_tax/model/vat_model.dart';
import '../vat_&_tax/provider/text_repo.dart';
import 'Repo/purchase_repo.dart';

class AddAndUpdatePurchaseScreen extends ConsumerStatefulWidget {
  AddAndUpdatePurchaseScreen({super.key, required this.customerModel, this.transitionModel});

  party.Party? customerModel;
  final PurchaseTransaction? transitionModel;

  @override
  AddSalesScreenState createState() => AddSalesScreenState();
}

class AddSalesScreenState extends ConsumerState<AddAndUpdatePurchaseScreen> {
  String? paymentType = 'Cash';

  bool isProcessing = false;

  DateTime selectedDate = DateTime.now();

  TextEditingController dateController = TextEditingController(text: DateTime.now().toString().substring(0, 10));
  TextEditingController phoneController = TextEditingController();
  TextEditingController recevedAmountController = TextEditingController();

  @override
  void initState() {
    if (widget.transitionModel != null) {
      final editedSales = widget.transitionModel;
      dateController.text = editedSales?.purchaseDate?.substring(0, 10) ?? '';
      recevedAmountController.text = editedSales?.paidAmount.toString() ?? '';
      widget.customerModel = party.Party(
        id: widget.transitionModel?.party?.id,
        name: widget.transitionModel?.party?.name,
      );
      if (widget.transitionModel?.discountType == 'flat') {
        discountType = 'Flat';
      } else {
        discountType = 'Percent';
      }
      addProductsInCartFromEditList();
    }
    super.initState();
  }

  @override
  void dispose() {
    dateController.dispose();
    phoneController.dispose();
    recevedAmountController.dispose();
    super.dispose();
  }

  void addProductsInCartFromEditList() {
    final cart = ref.read(cartNotifierPurchaseNew);

    if (widget.transitionModel?.details?.isNotEmpty ?? false) {
      for (var detail in widget.transitionModel!.details!) {
        cart.addToCartRiverPod(
            cartItem: CartProductModelPurchase(
              productName: detail.product?.productName ?? '',
              productId: detail.productId ?? 0,
              quantities: detail.quantities,
              productWholeSalePrice: detail.product?.productWholeSalePrice ?? 0, // detail.productWholeSalePrice,
              productSalePrice: detail.product?.productSalePrice ?? 0, // detail.productSalePrice,
              productPurchasePrice: detail.productPurchasePrice,
              productDealerPrice: detail.product?.productDealerPrice ?? 0,
              stock: detail.product?.productStock ?? 0, // detail,
            ),
            fromEditSales: true);
      }
    }

    cart.discountAmount = widget.transitionModel?.discountAmount ?? 0;
    if (widget.transitionModel?.discountType == 'flat') {
      cart.discountTextControllerFlat.text = widget.transitionModel?.discountAmount.toString() ?? '';
    } else {
      cart.discountTextControllerFlat.text = widget.transitionModel?.discountPercent?.toString() ?? '';
    }
    cart.finalShippingCharge = widget.transitionModel?.shippingCharge ?? 0;
    cart.shippingChargeController.text = widget.transitionModel?.shippingCharge.toString() ?? '';
    // cart.discountTextControllerFlat.text = widget.transitionModel?.discountAmount.toString() ?? '';
    cart.vatAmountController.text = widget.transitionModel?.vatAmount.toString() ?? '';
    cart.calculatePrice(receivedAmount: widget.transitionModel?.paidAmount.toString(), stopRebuild: true);
  }

  bool hasPreselected = false; // Flag to ensure preselection happens only once
  String discountType = 'Flat';
  @override
  Widget build(BuildContext context) {
    final _theme = Theme.of(context);
    final providerData = ref.watch(cartNotifierPurchaseNew);
    final personalData = ref.watch(businessInfoProvider);
    final taxesData = ref.watch(taxProvider);
    return personalData.when(data: (data) {
      return GlobalPopup(
        child: Scaffold(
          backgroundColor: kWhite,
          appBar: AppBar(
            backgroundColor: Colors.white,
            title: Text(
              lang.S.of(context).addPurchase,
              style: GoogleFonts.poppins(
                color: Colors.black,
              ),
            ),
            centerTitle: true,
            iconTheme: const IconThemeData(color: Colors.black),
            elevation: 2.0,
            surfaceTintColor: kWhite,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  ///_______Invoice_And_Date_____________________________________________________
                  Row(
                    children: [
                      widget.transitionModel == null
                          ? FutureBuilder(
                              future: FutureInvoice().getFutureInvoice(tag: 'purchases'),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Expanded(
                                    child: AppTextField(
                                      textFieldType: TextFieldType.NAME,
                                      initialValue: snapshot.data.toString(),
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        labelText: lang.S.of(context).inv,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                } else {
                                  return Expanded(
                                    child: TextFormField(
                                      readOnly: true,
                                      decoration: InputDecoration(
                                        floatingLabelBehavior: FloatingLabelBehavior.always,
                                        labelText: lang.S.of(context).inv,
                                        border: const OutlineInputBorder(),
                                      ),
                                    ),
                                  );
                                }
                              },
                            )
                          : Expanded(
                              child: AppTextField(
                                textFieldType: TextFieldType.NAME,
                                initialValue: widget.transitionModel?.invoiceNumber,
                                readOnly: true,
                                decoration: InputDecoration(
                                  floatingLabelBehavior: FloatingLabelBehavior.always,
                                  labelText: lang.S.of(context).inv,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: dateController,
                          decoration: InputDecoration(
                            floatingLabelBehavior: FloatingLabelBehavior.always,
                            labelText: lang.S.of(context).date,
                            suffixIcon: IconButton(
                              onPressed: () async {
                                final DateTime? picked = await showDatePicker(
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2015, 8),
                                  lastDate: DateTime(2101),
                                  context: context,
                                );
                                if (picked != null && picked != selectedDate) {
                                  setState(() {
                                    selectedDate = picked;
                                    dateController.text = selectedDate.toString().substring(0, 10);
                                  });
                                }
                              },
                              icon: const Icon(FeatherIcons.calendar),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  ///______Selected_Due_And_Customer___________________________________________
                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(lang.S.of(context).dueAmount),
                          Text(
                            widget.customerModel?.due == null ? '$currency 0' : '$currency${widget.customerModel?.due}',
                            style: const TextStyle(color: Color(0xFFFF8C34)),
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      AppTextField(
                        textFieldType: TextFieldType.NAME,
                        readOnly: true,
                        initialValue: widget.customerModel?.name ?? 'Guest',
                        decoration: InputDecoration(
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          labelText: lang.S.of(context).customerName,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      Visibility(
                        visible: widget.customerModel == null,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: AppTextField(
                            controller: phoneController,
                            textFieldType: TextFieldType.PHONE,
                            decoration: kInputDecoration.copyWith(
                              floatingLabelBehavior: FloatingLabelBehavior.always,
                              //labelText: 'Customer Phone Number',
                              labelText: lang.S.of(context).customerPhoneNumber,
                              //hintText: 'Enter customer phone number',
                              hintText: lang.S.of(context).enterCustomerPhoneNumber,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ///_______Added_Items_List_________________________________________________
                  Padding(
                      padding: const EdgeInsets.only(bottom: 20.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                          border: Border.all(width: 1, color: const Color(0xffEAEFFA)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Color(0xffEAEFFA),
                                  borderRadius: BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: SizedBox(
                                    width: context.width() / 1.35,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          lang.S.of(context).itemAdded,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        Text(
                                          lang.S.of(context).quantity,
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  ),
                                )),
                            ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: providerData.cartItemList.length,
                                itemBuilder: (context, index) {
                                  // providerData.controllers[index].text = (providerData.cartItemList[index].quantity.toString());
                                  // providerData.focus[index].addListener(
                                  //   () {
                                  //     if (!providerData.focus[index].hasFocus) {
                                  //       setState(() {
                                  //         vatAmount = (vatPercentageEditingController.text.toDouble() / 100) * providerData.getTotalAmount().toDouble();
                                  //         vatAmountEditingController.text = vatAmount.toStringAsFixed(2);
                                  //       });
                                  //     }
                                  //   },
                                  // );
                                  return Padding(
                                    padding: const EdgeInsets.only(left: 10, right: 10),
                                    child: ListTile(
                                      onTap: () => showDialog(
                                          context: context,
                                          builder: (_) {
                                            return purchaseProductAddBottomSheet(context: context, product: providerData.cartItemList[index], ref: ref, fromUpdate: true);
                                          }),
                                      contentPadding: const EdgeInsets.all(0),
                                      title: Text(providerData.cartItemList[index].productName.toString()),
                                      subtitle: Text(
                                          '${providerData.cartItemList[index].quantities} X ${providerData.cartItemList[index].productPurchasePrice} = ${((providerData.cartItemList[index].quantities ?? 0) * (providerData.cartItemList[index].productPurchasePrice ?? 0)).toStringAsFixed(2)}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                GestureDetector(
                                                  onTap: () {
                                                    providerData.quantityDecrease(index);
                                                  },
                                                  child: Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: const BoxDecoration(
                                                      color: kMainColor,
                                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                                    ),
                                                    child: const Center(
                                                      child: Text(
                                                        '-',
                                                        style: TextStyle(fontSize: 14, color: Colors.white),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                SizedBox(
                                                  width: 30,
                                                  child: Center(
                                                    child: Text(
                                                      providerData.cartItemList[index].quantities.toString(),
                                                      style: GoogleFonts.poppins(
                                                        color: kGreyTextColor,
                                                        fontSize: 15.0,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                GestureDetector(
                                                  onTap: () {
                                                    providerData.quantityIncrease(index);
                                                  },
                                                  child: Container(
                                                    height: 20,
                                                    width: 20,
                                                    decoration: const BoxDecoration(
                                                      color: kMainColor,
                                                      borderRadius: BorderRadius.all(Radius.circular(10)),
                                                    ),
                                                    child: const Center(
                                                        child: Text(
                                                      '+',
                                                      style: TextStyle(fontSize: 14, color: Colors.white),
                                                    )),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          GestureDetector(
                                            onTap: () {
                                              providerData.deleteToCart(index);
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              color: Colors.red.withOpacity(0.1),
                                              child: const Icon(
                                                Icons.delete,
                                                size: 20,
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                  // return Padding(
                                  //   padding: const EdgeInsets.only(left: 10, right: 10),
                                  //   child: ListTile(
                                  //     onTap: () => showModalBottomSheet(
                                  //       context: context,
                                  //       builder: (context2) {
                                  //         return Column(
                                  //           children: [
                                  //             Padding(
                                  //               padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  //               child: Row(
                                  //                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //                 children: [
                                  //                   Text(
                                  //                     lang.S.of(context).updateProduct,
                                  //                   ),
                                  //                   CloseButton(
                                  //                     onPressed: () => Navigator.pop(context2),
                                  //                   )
                                  //                 ],
                                  //               ),
                                  //             ),
                                  //             const Divider(thickness: 1, color: kBorderColorTextField),
                                  //             Padding(
                                  //               padding: const EdgeInsets.all(16.0),
                                  //               child: SalesAddToCartForm(
                                  //                 batchWiseStockModel: providerData.cartItemList[index],
                                  //                 previousContext: context2,
                                  //               ),
                                  //             ),
                                  //           ],
                                  //         );
                                  //       },
                                  //     ),
                                  //     contentPadding: const EdgeInsets.all(0),
                                  //     title: Text(providerData.cartItemList[index].productName.toString()),
                                  //     subtitle: Text(
                                  //         '${providerData.cartItemList[index].quantities} X ${providerData.cartItemList[index].productPurchasePrice} = ${((providerData.cartItemList[index].productPurchasePrice ?? 0) * (providerData.cartItemList[index].quantities ?? 0)).toStringAsFixed(2)}'),
                                  //     trailing: Row(
                                  //       mainAxisSize: MainAxisSize.min,
                                  //       children: [
                                  //         SizedBox(
                                  //           width: 80,
                                  //           child: Row(
                                  //             mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  //             children: [
                                  //               GestureDetector(
                                  //                 onTap: () => providerData.quantityDecrease(index),
                                  //                 child: Container(
                                  //                   height: 20,
                                  //                   width: 20,
                                  //                   decoration: const BoxDecoration(
                                  //                     color: kMainColor,
                                  //                     borderRadius: BorderRadius.all(Radius.circular(10)),
                                  //                   ),
                                  //                   child: const Center(
                                  //                     child: Text(
                                  //                       '-',
                                  //                       style: TextStyle(fontSize: 14, color: Colors.white),
                                  //                     ),
                                  //                   ),
                                  //                 ),
                                  //               ),
                                  //               const SizedBox(width: 5),
                                  //               SizedBox(
                                  //                 width: 30,
                                  //                 child: Center(
                                  //                     child: Text(
                                  //                   '${providerData.cartItemList[index].quantities}',
                                  //                   style: const TextStyle(fontSize: 14),
                                  //                 )),
                                  //               ),
                                  //               const SizedBox(width: 5),
                                  //               GestureDetector(
                                  //                 onTap: () => providerData.quantityIncrease(index),
                                  //                 child: Container(
                                  //                   height: 20,
                                  //                   width: 20,
                                  //                   decoration: const BoxDecoration(
                                  //                     color: kMainColor,
                                  //                     borderRadius: BorderRadius.all(Radius.circular(10)),
                                  //                   ),
                                  //                   child: const Center(
                                  //                       child: Text(
                                  //                     '+',
                                  //                     style: TextStyle(fontSize: 14, color: Colors.white),
                                  //                   )),
                                  //                 ),
                                  //               ),
                                  //             ],
                                  //           ),
                                  //         ),
                                  //         const SizedBox(width: 10),
                                  //         GestureDetector(
                                  //           onTap: () => providerData.deleteToCart(index),
                                  //           child: Container(
                                  //             padding: const EdgeInsets.all(4),
                                  //             color: Colors.red.withOpacity(0.1),
                                  //             child: const Icon(
                                  //               Icons.delete,
                                  //               size: 20,
                                  //               color: Colors.red,
                                  //             ),
                                  //           ),
                                  //         ),
                                  //       ],
                                  //     ),
                                  //   ),
                                  // );
                                }),
                          ],
                        ),
                      )).visible(providerData.cartItemList.isNotEmpty),

                  ///_______Add_Button__________________________________________________
                  GestureDetector(
                    onTap: () {
                      PurchaseProducts(
                        customerModel: widget.customerModel,
                      ).launch(context);
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(color: kMainColor.withOpacity(0.1), borderRadius: const BorderRadius.all(Radius.circular(10))),
                      child: Center(
                        child: Text(
                          lang.S.of(context).addItems,
                          style: const TextStyle(color: kMainColor, fontSize: 20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  ///_____Total_Section_____________________________
                  Container(
                    decoration: BoxDecoration(borderRadius: const BorderRadius.all(Radius.circular(10)), border: Border.all(color: Colors.grey.shade300, width: 1)),
                    child: Column(
                      spacing: 7,
                      children: [
                        ///________Total_title_reader_________________________
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(color: Color(0xffFEF0F1), borderRadius: BorderRadius.only(topRight: Radius.circular(10), topLeft: Radius.circular(10))),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).subTotal,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                providerData.totalAmount.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        ///_________Discount___________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).discount,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    border: Border(bottom: BorderSide(color: kBorder, width: 1)),
                                  ),
                                  child: DropdownButton<String?>(
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    isDense: true,
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
                                    hint: Text(
                                      'Select',
                                      style: _theme.textTheme.bodyMedium?.copyWith(
                                        color: kGreyTextColor,
                                      ),
                                    ),
                                    value: discountType,
                                    items: [
                                      "Flat",
                                      "Percent",
                                    ]
                                        .map((type) => DropdownMenuItem<String?>(
                                              value: type,
                                              child: Text(
                                                type,
                                                style: _theme.textTheme.bodyMedium?.copyWith(color: kNeutralColor),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        discountType = value!;
                                        providerData.calculateDiscount(
                                          value: providerData.discountTextControllerFlat.text,
                                          selectedTaxType: discountType,
                                        );
                                        print(providerData.discountPercent);
                                        print(providerData.discountAmount);
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextField(
                                  controller: providerData.discountTextControllerFlat,
                                  onChanged: (value) {
                                    setState(() {
                                      providerData.calculateDiscount(
                                        value: value,
                                        selectedTaxType: discountType,
                                      );
                                    });
                                  },
                                  // onChanged: (value) => providerData.calculateDiscount(value: value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ),

                        ///_________Vat_Dropdown_______________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Vat',
                                style: TextStyle(fontSize: 16),
                              ),
                              const Spacer(),
                              taxesData.when(
                                data: (data) {
                                  List<VatModel> dataList = data.where((tax) => tax.status == true).toList();
                                  if (widget.transitionModel != null && widget.transitionModel?.vatId != null && !hasPreselected) {
                                    VatModel matched = dataList.firstWhere(
                                      (element) => element.id == widget.transitionModel?.vatId,
                                      orElse: () => VatModel(),
                                    );
                                    if (matched.id != null) {
                                      hasPreselected = true;
                                      providerData.selectedVat = matched;
                                      // providerData.calculatePrice();
                                    }
                                  }
                                  return SizedBox(
                                    width: context.width() / 4,
                                    height: 30,
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        border: Border(bottom: BorderSide(color: kBorder, width: 1)),
                                      ),
                                      child: DropdownButton<VatModel?>(
                                        icon: providerData.selectedVat != null
                                            ? GestureDetector(
                                                onTap: () => providerData.changeSelectedVat(data: null),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.red,
                                                  size: 16,
                                                ),
                                              )
                                            : const Icon(Icons.keyboard_arrow_down, color: kGreyTextColor),
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        isDense: true,
                                        padding: EdgeInsets.zero,
                                        hint: Text(
                                          'Select',
                                          style: _theme.textTheme.bodyMedium?.copyWith(
                                            color: kGreyTextColor,
                                          ),
                                        ),
                                        value: providerData.selectedVat,
                                        items: dataList.map((VatModel tax) {
                                          return DropdownMenuItem<VatModel>(
                                            value: tax,
                                            child: Text(
                                              tax.name ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: _theme.textTheme.bodyMedium?.copyWith(
                                                color: kGreyTextColor,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (VatModel? newValue) {
                                          providerData.changeSelectedVat(data: newValue);
                                        },
                                      ),
                                    ),
                                  );

                                  //   DropdownButton<VatModel>(
                                  //   icon: providerData.selectedVat != null
                                  //       ? GestureDetector(
                                  //           onTap: () => providerData.changeSelectedVat(data: null),
                                  //           child: const Icon(
                                  //             Icons.close,
                                  //             color: Colors.red,
                                  //           ),
                                  //         )
                                  //       : const Icon(Icons.keyboard_arrow_down),
                                  //   hint: Text(
                                  //     'Select one',
                                  //     maxLines: 1,
                                  //     overflow: TextOverflow.ellipsis,
                                  //     style: _theme.textTheme.bodyMedium?.copyWith(color: kGreyTextColor),
                                  //   ),
                                  //   isExpanded: true,
                                  //   isDense: true,
                                  //   value: providerData.selectedVat,
                                  //   items: dataList.map((VatModel tax) {
                                  //     return DropdownMenuItem<VatModel>(
                                  //       value: tax,
                                  //       child: Text(
                                  //         tax.name ?? '',
                                  //         maxLines: 1,
                                  //         overflow: TextOverflow.ellipsis,
                                  //         style: _theme.textTheme.bodyMedium?.copyWith(
                                  //           color: kGreyTextColor,
                                  //         ),
                                  //       ),
                                  //     );
                                  //   }).toList(),
                                  //   onChanged: (VatModel? newValue) {
                                  //     providerData.changeSelectedVat(data: newValue);
                                  //   },
                                  // );
                                },
                                error: (error, stackTrace) {
                                  return Text(error.toString());
                                },
                                loading: () {
                                  return const SizedBox.shrink();
                                },
                              ),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextFormField(
                                  controller: providerData.vatAmountController,
                                  readOnly: true,
                                  onChanged: (value) => providerData.calculateDiscount(value: value, selectedTaxType: discountType.toString()),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              // SizedBox(
                              //   width: context.width() / 4,
                              //   height: 40,
                              //   child: TextFormField(
                              //     inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
                              //     textAlign: TextAlign.right,
                              //     readOnly: true,
                              //     controller: providerData.vatAmountController,
                              //     cursorColor: const Color(0xff00987F),
                              //     decoration: const InputDecoration(
                              //       // contentPadding: const EdgeInsets.only(right: 6.0),
                              //       hintText: '0',
                              //       border: UnderlineInputBorder(
                              //         // gapPadding: 0.0,
                              //         borderSide: BorderSide(
                              //           color: Color(0xff00987F),
                              //         ),
                              //       ),
                              //       // enabledBorder: UnderlineInputBorder(
                              //       //   // gapPadding: 0.0,
                              //       //   borderSide: BorderSide(
                              //       //     color: Color(0xff00987F),
                              //       //   ),
                              //       // ),
                              //       // disabledBorder: UnderlineInputBorder(
                              //       //   // gapPadding: 0.0,
                              //       //   borderSide: BorderSide(
                              //       //     color: Color(0xff00987F),
                              //       //   ),
                              //       // ),
                              //       focusedBorder: OutlineInputBorder(gapPadding: 0.0, borderSide: BorderSide(color: Color(0xff00987F))),
                              //       prefixIconConstraints: BoxConstraints(maxWidth: 30.0, minWidth: 30.0),
                              //       // prefixIcon: Container(
                              //       //   alignment: Alignment.center,
                              //       //   height: 40,
                              //       //   decoration: const BoxDecoration(
                              //       //     color: Color(0xff00987F),
                              //       //     borderRadius: BorderRadius.only(
                              //       //       topLeft: Radius.circular(4.0),
                              //       //       bottomLeft: Radius.circular(4.0),
                              //       //     ),
                              //       //   ),
                              //       //   child: const Icon(
                              //       //     LineIcons.dollar_sign,
                              //       //     size: 16,
                              //       //     color: Colors.white,
                              //       //   ),
                              //       // ),
                              //     ),
                              //     keyboardType: TextInputType.number,
                              //   ),
                              // ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Shipping Charge',
                                style: TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextFormField(
                                  controller: providerData.shippingChargeController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => providerData.calculatePrice(shippingCharge: value.isEmpty?'0':value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ///________Total_______________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10, top: 7),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).total,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                providerData.totalPayableAmount.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        ///________paid_Amount__________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).paidAmount,
                                style: const TextStyle(fontSize: 16),
                              ),
                              SizedBox(
                                width: context.width() / 4,
                                height: 30,
                                child: TextField(
                                  controller: recevedAmountController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) => providerData.calculatePrice(receivedAmount: value),
                                  textAlign: TextAlign.right,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: kNeutralColor),
                                    border: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: kBorder)),
                                    focusedBorder: UnderlineInputBorder(),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        ///________Return_Amount_________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10, top: 10),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).returnAmount,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                providerData.changeAmount.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),

                        ///_______Due_amount_____________________________________
                        Padding(
                          padding: const EdgeInsets.only(right: 10, left: 10, top: 13, bottom: 13),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                lang.S.of(context).dueAmount,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                providerData.dueAmount.toStringAsFixed(2),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  ///_______Payment_Type_______________________________
                  const Divider(height: 0),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            lang.S.of(context).paymentTypes,
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.wallet,
                            color: Colors.green,
                          )
                        ],
                      ),
                      DropdownButton(
                        value: paymentType,
                        icon: const Icon(Icons.keyboard_arrow_down),
                        items: paymentsTypeList.map((String items) {
                          return DropdownMenuItem(
                            value: items,
                            child: Text(items),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            paymentType = newValue.toString();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  const Divider(height: 0),
                  const SizedBox(height: 24),

                  ///_____Action_Button_____________________________________
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            maximumSize: const Size(double.infinity, 48),
                            minimumSize: const Size(double.infinity, 48),
                            disabledBackgroundColor: _theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          onPressed: () async {
                            const Home().launch(context, isNewTask: true);
                          },
                          child: Text(
                            lang.S.of(context).cancel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _theme.textTheme.bodyMedium?.copyWith(
                              color: _theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          style: OutlinedButton.styleFrom(
                            maximumSize: const Size(double.infinity, 48),
                            minimumSize: const Size(double.infinity, 48),
                            disabledBackgroundColor: _theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          onPressed: () async {
                            if (providerData.cartItemList.isEmpty) {
                              EasyLoading.showError(lang.S.of(context).addProductFirst);
                              return;
                            }
                            if (widget.customerModel == null && providerData.dueAmount > 0) {
                              EasyLoading.showError('Sales on due are not allowed for walk-in customers.');
                              return;
                            }

                            ///_______ Prevent multiple clicks________________
                            if (isProcessing) return;

                            setState(() {
                              isProcessing = true; // Disable button while processing
                            });

                            try {
                              EasyLoading.show(status: lang.S.of(context).loading, dismissOnTap: false);
                              if (widget.transitionModel == null) {
                                PurchaseRepo repo = PurchaseRepo();
                                PurchaseTransaction? purchaseData;
                                purchaseData = await repo.createPurchase(
                                  ref: ref,
                                  context: context,
                                  vatId: providerData.selectedVat?.id,
                                  totalAmount: providerData.totalPayableAmount,
                                  purchaseDate: selectedDate.toString(),
                                  products: providerData.cartItemList,
                                  vatAmount: providerData.vatAmount,
                                  vatPercent: providerData.selectedVat?.rate ?? 0,
                                  paymentType: paymentType ?? 'Cash',
                                  partyId: widget.customerModel?.id ?? 0,
                                  isPaid: providerData.dueAmount <= 0 ? true : false,
                                  dueAmount: providerData.dueAmount <= 0 ? 0 : providerData.dueAmount,
                                  discountAmount: providerData.discountAmount,
                                  paidAmount: providerData.receiveAmount,
                                  shippingCharge: providerData.finalShippingCharge,
                                  discountPercent: providerData.discountPercent,
                                  discountType: discountType.toLowerCase() ?? '',
                                );

                                if (purchaseData != null) {
                                  PurchaseInvoiceDetails(
                                    businessInfo: personalData.value!,
                                    transitionModel: purchaseData,
                                    isFromPurchase: true,
                                  ).launch(context);
                                }
                              } else {
                                PurchaseRepo repo = PurchaseRepo();
                                PurchaseTransaction? purchaseData;
                                purchaseData = await repo.updatePurchase(
                                  id: widget.transitionModel!.id!,
                                  ref: ref,
                                  context: context,
                                  vatId: providerData.selectedVat?.id,
                                  totalAmount: providerData.totalPayableAmount,
                                  purchaseDate: selectedDate.toString(),
                                  products: providerData.cartItemList,
                                  vatAmount: providerData.vatAmount,
                                  vatPercent: providerData.selectedVat?.rate ?? 0,
                                  paymentType: paymentType ?? 'Cash',
                                  partyId: widget.transitionModel?.party?.id ?? 0,
                                  isPaid: providerData.dueAmount <= 0 ? true : false,
                                  dueAmount: providerData.dueAmount <= 0 ? 0 : providerData.dueAmount,
                                  discountAmount: providerData.discountAmount,
                                  paidAmount: providerData.receiveAmount,
                                );

                                if (purchaseData != null) {
                                  const PurchaseListScreen().launch(context);
                                }
                                // await repo.updateSale(
                                //   id: widget.transitionModel?.id ?? 0,
                                //   ref: ref,
                                //   context: context,
                                //   totalAmount: providerData.totalPayableAmount,
                                //   purchaseDate: selectedDate.toString(),
                                //   products: selectedProductList,
                                //   paymentType: paymentType ?? 'Cash',
                                //   partyId: widget.transitionModel?.party?.id,
                                //   vatAmount: providerData.vatAmount,
                                //   vatPercent: providerData.selectedVat != null ? providerData.selectedVat!.rate! : 0,
                                //   isPaid: providerData.isFullPaid,
                                //   dueAmount: providerData.dueAmount,
                                //   discountAmount: providerData.discountAmount,
                                //   paidAmount: providerData.receiveAmount,
                                // );
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            } finally {
                              EasyLoading.dismiss();
                              setState(() {
                                isProcessing = false; // Re-enable button after processing
                              });
                            }
                          },
                          child: Text(
                            lang.S.of(context).save,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: _theme.textTheme.bodyMedium?.copyWith(
                              color: _theme.colorScheme.primaryContainer,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }, error: (e, stack) {
      return Center(
        child: Text(e.toString()),
      );
    }, loading: () {
      return const Center(child: CircularProgressIndicator());
    });
  }
}
