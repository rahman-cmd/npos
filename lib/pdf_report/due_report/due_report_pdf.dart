import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Due%20Calculation/Model/due_collection_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../model/business_info_model.dart';
import 'due_status.dart';

Future<void> generateDueReportPdf(BuildContext context, List<DueCollection>? data, BusinessInformationModel? business, DateTime? fromDate, DateTime? toDate) async {
  final pw.Document pdf = pw.Document();
  final interFont = await PdfGoogleFonts.notoSansRegular();

  // Show loading indicator
  EasyLoading.show(status: 'Generating PDF');
  double total = 0;
  double totalDue = 0;
  double totalPaid = 0;

// Calculate totals from data
  if (data != null) {
    for (var item in data) {
      final totalAmounts = item.totalDue ?? 0;
      total += totalAmounts;
    }
  }

  //total due
  if (data != null) {
    for (var item in data) {
      final due = item.dueAmountAfterPay ?? 0;
      totalDue += due;
    }
  }

  //total paid
  if (data != null) {
    for (var item in data) {
      final paid = item.payDueAmount ?? 0;
      totalPaid += paid;
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
                  'Due Report',
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
            final status = getDueStatus(data[i]);
            tableData.add([
              // '${i + 1}',
              data[i].invoiceNumber ?? 'n/a',
              DateFormat('dd-MM-yyyy').format(DateTime.parse(data[i].paymentDate.toString())),
              data[i].party!.name ?? 'n/a',
              // data[i]. ?? 'n/a',
              status,
              data[i].totalDue.toString(),
              data[i].payDueAmount.toString(),
              data[i].dueAmountAfterPay.toString(),
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
                'Name',
                'Status',
                'Total',
                'Paid',
                'Due',
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
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(4),
                5: const pw.FlexColumnWidth(4),
                6: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
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
                1: const pw.FlexColumnWidth(5),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(4),
                5: const pw.FlexColumnWidth(4),
                6: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
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
    final file = File('${dir.path}/${appsName}-due-report.pdf');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    EasyLoading.showSuccess('Generate Complete');
    //print pdf
    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Due Report',
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
