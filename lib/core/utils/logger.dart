import 'dart:io';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Output personalizado que escribe tanto en consola como en archivo
class FileOutput extends LogOutput {
  final File file;
  final bool overrideExisting;
  final Encoding encoding;

  FileOutput({
    required this.file,
    this.overrideExisting = false,
    this.encoding = utf8,
  });

  @override
  Future<void> init() async {
    if (overrideExisting && await file.exists()) {
      await file.delete();
    }
    await file.create(recursive: true);
  }

  @override
  void output(OutputEvent event) {
    final message = event.lines.join('\n');
    try {
      file.writeAsStringSync('$message\n', mode: FileMode.append, encoding: encoding);
    } catch (e) {
      // Si falla escribir al archivo, no hacer nada (solo consola)
    }
  }
}

/// Inicializa el logger con archivo
Future<void> _initLogger() async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final logDir = Directory(p.join(directory.path, 'app_contabilidad', 'logs'));
    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }
    final timestamp = DateTime.now().toIso8601String().split('T')[0]; // YYYY-MM-DD
    final logFile = File(p.join(logDir.path, 'app_$timestamp.log'));
    
    _appLoggerInstance = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
      output: MultiOutput([
        ConsoleOutput(), // Escribe en consola
        FileOutput(file: logFile), // Escribe en archivo
      ]),
    );
  } catch (e) {
    // Si falla, usar solo consola
    _appLoggerInstance = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
}

Logger? _appLoggerInstance;
bool _isInitializing = false;

/// Logger global de la aplicación (se inicializa automáticamente)
Logger get appLogger {
  if (_appLoggerInstance == null && !_isInitializing) {
    _isInitializing = true;
    // Inicializar de forma asíncrona en segundo plano
    _initLogger().then((_) {
      _isInitializing = false;
    }).catchError((e) {
      _isInitializing = false;
      print('Error inicializando logger: $e');
    });
    
    // Mientras tanto, usar logger básico que siempre funciona
    _appLoggerInstance = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  return _appLoggerInstance ?? Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );
}

/// Logger para producción (sin colores ni emojis)
final productionLogger = Logger(
  printer: SimplePrinter(colors: false),
);

