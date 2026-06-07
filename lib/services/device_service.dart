// lib/services/device_service.dart
//
// Manages this display device's persisted code and keeps the TV in sync through
// device-scoped WebSocket updates.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../core/app_environment.dart';
import '../models/models.dart';

class DeviceService extends ChangeNotifier with WidgetsBindingObserver {
  static String get _baseUrl => AppEnvironment.apiBaseUrl;
  static String get _wsUrl => AppEnvironment.realtimeWsUrl;
  static const MethodChannel _deviceInfoChannel =
      MethodChannel('com.flexit.display/device_info');
  static const String _menuConfigCachePrefix = 'cached_menu_config_';
  static const Duration _socketReadyTimeout = Duration(seconds: 3);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 20);

  late String _deviceCode;
  DeviceConfig? _config;
  bool _hasEverPaired = false;
  bool _isLoading = true;
  String? _error;
  String _configStatus = 'waiting for websocket config';
  WebSocketChannel? _socket;
  StreamSubscription? _socketSubscription;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _socketGeneration = 0;
  String _realtimeStatus = 'connecting';
  Map<String, dynamic> _deviceInfo = const {};
  bool _isReportingDeviceInfo = false;
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
  Map<String, dynamic> get deviceInfo => _deviceInfo;

  Future<void> initialize() async {
    _ensureLifecycleObserver();

    try {
      _deviceCode = await _loadOrCreateDeviceCode();
      _deviceInfo = await _loadDeviceInfo();
      _config = await _loadCachedMenuConfig() ?? _unpairedConfig();
      if (_config?.isPaired == true) {
        _hasEverPaired = true;
      }
      _isLoading = false;
      _error = null;
      notifyListeners();
      unawaited(_reportDeviceInfoToBackend());

      _connectRealtime();
    } catch (_) {
      if (!_isDeviceCodeReady) {
        _deviceCode = _generateDeviceCode();
      }
      _deviceInfo = await _loadDeviceInfo();
      _config = _unpairedConfig();
      _isLoading = false;
      _error = null;
      notifyListeners();
      unawaited(_reportDeviceInfoToBackend());
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

  Future<Map<String, dynamic>> _loadDeviceInfo() async {
    try {
      final info = await _deviceInfoChannel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      return Map<String, dynamic>.from(info ?? const {});
    } catch (_) {
      return const {};
    }
  }

  Future<void> _reportDeviceInfoToBackend() async {
    if (_isReportingDeviceInfo || _deviceInfo.isEmpty) return;
    if (!_isDeviceCodeReady) return;

    _isReportingDeviceInfo = true;
    try {
      final endpoint = Uri.parse(
        '$_baseUrl/api/content/device/${Uri.encodeComponent(_deviceCode.trim().toUpperCase())}/metadata',
      );
      await http
          .post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'deviceInfo': _deviceInfo}),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Best-effort metadata sync. Display pairing/config must never depend on it.
    } finally {
      _isReportingDeviceInfo = false;
    }
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
    socket.ready.timeout(_socketReadyTimeout).then((_) {
      if (_disposed || generation != _socketGeneration) {
        socket.sink.close();
        return;
      }

      _socket = socket;
      _error = null;
      _realtimeStatus = 'connected ${Uri.parse(_wsUrl).port}';
      _configStatus = 'requesting websocket config';
      notifyListeners();
      _startPing();
      unawaited(_reportDeviceInfoToBackend());
      _requestConfigOverRealtime();

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

  void _requestConfigOverRealtime() {
    final socket = _socket;
    if (socket == null) return;

    try {
      socket.sink.add(jsonEncode({
        'type': 'DEVICE_CONFIG_REQUEST',
        'data': {'deviceCode': _deviceCode},
      }));
    } catch (_) {}
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

      if (type == 'PONG') return;

      if (type == 'DEVICE_WS_CONNECTED') {
        _configStatus = 'websocket connected';
        unawaited(_reportDeviceInfoToBackend());
        _requestConfigOverRealtime();
        notifyListeners();
        return;
      }

      if (type == 'DEVICE_DELETED') {
        _config = _unpairedConfig();
        _hasEverPaired = false;
        _clearMenuConfigCache();
        _configStatus = 'device deleted';
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
          _saveMenuConfigCache(_config);
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
            _saveMenuConfigCache(_config);
          } else {
            _config = _unpairedConfig();
            _clearMenuConfigCache();
          }
        }

        _configStatus = 'config via websocket';
        _isLoading = false;
        _error = null;
        notifyListeners();
        if (_config?.isPaired == true) {
          unawaited(_reportDeviceInfoToBackend());
        }
      }
    } catch (_) {
      // Ignore malformed realtime payloads so one bad message does not blank TV.
    }
  }

  Future<void> refresh() async {
    _connectRealtime();
    _requestConfigOverRealtime();
  }

  Future<void> useOfflineStartupFallback() async {
    if (!_isDeviceCodeReady) {
      _deviceCode = _generateDeviceCode();
    }
    _config = _hasEverPaired
        ? await _loadCachedMenuConfig() ?? _unpairedConfig()
        : _unpairedConfig();
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

  Future<DeviceConfig?> _loadCachedMenuConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('$_menuConfigCachePrefix$_deviceCode');
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      final cached = DeviceConfig.fromJson(decoded);
      if (!cached.isPaired ||
          cached.displayConfig?.mode != DisplayMode.menuBoard) {
        return null;
      }
      return cached;
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveMenuConfigCache(DeviceConfig? config) async {
    if (config == null ||
        !config.isPaired ||
        config.displayConfig?.mode != DisplayMode.menuBoard) {
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        '$_menuConfigCachePrefix$_deviceCode',
        jsonEncode(config.toJson()),
      );
    } catch (_) {}
  }

  Future<void> _clearMenuConfigCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_menuConfigCachePrefix$_deviceCode');
    } catch (_) {}
  }
}
