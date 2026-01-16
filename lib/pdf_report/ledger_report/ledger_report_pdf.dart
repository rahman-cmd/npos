import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos/Screens/Customers/Model/parties_model.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/Screens/party%20ledger/model/party_ledger_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Screens/PDF/pdf.dart';
import '../../Screens/Products/Model/product_total_stock_model.dart';
import '../../currency.dart';
import '../../model/business_info_model.dart';
import 'generate_pdf_date_range.dart';

Future<void> generateLedgerReportPdf(
  BuildContext context,
  List<PartyLedgerModel>? data,
  BusinessInformationModel business,
  DateTime? fromDate,
  DateTime? toDate,
  String selectedTime, // pass selected filter
) async {
  if (data == null || data.isEmpty) {
    EasyLoading.showInfo('No transactions to generate PDF');
    return;
  }

  final pdf = pw.Document();

  try {
    EasyLoading.show(status: 'Generating PDF...');

    double creditBalance = 0;
    double debitBalance = 0;
    // for (var item in data) {
    //   if (item.type == 'credit') creditBalance += item.amount ?? 0;
    //   if (item.type != 'credit') debitBalance += item.amount ?? 0;
    // }

    for (var item in data) {
      creditBalance += item.creditAmount ?? 0;
    }

    for (var item in data) {
      debitBalance += item.debitAmount ?? 0;
    }

    // Calculate correct PDF date range
    final pdfDateRange = getPdfDateRangeForSelectedTime(
      selectedTime,
      fromDate: fromDate,
      toDate: toDate,
    );

    final fromDateStr = pdfDateRange['from']!;
    final toDateStr = pdfDateRange['to']!;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: const pw.EdgeInsets.symmetric(horizontal: 16),
        header: (context) => pw.Center(
          child: pw.Column(
            children: [
              pw.Text(appsName, style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.Text('Party Ledger', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 2),
              pw.Text('$fromDateStr TO $toDateStr', style: const pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 4),
            ],
          ),
        ),
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('${business.data?.developByLevel ?? ''} ${business.data?.developBy ?? ''}'),
              pw.Text('Page-${context.pageNumber}'),
            ],
          );
        },
        build: (pw.Context context) {
          final List<List<String>> tableData = [];

          for (int i = 0; i < data.length; i++) {
            final isOpening = data[i].platform == 'opening_balance';
            // final stockPrice = (data[i].stocks != null && data[i].stocks!.isNotEmpty) ? data[i].stocks!.last.productPurchasePrice?.toString() ?? '0' : '0';
            tableData.add([
              DateFormat('dd-MM-yyyy').format(DateTime.parse(data[i].date.toString())),
              data[i].invoiceNumber ?? '--',
              isOpening ? "Opening" : (data[i].platform?.replaceAll('_', ' ') ?? 'Transaction'),
              '$currency${data[i].creditAmount ?? 0}',
              '$currency${data[i].debitAmount ?? 0}',
              '$currency${data[i].balance ?? 0}',
            ]);
          }

          return [
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: [
                'Date',
                'Reference No',
                'Description',
                'Credit',
                'Debit',
                'Balance',
              ],
              data: tableData,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xffF7F7F7),
              ),
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xffD9D9D9)),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              rowDecoration: const pw.BoxDecoration(
                color: PdfColors.white,
              ),
              // oddRowDecoration: pw.BoxDecoration(
              //   color: PdfColor.fromInt(0xffF7F7F7),
              // ),
              cellPadding: const pw.EdgeInsets.all(8),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(3),
                5: const pw.FlexColumnWidth(3),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
            ),
            pw.Table.fromTextArray(
              border: pw.TableBorder.all(color: PdfColor.fromInt(0xffD9D9D9)),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(4),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(3),
                4: const pw.FlexColumnWidth(3),
                5: const pw.FlexColumnWidth(3),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
              },
              data: [
                [
                  '',
                  '',
                  'Total',
                  creditBalance,
                  debitBalance,
                  data.last.balance,
                ]
              ],
              // headerDecoration: const pw.BoxDecoration(
              //   color: PdfColor.fromInt(0xffF7F7F7),
              // ),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.black,
              ),
              cellAlignment: pw.Alignment.center,
              cellPadding: const pw.EdgeInsets.all(8),
            ),
          ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/$appsName-leger-report-$timestamp.pdf');
    await file.writeAsBytes(bytes);
    await EasyLoading.dismiss();

    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Leger Report',
        usePrinterSettings: true,
        dynamicLayout: true,
        forceCustomPrintPaper: true,
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }

    // if (context.mounted) {
    //   Navigator.push(context, MaterialPageRoute(builder: (_) => PDFViewerPage(path: file.path)));
    // }
  } catch (e) {
    await EasyLoading.dismiss();
    EasyLoading.showError('Failed to generate PDF: $e');
  }
}
