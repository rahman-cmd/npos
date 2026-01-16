import 'dart:async';
import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/PDF%20Invoice/universal_image_widget.dart';
import 'package:mobile_pos/Screens/all_transaction/model/transaction_model.dart';
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
import '../model/subscription_report_model.dart';
import 'pdf_common_functions.dart';

class SubscriptionInvoicePdf {
  static Future<void> generateSaleDocument(
      List<SubscriptionReportModel> subscription, BusinessInformationModel personalInformation, BuildContext context,
      {bool? share, bool? download, bool? showPreview}) async {
    final pw.Document doc = pw.Document();
    final _lang = l.S.of(context);

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
                            _lang.billTO,
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
                            personalInformation.data?.user?.name ?? '',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFontWithLangMatching(personalInformation.data?.user?.name ?? ''),
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
                        child: getLocalizedPdfText(personalInformation.data?.phoneNumber ?? 'n/a',
                            pw.TextStyle(font: getFont(), fontFallback: [englishFont])),
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
                            personalInformation.data?.address ?? '',
                            pw.TextStyle(
                              color: PdfColors.black,
                              font: getFontWithLangMatching(personalInformation.data?.address ?? ''),
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
              crossAxisAlignment: pw.CrossAxisAlignment.start,
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
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(3),
                    3: const pw.FlexColumnWidth(2),
                    4: const pw.FlexColumnWidth(2),
                    5: const pw.FlexColumnWidth(3),
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
                            _lang.date,
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
                            _lang.packageName,
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
                            _lang.started,
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
                            _lang.end,
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
                            _lang.paymentMethod,
                            pw.TextStyle(
                              font: getFont(bold: true),
                              fontFallback: [englishFont],
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlignment: pw.TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    // Table rows for products
                    for (int i = 0; i < subscription.length; i++)
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                textAlignment: pw.TextAlign.center,
                                subscription[i].startDate == null
                                    ? "N/A"
                                    : DateFormat('dd MMM yyyy').format(subscription[i].startDate!),
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                textAlignment: pw.TextAlign.center,
                                subscription[i].name ?? 'n/a',
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                textAlignment: pw.TextAlign.center,
                                subscription[i].startDate == null
                                    ? "N/A"
                                    : DateFormat('dd MMM yyyy').format(subscription[i].startDate!),
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                textAlignment: pw.TextAlign.center,
                                subscription[i].endDate == null
                                    ? "N/A"
                                    : DateFormat('dd MMM yyyy').format(subscription[i].startDate!),
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Padding(
                            padding: pw.EdgeInsets.all(8.0),
                            child: getLocalizedPdfTextWithLanguage(
                                textAlignment: pw.TextAlign.center,
                                subscription[i].paymentBy ?? 'n/a',
                                pw.TextStyle(
                                  font: getFont(),
                                  fontFallback: [englishFont],
                                )),
                          ),
                        ],
                      ),
                  ],
                ),

                pw.SizedBox(height: 20.0),
                if ((!personalInformation.data!.invoiceNote.isEmptyOrNull ||
                        !personalInformation.data!.invoiceNoteLevel.isEmptyOrNull) &&
                    personalInformation.data!.showNote == 1)
                  pw.RichText(
                      textAlign: pw.TextAlign.start,
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
                pw.SizedBox(height: 30),

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
        invoice: '1',
        doc: doc,
        isShare: share,
        download: download,
      );
    }
  }
}
