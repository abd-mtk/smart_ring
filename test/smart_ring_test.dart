import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ring/smart_ring.dart';
import 'package:smart_ring/smart_ring_platform_interface.dart';
import 'package:smart_ring/smart_ring_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmartRingPlatform
    with MockPlatformInterfaceMixin
    implements SmartRingPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final SmartRingPlatform initialPlatform = SmartRingPlatform.instance;

  test('$MethodChannelSmartRing is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelSmartRing>());
  });

  test('getPlatformVersion', () async {
    SmartRing smartRingPlugin = SmartRing();
    MockSmartRingPlatform fakePlatform = MockSmartRingPlatform();
    SmartRingPlatform.instance = fakePlatform;

    expect(await smartRingPlugin.getPlatformVersion(), '42');
  });
}
