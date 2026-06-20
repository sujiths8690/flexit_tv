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
  static const MethodChannel _subscriptionChannel =
      MethodChannel('com.flexit.display/subscription');
  static const String _menuConfigCachePrefix = 'cached_menu_config_';
  static const Duration _socketReadyTimeout = Duration(seconds: 3);
  static const Duration _reconnectDelay = Duration(seconds: 5);
  static const Duration _pingInterval = Duration(seconds: 20);
  static const Duration _unpairedPollInterval = Duration(seconds: 7);
  static const Duration _pairedRealtimePollInterval = Duration(minutes: 10);
  static const Duration _pairedOfflinePollInterval = Duration(seconds: 45);

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
  Timer? _configPollTimer;
  Timer? _subscriptionTimer;
  int _socketGeneration = 0;
  String _realtimeStatus = 'connecting';
  Map<String, dynamic> _deviceInfo = const {};
  bool _isReportingDeviceInfo = false;
  bool _disposed = false;
  bool _isObservingLifecycle = false;
  bool _isSubscriptionExpired = false;
  bool _backendConfirmedDeleted = false;

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
  bool get isSubscriptionExpired => _isSubscriptionExpired;
  bool get _hasOpenRealtime => _socket != null;

  Future<void> initialize() async {
    _ensureLifecycleObserver();

    try {
      _deviceCode = await _loadOrCreateDeviceCode();
      await _refreshSubscriptionState();
      _startSubscriptionTimer();
      _deviceInfo = await _loadDeviceInfo();
      _startConfigPollTimer();
      _config = await _loadCachedMenuConfig() ?? _unpairedConfig();
      if (_config?.isPaired == true) {
        _hasEverPaired = true;
        unawaited(_storeSubscriptionEntitlement(_config!));
      }
      await _verifyPairingWithBackend();
      unawaited(_refreshConfigFromBackend());
      _isLoading = false;
      _error = null;
      notifyListeners();
      unawaited(_reportDeviceInfoToBackend());

      _connectRealtime();
    } catch (_) {
      if (!_isDeviceCodeReady) {
        _deviceCode = _generateDeviceCode();
      }
      await _refreshSubscriptionState();
      _startSubscriptionTimer();
      _deviceInfo = await _loadDeviceInfo();
      _startConfigPollTimer();
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

  Future<bool?> _verifyPairingWithBackend() async {
    if (!_isDeviceCodeReady) return null;

    try {
      final endpoint = Uri.parse(
        '$_baseUrl/api/content/device/${Uri.encodeComponent(_deviceCode.trim().toUpperCase())}/pairing-status',
      );
      final response =
          await http.get(endpoint).timeout(const Duration(seconds: 3));
      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return null;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      final isPaired = data['isPaired'];
      if (isPaired is! bool) return null;

      _backendConfirmedDeleted = !isPaired;
      if (!isPaired) {
        _config = _unpairedConfig();
        _hasEverPaired = false;
        await _clearMenuConfigCache();
        if (!_disposed) notifyListeners();
      }
      return isPaired;
    } catch (_) {
      // Offline startup keeps the last paired menu until the backend is reachable.
      return null;
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
      unawaited(_verifyPairingWithBackend());

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

  void _startSubscriptionTimer() {
    _subscriptionTimer?.cancel();
    _subscriptionTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      unawaited(_refreshSubscriptionState());
    });
  }

  void _startConfigPollTimer() {
    _configPollTimer?.cancel();
    _configPollTimer = Timer(_nextConfigPollInterval(), _runConfigPoll);
  }

  Duration _nextConfigPollInterval() {
    if (!isPaired) return _unpairedPollInterval;
    if (_hasOpenRealtime) return _pairedRealtimePollInterval;
    return _pairedOfflinePollInterval;
  }

  Future<void> _runConfigPoll() async {
    if (_disposed) return;

    if (!isPaired) {
      final isPaired = await _verifyPairingWithBackend();
      if (isPaired == true) {
        await _refreshConfigFromBackend();
      } else {
        _requestConfigOverRealtime();
      }
    } else if (_hasOpenRealtime) {
      await _verifyPairingWithBackend();
      _requestConfigOverRealtime();
    } else {
      await _verifyPairingWithBackend();
      await _refreshConfigFromBackend();
    }

    if (!_disposed) _startConfigPollTimer();
  }

  Future<void> _refreshSubscriptionState() async {
    try {
      final status = await _subscriptionChannel
          .invokeMapMethod<String, dynamic>('getStatus');
      final expired = status?['expired'] == true;
      if (_isSubscriptionExpired == expired) return;
      _isSubscriptionExpired = expired;
      if (!_disposed) notifyListeners();
    } catch (_) {
      // Unsupported platforms keep the last trusted in-memory state.
    }
  }

  Future<void> _storeSubscriptionEntitlement(DeviceConfig config) async {
    final expiresAt = config.subscriptionExpiresAt;
    final serverTime = config.serverTime;
    try {
      final status =
          await _subscriptionChannel.invokeMapMethod<String, dynamic>(
        'updateEntitlement',
        {
          'deviceCode': config.deviceCode,
          'expiresAtMillis': expiresAt?.millisecondsSinceEpoch,
          'blocked': config.subscriptionBlocked,
          'serverTimeMillis': serverTime?.millisecondsSinceEpoch ??
              DateTime.now().millisecondsSinceEpoch,
        },
      );
      final expired = status?['expired'] == true;
      if (_isSubscriptionExpired != expired) {
        _isSubscriptionExpired = expired;
        if (!_disposed) notifyListeners();
      }
    } catch (_) {
      final now = serverTime ?? DateTime.now();
      final expired = config.subscriptionBlocked ||
          (expiresAt != null && !expiresAt.isAfter(now));
      if (_isSubscriptionExpired != expired) {
        _isSubscriptionExpired = expired;
        if (!_disposed) notifyListeners();
      }
    }
  }

  Future<void> _refreshConfigFromBackend() async {
    if (!_isDeviceCodeReady || _disposed) return;

    try {
      final endpoint = Uri.parse(
        '$_baseUrl/api/content/device/${Uri.encodeComponent(_deviceCode.trim().toUpperCase())}/config',
      );
      final response =
          await http.get(endpoint).timeout(const Duration(seconds: 5));
      if (response.statusCode < 200 || response.statusCode >= 300) return;

      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return;
      final data = body['data'];
      if (data is! Map<String, dynamic>) return;

      _handleRealtimeMessage(
        jsonEncode({'type': 'DEVICE_CONFIG_UPDATED', 'data': data}),
      );
    } catch (_) {
      // Realtime/cached config keeps the display running when polling is offline.
    }
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
        _backendConfirmedDeleted = true;
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
        if (data['isPaired'] == true && _backendConfirmedDeleted) {
          unawaited(_acceptPairedConfigAfterVerification(data));
          return;
        }
        if (data['isPaired'] == true) {
          _hasEverPaired = true;
        }

        try {
          _config = DeviceConfig.fromJson(data);
          unawaited(_storeSubscriptionEntitlement(_config!));
          _saveMenuConfigCache(_config);
        } catch (_) {
          if (data['isPaired'] == true) {
            _config = DeviceConfig(
              deviceCode: data['deviceCode']?.toString() ?? _deviceCode,
              isPaired: true,
              businessName: data['businessName'] as String?,
              businessLogoUrl: data['businessLogoUrl'] as String?,
              subscriptionExpiresAt: DateTime.tryParse(
                data['subscriptionExpiresAt']?.toString() ?? '',
              ),
              subscriptionBlocked:
                  data['subscriptionBlocked'] as bool? ?? false,
              serverTime:
                  DateTime.tryParse(data['serverTime']?.toString() ?? ''),
              orientation: _config?.orientation ?? DisplayOrientation.normal,
              menuTheme: _config?.menuTheme,
              themeColor: _config?.themeColor ?? 'gold',
              displayConfig: _config?.displayConfig,
            );
            unawaited(_storeSubscriptionEntitlement(_config!));
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

  Future<void> _acceptPairedConfigAfterVerification(
    Map<String, dynamic> data,
  ) async {
    final isPaired = await _verifyPairingWithBackend();
    if (isPaired != true || _disposed) return;
    _handleRealtimeMessage(
      jsonEncode({'type': 'DEVICE_CONFIG_UPDATED', 'data': data}),
    );
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
    _configPollTimer?.cancel();
    _subscriptionTimer?.cancel();
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
