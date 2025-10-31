import 'dart:developer' as developer;
import 'dart:io';

Future<void> logGeoapifyNoMatch(
  String query,
  Uri requestUri,
  String responseBody,
) async {
  final formattedMessage = StringBuffer()
    ..writeln('Geoapify lookup returned no matches.')
    ..writeln('Request: GET $requestUri')
    ..writeln('Query: $query')
    ..writeln('Response: $responseBody');

  developer.log(
    formattedMessage.toString(),
    name: 'GeoapifyService',
  );

  final timestamp = DateTime.now().toIso8601String();
  final buffer = StringBuffer()
    ..writeln('[$timestamp] Geoapify lookup returned no matches.')
    ..writeln('Request: GET $requestUri')
    ..writeln('Query: $query')
    ..writeln('Response: $responseBody')
    ..writeln();

  final logFilePath =
      '${Directory.systemTemp.path}${Platform.pathSeparator}geoapify_service.log';
  final logFile = File(logFilePath);

  try {
    await logFile.writeAsString(
      buffer.toString(),
      mode: FileMode.append,
      flush: true,
    );
  } catch (error, stackTrace) {
    developer.log(
      'Failed to write Geoapify log file: $error',
      name: 'GeoapifyService',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
