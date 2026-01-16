import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../model/business_info_model.dart';
import '../../model/loss_profit_model.dart' as model;

Future<void> generateLossProfitReportPdf(BuildContext context, model.LossProfitModel data,
    BusinessInformationModel? business, DateTime? fromDate, DateTime? toDate) async {
  final pw.Document pdf = pw.Document();
  final interFont = await PdfGoogleFonts.notoSansRegular();

  // Show loading indicator
  EasyLoading.show(status: 'Generating PDF');

  try {
    pdf.addPage(
      pw.MultiPage(
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
                  'Profit & Loss',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    // font: ttf,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  fromDate != null
                      ? 'Duration: ${DateFormat('dd-MM-yyyy').format(fromDate)} to ${DateFormat('dd-MM-yyyy').format(toDate!)}'
                      : '',
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
          final _length = math.max((data.expenseSummary?.length ?? 0), (data.incomeSummary?.length ?? 0));
          final List<List<String>> tableData = [];

          for (int i = 0; i < _length; i++) {
            final _income = (i < (data.incomeSummary?.length ?? 0)) ? data.incomeSummary![i] : null;

            final _expense = (i < (data.expenseSummary?.length ?? 0)) ? data.expenseSummary![i] : null;

            tableData.add([
              // Income Type
              _income?.type ?? '',
              _income?.totalIncome == null ? '' : formatPointNumber(_income!.totalIncome!),

              // Expense Type
              _expense?.type ?? '',
              _expense?.totalExpense == null ? '' : formatPointNumber(_expense!.totalExpense!),
            ]);
          }
          return [
            pw.SizedBox(height: 16),

            // Main Table
            pw.Table.fromTextArray(
              headers: [
                "Income type",
                "Amount",
                "Expenses Types",
                "Amount",
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
                0: const pw.FlexColumnWidth(6),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(6),
                3: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
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
                0: const pw.FlexColumnWidth(6),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(6),
                3: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.centerRight,
              },
              data: [
                [
                  "Gross Profit",
                  formatPointNumber(data.grossIncomeProfit ?? 0),
                  "Total Expense",
                  formatPointNumber(data.totalExpenses ?? 0),
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

            // Net Profit (Incomes - Expense)
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              alignment: pw.Alignment.center,
              decoration: pw.BoxDecoration(
                border: pw.Border(bottom: pw.BorderSide(color: PdfColor.fromHex("D8D8D880"))),
              ),
              child: pw.Text(
                "Net Profit (Incomes - Expense) =${formatPointNumber(data.netProfit ?? 0, addComma: true)}",
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  // font: interFont,
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox.square(dimension: 16),

            // Overview Containers
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                // Gross Profit
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('121535')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(formatPointNumber(data.cartGrossProfit ?? 0)),
                        pw.SizedBox.square(dimension: 4),
                        pw.Text('Gross Profit'),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox.square(dimension: 10),

                // Total Expenses
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('121535')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(formatPointNumber(data.totalCardExpense ?? 0)),
                        pw.SizedBox.square(dimension: 4),
                        pw.Text('Total Expenses'),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox.square(dimension: 10),

                // Net Profit
                pw.Expanded(
                  child: pw.Container(
                    padding: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColor.fromHex('121535')),
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(formatPointNumber(data.cardNetProfit ?? 0)),
                        pw.SizedBox.square(dimension: 4),
                        pw.Text('Net Profit'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );

    final byteData = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$appsName-loss-profit-report.pdf');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    EasyLoading.showSuccess('Generate Complete');
    //print pdf
    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Loss Profit Report',
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
