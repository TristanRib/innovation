import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/remedy.dart';

class PdfService {
  Future<void> exportRemedy(Remedy remedy) async {
    final regular = await PdfGoogleFonts.openSansRegular();
    final bold = await PdfGoogleFonts.openSansBold();

    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (_) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Remedia',
                  style: pw.TextStyle(font: bold, fontSize: 10, color: PdfColors.grey500)),
              pw.Text(
                DateFormat('dd/MM/yyyy').format(DateTime.now()),
                style: pw.TextStyle(
                    font: regular, fontSize: 10, color: PdfColors.grey500),
              ),
            ],
          ),
        ),
        build: (_) => [
          pw.Text(remedy.title,
              style: pw.TextStyle(font: bold, fontSize: 20)),
          pw.SizedBox(height: 6),
          if (remedy.tags.isNotEmpty) ...[
            pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: remedy.tags
                  .map((t) => pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          borderRadius: const pw.BorderRadius.all(
                              pw.Radius.circular(10)),
                        ),
                        child: pw.Text(t,
                            style: pw.TextStyle(
                                font: regular,
                                fontSize: 9,
                                color: PdfColors.green900)),
                      ))
                  .toList(),
            ),
            pw.SizedBox(height: 16),
          ],
          pw.Text('Description',
              style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.SizedBox(height: 6),
          pw.Text(remedy.description,
              style: pw.TextStyle(font: regular, fontSize: 11)),
          pw.SizedBox(height: 16),
          pw.Text('Ingrédients',
              style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.SizedBox(height: 6),
          ...remedy.ingredients.map((ing) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('• ',
                        style: pw.TextStyle(font: bold, fontSize: 11)),
                    pw.Expanded(
                        child: pw.Text(ing,
                            style:
                                pw.TextStyle(font: regular, fontSize: 11))),
                  ],
                ),
              )),
          pw.SizedBox(height: 16),
          pw.Text('Préparation',
              style: pw.TextStyle(font: bold, fontSize: 13)),
          pw.SizedBox(height: 6),
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.green50,
              borderRadius:
                  const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(remedy.method,
                style: pw.TextStyle(font: regular, fontSize: 11)),
          ),
          pw.SizedBox(height: 24),
          pw.Text(
            'Par ${remedy.authorName} · Remedia — remèdes naturels & traditionnels',
            style: pw.TextStyle(
                font: regular, fontSize: 9, color: PdfColors.grey400),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: '${remedy.title}.pdf',
    );
  }
}
