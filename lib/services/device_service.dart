// lib/services/device_service.dart
//
// Manages this display device's persisted code and keeps the TV in sync through
// device-scoped WebSocket updates.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/models.dart';

class DeviceService extends ChangeNotifier with WidgetsBindingObserver {
  static const String _baseUrl = 'http://192.168.29.184:4000';
  static const String _wsUrl = 'ws://192.168.29.184:4000/realtime-ws';
  static const Duration _requestTimeout = Duration(seconds: 3);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 20);

  late String _deviceCode;
  DeviceConfig? _config;
  bool _hasEverPaired = false;
  bool _isLoading = true;
  String? _error;
  String _configStatus = 'config not loaded';
  WebSocketChannel? _socket;
  StreamSubscription? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _socketGeneration = 0;
  String _realtimeStatus = 'connecting';
  bool _disposed = false;
  bool _isObservingLifecycle = false;

  String get deviceCode => _deviceCode;
  DeviceConfig? get config => _config;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isPaired => _config?.isPaired ?? false;
  String get realtimeStatus => _realtimeStatus;
  String get configStatus => _configStatus;
  String get backendEndpoint => _baseUrl;
  String get realtimeEndpoint => _wsUrl;

  Future<void> initialize() async {
    _ensureLifecycleObserver();

    try {
      _deviceCode = await _loadOrCreateDeviceCode();
      _config = _unpairedConfig();
      _isLoading = false;
      _error = null;
      notifyListeners();

      await _fetchConfig();
      _connectRealtime();
    } catch (_) {
      if (!_isDeviceCodeReady) {
        _deviceCode = _generateDeviceCode();
      }
      _config = _unpairedConfig();
      _isLoading = false;
      _error = null;
      notifyListeners();
      _connectRealtime();
    }
  }

  void _ensureLifecycleObserver() {
    if (_isObservingLifecycle) return;
    WidgetsBinding.instance.addObserver(this);
    _isObservingLifecycle = true;
  }

  bool get _isDeviceCodeReady {
    try {
      _deviceCode;
      return true;
    } catch (_) {
      return false;
    }
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

  Future<void> _fetchConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/content/device/$_deviceCode/config'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(_requestTimeout);

      _configStatus = 'config ${response.statusCode}';

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          _config = DeviceConfig.fromJson(data);
          if (_config?.isPaired == true) {
            _hasEverPaired = true;
          }
        } else {
          _config = _hasEverPaired ? _offlinePairedConfig() : _unpairedConfig();
        }
      } else {
        _config = _hasEverPaired ? _offlinePairedConfig() : _unpairedConfig();
      }

      _isLoading = false;
      _error = null;
    } catch (_) {
      _configStatus = 'config unavailable';
      _config = _hasEverPaired ? _offlinePairedConfig() : _unpairedConfig();
      _isLoading = false;
      _error = null;
    }
    notifyListeners();
  }

  void _connectRealtime() {
    if (_disposed) return;
    final generation = ++_socketGeneration;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    final previousSocket = _socket;
    _socket = null;
    previousSocket?.sink.close();

    _realtimeStatus = 'connecting ${Uri.parse(_wsUrl).port}';
    notifyListeners();

    final uri = Uri.parse(_wsUrl).replace(
      queryParameters: {'deviceCode': _deviceCode.trim().toUpperCase()},
    );

    final socket = WebSocketChannel.connect(uri);
    socket.ready.timeout(_requestTimeout).then((_) {
      if (_disposed || generation != _socketGeneration) {
        socket.sink.close();
        return;
      }

      _socket = socket;
      _error = null;
      _realtimeStatus = 'connected ${Uri.parse(_wsUrl).port}';
      notifyListeners();
      _startPing();

      _socketSubscription = socket.stream.listen(
        _handleRealtimeMessage,
        onDone: () {
          if (_socket == socket && generation == _socketGeneration) {
            _scheduleReconnect();
          }
        },
        onError: (_) {
          if (_socket == socket && generation == _socketGeneration) {
            _scheduleReconnect();
          }
        },
        cancelOnError: true,
      );
    }).catchError((_) {
      socket.sink.close();
      if (!_disposed && generation == _socketGeneration) {
        _scheduleReconnect();
      }
    });
  }

  void _startPing() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(_pingInterval, (_) {
      final socket = _socket;
      if (socket != null) {
        socket.sink.add(jsonEncode({'type': 'PING'}));
      }
    });
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    _socket?.sink.close();
    _socket = null;
    _socketSubscription = null;
    _realtimeStatus = 'retrying ${Uri.parse(_wsUrl).port}';
    notifyListeners();

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay, () async {
      if (_disposed) return;
      if (!_disposed) _connectRealtime();
    });
  }

  void _disconnectRealtime({bool notify = true}) {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    try {
      _socket?.sink.add(jsonEncode({'type': 'DEVICE_DISCONNECT'}));
    } catch (_) {}
    _socket?.sink.close();
    _socket = null;
    _socketSubscription = null;
    _realtimeStatus = 'disconnected';
    if (notify) notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;

    if (state == AppLifecycleState.resumed) {
      _connectRealtime();
      _fetchConfig();
      return;
    }

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _socketGeneration++;
      _disconnectRealtime();
    }
  }

  void _handleRealtimeMessage(dynamic raw) {
    try {
      final message = jsonDecode(raw.toString()) as Map<String, dynamic>;
      final type = message['type']?.toString();
      final data = message['data'];

      if (type == 'PONG' || type == 'DEVICE_WS_CONNECTED') return;

      if (type == 'DEVICE_DELETED') {
        _config = _unpairedConfig();
        _hasEverPaired = false;
        _isLoading = false;
        _error = null;
        notifyListeners();
        return;
      }

      if (type == 'DEVICE_CONFIG_UPDATED' && data is Map<String, dynamic>) {
        if (data['isPaired'] == true) {
          _hasEverPaired = true;
        }

        try {
          _config = DeviceConfig.fromJson(data);
        } catch (_) {
          if (data['isPaired'] == true) {
            _config = DeviceConfig(
              deviceCode: data['deviceCode']?.toString() ?? _deviceCode,
              isPaired: true,
              businessName: data['businessName'] as String?,
              businessLogoUrl: data['businessLogoUrl'] as String?,
              orientation: _config?.orientation ?? DisplayOrientation.normal,
              menuTheme: _config?.menuTheme,
              themeColor: _config?.themeColor ?? 'gold',
              displayConfig: _config?.displayConfig,
            );
          } else {
            _config = _unpairedConfig();
          }
        }

        _isLoading = false;
        _error = null;
        notifyListeners();
      }
    } catch (_) {
      // Ignore malformed realtime payloads so one bad message does not blank TV.
    }
  }

  Future<void> refresh() async {
    _connectRealtime();
  }

  void useOfflineStartupFallback() {
    if (!_isDeviceCodeReady) {
      _deviceCode = _generateDeviceCode();
    }
    _config = _hasEverPaired ? _offlinePairedConfig() : _unpairedConfig();
    _isLoading = false;
    _error = null;
    notifyListeners();
    _connectRealtime();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_isObservingLifecycle) {
      WidgetsBinding.instance.removeObserver(this);
      _isObservingLifecycle = false;
    }
    _socketGeneration++;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _socketSubscription?.cancel();
    _disconnectRealtime(notify: false);
    super.dispose();
  }

  DeviceConfig _unpairedConfig() {
    return DeviceConfig(
      deviceCode: _deviceCode,
      isPaired: false,
      orientation: DisplayOrientation.normal,
    );
  }

  DeviceConfig _offlinePairedConfig() {
    return DeviceConfig(
      deviceCode: _deviceCode,
      isPaired: true,
      businessName: _config?.businessName,
      businessLogoUrl: _config?.businessLogoUrl,
      orientation: _config?.orientation ?? DisplayOrientation.normal,
      menuTheme: _config?.menuTheme,
      themeColor: _config?.themeColor ?? 'gold',
      displayConfig: null,
    );
  }
}
