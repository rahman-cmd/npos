import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:mobile_pos/constant.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../Screens/Customers/Model/parties_model.dart';
import '../../model/business_info_model.dart';

Future<void> generateTop5CustomerReportPdf(
    BuildContext context, List<Party>? data, BusinessInformationModel? business) async {
  final pw.Document pdf = pw.Document();

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
                  'Top 5 Customers',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    // font: ttf,
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
            final party = data[i];
            tableData.add([
              party.name ?? 'n/a',
              party.phone ?? 'n/a',
              party.email ?? 'n/a',
              formatPointNumber(party.saleCount ?? 0),
            ]);
          }

          return [
            pw.SizedBox(height: 16),

            // Main Table
            pw.Table.fromTextArray(
              headers: [
                "Customer Name",
                "Phone",
                "Email",
                "Total Sales",
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
                4: const pw.FlexColumnWidth(4),
                5: const pw.FlexColumnWidth(4),
                6: const pw.FlexColumnWidth(4),
              },
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.center,
                5: pw.Alignment.center,
                6: pw.Alignment.center,
              },
            ),
          ];
        },
      ),
    );

    final byteData = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$appsName-customer-ledger.pdf');
    await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    EasyLoading.showSuccess('Generate Complete');
    //print pdf
    if (context.mounted) {
      await Printing.layoutPdf(
        name: 'Sales Report',
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
