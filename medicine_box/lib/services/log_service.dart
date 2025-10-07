import 'dart:io';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';

class FileLogOutput extends LogOutput {
  late File _file;

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _file = File('${dir.path}/app_logs.txt');
  }

  @override
  void output(OutputEvent event) {
    final lines = event.lines.join('\n');
    _file.writeAsStringSync(
      '${DateTime.now().toIso8601String()} — $lines\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}

class LogService {
  static final LogService _instance = LogService._internal();
  factory LogService() => _instance;
  LogService._internal();

  late final Logger logger;
  late final FileLogOutput fileOutput;

  Future<void> init() async {
    fileOutput = FileLogOutput();
    await fileOutput.init();

    logger = Logger(
      printer: PrettyPrinter(
        methodCount: 0,
        colors: false,
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      output: fileOutput,
      level: Level.debug,
    );
  }
}
