import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Const/api_config.dart';
import 'package:mobile_pos/constant.dart';
import 'package:mobile_pos/model/business_setting_model.dart';
import 'package:mobile_pos/model/sale_transaction_model.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import '../Screens/Due Calculation/Model/due_collection_model.dart';
import '../Screens/PDF/pdf.dart';
import '../Screens/Purchase/Model/purchase_transaction_model.dart';
import '../model/business_info_model.dart';

class GeneratePdf {
  //-------------------image
  Future<dynamic> getNetworkImage(String imageURL) async {
    if (imageURL.isEmpty) return null;
    try {
      final Uri uri = Uri.parse(imageURL);
      final String fileExtension = uri.path.split('.').last.toLowerCase();
      if (fileExtension == 'png' || fileExtension == 'jpg' || fileExtension == 'jpeg') {
        final List<int> responseBytes = await http.readBytes(uri);
        return Uint8List.fromList(responseBytes);
      } else if (fileExtension == 'svg') {
        final response = await http.get(uri);
        return response.body;
      } else {
        print('Unsupported image type: $fileExtension');
        return null;
      }
    } catch (e) {
      print('Error loading image: $e');
      return null;
    }
  }

  Future<Uint8List?> loadAssetImage(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      print('Error loading local image: $e');
      return null;
    }
  }

  // // Load image from assets
  // Future<Uint8List> loadAssetImage(String path) async {
  //   final data = await rootBundle.load(path);
  //   return data.buffer.asUint8List();
  // }

  int serialNumber = 1; // Initialize serial number

  num getProductQuantity({required num detailsId, required SalesTransactionModel transactions}) {
    num totalQuantity = transactions.salesDetails?.where((element) => element.id == detailsId).first.quantities ?? 0;
    if (transactions.salesReturns?.isNotEmpty ?? false) {
      for (var returns in transactions.salesReturns!) {
        if (returns.salesReturnDetails?.isNotEmpty ?? false) {
          for (var details in returns.salesReturnDetails!) {
            if (details.saleDetailId == detailsId) {
              totalQuantity += details.returnQty ?? 0;
            }
          }
        }
      }
    }

    return totalQuantity;
  }

  Future<void> generatePurchaseDocument(
      PurchaseTransaction transactions, BusinessInformation personalInformation, BuildContext context, BusinessSettingModel businessSetting) async {
    final pw.Document doc = pw.Document();

    String productName({required num detailsId}) {
      return transactions.details?[transactions.details!.indexWhere((element) => element.id == detailsId)].product?.productName ?? '';
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
              totalReturnDiscount += ((productPrice(detailsId: details.purchaseDetailId ?? 0) * (details.returnQty ?? 0)) - ((details.returnAmount ?? 0)));
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

    EasyLoading.show(status: 'Generating PDF');

    final String imageUrl = '${APIConfig.domain}${businessSetting.pictureUrl}';
    dynamic imageData = await getNetworkImage(imageUrl);
    imageData ??= await loadAssetImage('images/logo.png');

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.zero,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        header: (pw.Context context) {
          print('--header--');
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20.0),
            child: pw.Column(
              children: [
                pw.Row(
                  children: [
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
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          personalInformation.companyName ?? '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                color: PdfColors.black,
                                fontSize: 25.0,
                                fontWeight: pw.FontWeight.bold,
                              ),
                        ),
                        pw.Text(
                          'Mobile: ${personalInformation.phoneNumber ?? ''}',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(
                                color: PdfColors.black,
                              ),
                        ),
                      ],
                    ),
                    pw.Spacer(),
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
                  ],
                ),
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
                          'Purchase By',
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
                          transactions.user?.name ?? '',
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
                          DateFormat('d MMM, yyyy').format(
                            DateTime.parse(transactions.purchaseDate ?? ''),
                          ),
                          // DateTimeFormat.format(DateTime.parse(transactions.purchaseDate ?? ''), format: 'd MMM yyyy'),
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    if (personalInformation.vatNumber != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                            personalInformation.vatName??'VAT Number',
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
                      1: const pw.FlexColumnWidth(6),
                      2: const pw.FlexColumnWidth(2),
                      3: const pw.FlexColumnWidth(2),
                      4: const pw.FlexColumnWidth(2),
                    },
                    border: const pw.TableBorder(
                      verticalInside: pw.BorderSide(
                        color: PdfColor.fromInt(0xffD9D9D9),
                      ),
                      left: pw.BorderSide(
                        color: PdfColor.fromInt(0xffD9D9D9),
                      ),
                      right: pw.BorderSide(
                        color: PdfColor.fromInt(0xffD9D9D9),
                      ),
                      bottom: pw.BorderSide(
                        color: PdfColor.fromInt(0xffD9D9D9),
                      ),
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
                      for (int i = 0; i < transactions.details!.length; i++)
                        pw.TableRow(
                          decoration: i % 2 == 0
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
                              child: pw.Text(
                                '${i + 1}',
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            //Item Name
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                (transactions.details!.elementAt(i).product?.productName).toString(),
                                textAlign: pw.TextAlign.left,
                              ),
                            ),
                            //Quantity
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                (getProductQuantity(detailsId: transactions.details!.elementAt(i).id ?? 0)).toString(),
                                textAlign: pw.TextAlign.center,
                              ),
                            ),
                            //unit price
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                (transactions.details!.elementAt(i).productPurchasePrice ?? 0).toStringAsFixed(2),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                            //Total price
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                ((transactions.details!.elementAt(i).productPurchasePrice ?? 0) * getProductQuantity(detailsId: transactions.details!.elementAt(i).id ?? 0))
                                    .toStringAsFixed(2),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                    ]),
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                    pw.SizedBox(height: 10.0),
                    pw.Text(
                      "Subtotal: ${getTotalForOldInvoice().toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Text(
                      "Discount: ${((transactions.discountAmount ?? 0) + getReturndDiscountAmount()).toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Text(
                      "${transactions.vat?.name ?? "Vat"}: ${((transactions.vatAmount ?? 0)).toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Text(
                      "${"Shipping Charge"}: ${((transactions.shippingCharge ?? 0)).toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Text(
                      "Total Amount: ${((transactions.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ]),
                ]),
                (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty) ? pw.Container(height: 10) : pw.Container(),

                ///-----return_table-----
                (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty)
                    ? pw.Column(children: [
                        pw.Table(
                          border: const pw.TableBorder(
                            verticalInside: pw.BorderSide(
                              color: PdfColor.fromInt(0xffD9D9D9),
                            ),
                            left: pw.BorderSide(
                              color: PdfColor.fromInt(0xffD9D9D9),
                            ),
                            right: pw.BorderSide(
                              color: PdfColor.fromInt(0xffD9D9D9),
                            ),
                            bottom: pw.BorderSide(
                              color: PdfColor.fromInt(0xffD9D9D9),
                            ),
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
                                    textAlign: pw.TextAlign.center,
                                  ),
                                ),
                                pw.Container(
                                  color: const PdfColor.fromInt(0xff000000), // Black background
                                  padding: const pw.EdgeInsets.all(8.0),
                                  child: pw.Text(
                                    'Quantity',
                                    style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                                    textAlign: pw.TextAlign.right,
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
                            for (int i = 0; i < (transactions.purchaseReturns?.length ?? 0); i++)
                              for (int j = 0; j < (transactions.purchaseReturns?[i].purchaseReturnDetails?.length ?? 0); j++)
                                pw.TableRow(
                                  decoration: serialNumber.isOdd
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
                                      child: pw.Text(
                                        '${serialNumber++}',
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    //Date
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(
                                        DateFormat.yMMMd().format(DateTime.parse(
                                          transactions.purchaseReturns?[i].returnDate ?? '0',
                                        )),
                                        textAlign: pw.TextAlign.left,
                                      ),
                                    ),
                                    //Total return
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(
                                        productName(detailsId: transactions.purchaseReturns?[i].purchaseReturnDetails?[j].purchaseDetailId ?? 0),
                                        textAlign: pw.TextAlign.center,
                                      ),
                                    ),
                                    //Quantity
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(
                                        transactions.purchaseReturns?[i].purchaseReturnDetails?[j].returnQty?.toString() ?? '0',
                                        textAlign: pw.TextAlign.right,
                                      ),
                                    ),
                                    //Total Return
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8),
                                      child: pw.Text(
                                        transactions.purchaseReturns?[i].purchaseReturnDetails?[j].returnAmount?.toStringAsFixed(2) ?? '0',
                                        textAlign: pw.TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                          ],
                        ),
                      ])
                    : pw.SizedBox.shrink(),

                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                  pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                    (transactions.purchaseReturns != null && transactions.purchaseReturns!.isNotEmpty)
                        ? pw.Column(
                            children: [
                              pw.SizedBox(height: 10.0),
                              pw.Text(
                                "Total Return Amount : ${getTotalReturndAmount().toStringAsFixed(2)}",
                                style: pw.TextStyle(
                                  color: PdfColors.black,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : pw.Container(),
                    pw.SizedBox(height: 5.0),
                    pw.Container(
                      color: const PdfColor.fromInt(0xffC52127),
                      padding: const pw.EdgeInsets.all(5.0),
                      child:
                          pw.Text("Payable Amount: ${transactions.totalAmount?.toStringAsFixed(2)}", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Container(
                      width: 540,
                      child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
                        pw.Text(
                          "Paid Via: ${transactions.paymentType}",
                          style: const pw.TextStyle(
                            color: PdfColors.black,
                          ),
                        ),
                        pw.Text(
                          "Paid Amount: ${(transactions.totalAmount!.toDouble() - transactions.dueAmount!.toDouble()).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ]),
                    ),
                    pw.SizedBox(height: 5.0),
                    pw.Text(
                      "Due: ${transactions.dueAmount?.toStringAsFixed(2)}",
                      style: pw.TextStyle(
                        color: PdfColors.black,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ]),
                ]),
                pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ],
            ),
          ),
        ],
      ),
    );
    if (Platform.isIOS) {
      EasyLoading.show(status: 'Generating PDF');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

      final byteData = await doc.save();
      try {
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        EasyLoading.showSuccess('Done');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
          ),
        );

        // OpenFile.open("${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
      } on FileSystemException catch (err) {
        EasyLoading.showError(err.message);
        // handle error
      }
    }
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      if (true) {
        EasyLoading.show(status: 'Generating PDF');
        const downloadsFolderPath = '/storage/emulated/0/Download/';
        Directory dir = Directory(downloadsFolderPath);
        final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

        final byteData = await doc.save();
        try {
          await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          EasyLoading.showSuccess('Done');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
            ),
          );
          // OpenFile.open("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
        } on FileSystemException catch (err) {
          EasyLoading.showError(err.message);
          // handle error
        }
      }
    }

    // if (Platform.isAndroid) {
    //   var status = await Permission.storage.status;
    //   if (status != PermissionStatus.granted) {
    //     status = await Permission.storage.request();
    //   }
    //   if (status.isGranted) {
    //     // const downloadsFolderPath = '/storage/emulated/0/Download/';
    //     // Directory dir = Directory(downloadsFolderPath);
    //     // final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');
    //     // await file.writeAsBytes(await doc.save());
    //     // EasyLoading.showSuccess('Successful');
    //     // OpenFile.open("/storage/emulated/0/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    //
    //     final file = File("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    //     await file.writeAsBytes(await doc.save());
    //     EasyLoading.showSuccess('Successful');
    //     OpenFile.open("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    //   } else {
    //     EasyLoading.showError('Sorry, Permission not granted');
    //   }
    // }

    // final byteData = await rootBundle.load('assets/$fileName');
    // try {
    //   await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    // } on FileSystemException catch (err) {
    //   // handle error
    // }
    // var status = await Permission.storage.request();
    // if (status.isGranted) {
    //   final file = File("/storage/emulated/0/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    //   await file.writeAsBytes(await doc.save());
    //   EasyLoading.showSuccess('Successful');
    //   OpenFile.open("/storage/emulated/0/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    // } else if (status.isDenied) {
    //   EasyLoading.dismiss();
    //   await Permission.storage.request();
    // } else if (status.isPermanentlyDenied) {
    //   EasyLoading.showError('Grant Access');
    // }
  }

  Future<void> generateSaleDocument(SalesTransactionModel transactions, BusinessInformation personalInformation, BuildContext context, BusinessSettingModel businessSetting) async {
    final pw.Document doc = pw.Document();

    // Load the image as bytes
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
        total += (element.price ?? 0) * getProductQuantity(detailsId: element.id ?? 0, transactions: transactions);
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
    dynamic imageData = await getNetworkImage(imageUrl);
    imageData ??= await loadAssetImage('images/logo.png');

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
                          transactions.user?.name ?? '',
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
                    if (personalInformation.vatNumber != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                           personalInformation.vatName?? 'VAT Number',
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
                            child: pw.Text(getProductQuantity(detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions).toString(),
                                textAlign: pw.TextAlign.center),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text("${transactions.salesDetails!.elementAt(i).price?.toStringAsFixed(2)}", textAlign: pw.TextAlign.right),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              ((transactions.salesDetails![i].price ?? 0) * (getProductQuantity(detailsId: transactions.salesDetails![i].id ?? 0, transactions: transactions)))
                                  .toStringAsFixed(2),
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
                          "Subtotal: ${getTotalForOldInvoice().toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "Discount: ${((transactions.discountAmount ?? 0) + returnedDiscountAmount()).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "${transactions.vat?.name ?? "VAT"}: ${transactions.vatAmount?.toStringAsFixed(2) ?? 0.00}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "${"Shipping Charge"}: ${((transactions.shippingCharge ?? 0)).toStringAsFixed(2)}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "Total Amount: ${((transactions.totalAmount ?? 0) + getTotalReturndAmount()).toStringAsFixed(2)}",
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
                                  decoration: serialNumber.isOdd
                                      ? const pw.BoxDecoration(color: PdfColors.white) // Odd row color
                                      : const pw.BoxDecoration(color: PdfColors.red50),
                                  children: [
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text('${serialNumber++}', textAlign: pw.TextAlign.center),
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
                                      child: pw.Text(transactions.salesReturns?[i].salesReturnDetails?[j].returnQty?.toString() ?? '0', textAlign: pw.TextAlign.center),
                                    ),
                                    pw.Padding(
                                      padding: const pw.EdgeInsets.all(8.0),
                                      child: pw.Text(transactions.salesReturns?[i].salesReturnDetails?[j].returnAmount?.toStringAsFixed(2) ?? '0', textAlign: pw.TextAlign.right),
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
                                      children: [pw.TextSpan(text: getTotalReturndAmount().toStringAsFixed(2))],
                                    ),
                                  ),
                                  pw.SizedBox(height: 5.0),
                                ],
                              )
                            : pw.SizedBox(),
                        pw.Container(
                          color: const PdfColor.fromInt(0xffC52127),
                          padding: const pw.EdgeInsets.all(5.0),
                          child: pw.Text(
                            "Payable Amount: ${transactions.totalAmount?.toStringAsFixed(2)}",
                            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Container(
                          width: 540,
                          child: pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                "Paid Via: ${transactions.paymentType}",
                                style: const pw.TextStyle(color: PdfColors.black),
                              ),
                              pw.Text(
                                "Paid Amount: ${(transactions.totalAmount!.toDouble() - transactions.dueAmount!.toDouble()).toStringAsFixed(2)}",
                                style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        pw.SizedBox(height: 5.0),
                        pw.Text(
                          "Due: ${transactions.dueAmount?.toStringAsFixed(2) ?? 0}",
                          style: pw.TextStyle(color: PdfColors.black, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 10.0),
                      ],
                    ),
                  ],
                ),
                if(transactions.meta?.note?.isNotEmpty ?? false)
                  pw.Column(
                    children: [
                      pw.SizedBox(height: 5.0),
                      pw.Align(
                        alignment: pw.AlignmentDirectional.centerStart,
                        child:  pw.Text(
                          "${"Note"}: ${(transactions.meta?.note ?? '')}",
                          style: pw.TextStyle(
                            color: PdfColors.black,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ]
                  ),


                pw.Padding(padding: const pw.EdgeInsets.all(10)),
              ],
            ),
          ),
        ],
      ),
    );
    if (Platform.isIOS) {
      EasyLoading.show(status: 'Generating PDF');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

      final byteData = await doc.save();
      try {
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        EasyLoading.showSuccess('Done');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
          ),
        );
        // OpenFile.open("${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
      } on FileSystemException catch (err) {
        EasyLoading.showError(err.message);
        // handle error
      }
    }

    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      if (true) {
        EasyLoading.show(status: 'Generating PDF');
        const downloadsFolderPath = '/storage/emulated/0/Download/';
        Directory dir = Directory(downloadsFolderPath);
        final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

        final byteData = await doc.save();
        try {
          await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          EasyLoading.showSuccess('Created and Saved');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
            ),
          );
          // OpenFile.open("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
        } on FileSystemException catch (err) {
          EasyLoading.showError(err.message);
          // handle error
        }
      }
    }
  }

  Future<void> generateDueDocument(DueCollection transactions, BusinessInformation personalInformation, BuildContext context, BusinessSettingModel businessSetting) async {
    final pw.Document doc = pw.Document();
    // Load the image as bytes
    final String imageUrl = '${APIConfig.domain}${businessSetting.pictureUrl}';
    dynamic imageData = await getNetworkImage(imageUrl);
    imageData ??= await loadAssetImage('images/logo.png');
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
                          transactions.user?.name ?? '',
                          style: pw.Theme.of(context).defaultTextStyle.copyWith(color: PdfColors.black),
                        ),
                      ),
                    ]),
                    if (personalInformation.vatNumber != null)
                      pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                        pw.SizedBox(
                          width: 100.0,
                          child: pw.Text(
                           personalInformation.vatName?? 'VAT Number',
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
                            child: pw.Text("${(transactions.totalDue!.toDouble() - transactions.dueAmountAfterPay!.toDouble()).toStringAsFixed(2)}", textAlign: pw.TextAlign.left),
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
                                "Paid By: ${transactions.paymentType}",
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
                        // pw.Text(
                        //   "Discount: ${0.0}",
                        //   style: pw.TextStyle(
                        //     color: PdfColors.black,
                        //     fontWeight: pw.FontWeight.bold,
                        //   ),
                        // ),
                        // pw.SizedBox(height: 5.0),
                        // pw.Container(
                        //   color: PdfColors.blueAccent,
                        //   padding: const pw.EdgeInsets.all(5.0),
                        //   child: pw.Text("Total Due: ${transactions.totalDue}", style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                        // ),
                        pw.SizedBox(height: 5.0),
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
    if (Platform.isIOS) {
      EasyLoading.show(status: 'Generating PDF');
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

      final byteData = await doc.save();
      try {
        await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
        EasyLoading.showSuccess('Done');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
          ),
        );
        // OpenFile.open("${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
      } on FileSystemException catch (err) {
        EasyLoading.showError(err.message);
        // handle error
      }
    }
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (status != PermissionStatus.granted) {
        status = await Permission.storage.request();
      }
      if (true) {
        EasyLoading.show(status: 'Generating PDF');
        const downloadsFolderPath = '/storage/emulated/0/Download/';
        Directory dir = Directory(downloadsFolderPath);
        final file = File('${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf');

        final byteData = await doc.save();
        try {
          await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
          EasyLoading.showSuccess('Done');
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(path: '${dir.path}/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf'),
            ),
          );
          // OpenFile.open("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
        } on FileSystemException catch (err) {
          EasyLoading.showError(err.message);
          // handle error
        }
      }
    }
    // var status = await Permission.storage.request();
    // if (status.isGranted) {
    //   final file = File("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    //   await file.writeAsBytes(await doc.save());
    //   EasyLoading.showSuccess('Successful');
    //   OpenFile.open("/storage/emulated/0/download/${'Npos-${personalInformation.companyName}-${transactions.invoiceNumber}'}.pdf");
    // } else if (status.isDenied) {
    //   EasyLoading.dismiss();
    //   await Permission.storage.request();
    // } else if (status.isPermanentlyDenied) {
    //   EasyLoading.showError('Grant Access');
    // }
  }
} // import 'dart:io';
