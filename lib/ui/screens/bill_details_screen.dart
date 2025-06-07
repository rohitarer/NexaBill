import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nexabill/data/bill_data.dart';
import 'package:nexabill/providers/bill_details_provider.dart';
import 'package:nexabill/ui/widgets/bill_card_view.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'dart:io';

class BillDetailsScreen extends ConsumerStatefulWidget {
  final String customerUid;
  final String billNo;

  const BillDetailsScreen({
    super.key,
    required this.customerUid,
    required this.billNo,
  });

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  final GlobalKey _billKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final billAsync = ref.watch(
      billDetailsProvider(
        BillDetailsParams(
          customerUid: widget.customerUid,
          billNo: widget.billNo,
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text("Bill Details")),
      body: billAsync.when(
        data: (_) {
          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: RepaintBoundary(
                  key: _billKey,
                  child: BillCardView(billItems: List.from(BillData.billItems)),
                ),
              ),
              Positioned(
                right: 16,
                top: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _downloadBillAsPdf,
                      child: Image.asset(
                        'assets/icons/download.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _shareBillPdf,
                      child: Image.asset(
                        'assets/icons/share.png',
                        width: 48,
                        height: 48,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error:
            (e, st) => Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Failed to load bill details\n\n$e",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              ),
            ),
      ),
    );
  }

  Future<void> _downloadBillAsPdf() async {
    try {
      RenderRepaintBoundary boundary =
          _billKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
              ),
            );
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
    } catch (e) {
      debugPrint('❌ PDF Generation Error: $e');
    }
  }

  Future<void> _shareBillPdf() async {
    try {
      RenderRepaintBoundary boundary =
          _billKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Center(
              child: pw.Image(
                pdfImage,
                fit: pw.BoxFit.contain,
                width: PdfPageFormat.a4.width,
                height: PdfPageFormat.a4.height,
              ),
            );
          },
        ),
      );

      final output = await getTemporaryDirectory();
      final file = File(
        "${output.path}/bill_${DateTime.now().millisecondsSinceEpoch}.pdf",
      );
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: '🧾 Here is your bill');
    } catch (e) {
      debugPrint('❌ PDF Share Error: $e');
    }
  }
}
