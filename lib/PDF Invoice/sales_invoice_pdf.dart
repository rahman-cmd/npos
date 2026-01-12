import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/business_info_model.dart';
import 'pdf_common_functions.dart';

class SalesInvoicePdf {
  static Future<void> generateSaleDocument(SalesTransactionModel transactions, BusinessInformation personalInformation, BuildContext context, BusinessSettingModel businessSetting,
      {bool? share}) async {
    final pw.Document doc = pw.Document();

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
              totalReturnDiscount += ((productPrice(detailsId: details.saleDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
            }
          }
        }
      }
      return totalReturnDiscount;
    }

    num getTotalForOldInvoice() {
      num total = 0;
      for (var element in transactions.salesDetails!) {
        total += (element.price ?? 0) * PDFCommonFunctions().getProductQuantity(detailsId: element.id ?? 0, transactions: transactions);
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

    final String imageUrl = '${APIConfig.domain}${businessSetting.pictureUrl}';
    dynamic imageData = await PDFCommonFunctions().getNetworkImage(imageUrl);
    imageData ??= await PDFCommonFunctions().loadAssetImage('images/logo.png');

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
                  ]),
                  pw.Container(
                    alignment: pw.Alignment.center,
                    height: 52,
                    width: 192,
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.black,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(25),
                        bottomLeft: pw.Radius.circular(25),
                      ),
                    ),
                    child: pw.Text(
                      'INVOICE',
                      style: pw.Theme.of(context).defaultTextStyle.copyWith(
                            color: PdfColors.white,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 35,
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
                          'Mobile',
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
                          transactions.party?.phone ?? (transactions.meta?.customerPhone ?? 'Guest'),
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
                          'Sells By',
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
                    pw.Row(children: [
                      pw.SizedBox(
                        width: 100.0,
                        child: pw.Text(
                          'Invoice Number',
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
                          '#${transactions.invoiceNumber}',
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
                          DateFormat('d MMM, yyyy').format(DateTime.parse(transactions.saleDate ?? '')),
                          // DateTimeFormat.format(DateTime.parse(transactions.saleDate ?? ''), format: 'D, M j'),
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
                  border: const pw.TableBorder(
                    verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                    left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                    right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
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
                    //pdf header
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
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          color: const PdfColor.fromInt(0xffC52127), // Red background
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Item',
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.left,
                          ),
                        ),
                        pw.Container(
                          color: const PdfColor.fromInt(0xff000000), // Black background
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Quantity',
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Container(
                          color: const PdfColor.fromInt(0xff000000), // Black background
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Unit Price',
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                        pw.Container(
                          color: const PdfColor.fromInt(0xff000000), // Black background
                          padding: const pw.EdgeInsets.all(8.0),
                          child: pw.Text(
                            'Total Price',
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    for (int i = 0; i < transactions.salesDetails!.length; i++)
                      pw.TableRow(
                        decoration: i % 2 == 0
                            ? const pw.BoxDecoration(
                                color: PdfColors.white,
                              ) // Odd row color
                            : const pw.BoxDecoration(
                                color: PdfColors.red50,
                              ),
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text('${i + 1}', textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(transactions.salesDetails!.elementAt(i).product?.productName.toString() ?? '', textAlign: pw.TextAlign.left),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(formatPointNumber(PDFCommonFunctions().getProductQuantity(detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions)),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(formatPointNumber(transactions.salesDetails!.elementAt(i).price ?? 0), textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              formatPointNumber((transactions.salesDetails![i].price ?? 0) *
                                  (PDFCommonFunctions().getProductQuantity(detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions))),
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Subtotal, VAT, Discount, and Total Amount
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.SizedBox(height: 10.0),
                        pw.Text(
                          "Subtotal: ${formatPointNumber(getTotalForOldInvoice())}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "Discount: ${formatPointNumber((transactions.discountAmount ?? 0) + returnedDiscountAmount())}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "${transactions.vat?.name ?? "VAT"}: ${formatPointNumber(transactions.vatAmount ?? 0.00)}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "${"Shipping Charge"}: ${formatPointNumber((transactions.shippingCharge ?? 0))}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),

                        ///______Rounded_amount__________________________________
                        if (transactions.roundingAmount != 0)
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(
                                "Amount: ${formatPointNumber((transactions.actualTotalAmount ?? 0))}",
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5.0),
                              pw.Text(
                                "Rounding: ${!(transactions.roundingAmount?.isNegative ?? true) ? '+' : ''}${formatPointNumber((transactions.roundingAmount ?? 0))}",
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 5.0),
                            ],
                          ),
                        pw.Text(
                          "Total Amount: ${formatPointNumber((transactions.totalAmount ?? 0) + getTotalReturndAmount())}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 10.0),
                      ],
                    ),
                  ],
                ),

                // Return table
                (transactions.salesReturns != null && transactions.salesReturns!.isNotEmpty)
                    ? pw.Column(children: [
                        pw.Table(
                          border: const pw.TableBorder(
                            verticalInside: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                            right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
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
                            //table header
                            pw.TableRow(
                              children: [
                                pw.Container(
                                  color: const PdfColor.fromInt(0xffC52127),
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'SL',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Container(
                                  color: const PdfColor.fromInt(0xffC52127),
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Date',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                                pw.Container(
                                  color: const PdfColor.fromInt(0xff000000), // Black background
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Returned Item',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.left,
                                  ),
                                ),
                                pw.Container(
                                  color: const PdfColor.fromInt(0xff000000), // Black background
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Quantity',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Container(
                                  color: const PdfColor.fromInt(0xff000000), // Black background
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Total return',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                            // Data rows for returns
                            for (int i = 0; i < (transactions.salesReturns?.length ?? 0); i++)
                              for (int j = 0; j < (transactions.salesReturns?[i].salesReturnDetails?.length ?? 0); j++)
                                pw.TableRow(
                                  decoration: PDFCommonFunctions().serialNumber.isOdd
                                      ? const pw.BoxDecoration(color: PdfColors.white) // Odd row color
                                      : const pw.BoxDecoration(color: PdfColors.red50),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text('${PDFCommonFunctions().serialNumber++}', textAlign: pw.TextAlign.center),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(DateFormat.yMMMd().format(DateTime.parse(transactions.salesReturns?[i].returnDate ?? '0')), textAlign: pw.TextAlign.left),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(productName(detailsId: transactions.salesReturns?[i].salesReturnDetails?[j].saleDetailId ?? 0), textAlign: pw.TextAlign.left),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(formatPointNumber(transactions.salesReturns?[i].salesReturnDetails?[j].returnQty ?? 0), textAlign: pw.TextAlign.center),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(formatPointNumber(transactions.salesReturns?[i].salesReturnDetails?[j].returnAmount ?? 0), textAlign: pw.TextAlign.right),
                                    ),
                                  ],
                                ),
                          ],
                        )
                      ])
                    : pw.SizedBox.shrink(),

                // Total returned amount and payable amount
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        (transactions.salesReturns != null && transactions.salesReturns!.isNotEmpty)
                            ? pw.Column(
                                children: [
                                  pw.SizedBox(height: 10),
                                  pw.RichText(
                                    text: pw.TextSpan(
                                      text: 'Total Returned Amount: ',
                                      style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                                      children: [pw.TextSpan(text: formatPointNumber(getTotalReturndAmount()))],
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                ],
                              )
                            : pw.SizedBox(),

                        ///____________Payable_amount_________________________________________
                        pw.Container(
                          width: 570,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Paid Via: ${transactions.paymentType?.name ?? 'N/A'}",
                                style: const pw.TextStyle(color: PdfColors.black),
                              ),
                              pw.Container(
                                color: const PdfColor.fromInt(0xffC52127),
                                padding: const pw.EdgeInsets.all(5.0),
                                child: pw.Text(
                                  "Payable Amount: ${formatPointNumber(transactions.totalAmount ?? 0)}",
                                  style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
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
                                  "Amounts in Words: ${PDFCommonFunctions().numberToWords(transactions.totalAmount ?? 0)}",
                                  style: const pw.TextStyle(color: PdfColors.black),
                                  maxLines: 3,
                                ),
                              ),
                              pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.end,
                                children: [
                                  pw.Text(
                                    "Received Amount: ${formatPointNumber(((transactions.totalAmount ?? 0) - (transactions.dueAmount ?? 0)) + (transactions.changeAmount ?? 0))}",
                                    style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                  pw.Text(
                                    (transactions.dueAmount ?? 0) > 0
                                        ? "Due: ${formatPointNumber(transactions.dueAmount ?? 0)}"
                                        : (transactions.changeAmount ?? 0) > 0
                                            ? "Change Amount: ${formatPointNumber(transactions.changeAmount ?? 0)}"
                                            : '',
                                    style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
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
                if (transactions.meta?.note?.isNotEmpty ?? false)
                  pw.Column(children: [
                    pw.SizedBox(height: 5.0),
                    pw.Align(
                      alignment: pw.AlignmentDirectional.centerStart,
                      child: pw.Text(
                        "${"Note"}: ${(transactions.meta?.note ?? '')}",
                        style: pw.TextStyle(
                          color: PdfColors.black,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ]),

                pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ],
            ),
          ),
        ],
      ),
    );
    await PDFCommonFunctions.savePdfAndShowPdf(
        context: context, shopName: personalInformation.companyName ?? '', invoice: transactions.invoiceNumber ?? '', doc: doc, isShare: share);
  }
}
