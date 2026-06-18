import 'package:flexit/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('device config preserves subscription entitlement fields', () {
    final config = DeviceConfig.fromJson({
      'deviceCode': 'TV-123',
      'isPaired': true,
      'subscriptionExpiresAt': '2026-07-15T12:30:00.000Z',
      'subscriptionBlocked': false,
      'serverTime': '2026-06-15T12:30:00.000Z',
      'displayConfig': {'mode': 'menuBoard'},
    });

    expect(
      config.subscriptionExpiresAt,
      DateTime.utc(2026, 7, 15, 12, 30),
    );
    expect(config.subscriptionBlocked, isFalse);
    expect(config.serverTime, DateTime.utc(2026, 6, 15, 12, 30));
    expect(
        config.toJson()['subscriptionExpiresAt'], '2026-07-15T12:30:00.000Z');
  });

  test('missing entitlement remains unblocked for legacy cached configs', () {
    final config = DeviceConfig.fromJson({
      'deviceCode': 'TV-LEGACY',
      'isPaired': true,
    });

    expect(config.subscriptionExpiresAt, isNull);
    expect(config.subscriptionBlocked, isFalse);
  });
}
