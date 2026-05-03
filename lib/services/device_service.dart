// lib/services/device_service.dart
//
// Manages this display device's persisted code and polls the backend until it
// is paired with a business.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class DeviceService extends ChangeNotifier {
  static const String _baseUrl = 'http://192.168.29.184:3000';
  static const Duration _pollInterval = Duration(seconds: 5);
  static const Duration _requestTimeout = Duration(seconds: 3);

  late String _deviceCode;
  DeviceConfig? _config;
  bool _isLoading = true;
  String? _error;
  Timer? _pollTimer;

  String get deviceCode => _deviceCode;
  DeviceConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPaired => _config?.isPaired ?? false;

  Future<void> initialize() async {
    _deviceCode = await _loadOrCreateDeviceCode();
    await _fetchConfig();
    _startPolling();
  }

  Future<String> _loadOrCreateDeviceCode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('deviceCode');
    if (savedCode != null && savedCode.isNotEmpty) {
      return savedCode;
    }

    final code = _generateDeviceCode();
    await prefs.setString('deviceCode', code);
    return code;
  }

  String _generateDeviceCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(12, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _fetchConfig());
  }

  Future<void> _fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/device/$_deviceCode/config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        _config = data is Map<String, dynamic>
            ? DeviceConfig.fromJson(data)
            : _unpairedConfig();
      } else {
        _config = _unpairedConfig();
      }

      _isLoading = false;
      _error = null;
    } catch (_) {
      _config = _unpairedConfig();
      _isLoading = false;
      _error = null;
    }
    notifyListeners();
  }

  Future<void> refresh() => _fetchConfig();

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  DeviceConfig _unpairedConfig() {
    return DeviceConfig(
      deviceCode: _deviceCode,
      isPaired: false,
      orientation: DisplayOrientation.normal,
    );
  }
}
