import 'package:flutter/foundation.dart';

class ApiLog {
  final String method;
  final String url;
  final int? statusCode;
  final String? requestBody;
  final String? responseBody;
  final DateTime timestamp;

  ApiLog({
    required this.method,
    required this.url,
    this.statusCode,
    this.requestBody,
    this.responseBody,
    required this.timestamp,
  });
}

class LoggingService extends ChangeNotifier {
  final List<ApiLog> _logs = [];

  List<ApiLog> get logs => List.unmodifiable(_logs);

  void addLog({
    required String method,
    required String url,
    int? statusCode,
    String? requestBody,
    String? responseBody,
  }) {
    _logs.insert(
      0,
      ApiLog(
        method: method,
        url: url,
        statusCode: statusCode,
        requestBody: requestBody,
        responseBody: responseBody,
        timestamp: DateTime.now(),
      ),
    );
    if (_logs.length > 100) {
      _logs.removeLast();
    }
    notifyListeners();
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }
}
