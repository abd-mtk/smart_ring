import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:smart_ring/smart_ring.dart';
import 'package:smart_ring/smart_ring_platform_interface.dart';
import 'package:smart_ring/smart_ring_method_channel.dart';
import 'package:smart_ring/smart_ring_errors.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSmartRingPlatform
    with MockPlatformInterfaceMixin
    implements SmartRingPlatform {
  @override
  Future<Either<SmartRingFailure, String>> getPlatformVersion() =>
      Future.value(Right('42'));

  @override
  Future<Either<SmartRingFailure, Unit>> startScan() =>
      Future.value(const Right(unit));

  @override
  Future<Either<SmartRingFailure, Unit>> connectToDevice(
    String deviceAddress,
  ) => Future.value(const Right(unit));

  @override
  Future<Either<SmartRingFailure, Unit>> disconnect() =>
      Future.value(const Right(unit));

  @override
  Future<Either<SmartRingFailure, MeasurementStatus>> getMeasurementStatus() =>
      Future.value(
        Right(
          MeasurementStatus(
            temperature: false,
            heartRate: false,
            hrv: false,
            stress: false,
            bloodOxygen: false,
            fullMeasurement: false,
            anyMeasurement: false,
          ),
        ),
      );

  @override
  Future<Either<SmartRingFailure, Unit>> stopAllMeasurements() =>
      Future.value(const Right(unit));

  @override
  Future<Either<SmartRingFailure, bool>> startTemperatureMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Future<Either<SmartRingFailure, bool>> startHeartRateMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Future<Either<SmartRingFailure, bool>> startHrvMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Future<Either<SmartRingFailure, bool>> startStressMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Future<Either<SmartRingFailure, bool>> startBloodOxygenMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Future<Either<SmartRingFailure, bool>> startFullMeasurement({
    int attempts = 2,
  }) => Future.value(const Right(true));

  @override
  Stream<num> get temperatureStream => const Stream.empty();

  @override
  Stream<num> get heartRateStream => const Stream.empty();

  @override
  Stream<num> get realtimeHeartRateStream => const Stream.empty();

  @override
  Stream<num> get hrvStream => const Stream.empty();

  @override
  Stream<num> get stressStream => const Stream.empty();

  @override
  Stream<num> get bloodOxygenStream => const Stream.empty();

  @override
  Stream<MeasurementError> get measurementErrorStream => const Stream.empty();

  @override
  Stream<MeasurementStatus> get measurementStatusStream => const Stream.empty();

  @override
  Stream<bool> get fullMeasurementCompleteStream => const Stream.empty();

  @override
  Stream<ScannedDevice> get deviceScannedStream => const Stream.empty();

  @override
  Stream<void> get scanCompleteStream => const Stream.empty();

  @override
  Stream<ConnectionState> get connectionStateStream => const Stream.empty();

  @override
  Stream<String> get connectionErrorStream => const Stream.empty();

  @override
  Future<Either<SmartRingFailure, Unit>> getBatteryLevel() =>
      Future.value(const Right(unit));

  @override
  Stream<num> get batteryStream => const Stream.empty();

  @override
  Stream<BatteryWarning> get batteryWarningStream => const Stream.empty();

  @override
  Stream<bool> get temperatureTimingStateStream => const Stream.empty();

  @override
  Stream<num> get heartRateTimingIntervalStream => const Stream.empty();

  @override
  Stream<num> get hrvTimingIntervalStream => const Stream.empty();

  @override
  Stream<num> get bloodOxygenTimingIntervalStream => const Stream.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('$MethodChannelSmartRing is the default instance', () {
    final initialPlatform = SmartRingPlatform.instance;
    expect(initialPlatform, isInstanceOf<MethodChannelSmartRing>());
  });

  test('getPlatformVersion', () async {
    MockSmartRingPlatform fakePlatform = MockSmartRingPlatform();
    SmartRingPlatform.instance = fakePlatform;

    SmartRing smartRingPlugin = SmartRing();

    final result = await smartRingPlugin.getPlatformVersion();
    result.fold(
      (failure) => fail('Expected success but got failure: $failure'),
      (version) => expect(version, '42'),
    );
  });
}
