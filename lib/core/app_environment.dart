import 'package:flutter/services.dart';

class AppEnvironment {
  AppEnvironment._();

  static const _defaults = {
    'API_BASE_URL': 'http://192.168.29.184:4000',
    'CONTENT_BASE_URL': 'http://192.168.29.184:4002',
    'REALTIME_WS_URL': 'ws://192.168.29.184:4000/realtime-ws',
  };

  static final Map<String, String> _values = Map.of(_defaults);

  static Future<void> load({String fileName = '.env'}) async {
    try {
      final content = await rootBundle.loadString(fileName);
      _values
        ..clear()
        ..addAll(_defaults)
        ..addAll(_parse(content));
    } catch (_) {
      _values
        ..clear()
        ..addAll(_defaults);
    }
  }

  static String get apiBaseUrl => _withoutTrailingSlash(_value('API_BASE_URL'));

  static String get contentBaseUrl =>
      _withoutTrailingSlash(_value('CONTENT_BASE_URL'));

  static String get realtimeWsUrl => _value('REALTIME_WS_URL');

  static String _value(String key) {
    final value = _values[key]?.trim();
    if (value == null || value.isEmpty) return _defaults[key]!;
    return value;
  }

  static String _withoutTrailingSlash(String value) =>
      value.endsWith('/') ? value.substring(0, value.length - 1) : value;

  static Map<String, String> _parse(String content) {
    final parsed = <String, String>{};
    for (final rawLine in content.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final separatorIndex = line.indexOf('=');
      if (separatorIndex <= 0) continue;
      final key = line.substring(0, separatorIndex).trim();
      final value = line.substring(separatorIndex + 1).trim();
      parsed[key] = _stripQuotes(value);
    }
    return parsed;
  }

  static String _stripQuotes(String value) {
    if (value.length < 2) return value;
    final first = value[0];
    final last = value[value.length - 1];
    if ((first == '"' && last == '"') || (first == "'" && last == "'")) {
      return value.substring(1, value.length - 1);
    }
    return value;
  }
}
