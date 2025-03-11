import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_pos/generated/l10n.dart' as lang;
import 'package:share_plus/share_plus.dart';

class PDFViewerPage extends StatefulWidget {
  final String path;

  const PDFViewerPage({super.key, required this.path});

  @override
  PDFViewerPageState createState() => PDFViewerPageState();
}

class PDFViewerPageState extends State<PDFViewerPage> {
  void _sharePDF() async {
    final file = File(widget.path);
    if (file.existsSync()) {
     await Share.shareXFiles([XFile(widget.path)], text: 'Check out this Invoice');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("File Not Found")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.S.of(context).invoiceViewr,
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontSize: 20.0,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _sharePDF, // Call the share function
            color: Colors.black,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PDFView(
              filePath: widget.path,
            ),
          ),
        ],
      ),
    );
  }
}
