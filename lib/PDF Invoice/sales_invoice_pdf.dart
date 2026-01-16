import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/PDF%20Invoice/universal_image_widget.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/generated/l10n.dart' as l;
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../Screens/Products/add product/modle/create_product_model.dart';
import '../model/business_info_model.dart';
import 'pdf_common_functions.dart';

class SalesInvoicePdf {
  static Future<void> generateSaleDocument(
      SalesTransactionModel transactions, BusinessInformationModel personalInformation, BuildContext context,
      {bool? share, bool? download, bool? showPreview}) async {
    final pw.Document doc = pw.Document();
    final _lang = l.S.of(context);

    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (transactions.salesReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    ///-------returned_discount_amount
    num productPrice({required num detailsId}) {
      return transactions.salesDetails!.where((element) => element.id == detailsId).first.price ?? 0;
    }

    num returnedDiscountAmount() {
      num totalReturnDiscount = 0;
      if (transactions.salesReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) -
                  ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in transactions.salesDetails!) {
        total += ((element.price ?? 0) *
                PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions) -
            ((element.discount ?? 0) *
                PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions)));
      }

      return total;
    }

    String productName({required num detailsId}) {
      final details =
          transactions.salesDetails?[transactions.salesDetails!.indexWhere((element) => element.id == detailsId)];
      return "${details?.product?.productName}${details?.product?.productType == ProductType.variant.name ? ' [${details?.stock?.batchNo ?? ""}]' : ''}";
    }

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

    final hasWarranty = transactions.salesDetails!.any((e) => e.warrantyInfo?.warrantyDuration != null);
    final hasGuarantee = transactions.salesDetails!.any((e) => e.warrantyInfo?.guaranteeDuration != null);

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
                          child: getLocalizedPdfText(
                            '${_lang.address}: ${personalInformation.data?.address ?? ''}',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            ),
                          ),
                        ),
                      if (personalInformation.data?.meta?.showPhoneNumber == 1)
                        pw.SizedBox(
                          width: 200,
                          child: getLocalizedPdfText(
                            '${_lang.mobile}: ${personalInformation.data?.phoneNumber ?? ''}',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFont(),
                              fontFallback: [englishFont],
                            ),
                          ),
                        ),
                      if (personalInformation.data?.meta?.showEmail == 1)
                        pw.SizedBox(
                          width: 200,
                          child: getLocalizedPdfText(
                              '${_lang.emailText}: ${personalInformation.data?.invoiceEmail ?? ''}',
                              pw.TextStyle(
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
                            child: getLocalizedPdfText(
                                '${personalInformation.data?.vatName ?? _lang.vatNumber}: ${personalInformation.data?.vatNo ?? ''}',
                                pw.TextStyle(
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
                    child: getLocalizedPdfText(
                      _lang.INVOICE,
                      pw.TextStyle(
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
                    if (personalInformation.data?.showNote == 1)
                      pw.Row(children: [
                        pw.SizedBox(
                          width: 60.0,
                          child: getLocalizedPdfText(
                              _lang.remark,
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
                          DateFormat('d MMM, yyyy').format(DateTime.parse(transactions.saleDate ?? '')),
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
                            _lang.time,
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
                          DateFormat('hh:mm a').format(DateTime.parse(transactions.saleDate!)),
                          pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                        ),
                      ),
                    ]),
                    //Sales by
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: getLocalizedPdfText(
                            _lang.sellsBy,
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
              child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
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
            ),
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
                // Main products table
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
                    1: pw.FlexColumnWidth(hasGuarantee && !hasWarranty ? 6 : 3),
                    2: pw.FlexColumnWidth(hasGuarantee && !hasWarranty ? 0 : 2),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    // Table header
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
                        if (hasWarranty)
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.warranty,
                              pw.TextStyle(
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlignment: pw.TextAlign.center,
                            ),
                          ),
                        if (hasGuarantee)
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: getLocalizedPdfText(
                              _lang.guarantee,
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
                            _lang.discount,
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
                    // Table rows for products
                    for (int i = 0; i < transactions.salesDetails!.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                "${transactions.salesDetails!.elementAt(i).product?.productName.toString() ?? ''}${transactions.salesDetails?.elementAt(i).product?.productType == ProductType.variant.name ? ' [${transactions.salesDetails?.elementAt(i).stock?.batchNo ?? ''}]' : ''}",
                                pw.TextStyle(
                                    font: getFontWithLangMatching(
                                        transactions.salesDetails!.elementAt(i).product?.productName.toString() ?? ''),
                                    fontFallback: [englishFont]),
                                textAlignment: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfText(
                              formatPointNumber(PDFCommonFunctions().getProductQuantity(
                                  detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions)),
                              textAlignment: pw.TextAlign.center,
                              pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                            ),
                          ),
                          // Warranty column
                          if (hasWarranty)
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfText(
                                '${transactions.salesDetails![i].warrantyInfo?.warrantyDuration ?? ''} ${transactions.salesDetails![i].warrantyInfo?.warrantyUnit ?? ''}',
                                textAlignment: pw.TextAlign.center,
                                pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                              ),
                            ),
                          // Guaranty column
                          if (hasGuarantee)
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: getLocalizedPdfText(
                                '${transactions.salesDetails![i].warrantyInfo?.guaranteeDuration ?? ''} ${transactions.salesDetails![i].warrantyInfo?.guaranteeUnit ?? ''}',
                                textAlignment: pw.TextAlign.center,
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                ),
                              ),
                            ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfText(
                              formatPointNumber(transactions.salesDetails!.elementAt(i).price ?? 0),
                              textAlignment: pw.TextAlign.center,
                              pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfText(
                              formatPointNumber(transactions.salesDetails!.elementAt(i).discount ?? 0),
                              textAlignment: pw.TextAlign.center,
                              pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfText(
                              formatPointNumber(((transactions.salesDetails![i].price ?? 0) *
                                      (PDFCommonFunctions().getProductQuantity(
                                          detailsId: transactions.salesDetails![i].id ?? 0,
                                          transactions: transactions)) -
                                  ((transactions.salesDetails![i].discount ?? 0) *
                                      (PDFCommonFunctions().getProductQuantity(
                                          detailsId: transactions.salesDetails![i].id ?? 0,
                                          transactions: transactions))))),
                              textAlignment: pw.TextAlign.right,
                              pw.TextStyle(font: getFont(), fontFallback: [englishFont]),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                // Two-column layout: Amount summary on right, Payment info on left (when no returns)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left column - Payment information (ONLY when NO returns)
                    if (transactions.salesReturns != null || transactions.salesReturns!.isNotEmpty) pw.SizedBox(),
                    if (transactions.salesReturns == null || transactions.salesReturns!.isEmpty)
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.SizedBox(height: 22),
                            // Amount in words
                            pw.SizedBox(
                              width: 350,
                              child: getLocalizedPdfText(
                                PDFCommonFunctions().numberToWords(transactions.totalAmount ?? 0),
                                pw.TextStyle(
                                  color: PdfColors.black,
                                  fontBold: englishBold,
                                  font: getFont(bold: true),
                                  fontFallback: [englishFont],
                                ),
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

                                  return getLocalizedPdfText(
                                    text,
                                    pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(),
                                      fontFallback: [englishFont],
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
                            // Bank details - FIXED: Check if transactions list is not empty

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
                                        _lang.bankDetails,
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
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                _lang.name,
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                ': ${latestBankTransaction.paymentType?.name ?? ''}',
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                            ],
                                          ),
                                          pw.SizedBox(height: 4),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                _lang.accountNumber,
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.accountNumber ?? ''}',
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                            ],
                                          ),
                                          pw.SizedBox(height: 4),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                _lang.ifscCode,
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.ifscCode ?? ''}',
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                            ],
                                          ),
                                          pw.SizedBox(height: 4),
                                          pw.Row(
                                            children: [
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                _lang.holderName,
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                              pw.Expanded(
                                                  child: getLocalizedPdfText(
                                                ': ${latestBankTransaction.paymentType?.paymentTypeMeta?.holderName ?? ''}',
                                                pw.TextStyle(
                                                  color: PdfColors.black,
                                                  font: getFont(),
                                                  fontFallback: [englishFont],
                                                ),
                                              )),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            pw.SizedBox(height: 12),
                            if (latestBankTransaction != null)
                              if (!personalInformation.data!.gratitudeMessage.isEmptyOrNull)
                                pw.Container(
                                  width: double.infinity,
                                  padding: const pw.EdgeInsets.only(bottom: 8.0),
                                  child: pw.Center(
                                      child: pw.Text(
                                    personalInformation.data!.gratitudeMessage ?? '',
                                  )),
                                ),
                          ],
                        ),
                      ),

                    // Right column - Amount calculation (ALWAYS shows)
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 10.0),
                        getLocalizedPdfText(
                            "${_lang.subTotal}: ${formatPointNumber(getTotalForOldInvoice())}",
                            pw.TextStyle(
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                            )),
                        pw.SizedBox(height: 5.0),
                        pw.Container(
                          width: 100,
                          padding: pw.EdgeInsets.only(bottom: 5),
                          alignment: pw.AlignmentDirectional.centerEnd,
                          decoration: pw.BoxDecoration(
                            border: pw.Border(
                                bottom: pw.BorderSide(
                              color: PdfColors.black,
                            )),
                          ),
                          child: getLocalizedPdfText(
                              "${_lang.discount}: ${formatPointNumber((transactions.discountAmount ?? 0) + returnedDiscountAmount())}",
                              pw.TextStyle(
                                color: PdfColors.black,
                                fontWeight: pw.FontWeight.bold,
                                font: getFont(bold: true),
                                fontFallback: [englishFont],
                              )),
                        ),
                        pw.SizedBox(height: 5.0),
                        getLocalizedPdfText(
                            "${transactions.vat?.name ?? _lang.vat}: ${formatPointNumber(transactions.vatAmount ?? 0.00)}",
                            pw.TextStyle(
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                            )),
                        pw.SizedBox(height: 5.0),
                        getLocalizedPdfText(
                            "${_lang.shippingCharge}: ${formatPointNumber((transactions.shippingCharge ?? 0))}",
                            pw.TextStyle(
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                            )),
                        pw.SizedBox(height: 5.0),
                        // Rounded amount
                        if (transactions.roundingAmount != 0)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              getLocalizedPdfText(
                                  "${_lang.amount}: ${formatPointNumber((transactions.actualTotalAmount ?? 0))}",
                                  pw.TextStyle(
                                    color: PdfColors.black,
                                    fontWeight: pw.FontWeight.bold,
                                    font: getFont(bold: true),
                                    fontFallback: [englishFont],
                                  )),
                              pw.SizedBox(height: 5.0),
                              getLocalizedPdfText(
                                  "${_lang.rounding}: ${!(transactions.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber((transactions.roundingAmount ?? 0))}",
                                  pw.TextStyle(
                                    color: PdfColors.black,
                                    fontWeight: pw.FontWeight.bold,
                                    font: getFont(bold: true),
                                    fontFallback: [englishFont],
                                  )),
                              pw.SizedBox(height: 5.0),
                            ],
                          ),
                        getLocalizedPdfText(
                            "${_lang.totalAmount}: ${formatPointNumber((transactions.totalAmount ?? 0) + getTotalReturndAmount())}",
                            pw.TextStyle(
                              color: PdfColors.black,
                              fontWeight: pw.FontWeight.bold,
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                            )),
                        // Payment summary for non-return invoices
                        if (transactions.salesReturns == null || transactions.salesReturns!.isEmpty)
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.end,
                            children: [
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.SizedBox(height: 5.0),
                                  getLocalizedPdfText(
                                    "${_lang.payableAmount}: ${formatPointNumber(transactions.totalAmount ?? 0)}",
                                    pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(bold: true),
                                      fontFallback: [englishFont],
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  getLocalizedPdfText(
                                    "${_lang.receivedAmount}: ${formatPointNumber(((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0)) + (transactions.changeAmount ?? 0))}",
                                    pw.TextStyle(
                                      color: PdfColors.black,
                                      font: getFont(bold: true),
                                      fontFallback: [englishFont],
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  getLocalizedPdfText(
                                    (transactions.dueAmount ?? 0) > 0
                                        ? "${_lang.due}: ${formatPointNumber(transactions.dueAmount ?? 0)}"
                                        : (transactions.changeAmount ?? 0) > 0
                                            ? "${_lang.changeAmount}: ${formatPointNumber(transactions.changeAmount ?? 0)}"
                                            : '',
                                    pw.TextStyle(
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
                      ],
                    ),
                  ],
                ),

                // Returns table - Only show if there are returns
                if (transactions.salesReturns != null && transactions.salesReturns!.isNotEmpty)
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 20),
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
                          // Table header for returns
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
                          // Data rows for returns
                          for (int i = 0; i < (transactions.salesReturns?.length ?? 0); i++)
                            for (int j = 0; j < (transactions.salesReturns?[i].salesReturnDetails?.length ?? 0); j++)
                              pw.TableRow(
                                decoration: (transactions.salesReturns?.length ?? 0) > 0 && i % 2 == 0
                                    ? const pw.BoxDecoration(color: PdfColors.white)
                                    : const pw.BoxDecoration(color: PdfColors.red50),
                                children: [
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: getLocalizedPdfText(
                                      '${(i * (transactions.salesReturns?[i].salesReturnDetails?.length ?? 0)) + j + 1}',
                                      pw.TextStyle(
                                        color: PdfColors.black,
                                        font: getFont(),
                                        fontFallback: [englishFont],
                                      ),
                                      textAlignment: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: getLocalizedPdfText(
                                      DateFormat.yMMMd()
                                          .format(DateTime.parse(transactions.salesReturns?[i].returnDate ?? '0')),
                                      pw.TextStyle(
                                        color: PdfColors.black,
                                        font: getFont(),
                                        fontFallback: [englishFont],
                                      ),
                                      textAlignment: pw.TextAlign.left,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: getLocalizedPdfTextWithLanguage(
                                      productName(
                                          detailsId:
                                              transactions.salesReturns?[i].salesReturnDetails?[j].saleDetailId ?? 0),
                                      pw.TextStyle(
                                        color: PdfColors.black,
                                        font: getFontWithLangMatching(productName(
                                            detailsId:
                                                transactions.salesReturns?[i].salesReturnDetails?[j].saleDetailId ??
                                                    0)),
                                        fontFallback: [englishFont],
                                      ),
                                      textAlignment: pw.TextAlign.left,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: getLocalizedPdfText(
                                      formatPointNumber(
                                          transactions.salesReturns?[i].salesReturnDetails?[j].returnQty ?? 0),
                                      pw.TextStyle(
                                        color: PdfColors.black,
                                        font: getFont(),
                                        fontFallback: [englishFont],
                                      ),
                                      textAlignment: pw.TextAlign.center,
                                    ),
                                  ),
                                  pw.Padding(
                                    padding: const pw.EdgeInsets.all(8.0),
                                    child: getLocalizedPdfText(
                                      formatPointNumber(
                                          transactions.salesReturns?[i].salesReturnDetails?[j].returnAmount ?? 0),
                                      pw.TextStyle(
                                        color: PdfColors.black,
                                        font: getFont(),
                                        fontFallback: [englishFont],
                                      ),
                                      textAlignment: pw.TextAlign.right,
                                    ),
                                  ),
                                ],
                              ),
                        ],
                      ),

                      // Payment information below returns table (ONLY when there ARE returns)
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

                                      return getLocalizedPdfText(
                                        text,
                                        pw.TextStyle(
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
                                // Bank details - FIXED: Check if transactions list is not empty

                                if (transactions.transactions != null &&
                                    transactions.transactions!.isNotEmpty &&
                                    transactions.transactions!.any((t) => t.transactionType == 'bank_payment'))
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
                                          child: getLocalizedPdfText(
                                            _lang.bankDetails,
                                            pw.TextStyle(
                                              color: PdfColors.black,
                                              font: getFont(),
                                              fontFallback: [englishFont],
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
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    _lang.name,
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                  pw.Expanded(
                                                      child: pw.Text(
                                                          ': ${latestBankTransaction?.paymentType?.paymentTypeMeta?.bankName ?? ''}')),
                                                ],
                                              ),
                                              pw.Row(
                                                children: [
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    _lang.accountNumber,
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    ': ${latestBankTransaction?.paymentType?.paymentTypeMeta?.accountNumber ?? ''}',
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                ],
                                              ),
                                              pw.Row(
                                                children: [
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    _lang.ifscCode,
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    ': ${latestBankTransaction?.paymentType?.paymentTypeMeta?.ifscCode ?? ''}',
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                ],
                                              ),
                                              pw.Row(
                                                children: [
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    _lang.holderName,
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
                                                  pw.Expanded(
                                                      child: getLocalizedPdfText(
                                                    ': ${latestBankTransaction?.paymentType?.paymentTypeMeta?.holderName ?? ''}',
                                                    pw.TextStyle(
                                                      color: PdfColors.black,
                                                      font: getFont(),
                                                      fontFallback: [englishFont],
                                                    ),
                                                  )),
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
              ],
            ),
          ),
        ],
      ),
    );

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
        isShare: share,
        download: download,
      );
    }
  }
}

class SalesInvoiceExcel {
  static Future<void> generateSaleDocument(
      SalesTransactionModel transactions, BusinessInformationModel personalInformation, BuildContext context,
      {bool? share, bool? download}) async {
    final _lang = l.S.of(context);
    final hasWarranty = transactions.salesDetails!.any((e) => e.warrantyInfo?.warrantyDuration != null);
    final hasGuarantee = transactions.salesDetails!.any((e) => e.warrantyInfo?.guaranteeDuration != null);
    num getTotalReturndAmount() {
      num totalReturn = 0;
      if (transactions.salesReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturn += details.returnAmount ?? 0;
            }
          }
        }
      }
      return totalReturn;
    }

    num productPrice({required num detailsId}) {
      return transactions.salesDetails!.where((element) => element.id == detailsId).first.price ?? 0;
    }

    num returnedDiscountAmount() {
      num totalReturnDiscount = 0;
      if (transactions.salesReturns?.isNotEmpty ?? false) {
        for (var returns in transactions.salesReturns!) {
          if (returns.salesReturnDetails?.isNotEmpty ?? false) {
            for (var details in returns.salesReturnDetails!) {
              totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) -
                  ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    // num getTotalForOldInvoice() {
    //   num total = 0;
    //   for (var element in transactions.salesDetails!) {
    //     total += (element.price ?? 0) * PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions);
    //   }
    //   return total;
    // }
    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in transactions.salesDetails!) {
        total += ((element.price ?? 0) *
                PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions) -
            ((element.discount ?? 0) *
                PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions)));
      }

      return total;
    }

    String productName({required num detailsId}) {
      return transactions
              .salesDetails?[transactions.salesDetails!.indexWhere(
            (element) => element.id == detailsId,
          )]
              .product
              ?.productName ??
          '';
    }

    // Create Excel document
    final excel = Excel.createExcel();
    final sheet = excel['Sales Invoice'];

    // Add header information
    if (personalInformation.data?.meta?.showCompanyName == 1) {
      sheet.appendRow([
        TextCellValue('Company: ${personalInformation.data?.companyName ?? ''}'),
      ]);
    }
    if (personalInformation.data?.meta?.showPhoneNumber == 1) {
      sheet.appendRow([
        TextCellValue('Mobile: ${personalInformation.data?.phoneNumber ?? ''}'),
      ]);
    }
    sheet.appendRow([
      TextCellValue('Invoice: #${transactions.invoiceNumber}'),
    ]);
    sheet.appendRow([
      TextCellValue('Date: ${DateFormat('d MMM, yyyy').format(DateTime.parse(transactions.saleDate ?? ''))}'),
    ]);
    sheet.appendRow([]);

    // Add customer information
    sheet.appendRow([
      TextCellValue('Bill To: ${transactions.party?.name ?? ''}'),
    ]);
    sheet.appendRow([
      TextCellValue('Mobile: ${transactions.party?.phone ?? (transactions.meta?.customerPhone ?? _lang.guest)}'),
    ]);
    sheet.appendRow([]);

    // Add sales details header
    sheet.appendRow([
      TextCellValue(_lang.sl),
      TextCellValue(_lang.item),
      if (hasWarranty) TextCellValue('Warranty'),
      if (hasGuarantee) TextCellValue('Guaranty'),
      TextCellValue(_lang.quantity),
      TextCellValue(_lang.unitPrice),
      TextCellValue(_lang.discount),
      TextCellValue(_lang.totalPrice),
    ]);

    // Add sales details
    for (int i = 0; i < transactions.salesDetails!.length; i++) {
      sheet.appendRow([
        TextCellValue('${i + 1}'),
        TextCellValue(transactions.salesDetails![i].product?.productName ?? ''),
        if (hasWarranty)
          TextCellValue(
              '${transactions.salesDetails![i].warrantyInfo?.warrantyDuration ?? ''} ${transactions.salesDetails![i].warrantyInfo?.warrantyUnit ?? ''}'),
        if (hasGuarantee)
          TextCellValue(
              '${transactions.salesDetails![i].warrantyInfo?.guaranteeDuration ?? ''} ${transactions.salesDetails![i].warrantyInfo?.guaranteeUnit ?? ''}'),
        TextCellValue(formatPointNumber(PDFCommonFunctions()
            .getProductQuantity(detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions))),
        TextCellValue(formatPointNumber(transactions.salesDetails![i].price ?? 0)),
        TextCellValue(formatPointNumber(transactions.salesDetails![i].discount ?? 0)),
        TextCellValue(
          formatPointNumber(((transactions.salesDetails![i].price ?? 0) *
                  (PDFCommonFunctions().getProductQuantity(
                      detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions))) -
              (transactions.salesDetails![i].discount ?? 0) *
                  (PDFCommonFunctions().getProductQuantity(
                      detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions))),
        )
      ]);
    }

    sheet.appendRow([]);

    // Add totals
    sheet.appendRow([
      TextCellValue('${_lang.subTotal}:'),
      TextCellValue(formatPointNumber(getTotalForOldInvoice())),
    ]);
    sheet.appendRow([
      TextCellValue('${_lang.discount}:'),
      TextCellValue(formatPointNumber((transactions.discountAmount ?? 0) + returnedDiscountAmount())),
    ]);
    sheet.appendRow([
      TextCellValue('${transactions.vat?.name ?? _lang.vat}:'),
      TextCellValue(formatPointNumber(transactions.vatAmount ?? 0.00)),
    ]);
    sheet.appendRow([
      TextCellValue('${_lang.shippingCharge}:'),
      TextCellValue(formatPointNumber((transactions.shippingCharge ?? 0))),
    ]);

    if (transactions.roundingAmount != 0) {
      sheet.appendRow([
        TextCellValue('${_lang.amount}:'),
        TextCellValue(formatPointNumber((transactions.actualTotalAmount ?? 0))),
      ]);
      sheet.appendRow([
        TextCellValue('${_lang.rounding}:'),
        TextCellValue(
            '${!(transactions.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber((transactions.roundingAmount ?? 0))}'),
      ]);
    }

    sheet.appendRow([
      TextCellValue('${_lang.totalAmount}:'),
      TextCellValue(formatPointNumber((transactions.totalAmount ?? 0) + getTotalReturndAmount())),
    ]);
    sheet.appendRow([]);

    // Add returns if any
    if (transactions.salesReturns != null && transactions.salesReturns!.isNotEmpty) {
      sheet.appendRow([
        TextCellValue(_lang.sl),
        TextCellValue(_lang.date),
        TextCellValue(_lang.returnedItem),
        TextCellValue(_lang.quantity),
        TextCellValue(_lang.totalReturned),
      ]);

      int returnIndex = 1;
      for (int i = 0; i < transactions.salesReturns!.length; i++) {
        for (int j = 0; j < (transactions.salesReturns![i].salesReturnDetails?.length ?? 0); j++) {
          sheet.appendRow([
            TextCellValue('${returnIndex++}'),
            TextCellValue(DateFormat.yMMMd().format(DateTime.parse(transactions.salesReturns![i].returnDate ?? '0'))),
            TextCellValue(
                productName(detailsId: transactions.salesReturns![i].salesReturnDetails?[j].saleDetailId ?? 0)),
            TextCellValue(formatPointNumber(transactions.salesReturns![i].salesReturnDetails?[j].returnQty ?? 0)),
            TextCellValue(formatPointNumber(transactions.salesReturns![i].salesReturnDetails?[j].returnAmount ?? 0)),
          ]);
        }
      }

      sheet.appendRow([
        TextCellValue('${_lang.totalReturnAmount}:'),
        TextCellValue(formatPointNumber(getTotalReturndAmount())),
      ]);
      sheet.appendRow([]);
    }

    // Add payment information
    sheet.appendRow([
      TextCellValue('${_lang.paidVia}: ${transactions.paymentType?.name ?? 'N/A'}'),
    ]);
    sheet.appendRow([
      TextCellValue('${_lang.payableAmount}: ${formatPointNumber(transactions.totalAmount ?? 0)}'),
    ]);
    sheet.appendRow([
      TextCellValue(
          '${_lang.receivedAmount}: ${formatPointNumber(((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0)) + (transactions.changeAmount ?? 0))}'),
    ]);

    if ((transactions.dueAmount ?? 0) > 0) {
      sheet.appendRow([
        TextCellValue('${_lang.due}: ${formatPointNumber(transactions.dueAmount ?? 0)}'),
      ]);
    } else if ((transactions.changeAmount ?? 0) > 0) {
      sheet.appendRow([
        TextCellValue('${_lang.changeAmount}: ${formatPointNumber(transactions.changeAmount ?? 0)}'),
      ]);
    }

    sheet.appendRow([
      TextCellValue('${_lang.amountsInWord}: ${PDFCommonFunctions().numberToWords(transactions.totalAmount ?? 0)}'),
    ]);

    if (transactions.meta?.note?.isNotEmpty ?? false) {
      sheet.appendRow([]);
      sheet.appendRow([
        TextCellValue('${_lang.note}: ${(transactions.meta?.note ?? '')}'),
      ]);
    }

    // Save the Excel file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/Sales_Invoice_${transactions.invoiceNumber}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    // Open the Excel file
    await OpenFile.open(filePath);

    // Optionally share or download
    if (share == true) {
      await FilePicker.platform.saveFile(
        fileName: 'Sales_Invoice_${transactions.invoiceNumber}.xlsx',
        // bytes: excel.encode(),
      );
    }
  }
}
