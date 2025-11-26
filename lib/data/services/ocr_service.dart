import 'dart:io';
import 'package:dartz/dartz.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:app_contabilidad/core/utils/result.dart';
import 'package:app_contabilidad/core/utils/logger.dart';
import 'package:app_contabilidad/core/errors/failures.dart';

/// Resultado del reconocimiento OCR
class OCRResult {
  final String? amount;
  final DateTime? date;
  final String? description;
  final String fullText;

  const OCRResult({
    this.amount,
    this.date,
    this.description,
    required this.fullText,
  });
}

/// Servicio de reconocimiento óptico de caracteres (OCR)
class OCRService {
  final TextRecognizer _textRecognizer;

  OCRService() : _textRecognizer = TextRecognizer();

  /// Reconoce texto de una imagen
  Future<Result<OCRResult>> recognizeText(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizedText = await _textRecognizer.processImage(inputImage);

      final fullText = recognizedText.text;
      
      // Extraer información del texto reconocido
      final amount = _extractAmount(fullText);
      final date = _extractDate(fullText);
      final description = _extractDescription(fullText);

      return Right(OCRResult(
        amount: amount,
        date: date,
        description: description,
        fullText: fullText,
      ));
    } catch (e) {
      appLogger.e('Error in OCR recognition', error: e);
      return Left(FileFailure('Error al reconocer texto: ${e.toString()}'));
    }
  }

  /// Extrae el monto del texto
  String? _extractAmount(String text) {
    // Buscar patrones de monto: $123.45, 123.45, etc.
    final amountRegex = RegExp(r'[\$]?\s*(\d+[.,]\d{2})');
    final match = amountRegex.firstMatch(text);
    if (match != null) {
      return match.group(1)?.replaceAll(',', '.');
    }
    return null;
  }

  /// Extrae la fecha del texto
  DateTime? _extractDate(String text) {
    // Buscar patrones de fecha: DD/MM/YYYY, MM/DD/YYYY, etc.
    final datePatterns = [
      RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4})'),
      RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})'),
    ];

    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          if (pattern == datePatterns[0]) {
            // DD/MM/YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          } else {
            // YYYY-MM-DD
            final year = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final day = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        } catch (e) {
          continue;
        }
      }
    }
    return null;
  }

  /// Extrae la descripción del texto
  String? _extractDescription(String text) {
    // Tomar las primeras líneas como descripción
    final lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      return lines.first.trim();
    }
    return null;
  }

  /// Libera recursos
  void dispose() {
    _textRecognizer.close();
  }
}

