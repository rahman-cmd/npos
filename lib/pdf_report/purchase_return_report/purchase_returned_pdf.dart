import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Purchase/Model/purchase_transaction_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../model/business_info_model.dart';
import '../../model/sale_transaction_model.dart';

Future<void> generatePurchaseReturnReportPdf(
    BuildContext context, List<PurchaseTransaction>? data, BusinessInformationModel? business, DateTime? fromDate, DateTime? toDate) async {
  final pw.Document pdf = pw.Document();
  final interFont = await PdfGoogleFonts.notoSansRegular();

  // Show loading indicator
  EasyLoading.show(status: 'Generating PDF');
  double total = 0;
  double totalDue = 0;
  double totalPaid = 0;
  num totalReturnedAmount = 0;

// Calculate totals from data
  if (data != null) {
    for (var item in data) {
      final totalAmounts = item.totalAmount ?? 0;
      total += totalAmounts;
    }
  }

  //total due
  if (data != null) {
    for (var item in data) {
      final due = item.dueAmount ?? 0;
      totalDue += due;
    }
  }

  //total paid
  if (data != null) {
    for (var item in data) {
      final paid = item.paidAmount ?? 0;
      totalPaid += paid;
    }
  }

  double getReturnedAmountForItem(item) {
    double returned = 0;

    for (var purchaseReturn in item.purchaseReturns ?? []) {
      for (var details in purchaseReturn.purchaseReturnDetails ?? []) {
        returned += details.returnAmount ?? 0;
      }
    }

    return returned;
  }

  if (data != null) {
    for (var item in data) {
      for (var purchaseReturn in item.purchaseReturns ?? []) {
        for (var details in purchaseReturn.purchaseReturnDetails ?? []) {
          totalReturnedAmount += details.returnAmount ?? 0;
        }
      }
    }
  }

  try {
    pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.symmetric(horizontal: 16),
        //----------------pdf header--------------
        header: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  business?.data?.companyName.toString() ?? '',
                  style: pw.TextStyle(
                    // font: interFont,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.Text(
                  // 'বিক্রয় প্রতিবেদন',
                  'Purchase Return Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    // font: ttf,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  fromDate != null ? 'Duration: ${DateFormat('dd-MM-yyyy').format(fromDate)} to ${DateFormat('dd-MM-yyyy').format(toDate!)}' : '',
                  style: pw.TextStyle(
                    font: interFont,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
        //-----------------pdf footer-------------
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${business?.data?.developByLevel ?? ''} ${business?.data?.developBy ?? ''}'),
              pw.Text('Page-${context.pageNumber}'),
            ],
          );
        },
        build: (pw.Context context) {
          final List<List<String>> tableData = [];

          for (int i = 0; i < data!.length; i++) {
            double returnedAmount = getReturnedAmountForItem(data[i]);

            tableData.add([
              // '${i + 1}',
              data[i].invoiceNumber ?? 'n/a',
              DateFormat('dd-MM-yyyy').format(DateTime.parse(data[i].purchaseDate.toString())),
              data[i].party!.name ?? 'n/a',
              // data[i]. ?? 'n/a',
              data[i].isPaid == true ? 'Paid' : 'Unpaid',
              data[i].totalAmount.toString(),
              data[i].paidAmount.toString(),
              data[i].dueAmount.toString(),
              formatPointNumber(returnedAmount),
            ]);
          }

          return [
            pw.SizedBox(height: 16),

            // Main Table
            pw.Table.fromTextArray(
              headers: [
                // 'SL',
                'Reference',
                'Date',
                'Supplier',
                'Status',
                'Total',
                'Paid',
                'Due',
                'Return Amount',
              ],
              data: tableData,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xffC52127),
              ),
              cellAlignment: pw.Alignment.center,
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xffD9D9D9)),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              oddRowDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0xffF7F7F7),
              ),
              cellPadding: const pw.EdgeInsets.all(8),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(3),
                5: const pw.FlexColumnWidth(3),
                6: const pw.FlexColumnWidth(3),
                7: const pw.FlexColumnWidth(3),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
              },
            ),
            // Totals row (styled to match)
            pw.Table.fromTextArray(
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
              ),
              columnWidths: <int, pw.TableColumnWidth>{
                0: const pw.FlexColumnWidth(4),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(3),
                5: const pw.FlexColumnWidth(3),
                6: const pw.FlexColumnWidth(3),
                7: const pw.FlexColumnWidth(3),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
                7: pw.Alignment.center,
              },
              data: [
                [
                  'Total',
                  '',
                  '',
                  '',
                  formatPointNumber(total),
                  formatPointNumber(totalPaid),
                  formatPointNumber(totalDue),
                  formatPointNumber(totalReturnedAmount),
                ]
              ],
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xffC52127),
              ),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ];
        }));

    final byteData = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${appsName}-purhase-return-report.pdf');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    EasyLoading.showSuccess('Generate Complete');
    //print pdf
    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Purchase Return Report',
        usePrinterSettings: true,
        dynamicLayout: true,
        forceCustomPrintPaper: true,
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => PDFViewerPage(path: file.path),
    //   ),
    // );
  } catch (e) {
    EasyLoading.showError('Error: $e');
    print('Error during PDF generation: $e');
  }
}
