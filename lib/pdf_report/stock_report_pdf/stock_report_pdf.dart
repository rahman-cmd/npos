import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobile_pos/Screens/Products/Model/product_model.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../Screens/PDF/pdf.dart';
import '../../Screens/Products/Model/product_total_stock_model.dart';
import '../../model/business_info_model.dart';

Future<void> generateStockReportPdf(BuildContext context, List<Product>? data, BusinessInformationModel? business, ProductListResponse? stockValue, bool? isLowStock) async {
  if (data == null || business == null) {
    EasyLoading.showError('Invalid data for report generation');
    return;
  }

  final pw.Document pdf = pw.Document();

  try {
    EasyLoading.show(status: 'Generating PDF...');

    double totalStockValue = 0;
    // for (var item in data) {
    //   if (item.stocks != null && item.stocks!.isNotEmpty && item.totalStockValue != null) {
    //     totalStockValue += item.totalStockValue! * item.stocks!.last.productPurchasePrice!.toDouble();
    //   }
    // }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter.copyWith(marginBottom: 1.5 * PdfPageFormat.cm),
        margin: pw.EdgeInsets.symmetric(horizontal: 16),
        header: (pw.Context context) {
          return pw.Center(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  business.data?.companyName.toString() ?? '',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                pw.Text(
                  'Stock Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
              ],
            ),
          );
        },
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
            final stockPrice = (data[i].stocks != null && data[i].stocks!.isNotEmpty) ? data[i].stocks!.last.productPurchasePrice?.toString() ?? '0' : '0';
            tableData.add([
              '${i + 1}',
              data[i].productName ?? 'n/a',
              data[i].stocksSumProductStock?.toString() ?? '0',
              stockPrice,
            ]);
          }

          return [
            pw.SizedBox(height: 16),
            pw.Table.fromTextArray(
              headers: ['SL', 'Product Name', 'Quantity', 'Cost'],
              data: tableData,
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xffC52127),
              ),
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
              columnWidths: {
                0: const pw.FlexColumnWidth(1),
                1: const pw.FlexColumnWidth(3),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
            ),
            pw.Table.fromTextArray(
              border: const pw.TableBorder(
                left: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                right: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xffD9D9D9)),
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(4),
                3: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.center,
                1: pw.Alignment.center,
                2: pw.Alignment.center,
                3: pw.Alignment.center,
              },
              data: [
                [
                  'Total',
                  '',
                  '',
                  isLowStock == true ? totalStockValue.toStringAsFixed(2) : stockValue?.totalStockValue?.toStringAsFixed(2) ?? '0.00',
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
        },
      ),
    );

    // Save the PDF
    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/$appsName-stock-report-$timestamp.pdf');

    await file.writeAsBytes(bytes);

    // Dismiss loading before navigation
    await EasyLoading.dismiss();

    //------print pdf------------------
    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Stock Report',
        usePrinterSettings: true,
        dynamicLayout: true,
        forceCustomPrintPaper: true,
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    }
    // if (context.mounted) {
    //   Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => PDFViewerPage(path: file.path),
    //     ),
    //   );
    // }
  } catch (e) {
    await EasyLoading.dismiss();
    if (context.mounted) {
      EasyLoading.showError('Failed to generate PDF: ${e.toString()}');
    }
    debugPrint('Error during PDF generation: $e');
  }
}
