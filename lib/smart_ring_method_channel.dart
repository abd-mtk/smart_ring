import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'smart_ring_platform_interface.dart';

/// An implementation of [SmartRingPlatform] that uses method channels.
class MethodChannelSmartRing extends SmartRingPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('smart_ring');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
