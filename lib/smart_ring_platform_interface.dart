import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'smart_ring_method_channel.dart';

abstract class SmartRingPlatform extends PlatformInterface {
  /// Constructs a SmartRingPlatform.
  SmartRingPlatform() : super(token: _token);

  static final Object _token = Object();

  static SmartRingPlatform _instance = MethodChannelSmartRing();

  /// The default instance of [SmartRingPlatform] to use.
  ///
  /// Defaults to [MethodChannelSmartRing].
  static SmartRingPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [SmartRingPlatform] when
  /// they register themselves.
  static set instance(SmartRingPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
