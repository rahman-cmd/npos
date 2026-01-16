import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_long_screenshot/flutter_long_screenshot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/Provider/profile_provider.dart';
import 'package:mobile_pos/Screens/invoice_details/components/common_image_builder.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:nb_utils/nb_utils.dart';
import 'package:provider/provider.dart' as pro;

import '../../GlobalComponents/glonal_popup.dart';
import '../../constant.dart' as mainConstant;
import '../../constant.dart';
import '../../currency.dart';
import '../../model/business_info_model.dart' as binfo;
import '../../thermal priting invoices/model/print_transaction_model.dart';
import '../../thermal priting invoices/provider/print_thermal_invoice_provider.dart';
import '../../widgets/dotted_border/global_dotted_border.dart';
import '../../widgets/universal_image.dart';
import '../Products/add product/modle/create_product_model.dart';
import '../Purchase/Model/purchase_transaction_model.dart';
import '../language/language_provider.dart';

class PurchaseInvoiceDetails extends StatefulWidget {
  const PurchaseInvoiceDetails(
      {super.key, required this.transitionModel, required this.businessInfo, this.isFromPurchase});

  final PurchaseTransaction transitionModel;
  final binfo.BusinessInformationModel businessInfo;
  final bool? isFromPurchase;

  @override
  State<PurchaseInvoiceDetails> createState() => _PurchaseInvoiceDetailsState();
}

class _PurchaseInvoiceDetailsState extends State<PurchaseInvoiceDetails> {
  final GlobalKey _screenshotKey = GlobalKey();

  num productPrice({required num detailsId}) {
    return widget.transitionModel.details!.where((element) => element.id == detailsId).first.productPurchasePrice ?? 0;
  }

  num getReturndDiscountAmount() {
    num totalReturnDiscount = 0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            totalReturnDiscount +=
                ((productPrice(detailsId: details.purchaseDetailId ?? 0) * (details.returnQty ?? 0)) -
                    ((details.returnAmount ?? 0)));
          }
        }
      }
    }
    return totalReturnDiscount;
  }

  String productName({required num detailsId}) {
    final details = widget
        .transitionModel.details?[widget.transitionModel.details!.indexWhere((element) => element.id == detailsId)];
    return "${details?.product?.productName}${details?.product?.productType == ProductType.variant.name ? ' [${details?.stock?.batchNo ?? ""}]' : ''}";
  }

  num getTotalReturndAmount() {
    num totalReturn = 0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            totalReturn += details.returnAmount ?? 0;
          }
        }
      }
    }
    return totalReturn;
  }

  // num getTotalForOldInvoice() {
  //   num total = 0;
  //   for (var element in widget.transitionModel.details!) {
  //     total += (element.productPurchasePrice ?? 0) * getProductQuantity(detailsId: element.id ?? 0);
  //   }
  //   return total + (widget.transitionModel.vatAmount ?? 0);
  // }
  num getTotalForOldInvoice() {
    num total = 0;
    for (var element in widget.transitionModel.details!) {
      // Calculate the total for each item without VAT
      num productPrice = element.productPurchasePrice ?? 0;
      num productQuantity = getProductQuantity(detailsId: element.id ?? 0);

      total += productPrice * productQuantity;
    }

    return total;
  }

  int serialNumber = 1;

  num getProductQuantity({required num detailsId}) {
    num totalQuantity =
        widget.transitionModel.details?.where((element) => element.id == detailsId).first.quantities ?? 0;
    if (widget.transitionModel.purchaseReturns?.isNotEmpty ?? false) {
      for (var returns in widget.transitionModel.purchaseReturns!) {
        if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.purchaseReturnDetails!) {
            if (details.purchaseDetailId == detailsId) {
              totalQuantity += details.returnQty ?? 0;
            }
          }
        }
      }
    }

    return totalQuantity;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(builder: (context, ref, __) {
      final printerData = ref.watch(thermalPrinterProvider);
      final businessSettingData = ref.watch(businessInfoProvider);
      final _theme = Theme.of(context);
      final _lang = lang.S.of(context);
      final locale = Localizations.localeOf(context).languageCode;
      // final hasWarranty = widget.transitionModel.details!.any((e) => e.warrantyInfo?.warrantyDuration != null);
      // final hasGuarantee = widget.saleTransaction.salesDetails!.any((e) => e.warrantyInfo?.guaranteeDuration != null);
      return SafeArea(
        child: GlobalPopup(
          child: Scaffold(
            backgroundColor: Colors.white,
            body: SingleChildScrollView(
              child: RepaintBoundary(
                key: _screenshotKey,
                child: SizedBox(
                  width: 374,
                  child: Container(
                    width: 374,
                    color: Colors.white,
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///------------header -------------------
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            //----------Invoice Logo------------------------
                            if (widget.businessInfo.data?.showThermalInvoiceLogo == 1)
                              businessSettingData.when(
                                data: (business) {
                                  final isSvg = business.data?.thermalInvoiceLogo?.endsWith('.svg');
                                  final imageUrl = '${APIConfig.domain}${business.data?.thermalInvoiceLogo}';
                                  const placeholder = AssetImage(mainConstant.logo);
                                  return (business.data?.thermalInvoiceLogo?.isEmptyOrNull ?? true)
                                      ? buildInvoiceLogo(image: placeholder)
                                      : (isSvg ?? false)
                                          ? SvgPicture.network(
                                              imageUrl,
                                              height: 46,
                                              width: 44,
                                              fit: BoxFit.cover,
                                              colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
                                            )
                                          : buildInvoiceLogo(
                                              image: NetworkImage(imageUrl),
                                            );
                                },
                                error: (e, stack) => Text(e.toString()),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              ),
                            SizedBox(
                              height: 10,
                            ),
                            //----------company name---------------------------
                            if (widget.businessInfo.data?.meta?.showCompanyName == 1)
                              Text(
                                '${widget.businessInfo.data?.companyName}',
                                style: _theme.textTheme.titleLarge?.copyWith(
                                  fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            //-------------company Branch---------------------------------
                            if (widget.transitionModel.branch?.name?.isNotEmpty ?? false)
                              Text.rich(
                                TextSpan(
                                  text: '${_lang.branch} : ',
                                  children: [
                                    TextSpan(
                                      text: widget.transitionModel.branch?.name.toString() ?? 'n/a',
                                      style: _theme.textTheme.bodyLarge?.copyWith(
                                        fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        color: mainConstant.kTextColor,
                                      ),
                                    ),
                                  ],
                                  style: _theme.textTheme.bodyLarge?.copyWith(
                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    color: mainConstant.kTextColor,
                                  ),
                                ),
                              ),
                            //----------------Address----------------------------------
                            if (widget.businessInfo.data?.meta?.showAddress == 1)
                              Text(
                                '${_lang.address}: ${widget.businessInfo.data?.address ?? ''}',
                                style: _theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  color: mainConstant.kTextColor,
                                ),
                              ),
                            //---------------Phone-------------------------------------------
                            if (widget.businessInfo.data?.meta?.showPhoneNumber == 1)
                              Text(
                                '${_lang.mobile} ${(widget.transitionModel.branch?.phone?.isNotEmpty ?? false) ? widget.transitionModel.branch?.phone ?? 'n/a' : widget.businessInfo.data?.phoneNumber?.toString() ?? 'n/a'}',
                                style: _theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  color: mainConstant.kTextColor,
                                ),
                              ),
                            //-----------------email----------------------------
                            if (widget.businessInfo.data?.meta?.showEmail == 1)
                              Text(
                                '${_lang.email}: ${widget.businessInfo.data?.user?.email ?? ''}',
                                style: _theme.textTheme.bodyLarge?.copyWith(
                                  fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  color: mainConstant.kTextColor,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            SizedBox(height: 8),
                            //-----------------Invoice-------------------
                            Text(
                              _lang.invoice.toUpperCase(),
                              style: _theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                            //-------------duplicate header section---------------------------
                            // ListTile(
                            //   contentPadding: EdgeInsets.zero,
                            //   leading: businessSettingData.when(
                            //     data: (business) {
                            //       final isSvg = business.pictureUrl?.endsWith('.svg');
                            //       final imageUrl = '${APIConfig.domain}${business.pictureUrl}';
                            //       const placeholder = AssetImage(mainConstant.logo);
                            //       return business.pictureUrl.isEmptyOrNull
                            //           ? _buildInvoiceLogo(image: placeholder)
                            //           : (isSvg ?? false)
                            //               ? SvgPicture.network(imageUrl, height: 54.12, width: 52, fit: BoxFit.cover)
                            //               : _buildInvoiceLogo(
                            //                   image: NetworkImage(imageUrl),
                            //                 );
                            //     },
                            //     error: (e, stack) => Text(e.toString()),
                            //     loading: () => const Center(
                            //       child: CircularProgressIndicator(),
                            //     ),
                            //   ),
                            //   title: Text(
                            //     '${widget.businessInfo.data?.companyName}',
                            //     style: _theme.textTheme.headlineSmall?.copyWith(
                            //       fontWeight: FontWeight.w700,
                            //     ),
                            //   ),
                            //   subtitle: Column(
                            //     crossAxisAlignment: CrossAxisAlignment.start,
                            //     children: [
                            //       if (widget.saleTransaction.branch?.name?.isNotEmpty ?? false)
                            //         Text.rich(
                            //           TextSpan(
                            //             text: 'Branch : ',
                            //             children: [
                            //               TextSpan(
                            //                 text: widget.saleTransaction.branch?.name.toString() ?? 'n/a',
                            //               ),
                            //             ],
                            //           ),
                            //         ),
                            //       Text.rich(
                            //         TextSpan(
                            //           text: '${lang.S.of(context).mobiles} : ',
                            //           children: [
                            //             TextSpan(
                            //               text: (widget.saleTransaction.branch?.phone?.isNotEmpty ?? false)
                            //                   ? widget.saleTransaction.branch?.phone ?? 'n/a'
                            //                   : widget.businessInfo.data?.phoneNumber?.toString() ?? 'n/a',
                            //             ),
                            //           ],
                            //         ),
                            //       ),
                            //     ],
                            //   ),
                            //   trailing: Container(
                            //     alignment: Alignment.center,
                            //     // height: 52,
                            //     width: 110,
                            //     padding: const EdgeInsets.all(8),
                            //     decoration: const BoxDecoration(
                            //       color: Colors.black,
                            //       borderRadius: BorderRadius.only(
                            //         topLeft: Radius.circular(25),
                            //         bottomLeft: Radius.circular(25),
                            //       ),
                            //     ),
                            //     child: Text(
                            //       lang.S.of(context).invoice,
                            //       style: _theme.textTheme.titleLarge?.copyWith(
                            //         color: white,
                            //         fontWeight: FontWeight.bold,
                            //       ),
                            //     ),
                            //   ),
                            // ),
                            SizedBox(height: 32),

                            ///--------header data-----------------
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      //Invoice
                                      Text.rich(
                                        TextSpan(
                                            text: '${lang.S.of(context).invoice} : ',
                                            children: [
                                              TextSpan(
                                                  text: widget.transitionModel.invoiceNumber ?? '',
                                                  style: _theme.textTheme.titleSmall?.copyWith(
                                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                                    fontWeight: FontWeight.w500,
                                                  ))
                                            ],
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              color: mainConstant.kTextColor,
                                            )),
                                      ),
                                      //name
                                      Text.rich(
                                        TextSpan(
                                          text: '${lang.S.of(context).name} : ',
                                          children: [
                                            TextSpan(
                                                text: widget.transitionModel.party?.name ?? '',
                                                style: _theme.textTheme.bodyMedium?.copyWith(
                                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                                    color: mainConstant.kTextColor))
                                          ],
                                          style: _theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                            color: mainConstant.kTextColor,
                                          ),
                                        ),
                                      ),
                                      //mobile
                                      Text.rich(
                                        TextSpan(
                                          text: '${lang.S.of(context).mobile} ',
                                          children: [
                                            TextSpan(
                                              text: widget.transitionModel.party?.phone,
                                              style: _theme.textTheme.bodyMedium?.copyWith(
                                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                                color: mainConstant.kTextColor,
                                              ),
                                            ),
                                          ],
                                          style: _theme.textTheme.bodyMedium?.copyWith(
                                            fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                            color: mainConstant.kTextColor,
                                          ),
                                        ),
                                      ),
                                      if (widget.businessInfo.data?.invoiceSize != "3_inch_80mm") ...[
                                        //date----------------
                                        Text.rich(
                                          TextSpan(
                                            text: '${lang.S.of(context).date} : ',
                                            children: [
                                              TextSpan(
                                                text: DateFormat.yMMMd().format(DateTime.parse(
                                                    widget.transitionModel.purchaseDate ?? DateTime.now().toString())),
                                              ),
                                            ],
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              color: mainConstant.kTextColor,
                                            ),
                                          ),
                                        ),
                                        //Time
                                        Text.rich(
                                          textAlign: TextAlign.end,
                                          TextSpan(
                                            text: '${locale == "en" ? 'Time' : lang.S.of(context).allTime}: ',
                                            children: [
                                              TextSpan(
                                                text: DateFormat.jm().format(DateTime.parse(
                                                    widget.transitionModel.purchaseDate ?? DateTime.now().toString())),
                                              )
                                            ],
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              color: mainConstant.kTextColor,
                                            ),
                                          ),
                                        ),
                                        //Purchase by
                                        Text.rich(
                                          TextSpan(
                                            text: '${lang.S.of(context).purchaseBy} ',
                                            children: [
                                              TextSpan(
                                                text: widget.transitionModel.user?.role == "shop-owner"
                                                    ? "Admin"
                                                    : widget.transitionModel.user?.name ?? '',
                                              )
                                            ],
                                            style: _theme.textTheme.titleSmall?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        //Vat Number
                                        Visibility(
                                          visible: widget.businessInfo.data?.vatNo != null &&
                                              widget.businessInfo.data?.meta?.showVat == 1,
                                          child: Text.rich(
                                            TextSpan(
                                              text: '${widget.businessInfo.data?.vatName ?? _lang.vatNumber} : ',
                                              children: [
                                                TextSpan(
                                                  text: widget.businessInfo.data?.vatNo ?? '',
                                                )
                                              ],
                                              style: _theme.textTheme.bodyLarge?.copyWith(
                                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                                color: mainConstant.kTextColor,
                                              ),
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (widget.businessInfo.data?.invoiceSize == "3_inch_80mm") ...[
                                  Flexible(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        //date----------------
                                        Text.rich(
                                          TextSpan(
                                            text: '${lang.S.of(context).date} : ',
                                            children: [
                                              TextSpan(
                                                text: DateFormat.yMMMd().format(DateTime.parse(
                                                    widget.transitionModel.purchaseDate ?? DateTime.now().toString())),
                                              ),
                                            ],
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              color: mainConstant.kTextColor,
                                            ),
                                          ),
                                        ),
                                        //Time
                                        Text.rich(
                                          textAlign: TextAlign.end,
                                          TextSpan(
                                            text: '${locale == "en" ? 'Time' : lang.S.of(context).allTime}: ',
                                            children: [
                                              TextSpan(
                                                text: DateFormat.jm().format(DateTime.parse(
                                                    widget.transitionModel.purchaseDate ?? DateTime.now().toString())),
                                              )
                                            ],
                                            style: _theme.textTheme.bodyMedium?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              color: mainConstant.kTextColor,
                                            ),
                                          ),
                                        ),
                                        //Purchase by
                                        Text.rich(
                                          TextSpan(
                                            text: '${lang.S.of(context).purchaseBy} ',
                                            children: [
                                              TextSpan(
                                                text: widget.transitionModel.user?.role == "shop-owner"
                                                    ? "Admin"
                                                    : widget.transitionModel.user?.name ?? '',
                                              )
                                            ],
                                            style: _theme.textTheme.titleSmall?.copyWith(
                                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        //Vat Number
                                        Visibility(
                                          visible: widget.businessInfo.data?.vatNo != null &&
                                              widget.businessInfo.data?.meta?.showVat == 1,
                                          child: Text.rich(
                                            TextSpan(
                                              text: '${widget.businessInfo.data?.vatName ?? _lang.vatNumber} : ',
                                              children: [
                                                TextSpan(
                                                  text: widget.businessInfo.data?.vatNo ?? '',
                                                )
                                              ],
                                              style: _theme.textTheme.bodyLarge?.copyWith(
                                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                                color: mainConstant.kTextColor,
                                              ),
                                            ),
                                            textAlign: TextAlign.start,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 12),

                        ///-----------Product Table------------------------------------------
                        globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              //SL
                              Expanded(
                                flex: 1,
                                child: Text(
                                  _lang.sl,
                                  textAlign: TextAlign.start,
                                  style: _theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  ),
                                ),
                              ),
                              //Product
                              Expanded(
                                flex: 3,
                                child: Text(
                                  _lang.product,
                                  textAlign: TextAlign.start,
                                  style: _theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  ),
                                ),
                              ),
                              //Quantity
                              Expanded(
                                flex: 2,
                                child: Text(
                                  lang.S.of(context).qty,
                                  textAlign: TextAlign.center,
                                  style: _theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  ),
                                ),
                              ),
                              //Unit Price
                              if (widget.businessInfo.data?.invoiceSize == "3_inch_80mm") ...[
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    locale == "en" ? "U.Price" : _lang.unitPrice,
                                    textAlign: TextAlign.center,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                              ],
                              //Amount
                              Expanded(
                                flex: 3,
                                child: Text(
                                  lang.S.of(context).amount,
                                  textAlign: TextAlign.end,
                                  style: _theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                        ...widget.transitionModel.details!.asMap().entries.map((entry) {
                          final i = entry.key; // This is the index
                          final detail = entry.value; // This is the detail object
                          final quantity = getProductQuantity(detailsId: detail.id ?? 0);
                          final unitPrice = detail.productPurchasePrice ?? 0;
                          final totalPrice = unitPrice * quantity;
                          return Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    (i + 1).toString(),
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                    textAlign: TextAlign.start,
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${detail.product?.productName ?? ''}${detail.product?.productType == ProductType.variant.name ? ' [${detail.stock?.batchNo ?? ''}]' : ''}',
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                      // if (hasWarranty)
                                      //   Text(
                                      //     'Warranty : ${saleDetail.warrantyInfo?.warrantyDuration ?? ''} ${saleDetail.warrantyInfo?.warrantyUnit ?? ''}',
                                      //     style: _theme.textTheme.bodySmall?.copyWith(
                                      //       fontSize: 10,
                                      //     ),
                                      //   ),
                                      // if (hasWarranty)
                                      //   Text(
                                      //     'Guaranty : ${saleDetail.warrantyInfo?.warrantyDuration ?? ''} ${saleDetail.warrantyInfo?.warrantyUnit ?? ''}',
                                      //     style: _theme.textTheme.bodySmall?.copyWith(
                                      //       fontSize: 10,
                                      //     ),
                                      //   ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    quantity.toString(),
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                if (widget.businessInfo.data?.invoiceSize == "3_inch_80mm") ...[
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      '$currency $unitPrice',
                                      style: _theme.textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                      ),
                                      // '$currency${formatPointNumber(saleDetail.price)}',
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    '$currency $totalPrice',
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        SizedBox(height: 7),
                        globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).subTotal} : ',
                              children: [
                                TextSpan(
                                  text: '$currency ${mainConstant.formatPointNumber(getTotalForOldInvoice())}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        //----------discount----------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).discount} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber((widget.transitionModel.discountAmount ?? 0) + getReturndDiscountAmount())}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5.0),
                        //----------vat----------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${widget.transitionModel.vat?.name ?? lang.S.of(context).vat} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber((widget.transitionModel.vatAmount ?? 0))}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),

                        const SizedBox(height: 5.0),

                        ///__________shipping_charge______________
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).shippingCharge} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber(widget.transitionModel.shippingCharge ?? 0)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        //----------total amount-------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).totalAmount} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber((widget.transitionModel.totalAmount ?? 0) + getTotalReturndAmount())}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),

                        ///------------Returned Amount--------------------------------------
                        if (widget.transitionModel.purchaseReturns!.isNotEmpty) ...[
                          ///-------------new product data---------------------
                          const SizedBox(height: 16),
                          globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              children: [
                                //SL
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _lang.sl,
                                    textAlign: TextAlign.start,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                                //Quantity
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    locale == 'en' ? 'R.Item' : _lang.returnedItem,
                                    textAlign: TextAlign.center,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                                //Product
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _lang.returnedDate,
                                    textAlign: TextAlign.start,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                                //Unit Price
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    _lang.qty,
                                    textAlign: TextAlign.center,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                                //Amount
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    lang.S.of(context).totalPrice,
                                    textAlign: TextAlign.end,
                                    style: _theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                          for (var i = 0; i < (widget.transitionModel.purchaseReturns?.length ?? 0); i++)
                            for (var detailIndex = 0;
                                detailIndex <
                                    (widget.transitionModel.purchaseReturns?[i].purchaseReturnDetails?.length ?? 0);
                                detailIndex++)
                              Padding(
                                padding: const EdgeInsets.only(top: 7),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        (serialNumber++).toString(),
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                        textAlign: TextAlign.start,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        productName(
                                            detailsId: widget.transitionModel.purchaseReturns?[i]
                                                    .purchaseReturnDetails?[detailIndex].purchaseDetailId ??
                                                0),
                                        textAlign: TextAlign.start,
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        DateFormat.yMMMd().format(DateTime.parse(
                                            widget.transitionModel.purchaseReturns?[i].returnDate ??
                                                DateTime.now().toString())),
                                        textAlign: TextAlign.start,
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Text(
                                        widget.transitionModel.purchaseReturns?[i].purchaseReturnDetails?[detailIndex]
                                                .returnQty
                                                .toString() ??
                                            '0',
                                        // '$currency${formatPointNumber(saleDetail.price)}',
                                        textAlign: TextAlign.center,
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$currency ${(widget.transitionModel.purchaseReturns?[i].purchaseReturnDetails?[detailIndex].returnAmount ?? 0)}',
                                        textAlign: TextAlign.end,
                                        style: _theme.textTheme.bodyLarge?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          SizedBox(height: 7),
                          globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                          SizedBox(height: 12),
                        ],
                        //__________Total Return amount______________________
                        if (widget.transitionModel.purchaseReturns!.isNotEmpty)
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: '${lang.S.of(context).totalReturnAmount} : ',
                                children: [
                                  TextSpan(
                                    text: '$currency ${getTotalReturndAmount()}',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                            ),
                          ),
                        const SizedBox(height: 5.0),

                        //-------------Total payable--------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).totalPayable} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber(widget.transitionModel.totalAmount ?? 0)}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        //----------------paid-------------------------
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text.rich(
                            TextSpan(
                              text: '${lang.S.of(context).paid} : ',
                              children: [
                                TextSpan(
                                  text:
                                      '$currency ${mainConstant.formatPointNumber(((widget.transitionModel.totalAmount ?? 0) - (widget.transitionModel.dueAmount ?? 0)) + (widget.transitionModel.changeAmount ?? 0))}',
                                ),
                              ],
                            ),
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5.0),

                        //-----------due--------------
                        Visibility(
                          visible: (widget.transitionModel.dueAmount ?? 0) > 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: '${lang.S.of(context).due} : ',
                                children: [
                                  TextSpan(
                                    text:
                                        '$currency ${mainConstant.formatPointNumber(widget.transitionModel.dueAmount ?? 0)}',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                            ),
                          ),
                        ),

                        ///-------------Change Amount---------------
                        Visibility(
                          visible: (widget.transitionModel.changeAmount ?? 0) > 0,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text.rich(
                              TextSpan(
                                text: '${_lang.changeAmount} : ',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text:
                                        '$currency${mainConstant.formatPointNumber(widget.transitionModel.changeAmount ?? 0)}',
                                  ),
                                ],
                              ),
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                            ),
                          ),
                        ),
                        globalDottedLine(borderColor: Colors.black54, height: 2, generatedLine: 60),
                        SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Text(
                              '${_lang.paidVia} :',
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                            ),
                            ...?(widget.transitionModel.transactions?.asMap().entries.map((entry) {
                              final index = entry.key;
                              final item = entry.value;

                              String label;
                              switch (item.transactionType) {
                                case 'cash_payment':
                                  label = 'Cash';
                                  break;

                                case 'cheque_payment':
                                  label = 'Cheque';
                                  break;

                                case 'wallet_payment':
                                  label = 'Wallet';
                                  break;

                                default:
                                  label = item.paymentType?.name ?? 'n/a';
                              }

                              final isLast = index == widget.transitionModel.transactions!.length - 1;
                              final text = isLast ? label : '$label,';

                              return Text(
                                text,
                                style: _theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                                ),
                              );
                            }).toList()),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        if (widget.businessInfo.data?.showNote == 1) ...[
                          Text(
                            '${widget.businessInfo.data?.invoiceNoteLevel ?? ''}: ${widget.businessInfo.data?.invoiceNote ?? ''}',
                            style: _theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                            ),
                          ),
                          SizedBox(height: 8),
                        ],
                        if (widget.businessInfo.data?.showGratitudeMsg == 1)
                          Center(
                            child: Text(
                              widget.businessInfo.data?.gratitudeMessage ?? '',
                              maxLines: 3,
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (widget.businessInfo.data?.showInvoiceScannerLogo == 1)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Center(
                              child: UniversalImage(
                                imagePath: '${APIConfig.domain}${widget.businessInfo.data?.invoiceScannerLogo}',
                                height: 120,
                                width: 120,
                              ),
                            ),
                          ),
                        if (widget.businessInfo.data?.developByLevel != null ||
                            widget.businessInfo.data?.developBy != null)
                          Center(
                            child: Text(
                              '${widget.businessInfo.data?.developByLevel ?? ''} ${widget.businessInfo.data?.developBy ?? ''}',
                              style: _theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: fontSizeForPrinter(widget.businessInfo.data?.invoiceSize),
                              ),
                            ),
                          ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottomNavigationBar: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          if (widget.isFromPurchase ?? false) {
                            int count = 0;
                            Navigator.popUntil(context, (route) {
                              return count++ == 2;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          lang.S.of(context).cancel,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    pro.Consumer<LanguageChangeProvider>(
                      builder: (BuildContext context, LanguageChangeProvider value, Widget? child) {
                        return Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              PrintPurchaseTransactionModel model = PrintPurchaseTransactionModel(
                                  purchaseTransitionModel: widget.transitionModel,
                                  personalInformationModel: widget.businessInfo);
                              await printerData.printPurchaseThermalInvoiceNow(
                                transaction: model,
                                productList: model.purchaseTransitionModel!.details,
                                context: context,
                                invoiceSize: ref.watch(businessInfoProvider).value!.data?.invoiceSize,
                              );
                            },
                            child: Text(
                              lang.S.of(context).print,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
