import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('parse files', () async {
    final files = [
      'FactoryLink_TRD.pdf',
      'FactoryLink_PRD.pdf',
      'FactoryLink_Factory_Connection_Guide.pdf',
      'FactoryLink_Complete_Plan.pdf',
      'FactoryLink_Technical_Architecture.pdf',
    ];
    for (var path in files) {
      if (await File(path).exists()) {
        try {
          final bytes = await File(path).readAsBytes();
          final document = PdfDocument(inputBytes: bytes);
          final extractor = PdfTextExtractor(document);
          final text = extractor.extractText();
          document.dispose();
          await File('${path}.txt').writeAsString(text);
          print('Extracted $path');
        } catch (e) {
          print('Failed to extract $path: $e');
        }
      } else {
        print('Not found: $path');
      }
    }
  });
}
