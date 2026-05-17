import 'package:flutter/services.dart';

import '../models/models.dart';

class LocalMediaService {
  static const _channel = MethodChannel('com.flexit.display/local_media');

  static Future<List<DisplayMediaItem>> scan() async {
    final rawItems = await _channel.invokeMethod<List<dynamic>>(
      'scanLocalMedia',
    );
    final items = rawItems ?? const [];
    return items
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(DisplayMediaItem.fromJson)
        .toList();
  }
}
