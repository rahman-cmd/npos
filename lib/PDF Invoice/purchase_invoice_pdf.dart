import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/PDF%20Invoice/universal_image_widget.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;
import 'package:nb_utils/nb_utils.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../Screens/Products/add product/add_product.dart';
import '../Screens/Products/add product/modle/create_product_model.dart';
import '../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../model/business_info_model.dart';
import 'pdf_common_functions.dart';

class PurchaseInvoicePDF {
  static Future<void> generatePurchaseDocument(
      PurchaseTransaction transactions, BusinessInformationModel personalInformation, BuildContext context,
      {bool? isShare, bool? download, bool? showPreview}) async {
    final pw.Document doc = pw.Document();

    final _lang = l.S.of(context);

    String productName({required num detailsId}) {
      final details = transactions.details?[transactions.details!.indexWhere((element) => element.id == detailsId)];
      return "${details?.product?.productName}${details?.product?.productType == ProductType.variant.name ? ' [${details?.stock?.batchNo ?? ''}]' : ''}" ??
          '';
    }

    num productPrice({required num detailsId}) {
      return transactions.details!.where((element) => element.id == detailsId).first.productPurchasePrice ?? 0;
    }

    num getReturndDiscountAmount() {
      num totalReturnDiscount = 0;
      if (transactions.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.purchaseReturns!) {
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

    num getProductQuantity({required num detailsId}) {
      num totalQuantity = transactions.details?.where((element) => element.id == detailsId).first.quantities ?? 0;
      if (transactions.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.purchaseReturns!) {
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

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (transactions.purchaseReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.purchaseReturns!) {
          if (returns.purchaseReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.purchaseReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in transactions.details!) {
        num productPrice = element.productPurchasePrice ?? 0;
        num productQuantity = getProductQuantity(detailsId: element.id ?? 0);

        total += productPrice * productQuantity;
      }

      return total;
    }

    EasyLoading.show(status: _lang.generatingPdf);

    final String imageUrl =
        '${APIConfig.domain}${(personalInformation.data?.showA4InvoiceLogo == 1) ? personalInformation.data?.a4InvoiceLogo : ''}';
    dynamic imageData = await PDFCommonFunctions().getNetworkImage(imageUrl);
    imageData ??= (personalInformation.data?.showA4InvoiceLogo == 1)
        ? await PDFCommonFunctions().loadAssetImage('images/logo.png')
        : null;
    final englishFont = pw.Font.ttf(await rootBundle.load('fonts/NotoSans/NotoSans-Regular.ttf'));
    final englishBold = pw.Font.ttf(await rootBundle.load('fonts/NotoSans/NotoSans-Medium.ttf'));
    final banglaFont = pw.Font.ttf(await rootBundle.load('assets/fonts/siyam_rupali_ansi.ttf'));
    final arabicFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf'));
    final hindiFont = pw.Font.ttf(await rootBundle.load('assets/fonts/Hind-Regular.ttf'));
    final frenchFont = pw.Font.ttf(await rootBundle.load('assets/fonts/GFSDidot-Regular.ttf'));

    // Helper function
    pw.Font getFont({bool bold = false}) {
      switch (selectedLanguage) {
        case 'en':
          return bold ? englishBold : englishFont;
        case 'bn':
          // Bold not available, fallback to regular
          return banglaFont;
        case 'ar':
          return arabicFont;
        case 'hi':
          return hindiFont;
        case 'fr':
          return frenchFont;
        default:
          return bold ? englishBold : englishFont;
      }
    }

    getFontWithLangMatching(String data) {
      String detectedLanguage = detectLanguageEnhanced(data);
      if (detectedLanguage == 'en') {
        return englishFont;
      } else if (detectedLanguage == 'bn') {
        return banglaFont;
      } else if (detectedLanguage == 'ar') {
        return arabicFont;
      } else if (detectedLanguage == 'hi') {
        return hindiFont;
      } else if (detectedLanguage == 'fr') {
        return frenchFont;
      } else {
        return englishFont;
      }
    }

    final bankTransactions =
        transactions.transactions?.where((t) => t.transactionType == 'bank_payment').toList() ?? [];

    final latestBankTransaction = bankTransactions.isNotEmpty ? bankTransactions.last : null;

    final showWarranty = personalInformation.data?.showWarranty == 1 &&
        (personalInformation.data?.warrantyVoidLabel != null || personalInformation.data?.warrantyVoid != null);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.zero,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        header: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20.0),
            child: pw.Column(
              children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Container(
                    height: 54.12,
                    width: 200,
                    child: universalImage(
                      imageData,
                      w: 200,
                      h: 54.12,
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (personalInformation.data?.meta?.showAddress == 1)
                        pw.SizedBox(
                          width: 200,
                          child: pw.Text(
                            '${_lang.address}: ${personalInformation.data?.address ?? ''}',
                            textAlign: pw.TextAlign.end,
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            ),
                          ),
                        ),
                      if (personalInformation.data?.meta?.showPhoneNumber == 1)
                        pw.SizedBox(
                          width: 200,
                          child: pw.Text(
                            '${_lang.mobile}: ${personalInformation.data?.phoneNumber ?? ''}',
                            textAlign: pw.TextAlign.end,
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            ),
                          ),
                        ),
                      if (personalInformation.data?.meta?.showEmail == 1)
                        pw.SizedBox(
                          width: 200,
                          child: pw.Text('${_lang.emailText}: ${personalInformation.data?.invoiceEmail ?? ''}',
                              textAlign: pw.TextAlign.end,
                              style: pw.TextStyle(
                                color: PdfColors.black,
                                font: getFont(),
                                fontFallback: [englishFont],
                              )),
                        ),
                      //vat Name
                      if (personalInformation.data?.meta?.showVat == 1)
                        if (personalInformation.data?.vatNo != null && personalInformation.data?.meta?.showVat == 1)
                          pw.SizedBox(
                            width: 200,
                            child: pw.Text(
                                '${personalInformation.data?.vatName ?? _lang.vatNumber}: ${personalInformation.data?.vatNo ?? ''}',
                                textAlign: pw.TextAlign.end,
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                    ],
                  ),
                ]),
                pw.SizedBox(height: 16.0),
                pw.Center(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 19, vertical: 10),
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(20),
                      border: pw.Border.all(color: PdfColors.black),
                    ),
                    child: pw.Text(
                      _lang.INVOICE,
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 18,
                        color: PdfColors.black,
                        font: getFont(bold: true),
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    //customer name
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 60.0,
                        child: getLocalizedPdfText(
                            _lang.customer,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfTextWithLanguage(
                            transactions.party?.name ?? '',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFontWithLangMatching(transactions.party?.name ?? ''),
                              fontFallback: [englishFont],
                            )),
                      ),
                    ]),
                    //Address
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 60.0,
                        child: getLocalizedPdfText(
                            _lang.address,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 150.0,
                        child: getLocalizedPdfTextWithLanguage(
                            transactions.party?.address ?? 'N/a',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFontWithLangMatching(transactions.party?.address ?? ''),
                              fontFallback: [englishFont],
                            )),
                      ),
                    ]),
                    //mobile
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 60.0,
                        child: getLocalizedPdfText(
                            _lang.mobile,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            transactions.party?.phone ?? (transactions.party?.phone ?? _lang.guest),
                            pw.TextStyle(font: getFont(), fontFallback: [englishFont])),
                      ),
                    ]),
                    //Remarks
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 60.0,
                        child: getLocalizedPdfText(
                            'Remark',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(personalInformation.data?.invoiceNote ?? 'N/A',
                            pw.TextStyle(font: getFont(), fontFallback: [englishFont])),
                      ),
                    ]),
                  ]),
                  pw.Column(children: [
                    //Invoice Number
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            _lang.invoiceNumber,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 75.0,
                        child: pw.Text(
                          '#${transactions.invoiceNumber}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    //date
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            _lang.date,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 75.0,
                        child: getLocalizedPdfText(
                          DateFormat('d MMM, yyyy').format(DateTime.parse(transactions.purchaseDate ?? '')),
                          // DateTimeFormat.format(DateTime.parse(transactions.saleDate ?? ''), format: 'D, M j'),
                          pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                        ),
                      ),
                    ]),
                    //Time
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            'Time',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 75.0,
                        child: getLocalizedPdfText(
                          DateFormat('hh:mm a').format(DateTime.parse(transactions.purchaseDate!)),
                          pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                        ),
                      ),
                    ]),
                    //Sales by
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            _lang.purchasedBy,
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            )),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 75.0,
                        child: getLocalizedPdfTextWithLanguage(
                            transactions.user?.role == "shop-owner" ? _lang.admin : transactions.user?.name ?? '',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFontWithLangMatching(transactions.user?.role == "shop-owner"
                                  ? _lang.admin
                                  : transactions.user?.name ?? ''),
                              fontFallback: [englishFont],
                            )),
                      ),
                    ]),
                  ]),
                ]),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Column(children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Column(children: [
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    child: pw.Column(children: [
                      pw.Container(
                        width: 120.0,
                        height: 2.0,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4.0),
                      getLocalizedPdfText(
                          _lang.customerSignature,
                          pw.TextStyle(
                            color: PdfColors.black,
                            font: getFont(),
                            fontFallback: [englishFont],
                          ))
                    ]),
                  ),
                  pw.Container(
                    alignment: pw.Alignment.centerRight,
                    margin: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    padding: const pw.EdgeInsets.only(bottom: 3.0 * PdfPageFormat.mm),
                    child: pw.Column(children: [
                      pw.Container(
                        width: 120.0,
                        height: 2.0,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4.0),
                      getLocalizedPdfText(
                          _lang.authorizedSignature,
                          pw.TextStyle(
                            color: PdfColors.black,
                            font: getFont(),
                            fontFallback: [englishFont],
                          ))
                    ]),
                  ),
                ]),
                pw.SizedBox(height: 5),
                if (showWarranty)
                  pw.Padding(
                    padding: pw.EdgeInsets.symmetric(horizontal: 10),
                    child: pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.black),
                      ),
                      child: pw.RichText(
                        text: pw.TextSpan(
                          children: [
                            if (personalInformation.data?.warrantyVoidLabel != null)
                              pw.TextSpan(
                                text: '${personalInformation.data!.warrantyVoidLabel!}- ',
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  font: getFont(bold: true),
                                  fontFallback: [englishFont],
                                ),
                              ),
                            if (personalInformation.data?.warrantyVoid != null)
                              pw.TextSpan(
                                text: personalInformation.data!.warrantyVoid!,
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ]),
            ),
            pw.SizedBox(height: 10),
            pw.Padding(
              padding: pw.EdgeInsets.symmetric(horizontal: 10),
              child: pw.Center(
                child: pw.Text(
                  '${personalInformation.data?.developByLevel ?? ''} ${personalInformation.data?.developBy ?? ''}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ),
            ),
          ]);
        },
        build: (pw.Context context) => <pw.Widget>[
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
            child: pw.Column(
              children: [
                pw.Table(
                    border: pw.TableBorder(
                      horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      top: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      bottom: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                    ),
                    columnWidths: <int, pw.TableColumnWidth>{
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(6),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // pw.TableRow(
                      //   children: [
                      //     pw.Container(
                      //       decoration: const pw.BoxDecoration(
                      //         color: PdfColor.fromInt(0xffC52127),
                      //       ), // Red background
                      //       padding: const pw.EdgeInsets.all(8.0),
                      //       child: getLocalizedPdfText(
                      //         _lang.sl,
                      //         pw.TextStyle(
                      //           color: PdfColors.white,
                      //           font: getFont(),
                      //           fontFallback: [englishFont],
                      //         ),
                      //         textAlignment: pw.TextAlign.center,
                      //       ),
                      //     ),
                      //     pw.Container(
                      //       color: const PdfColor.fromInt(0xffC52127), // Red background
                      //       padding: const pw.EdgeInsets.all(8.0),
                      //       child: getLocalizedPdfText(
                      //         _lang.item,
                      //         pw.TextStyle(
                      //           color: PdfColors.white,
                      //           font: getFont(),
                      //           fontFallback: [englishFont],
                      //         ),
                      //         textAlignment: pw.TextAlign.left,
                      //       ),
                      //     ),
                      //     pw.Container(
                      //       color: const PdfColor.fromInt(0xff000000), // Black background
                      //       padding: const pw.EdgeInsets.all(8.0),
                      //       child: getLocalizedPdfText(
                      //         _lang.quantity,
                      //         pw.TextStyle(
                      //           color: PdfColors.white,
                      //           font: getFont(),
                      //           fontFallback: [englishFont],
                      //         ),
                      //         textAlignment: pw.TextAlign.center,
                      //       ),
                      //     ),
                      //     pw.Container(
                      //       color: const PdfColor.fromInt(0xff000000), // Black background
                      //       padding: const pw.EdgeInsets.all(8.0),
                      //       child: getLocalizedPdfText(
                      //         _lang.unitPrice,
                      //         pw.TextStyle(
                      //           color: PdfColors.white,
                      //           font: getFont(),
                      //           fontFallback: [englishFont],
                      //         ),
                      //         textAlignment: pw.TextAlign.right,
                      //       ),
                      //     ),
                      //     pw.Container(
                      //       color: const PdfColor.fromInt(0xff000000), // Black background
                      //       padding: const pw.EdgeInsets.all(8.0),
                      //       child: getLocalizedPdfText(
                      //         _lang.totalPrice,
                      //         pw.TextStyle(
                      //           color: PdfColors.white,
                      //           font: getFont(),
                      //           fontFallback: [englishFont],
                      //         ),
                      //         textAlignment: pw.TextAlign.right,
                      //       ),
                      //     ),
                      //   ],
                      // ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.sl,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                              textAlignment: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.item,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlignment: pw.TextAlign.left,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.quantity,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlignment: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.unitPrice,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlignment: pw.TextAlign.right,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.totalPrice,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlignment: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                      for (int i = 0; i < transactions.details!.length; i++)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfTextWithLanguage(
                                  "${transactions.details!.elementAt(i).product?.productName.toString()}${transactions.details!.elementAt(i).product?.productType == ProductType.variant.name ? ' [${transactions.details!.elementAt(i).stock?.batchNo ?? ''}]' : ''}",
                                  pw.TextStyle(
                                      font: getFontWithLangMatching(
                                          transactions.details!.elementAt(i).product?.productName.toString() ?? ''),
                                      fontFallback: [englishFont]),
                                  textAlignment: pw.TextAlign.left),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfText(
                                (getProductQuantity(detailsId: transactions.details!.elementAt(i).id ?? 0)).toString(),
                                textAlignment: pw.TextAlign.center,
                                pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfText(
                                formatPointNumber(transactions.details!.elementAt(i).productPurchasePrice ?? 0),
                                textAlignment: pw.TextAlign.right,
                                pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfText(
                                ((transactions.details!.elementAt(i).productPurchasePrice ?? 0) *
                                        getProductQuantity(detailsId: transactions.details!.elementAt(i).id ?? 0))
                                    .toStringAsFixed(2),
                                textAlignment: pw.TextAlign.right,
                                pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                              ),
                            ),
                          ],
                        ),
                    ]),
                pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left column - Payment information (ONLY when NO returns)
                      if (transactions.purchaseReturns != null || transactions.purchaseReturns!.isNotEmpty)
                        pw.SizedBox(),
                      if (transactions.purchaseReturns == null || transactions.purchaseReturns!.isEmpty)
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(height: 22),
                              // Amount in words
                              pw.SizedBox(
                                width: 350,
                                child: pw.Text(
                                  PDFCommonFunctions().numberToWords(transactions.totalAmount ?? 0),
                                  style: pw.TextStyle(
                                    color: PdfColors.black,
                                    font: getFont(bold: true),
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                  maxLines: 3,
                                ),
                              ),
                              pw.SizedBox(height: 18),
                              // Paid via
                              pw.Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  pw.Text('${_lang.paidVia} :'),
                                  ...?transactions.transactions?.asMap().entries.map((entry) {
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

                                    final isLast = index == transactions.transactions!.length - 1;
                                    final text = isLast ? label : '$label,';

                                    return pw.Text(
                                      text,
                                      style: pw.TextStyle(
                                        font: getFont(bold: true),
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    );
                                  }),
                                ],
                              ),
                              pw.SizedBox(height: 12),
                              if ((!personalInformation.data!.invoiceNote.isEmptyOrNull ||
                                      !personalInformation.data!.invoiceNoteLevel.isEmptyOrNull) &&
                                  personalInformation.data!.showNote == 1)
                                pw.RichText(
                                    text: pw.TextSpan(
                                        text: '${personalInformation.data?.invoiceNoteLevel ?? ''}: ',
                                        style: pw.TextStyle(
                                          font: getFont(bold: true),
                                        ),
                                        children: [
                                      pw.TextSpan(
                                          text: personalInformation.data?.invoiceNote ?? '',
                                          style: pw.TextStyle(
                                            font: getFont(bold: true),
                                          ))
                                    ])),

                              pw.SizedBox(height: 12),

                              if (latestBankTransaction != null)
                                pw.Container(
                                  width: 256,
                                  height: 120,
                                  decoration: pw.BoxDecoration(
                                    border: pw.Border.all(color: PdfColors.black),
                                  ),
                                  child: pw.Column(
                                    children: [
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                        child: pw.Text(
                                          'Bank Details',
                                          style: pw.TextStyle(
                                            fontWeight: pw.FontWeight.bold,
                                            font: getFont(bold: true),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      pw.Divider(color: PdfColors.black, height: 1),
                                      pw.Padding(
                                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        child: pw.Column(
                                          children: [
                                            pw.Row(
                                              children: [
                                                pw.Expanded(child: pw.Text('Name')),
                                                pw.Expanded(
                                                    child:
                                                        pw.Text(': ${latestBankTransaction.paymentType?.name ?? ''}')),
                                              ],
                                            ),
                                            pw.SizedBox(height: 4),
                                            pw.Row(
                                              children: [
                                                pw.Expanded(child: pw.Text('Account No')),
                                                pw.Expanded(
                                                    child: pw.Text(
                                                        ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.accountNumber ?? ''}')),
                                              ],
                                            ),
                                            pw.SizedBox(height: 4),
                                            pw.Row(
                                              children: [
                                                pw.Expanded(child: pw.Text('IFSC Code')),
                                                pw.Expanded(
                                                    child: pw.Text(
                                                        ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.ifscCode ?? ''}')),
                                              ],
                                            ),
                                            pw.SizedBox(height: 4),
                                            pw.Row(
                                              children: [
                                                pw.Expanded(child: pw.Text("Holder's Name")),
                                                pw.Expanded(
                                                    child: pw.Text(
                                                        ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.holderName ?? ''}')),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          mainAxisAlignment: pw.MainAxisAlignment.end,
                          children: [
                            pw.SizedBox(height: 10.0),
                            getLocalizedPdfText(
                              "${_lang.subTotal}: ${getTotalForOldInvoice().toStringAsFixed(2)}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                            ),
                            pw.SizedBox(height: 5.0),
                            getLocalizedPdfText(
                              "${_lang.discount}: ${((transactions.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2)}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                            ),
                            pw.SizedBox(height: 5.0),
                            getLocalizedPdfText(
                              "${transactions.vat?.name ?? _lang.vat}: ${((transactions.vatAmount ?? 0)).toStringAsFixed(2)}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                            ),
                            pw.SizedBox(height: 5.0),
                            getLocalizedPdfText(
                              "${_lang.shippingCharge}: ${((transactions.shippingCharge ?? 0)).toStringAsFixed(2)}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                            ),
                            pw.SizedBox(height: 5.0),
                            getLocalizedPdfText(
                              "${_lang.totalAmount}: ${((transactions.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2)}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              ),
                            ),
                            // Payment summary for non-return invoices
                            if (transactions.purchaseReturns == null || transactions.purchaseReturns!.isEmpty)
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5.0),
                                  pw.Text(
                                    "${_lang.payableAmount}: ${formatPointNumber(transactions.totalAmount ?? 0)}",
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(bold: true),
                                      fontFallback: [englishFont],
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  pw.Text(
                                    "${_lang.paidAmount}: ${formatPointNumber(((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0)) + (transactions.changeAmount ?? 0))}",
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(bold: true),
                                      fontFallback: [englishFont],
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  pw.Text(
                                    (transactions.dueAmount ?? 0) > 0
                                        ? "${_lang.due}: ${formatPointNumber(transactions.dueAmount ?? 0)}"
                                        : (transactions.changeAmount ?? 0) > 0
                                            ? "${_lang.changeAmount}: ${formatPointNumber(transactions.changeAmount ?? 0)}"
                                            : '',
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(bold: true),
                                      fontFallback: [englishFont],
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 10.0),
                                ],
                              ),
                          ]),
                    ]),
                (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty)
                    ? pw.Container(height: 10)
                    : pw.Container(),

                ///-----return_table-----
                (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty)
                    ? pw.Column(children: [
                        pw.Table(
                          border: pw.TableBorder(
                            horizontalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            top: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            bottom: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                          ),
                          columnWidths: <int, pw.TableColumnWidth>{
                            0: const pw.FlexColumnWidth(1),
                            1: const pw.FlexColumnWidth(3),
                            2: const pw.FlexColumnWidth(4),
                            3: const pw.FlexColumnWidth(2),
                            4: const pw.FlexColumnWidth(3),
                          },
                          children: [
                            pw.TableRow(
                              children: [
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: getLocalizedPdfText(
                                    _lang.sl,
                                    pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                      fontFallback: [englishFont],
                                    ),
                                    textAlignment: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: getLocalizedPdfText(
                                    _lang.date,
                                    pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                      fontFallback: [englishFont],
                                    ),
                                    textAlignment: pw.TextAlign.left,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: getLocalizedPdfText(
                                    _lang.returnedItem,
                                    pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                      fontFallback: [englishFont],
                                    ),
                                    textAlignment: pw.TextAlign.left,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: getLocalizedPdfText(
                                    _lang.quantity,
                                    pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                      fontFallback: [englishFont],
                                    ),
                                    textAlignment: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Padding(
                                  padding: const pw.EdgeInsets.all(8),
                                  child: getLocalizedPdfText(
                                    _lang.totalReturned,
                                    pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                      fontFallback: [englishFont],
                                    ),
                                    textAlignment: pw.TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            for (int i = 0; i < (transactions.purchaseReturns?.length ?? 0); i++)
                              for (int j = 0;
                                  j < (transactions.purchaseReturns?[i].purchaseReturnDetails?.length ?? 0);
                                  j++)
                                pw.TableRow(
                                  decoration: PDFCommonFunctions().serialNumber.isOdd
                                      ? const pw.BoxDecoration(
                                          color: PdfColors.white,
                                        ) // Odd row color
                                      : const pw.BoxDecoration(
                                          color: PdfColors.red50,
                                        ),
                                  children: [
                                    //serial number
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: getLocalizedPdfText(
                                        '${PDFCommonFunctions().serialNumber++}',
                                        pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                                        textAlignment: pw.TextAlign.center,
                                      ),
                                    ),
                                    //Date
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: getLocalizedPdfText(
                                        DateFormat.yMMMd().format(DateTime.parse(
                                          transactions.purchaseReturns?[i].returnDate ?? '0',
                                        )),
                                        pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                                        textAlignment: pw.TextAlign.left,
                                      ),
                                    ),
                                    //Total return
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: getLocalizedPdfTextWithLanguage(
                                        productName(
                                            detailsId: transactions
                                                    .purchaseReturns?[i].purchaseReturnDetails?[j].purchaseDetailId ??
                                                0),
                                        pw.TextStyle(
                                            font: getFontWithLangMatching(productName(
                                                detailsId: transactions.purchaseReturns?[i].purchaseReturnDetails?[j]
                                                        .purchaseDetailId ??
                                                    0)),
                                            fontFallback: [englishFont]),
                                        textAlignment: pw.TextAlign.center,
                                      ),
                                    ),
                                    //Quantity
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: getLocalizedPdfText(
                                        transactions.purchaseReturns?[i].purchaseReturnDetails?[j].returnQty
                                                ?.toString() ??
                                            '0',
                                        pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                                        textAlignment: pw.TextAlign.right,
                                      ),
                                    ),
                                    //Total Return
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: getLocalizedPdfText(
                                        transactions.purchaseReturns?[i].purchaseReturnDetails?[j].returnAmount
                                                ?.toStringAsFixed(2) ??
                                            '0',
                                        pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                                        textAlignment: pw.TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ])
                    : pw.SizedBox.shrink(),
                // Payment information below returns table (ONLY when there ARE returns)
                if (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Left column - Payment information (ONLY when there ARE returns)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 22),
                            // Amount in words
                            pw.SizedBox(
                              width: 350,
                              child: pw.Text(
                                PDFCommonFunctions().numberToWords(transactions.totalAmount ?? 0),
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  font: getFont(bold: true),
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                maxLines: 3,
                              ),
                            ),
                            pw.SizedBox(height: 18),
                            // Paid via
                            pw.Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                pw.Text('${_lang.paidVia} :'),
                                ...?transactions.transactions?.asMap().entries.map((entry) {
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

                                  final isLast = index == transactions.transactions!.length - 1;
                                  final text = isLast ? label : '$label,';

                                  return pw.Text(
                                    text,
                                    style: pw.TextStyle(
                                      font: getFont(bold: true),
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  );
                                }),
                              ],
                            ),
                            pw.SizedBox(height: 12),
                            if ((!personalInformation.data!.invoiceNote.isEmptyOrNull ||
                                    !personalInformation.data!.invoiceNoteLevel.isEmptyOrNull) &&
                                personalInformation.data!.showNote == 1)
                              pw.RichText(
                                  text: pw.TextSpan(
                                      text: '${personalInformation.data?.invoiceNoteLevel ?? ''}: ',
                                      style: pw.TextStyle(
                                        font: getFont(bold: true),
                                      ),
                                      children: [
                                    pw.TextSpan(
                                        text: personalInformation.data?.invoiceNote ?? '',
                                        style: pw.TextStyle(
                                          font: getFont(bold: true),
                                        ))
                                  ])),

                            pw.SizedBox(height: 12),

                            if (latestBankTransaction != null)
                              pw.Container(
                                width: 256,
                                height: 120,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black),
                                ),
                                child: pw.Column(
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: pw.Text(
                                        'Bank Details',
                                        style: pw.TextStyle(
                                          font: getFont(bold: true),
                                          fontWeight: pw.FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    pw.Divider(color: PdfColors.black, height: 1),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      child: pw.Column(
                                        children: [
                                          pw.Row(
                                            children: [
                                              pw.Expanded(child: pw.Text('Name')),
                                              pw.Expanded(
                                                  child: pw.Text(
                                                      ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.bankName ?? ''}')),
                                            ],
                                          ),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(child: pw.Text('Account No')),
                                              pw.Expanded(
                                                  child: pw.Text(
                                                      ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.accountNumber ?? ''}')),
                                            ],
                                          ),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(child: pw.Text('IFSC Code')),
                                              pw.Expanded(
                                                  child: pw.Text(
                                                      ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.ifscCode ?? ''}')),
                                            ],
                                          ),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(child: pw.Text("Holder's Name")),
                                              pw.Expanded(
                                                  child: pw.Text(
                                                      ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.holderName ?? ''}')),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Right column - Return amount summary
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.SizedBox(height: 10.0),
                          pw.RichText(
                            text: pw.TextSpan(
                              text: '${_lang.totalReturnAmount}: ',
                              style: pw.TextStyle(
                                color: PdfColors.black,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              children: [
                                pw.TextSpan(
                                  text: formatPointNumber(getTotalReturndAmount()),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 5.0),
                          pw.Text(
                            "${_lang.payableAmount}: ${formatPointNumber(transactions.totalAmount ?? 0)}",
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5.0),
                          pw.Text(
                            "${_lang.receivedAmount}: ${formatPointNumber(((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0)) + (transactions.changeAmount ?? 0))}",
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 5.0),
                          pw.Text(
                            (transactions.dueAmount ?? 0) > 0
                                ? "${_lang.due}: ${formatPointNumber(transactions.dueAmount ?? 0)}"
                                : (transactions.changeAmount ?? 0) > 0
                                    ? "${_lang.changeAmount}: ${formatPointNumber(transactions.changeAmount ?? 0)}"
                                    : '',
                            style: pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 10.0),
                        ],
                      ),
                    ],
                  ),

                pw.SizedBox(height: 20.0),
                if (personalInformation.data?.showGratitudeMsg == 1)
                  if (!personalInformation.data!.gratitudeMessage.isEmptyOrNull)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.only(bottom: 8.0),
                      child: pw.Center(
                          child: pw.Text(
                        personalInformation.data!.gratitudeMessage ?? '',
                      )),
                    ),

                pw.Padding(padding: const pw.EdgeInsets.all(10)),

                pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ],
            ),
          ),
        ],
      ),
    );
    EasyLoading.showSuccess('Pdf Generate Successfully');
    if (showPreview == true) {
      await Printing.layoutPdf(
          name: personalInformation.data?.companyName ?? '',
          usePrinterSettings: true,
          dynamicLayout: true,
          forceCustomPrintPaper: true,
          onLayout: (PdfPageFormat format) async => doc.save());
    } else {
      await PDFCommonFunctions.savePdfAndShowPdf(
        context: context,
        shopName: personalInformation.data?.companyName ?? '',
        invoice: transactions.invoiceNumber ?? '',
        doc: doc,
        isShare: isShare,
        download: download,
      );
    }
  }
}
