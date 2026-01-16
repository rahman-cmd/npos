import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/Screens/Products/add%20product/modle/create_product_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/currency.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;

import '../../GlobalComponents/glonal_popup.dart';
import '../../Provider/product_provider.dart';
import '../../service/check_actions_when_no_branch.dart';
import '../../service/check_user_role_permission_provider.dart';
import '../../widgets/empty_widget/_empty_widget.dart';
import '../../widgets/key_values/key_values_widget.dart';
import '../Purchase/Repo/purchase_repo.dart';
import '../Purchase/purchase_product_buttom_sheet.dart';
import '../hrm/widgets/deleteing_alart_dialog.dart';
import 'Repo/product_repo.dart';
import 'add product/add_edit_comboItem.dart';
import 'add product/add_product.dart';
import 'add product/combo_product_form.dart';

class ProductDetails extends ConsumerStatefulWidget {
  const ProductDetails({
    super.key,
    required this.details,
  });

  final Product details;

  @override
  ConsumerState<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends ConsumerState<ProductDetails> {
  TextEditingController productStockController = TextEditingController();
  TextEditingController salePriceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final providerData = ref.watch(fetchProductDetails(widget.details.id.toString()));
    final permissionService = PermissionService(ref);
    final _lang = lang.S.of(context);

    return GlobalPopup(
        child: providerData.when(data: (snapshot) {
      return Scaffold(
        backgroundColor: kWhite,
        appBar: AppBar(
          backgroundColor: kWhite,
          surfaceTintColor: kWhite,
          title: Text(
            lang.S.of(context).productDetails,
            //'Product Details',
          ),
          actions: [
            IconButton(
                visualDensity: VisualDensity(horizontal: -4, vertical: -4),
                padding: EdgeInsets.zero,
                onPressed: () async {
                  bool result = await checkActionWhenNoBranch(ref: ref, context: context);
                  if (!result) {
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddProduct(
                        productModel: snapshot,
                      ),
                    ),
                  );
                },
                icon: Icon(
                  Icons.edit,
                  color: Colors.green,
                  size: 22,
                )),
            IconButton(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity(horizontal: -4, vertical: -4),
              onPressed: () async {
                bool confirmDelete = await showDeleteConfirmationDialog(context: context, itemName: 'product');
                if (confirmDelete) {
                  EasyLoading.show(
                    status: lang.S.of(context).deleting,
                  );
                  ProductRepo productRepo = ProductRepo();
                  await productRepo.deleteProduct(id: snapshot.id.toString(), context: context, ref: ref);
                  Navigator.pop(context);
                }
              },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDelete02,
                color: kMainColor,
                size: 22,
              ),
            ),
            SizedBox(width: 10),
          ],
          centerTitle: true,
          // iconTheme: const IconThemeData(color: Colors.white),
          elevation: 0.0,
        ),
        body: Container(
          alignment: Alignment.topCenter,
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(topRight: Radius.circular(30), topLeft: Radius.circular(30))),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (permissionService.hasPermission(Permit.productsRead.value)) ...{
                  Container(
                    height: 256,
                    padding: EdgeInsets.all(8),
                    width: MediaQuery.of(context).size.width,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Color(0xffF5F3F3),
                    ),
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                          color: Color(0xffF5F3F3),
                          borderRadius: BorderRadius.circular(5),
                          image: snapshot.productPicture == null
                              ? DecorationImage(fit: BoxFit.cover, image: AssetImage(noProductImageUrl))
                              : DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage('${APIConfig.domain}${snapshot.productPicture}'))),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.productName.toString(),
                          //'Smart watch',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          snapshot.category?.categoryName.toString() ?? 'n/a',
                          //'Apple Watch',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: kGreyTextColor,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: const Color(0xffFEF0F1),
                          ),
                          child: Column(
                            children: [
                              //Single product details-------------------------
                              if (snapshot.productType == 'single')
                                ...{
                                  _lang.skuOrCode: snapshot.productCode ?? 'n/a',
                                  _lang.brand: snapshot.brand?.brandName ?? 'n/a',
                                  _lang.model: snapshot.productModel?.name ?? 'n/a',
                                  _lang.units: snapshot.unit?.unitName ?? 'n/a',
                                  _lang.rack: snapshot.rack?.name ?? 'n/a',
                                  _lang.shelf: snapshot.shelf?.name ?? 'n/a',
                                  // 'Test': snapshot.shelfId ?? 'n/a',
                                  _lang.stock: snapshot.stocksSumProductStock?.toString() ?? '0',
                                  _lang.lowStockAlert: snapshot.alertQty?.toString() ?? 'n/a',
                                  _lang.warehouse: snapshot.stocks?.first.warehouse?.name?.toString() ?? 'n/a',
                                  _lang.taxType: snapshot.vatType ?? 'n/a',
                                  _lang.tax: snapshot.vatAmount?.toString() ?? 'n/a',
                                  _lang.costExclusionTax: (snapshot.vatType != 'exclusive')
                                      ? (snapshot.stocks != null &&
                                              snapshot.stocks!.isNotEmpty &&
                                              snapshot.stocks!.first.productPurchasePrice != null &&
                                              snapshot.vatAmount != null
                                          ? '${snapshot.stocks!.first.productPurchasePrice! - snapshot.vatAmount!}'
                                          : '0')
                                      : ('$currency${snapshot.stocks?.isNotEmpty == true ? snapshot.stocks!.first.productPurchasePrice ?? '0' : '0'}'),
                                  _lang.costInclusionTax: (snapshot.vatType == 'exclusive')
                                      ? (snapshot.stocks != null &&
                                              snapshot.stocks!.isNotEmpty &&
                                              snapshot.stocks!.first.productPurchasePrice != null &&
                                              snapshot.vatAmount != null
                                          ? '$currency${snapshot.stocks!.first.productPurchasePrice! + snapshot.vatAmount!}'
                                          : '0')
                                      : ('$currency${snapshot.stocks?.isNotEmpty == true ? snapshot.stocks!.first.productPurchasePrice ?? '0' : '0'}'),
                                  '${_lang.profitMargin} (%)': (snapshot.stocks?.isNotEmpty == true &&
                                          snapshot.stocks!.first.profitPercent != null
                                      ? snapshot.stocks!.first.profitPercent.toString()
                                      : '0'),
                                  _lang.mrpOrSalePrice: (snapshot.stocks?.isNotEmpty == true &&
                                          snapshot.stocks!.first.productSalePrice != null
                                      ? '$currency${snapshot.stocks!.first.productSalePrice}'
                                      : '0'),
                                  _lang.wholeSalePrice: (snapshot.stocks?.isNotEmpty == true &&
                                          snapshot.stocks!.first.productWholeSalePrice != null
                                      ? '$currency${snapshot.stocks!.first.productWholeSalePrice}'
                                      : '0'),
                                  _lang.dealerPrice: (snapshot.stocks?.isNotEmpty == true &&
                                          snapshot.stocks!.first.productDealerPrice != null
                                      ? '$currency${snapshot.stocks?.first.productDealerPrice}'
                                      : '0'),
                                  _lang.manufactureDate:
                                      (snapshot.stocks?.isNotEmpty == true && snapshot.stocks!.first.mfgDate != null)
                                          ? DateFormat('d MMMM yyyy')
                                              .format(DateTime.parse(snapshot.stocks!.first.mfgDate!))
                                          : 'n/a',
                                  _lang.expiredDate:
                                      (snapshot.stocks?.isNotEmpty == true && snapshot.stocks!.first.expireDate != null)
                                          ? DateFormat('d MMMM yyyy')
                                              .format(DateTime.parse(snapshot.stocks?.first.expireDate ?? ''))
                                          : 'n/a',
                                  _lang.warranty:
                                      '${snapshot.warrantyGuaranteeInfo?.warrantyDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.warrantyUnit?.toString() ?? 'n/a'}',
                                  _lang.warranty:
                                      '${snapshot.warrantyGuaranteeInfo?.guaranteeDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.guaranteeUnit?.toString() ?? 'n/a'}',
                                }.entries.map(
                                      (entry) => KeyValueRow(
                                        title: entry.key,
                                        titleFlex: 6,
                                        description: entry.value.toString(),
                                        descriptionFlex: 8,
                                      ),
                                    ),
                              //---------------variant product----------------
                              if (snapshot.productType == 'variant')
                                ...{
                                  _lang.skuOrCode: snapshot.productCode ?? 'n/a',
                                  _lang.brand: snapshot.brand?.brandName ?? 'n/a',
                                  _lang.model: snapshot.productModel?.name ?? 'n/a',
                                  _lang.rack: snapshot.shelf?.name ?? 'n/a',
                                  _lang.lowStockAlert: snapshot.alertQty?.toString() ?? 'n/a',
                                  _lang.taxReport: snapshot.vatType ?? 'n/a',
                                  _lang.tax: snapshot.vatAmount?.toString() ?? 'n/a',
                                  _lang.warranty:
                                      '${snapshot.warrantyGuaranteeInfo?.warrantyDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.warrantyUnit?.toString() ?? 'n/a'}',
                                  _lang.guarantee:
                                      '${snapshot.warrantyGuaranteeInfo?.guaranteeDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.guaranteeUnit?.toString() ?? 'n/a'}',
                                }.entries.map(
                                      (entry) => KeyValueRow(
                                        title: entry.key,
                                        titleFlex: 6,
                                        description: entry.value.toString(),
                                        descriptionFlex: 8,
                                      ),
                                    ),
                              //---------------Combo product----------------
                              if (snapshot.productType == 'combo')
                                ...{
                                  _lang.skuOrCode: snapshot.productCode ?? 'n/a',
                                  _lang.brand: snapshot.brand?.brandName ?? 'n/a',
                                  _lang.model: snapshot.productModel?.name ?? 'n/a',
                                  _lang.units: snapshot.unit?.unitName ?? 'n/a',
                                  _lang.rack: snapshot.rack?.name ?? 'n/a',
                                  _lang.shelf: snapshot.shelf?.name ?? 'n/a',
                                  _lang.lowStockAlert: snapshot.alertQty?.toString() ?? 'n/a',
                                  _lang.type: snapshot.productType ?? 'n/a',
                                  _lang.taxType: snapshot.vatType ?? 'n/a',
                                  _lang.tax: snapshot.vatAmount?.toString() ?? 'n/a',
                                  _lang.netTotalAmount:
                                      (snapshot.productSalePrice != null && snapshot.profitPercent != null)
                                          ? (snapshot.productSalePrice! / (1 + (snapshot.profitPercent! / 100)))
                                              .toStringAsFixed(2)
                                          : 'n/a',
                                  '${_lang.profitMargin} (%)': '${snapshot.profitPercent ?? 0}%',
                                  _lang.sellingPrice: '$currency${snapshot.productSalePrice ?? 0}',
                                  _lang.warranty:
                                      '${snapshot.warrantyGuaranteeInfo?.warrantyDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.warrantyUnit?.toString() ?? 'n/a'}',
                                  _lang.guarantee:
                                      '${snapshot.warrantyGuaranteeInfo?.guaranteeDuration?.toString() ?? ''} ${snapshot.warrantyGuaranteeInfo?.guaranteeUnit?.toString() ?? 'n/a'}',
                                }.entries.map(
                                      (entry) => KeyValueRow(
                                        title: entry.key,
                                        titleFlex: 6,
                                        description: entry.value.toString(),
                                        descriptionFlex: 8,
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  //--------------variant product details---------------------------------
                  if (snapshot.productType == 'variant') ...[
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 16, end: 16, top: 16, bottom: 6),
                      child: Text(
                        _lang.variationsProduct,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ListView.separated(
                      // padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 16),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.stocks?.length ?? 0,
                      separatorBuilder: (context, index) => Divider(
                        thickness: 0.3,
                        color: kBorderColorTextField,
                      ),
                      itemBuilder: (context, index) {
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  snapshot.stocks?[index].variantName ?? 'n/a',
                                  maxLines: 1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: kTitleColor,
                                    // fontWeight: FontWeight.w500,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  '${_lang.sale}: $currency${snapshot.stocks?[index].productSalePrice ?? '0'}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: kTitleColor,
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${_lang.batch}: ${snapshot.stocks?[index].batchNo ?? 'N/A'}',
                                  maxLines: 1,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: kTitleColor,
                                    // fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: RichText(
                                  text: TextSpan(
                                    text: '${_lang.stock}: ',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: kNeutralColor,
                                      fontWeight: FontWeight.w400,
                                      fontSize: 14,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: snapshot.stocks?[index].productStock.toString() ?? '0',
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: Color(0xff34C759),
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          trailing: SizedBox(
                            width: 30,
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              iconColor: kPeraColor,
                              onSelected: (value) {
                                switch (value) {
                                  case 'view':
                                    viewModal(context, snapshot, index);
                                    break;
                                  case 'edit':
                                    final stock = snapshot.stocks?[index];

                                    final cartProduct = CartProductModelPurchase(
                                      productId: snapshot.id ?? 0,
                                      variantName: stock?.variantName,
                                      brandName: snapshot.brand?.brandName,
                                      productName: snapshot.productName ?? '',
                                      productDealerPrice: stock?.productDealerPrice,
                                      productPurchasePrice: stock?.productPurchasePrice,
                                      productSalePrice: stock?.productSalePrice,
                                      productWholeSalePrice: stock?.productWholeSalePrice,
                                      quantities: stock?.productStock,
                                      productType: snapshot.productType ?? '',
                                      vatAmount: snapshot.vatAmount ?? 0,
                                      vatRate: snapshot.vat?.rate ?? 0,
                                      vatType: snapshot.vatType ?? 'exclusive',
                                      expireDate: stock?.expireDate,
                                      mfgDate: stock?.mfgDate,
                                      profitPercent: stock?.profitPercent ?? 0,
                                      stock: stock?.productStock,
                                      batchNumber: stock?.batchNo ?? '',
                                    );
                                    addProductInPurchaseCartButtomSheet(
                                        context: context,
                                        product: cartProduct,
                                        ref: ref,
                                        fromUpdate: false,
                                        index: index,
                                        fromStock: true,
                                        stocks: []);
                                    break;
                                  case 'add_stock':
                                    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
                                    productStockController.text = '1';
                                    salePriceController.text =
                                        snapshot.stocks?[index].productSalePrice?.toString() ?? '0.0';
                                    addStockPopUp(context, _formKey, theme, snapshot, index);
                                    break;
                                  case 'delete':
                                    showEditDeletePopUp(
                                        context: context,
                                        data: snapshot.stocks?[index],
                                        ref: ref,
                                        productId: widget.details.id.toString());
                                    break;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(value: 'view', child: Text(_lang.view)),
                                PopupMenuItem(value: 'edit', child: Text(_lang.edit)),
                                PopupMenuItem(value: 'add_stock', child: Text(_lang.addStock)),
                                PopupMenuItem(value: 'delete', child: Text(_lang.delete)),
                              ],
                            ),
                          ),
                          visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                        );
                      },
                    ),
                  ],
                  //--------------Combo product details---------------------------------
                  if (snapshot.productType == 'combo') ...[
                    Padding(
                      padding: EdgeInsetsDirectional.only(start: 16, end: 16, top: 16, bottom: 6),
                      child: Text(
                        _lang.comboProducts,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ListView.separated(
                      // padding: EdgeInsetsGeometry.symmetric(vertical: 10, horizontal: 16),
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: snapshot.comboProducts?.length ?? 0,
                      separatorBuilder: (context, index) => Divider(
                        thickness: 0.3,
                        color: kBorderColorTextField,
                      ),
                      itemBuilder: (context, index) {
                        final combo = snapshot.comboProducts![index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${combo.stock?.product?.productName ?? 'n/a'} ${combo.stock?.variantName ?? ''}',
                                maxLines: 1,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: kTitleColor,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${_lang.qty}: ${combo.quantity ?? '0'}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: kPeraColor,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${_lang.code}: ${combo.stock?.product?.productCode ?? 'n/a'}, ${_lang.batchNo}: ${snapshot.comboProducts?[index].stock?.batchNo ?? 'n/a'}',
                                maxLines: 1,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: kPeraColor,
                                ),
                              ),
                              Text(
                                '$currency${combo.stock?.productSalePrice ?? 0}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          // trailing: SizedBox(
                          //   width: 30,
                          //   child: PopupMenuButton<String>(
                          //     iconColor: kPeraColor,
                          //     onSelected: (value) async {
                          //       switch (value) {
                          //         case 'edit':
                          //           // Convert ComboProductComponent → ComboItem
                          //           final comboItem = ComboItem(
                          //             product: combo.product!,
                          //             stockData: combo.stock!,
                          //             quantity: combo.quantity ?? combo.stock?.productStock ?? 1,
                          //             manualPurchasePrice: combo.purchasePrice?.toDouble(),
                          //           );
                          //
                          //           // Navigate to edit page
                          //           Navigator.push(
                          //             context,
                          //             MaterialPageRoute(
                          //               builder: (context) => AddOrEditComboItem(
                          //                 existingItem: comboItem,
                          //                 onSubmit: (updatedItem) {
                          //                   setState(() {
                          //                     // Convert ComboItem → ComboProductComponent after edit
                          //                     snapshot.comboProducts![index] = ComboProductComponent(
                          //                       id: combo.id,
                          //                       productId: updatedItem.product.id,
                          //                       stockId: updatedItem.stockData.id,
                          //                       purchasePrice: updatedItem.manualPurchasePrice,
                          //                       quantity: updatedItem.quantity,
                          //                       stock: updatedItem.stockData,
                          //                       product: updatedItem.product,
                          //                     );
                          //                   });
                          //                 },
                          //               ),
                          //             ),
                          //           );
                          //           break;
                          //
                          //         case 'delete':
                          //           final confirmDelete = await showDialog<bool>(
                          //             context: context,
                          //             builder: (context) => AlertDialog(
                          //               title: const Text('Delete Combo Product'),
                          //               content: const Text('Are you sure you want to delete this item?'),
                          //               actions: [
                          //                 TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                          //                 TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                          //               ],
                          //             ),
                          //           );
                          //
                          //           if (confirmDelete == true) {
                          //             setState(() {
                          //               snapshot.comboProducts!.removeAt(index);
                          //             });
                          //           }
                          //           break;
                          //       }
                          //     },
                          //     itemBuilder: (BuildContext context) => [
                          //       const PopupMenuItem(value: 'edit', child: Text('Edit')),
                          //       const PopupMenuItem(
                          //         value: 'delete',
                          //         child: Text('Delete', style: TextStyle(color: Colors.red)),
                          //       ),
                          //     ],
                          //   ),
                          // ),
                          visualDensity: VisualDensity(vertical: -4, horizontal: -4),
                        );
                      },
                    ),
                  ],
                } else
                  Center(child: PermitDenyWidget()),
              ],
            ),
          ),
        ),
      );
    }, error: (e, stack) {
      return Text(e.toString());
    }, loading: () {
      return const Center(child: CircularProgressIndicator());
    }));
  }

  // Add stock popup
  Future<dynamic> addStockPopUp(
      BuildContext context, GlobalKey<FormState> _formKey, ThemeData theme, Product snapshot, int index) {
    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(start: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        lang.S.of(context).addStock,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: kTitleColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: kTitleColor, size: 16),
                        iconSize: 16,
                        constraints: BoxConstraints(
                          minWidth: 30,
                          minHeight: 30,
                        ),
                        style: ButtonStyle(
                          backgroundColor: WidgetStatePropertyAll(Color(0xffEEF3FF)),
                          padding: WidgetStatePropertyAll(EdgeInsets.zero),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Divider(
                  thickness: 0.3,
                  color: kBorderColorTextField,
                  height: 0,
                ),
                SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        textAlign: TextAlign.center,
                        controller: productStockController,
                        validator: (value) {
                          final int? enteredStock = int.tryParse(value ?? '');
                          if (enteredStock == null || enteredStock < 1) {
                            return lang.S.of(context).stockWarn;
                          }
                          return null;
                        },
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: lang.S.of(context).enterStock,
                          prefixIcon: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xffE0E2E7),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: () {
                                int quantity = int.tryParse(productStockController.text) ?? 1;
                                if (quantity > 1) {
                                  quantity--;
                                  productStockController.text = quantity.toString();
                                }
                              },
                              child: Icon(Icons.remove, color: Color(0xff4A4A52)),
                            ),
                          ),
                          suffixIcon: Container(
                            margin: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            height: 26,
                            width: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: kMainColor.withOpacity(0.15),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(50),
                              onTap: () {
                                int quantity = int.tryParse(productStockController.text) ?? 1;
                                quantity++;
                                productStockController.text = quantity.toString();
                              },
                              child: Icon(Icons.add, color: theme.colorScheme.primary),
                            ),
                          ),
                          border: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffE0E2E7))),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffE0E2E7))),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xffE0E2E7))),
                          contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                        ),
                      ),
                      SizedBox(height: 24),
                      TextFormField(
                        readOnly: true,
                        controller: salePriceController,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: lang.S.of(context).salePrice,
                          hintText: lang.S.of(context).enterAmount,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Color(0xffF68A3D)),
                              ),
                              child: Text(lang.S.of(context).cancel, style: TextStyle(color: Color(0xffF68A3D))),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              child: Text(lang.S.of(context).save),
                              onPressed: () async {
                                if (_formKey.currentState?.validate() ?? false) {
                                  final int newStock = int.tryParse(productStockController.text) ?? 0;

                                  try {
                                    EasyLoading.show(status: lang.S.of(context).updating);

                                    final repo = ProductRepo();
                                    final String productId = snapshot.stocks?[index].id.toString() ?? '';

                                    final bool success = await repo.addStock(
                                      id: productId,
                                      qty: newStock.toString(),
                                    );

                                    EasyLoading.dismiss();

                                    if (success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(lang.S.of(context).updateSuccess)),
                                      );

                                      ref.refresh(fetchProductDetails(widget.details.id.toString()));
                                      ref.refresh(productProvider);

                                      productStockController.clear();
                                      salePriceController.clear();

                                      Navigator.pop(context);
                                    } else {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(lang.S.of(context).updateFailed)),
                                      );
                                    }
                                  } catch (e) {
                                    EasyLoading.dismiss();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: ${e.toString()}')),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }

  // view modal sheet
  Future<dynamic> viewModal(BuildContext context, Product snapshot, int index) {
    final _lang = lang.S.of(context);
    return showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setNewState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: EdgeInsetsDirectional.only(start: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      lang.S.of(context).view,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, size: 18),
                    )
                  ],
                ),
              ),
              Divider(color: kBorderColor, height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  children: [
                    if (snapshot.stocks != null && snapshot.stocks!.isNotEmpty && index < snapshot.stocks!.length)
                      ...{
                        _lang.batchNo: snapshot.stocks![index].batchNo ?? 'n/a',
                        _lang.qty: snapshot.stocks![index].productStock?.toString() ?? '0',
                        _lang.costExclusionTax: snapshot.vatType != 'exclusive'
                            ? (snapshot.stocks![index].productPurchasePrice != null && snapshot.vatAmount != null
                                ? '${snapshot.stocks![index].productPurchasePrice! - snapshot.vatAmount!}'
                                : 'n/a')
                            : (snapshot.stocks![index].productPurchasePrice?.toString() ?? 'n/a'),
                        _lang.costInclusionTax: snapshot.vatType == 'exclusive'
                            ? (snapshot.stocks![index].productPurchasePrice != null && snapshot.vatAmount != null
                                ? '${snapshot.stocks![index].productPurchasePrice! + snapshot.vatAmount!}'
                                : 'n/a')
                            : (snapshot.stocks![index].productPurchasePrice?.toString() ?? 'n/a'),
                        '${_lang.profitMargin} (%)': snapshot.stocks![index].profitPercent?.toString() ?? 'n/a',
                        _lang.salePrice: snapshot.stocks![index].productSalePrice?.toString() ?? 'n/a',
                        _lang.wholeSalePrice: snapshot.stocks![index].productWholeSalePrice?.toString() ?? 'n/a',
                        _lang.dealerPrice: snapshot.stocks![index].productDealerPrice?.toString() ?? 'n/a',
                        _lang.manufactureDate:
                            (snapshot.stocks![index].mfgDate != null && snapshot.stocks![index].mfgDate!.isNotEmpty)
                                ? DateFormat('d MMMM yyyy')
                                    .format(DateTime.tryParse(snapshot.stocks![index].mfgDate!) ?? DateTime(0))
                                : 'n/a',
                        _lang.expiredDate: (snapshot.stocks![index].expireDate != null &&
                                snapshot.stocks![index].expireDate!.isNotEmpty)
                            ? DateFormat('d MMMM yyyy')
                                .format(DateTime.tryParse(snapshot.stocks![index].expireDate!) ?? DateTime(0))
                            : 'n/a',
                      }.entries.map(
                            (entry) => KeyValueRow(
                              title: entry.key,
                              titleFlex: 6,
                              description: entry.value.toString(),
                              descriptionFlex: 8,
                            ),
                          )
                    else
                      Text(_lang.noStockAvailable),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> showEditDeletePopUp(
    {required BuildContext context, Stock? data, required WidgetRef ref, required String productId}) async {
  final _theme = Theme.of(context);
  return await showDialog(
    barrierDismissible: false,
    context: context,
    builder: (BuildContext dialogContext) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(
                Radius.circular(8),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  lang.S.of(context).deleteBatchWarn,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 26),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xffF68A3D).withValues(alpha: 0.1),
                  ),
                  padding: EdgeInsets.all(20),
                  child: SvgPicture.asset(
                    height: 146,
                    width: 146,
                    'images/trash.svg',
                  ),
                ),
                SizedBox(height: 26),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(context);
                        },
                        child: Text(lang.S.of(context).cancel),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await Future.delayed(Duration.zero);
                          ProductRepo repo = ProductRepo();
                          bool success;
                          success = await repo.deleteStock(
                            id: data?.id.toString() ?? '',
                          );
                          if (success) {
                            ref.refresh(fetchProductDetails(productId));
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(lang.S.of(context).deletedSuccessFully)));
                            Navigator.pop(context);
                          }
                        },
                        child: Text(lang.S.of(context).delete),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
