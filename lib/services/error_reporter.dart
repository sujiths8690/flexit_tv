import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ErrorReporter {
  ErrorReporter._();

  static const _baseUrl = 'http://192.168.29.184:4000';

  static Future<void> report(
    Object error,
    StackTrace? stackTrace, {
    String severity = 'medium',
  }) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/api/user-activity/errors'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'source': 'flutter_tv_app',
          'errorType': 'tv',
          'severity': severity,
          'status': 'open',
          'message': error.toString(),
          'stackTrace': stackTrace?.toString(),
          'appVersion': '1.0.0+1',
          'environment': {
            'platform': defaultTargetPlatform.name,
            'debug': kDebugMode,
          },
        }),
      );
    } catch (_) {}
  }
}
