import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../Screens/Due Calculation/Model/due_collection_model.dart';
import '../model/business_info_model.dart';
import 'pdf_common_functions.dart';

class DueInvoicePDF {
  static Future<void> generateDueDocument(DueCollection transactions, BusinessInformation personalInformation, BuildContext context, BusinessSettingModel businessSetting,
      {bool? isShare}) async {
    final pw.Document doc = pw.Document();
    // Load the image as bytes
    final String imageUrl = '${APIConfig.domain}${businessSetting.pictureUrl}';
    dynamic imageData = await PDFCommonFunctions().getNetworkImage(imageUrl);
    imageData ??= await PDFCommonFunctions().loadAssetImage('images/logo.png');
    EasyLoading.show(status: 'Generating PDF');
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
                pw.Row(children: [
                  // image section
                  if (imageData is Uint8List)
                    pw.Container(
                      height: 54.12,
                      width: 52,
                      child: pw.Image(
                        pw.MemoryImage(imageData),
                        fit: pw.BoxFit.cover,
                      ),
                    )
                  else if (imageData is String)
                    pw.Container(
                      height: 54.12,
                      width: 52,
                      child: pw.SvgImage(
                        svg: imageData,
                        fit: pw.BoxFit.cover,
                      ),
                    )
                  else
                    pw.Container(
                      height: 54.12,
                      width: 52,
                      child: pw.Image(pw.MemoryImage(imageData)),
                    ),
                  pw.SizedBox(width: 10.0),
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                    pw.Text(
                      personalInformation.companyName ?? '',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black, fontSize: 24.0, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Mobile: ${personalInformation.phoneNumber ?? ''}',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                    ),
                  ]),
                  pw.Spacer(),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    height: 52,
                    width: 247,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.black,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(25),
                        bottomLeft: pw.Radius.circular(25),
                      ),
                    ),
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 12, right: 19, top: 8, bottom: 8),
                      child: pw.Text(
                        'Money Receipt',
                        style: pw.Theme.of(context).defaultTextStyle.copyWith(
                              color: PdfColors.white,
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 30,
                            ),
                      ),
                    ),
                  ),
                ]),
                pw.SizedBox(height: 35.0),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                  pw.Column(children: [
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 50.0,
                        child: pw.Text(
                          'Bill To',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
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
                        child: pw.Text(
                          transactions.party?.name ?? '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 50.0,
                        child: pw.Text(
                          'Phone',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
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
                        child: pw.Text(
                          transactions.party?.phone ?? '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                  ]),
                  pw.Column(children: [
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Receipt',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 70.0,
                        child: pw.Text(
                          '${transactions.invoiceNumber}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Date',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 70.0,
                        child: pw.Text(
                          DateFormat('d MMM,yyy').format(DateTime.parse(transactions.paymentDate ?? '')),
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Collected By',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 10.0,
                        child: pw.Text(
                          ':',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                      pw.SizedBox(
                        width: 70.0,
                        child: pw.Text(
                          transactions.user?.role == "shop-owner" ? 'Admin' : transactions.user?.name ?? '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    if (personalInformation.address != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                            'Address',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 10.0,
                          child: pw.Text(
                            ':',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 70.0,
                          child: pw.Text(
                            personalInformation.address ?? '',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                      ]),
                    if (personalInformation.crNo != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                            'C.R',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 10.0,
                          child: pw.Text(
                            ':',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 70.0,
                          child: pw.Text(
                            personalInformation.crNo ?? '',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                      ]),
                    if (personalInformation.vatNumber != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                            personalInformation.vatName ?? 'VAT Number',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 10.0,
                          child: pw.Text(
                            ':',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
                        ),
                        pw.SizedBox(
                          width: 70.0,
                          child: pw.Text(
                            personalInformation.vatNumber ?? '',
                            style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                          ),
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
                    pw.Text(
                      'Customer Signature',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                    )
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
                    pw.Text(
                      'Authorized Signature',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                    )
                  ]),
                ),
              ]),
            ),
            pw.Container(
              width: double.infinity,
              color: const PdfColor.fromInt(0xffC52127),
              padding: const pw.EdgeInsets.all(10.0),
              child: pw.Center(child: pw.Text('Powered By $companyName', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold))),
            ),
          ]);
        },
        build: (pw.Context context) => <pw.Widget>[
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
            child: pw.Column(
              children: [
                pw.Table(
                    columnWidths: <int, pw.TableColumnWidth>{
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(3),
                      2: const pw.FlexColumnWidth(3),
                      3: const pw.FlexColumnWidth(3),
                    },
                    border: const pw.TableBorder(
                      verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                      bottom: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                    ),
                    children: [
                      pw.TableRow(
                        children: [
                          pw.Container(
                            decoration: const pw.BoxDecoration(
                              color: PdfColor.fromInt(0xffC52127),
                            ), // Red background
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              'SL',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Container(
                            color: const PdfColor.fromInt(0xffC52127), // Red background
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              'Total Due',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Container(
                            color: const PdfColor.fromInt(0xff000000), // Black background
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              'Payment Amount',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                          pw.Container(
                            color: const PdfColor.fromInt(0xff000000), // Black background
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              'Remaining Due',
                              style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                              textAlign: pw.TextAlign.left,
                            ),
                          ),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('1', textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text("${transactions.totalDue}", textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text((transactions.totalDue!.toDouble() - transactions.dueAmountAfterPay!.toDouble()).toStringAsFixed(2), textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text("${transactions.dueAmountAfterPay?.toStringAsFixed(2)}", textAlign: pw.TextAlign.left),
                          ),
                        ],
                      ),
                    ]),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 10.0),
                        pw.Container(
                          width: 570,
                          child: pw.Row(
                            children: [
                              pw.Text(
                                "Paid By: ${transactions.paymentType?.name ?? 'N/A'}",
                                style: const pw.TextStyle(
                                  color: PdfColors.black,
                                ),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                "Payable Amount: ${transactions.totalDue?.toStringAsFixed(2) ?? 0}",
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Container(
                          width: 570,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.SizedBox(
                                width: 350,
                                height: 20,
                                child: pw.Text(
                                  "Amounts in Words: ${PDFCommonFunctions().numberToWords(transactions.totalDue ?? 0)}",
                                  style: const pw.TextStyle(color: PdfColors.black),
                                  maxLines: 3,
                                ),
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    "Received Amount : ${(transactions.totalDue!.toDouble() - transactions.dueAmountAfterPay!.toDouble()).toStringAsFixed(2)}",
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  pw.Text(
                                    "Due Amount : ${transactions.dueAmountAfterPay?.toStringAsFixed(2) ?? 0}",
                                    style: pw.TextStyle(
                                      color: PdfColors.black,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 10.0),
                      ],
                    ),
                  ],
                ),
                pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ],
            ),
          ),
        ],
      ),
    );

    await PDFCommonFunctions.savePdfAndShowPdf(
        context: context, shopName: personalInformation.companyName ?? '', invoice: transactions.invoiceNumber ?? '', doc: doc, isShare: isShare);
  }
}
