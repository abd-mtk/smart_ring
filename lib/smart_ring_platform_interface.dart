import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:fpdart/fpdart.dart';
import 'dart:async';

import 'smart_ring_method_channel.dart';
import 'smart_ring_errors.dart';

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

  Future<Either<SmartRingFailure, String>> getPlatformVersion();

  // ==================== Connection Methods ====================
  Future<Either<SmartRingFailure, Unit>> startScan();
  Future<Either<SmartRingFailure, Unit>> connectToDevice(String deviceAddress);
  Future<Either<SmartRingFailure, Unit>> disconnect();
  Future<Either<SmartRingFailure, MeasurementStatus>> getMeasurementStatus();
  Future<Either<SmartRingFailure, Unit>> stopAllMeasurements();

  // ==================== Measurement Methods ====================
  Future<Either<SmartRingFailure, bool>> startTemperatureMeasurement({
    int attempts = 2,
  });
  Future<Either<SmartRingFailure, bool>> startHeartRateMeasurement({
    int attempts = 2,
  });
  Future<Either<SmartRingFailure, bool>> startHrvMeasurement({
    int attempts = 2,
  });
  Future<Either<SmartRingFailure, bool>> startStressMeasurement({
    int attempts = 2,
  });
  Future<Either<SmartRingFailure, bool>> startBloodOxygenMeasurement({
    int attempts = 2,
  });
  Future<Either<SmartRingFailure, bool>> startFullMeasurement({
    int attempts = 2,
  });

  // ==================== Measurement Streams ====================
  Stream<num> get temperatureStream;
  Stream<num> get heartRateStream;
  Stream<num> get realtimeHeartRateStream;
  Stream<num> get hrvStream;
  Stream<num> get stressStream;
  Stream<num> get bloodOxygenStream;
  Stream<MeasurementError> get measurementErrorStream;
  Stream<MeasurementStatus> get measurementStatusStream;
  Stream<bool> get fullMeasurementCompleteStream;

  // ==================== Connection Streams ====================
  Stream<ScannedDevice> get deviceScannedStream;
  Stream<void> get scanCompleteStream;
  Stream<ConnectionState> get connectionStateStream;
  Stream<String> get connectionErrorStream;

  // ==================== Battery Methods ====================
  Future<Either<SmartRingFailure, Unit>> getBatteryLevel();
  Stream<num> get batteryStream;
  Stream<BatteryWarning> get batteryWarningStream;

  // ==================== Timing Streams ====================
  Stream<bool> get temperatureTimingStateStream;
  Stream<num> get heartRateTimingIntervalStream;
  Stream<num> get hrvTimingIntervalStream;
  Stream<num> get bloodOxygenTimingIntervalStream;
}

/// Represents a measurement error
class MeasurementError {
  final String type;
  final String? errorType;
  final String errorMessage;

  MeasurementError({
    required this.type,
    this.errorType,
    required this.errorMessage,
  });

  factory MeasurementError.fromJson(Map<String, dynamic> json) {
    return MeasurementError(
      type: json['type'] as String? ?? 'unknown',
      errorType: json['errorType'] as String?,
      errorMessage:
          json['errorMessage'] as String? ??
          json['error'] as String? ??
          'Unknown error',
    );
  }

  @override
  String toString() => 'MeasurementError(type: $type, error: $errorMessage)';
}

/// Represents measurement status
class MeasurementStatus {
  final bool temperature;
  final bool heartRate;
  final bool hrv;
  final bool stress;
  final bool bloodOxygen;
  final bool fullMeasurement;
  final bool anyMeasurement;

  MeasurementStatus({
    required this.temperature,
    required this.heartRate,
    required this.hrv,
    required this.stress,
    required this.bloodOxygen,
    required this.fullMeasurement,
    required this.anyMeasurement,
  });

  factory MeasurementStatus.fromJson(Map<String, dynamic> json) {
    return MeasurementStatus(
      temperature: json['temperature'] as bool? ?? false,
      heartRate: json['heartRate'] as bool? ?? false,
      hrv: json['hrv'] as bool? ?? false,
      stress: json['stress'] as bool? ?? false,
      bloodOxygen: json['bloodOxygen'] as bool? ?? false,
      fullMeasurement: json['fullMeasurement'] as bool? ?? false,
      anyMeasurement: json['anyMeasurement'] as bool? ?? false,
    );
  }
}

/// Represents a scanned device
class ScannedDevice {
  final String name;
  final String address;

  ScannedDevice({required this.name, required this.address});

  factory ScannedDevice.fromJson(Map<String, dynamic> json) {
    return ScannedDevice(
      name: json['name'] as String? ?? 'Unknown',
      address: json['address'] as String? ?? '',
    );
  }
}

/// Represents connection state
enum ConnectionState {
  disconnected(0),
  connecting(1),
  connected(2);

  final int value;
  const ConnectionState(this.value);

  static ConnectionState fromInt(int value) {
    switch (value) {
      case 0:
        return ConnectionState.disconnected;
      case 1:
        return ConnectionState.connecting;
      case 2:
        return ConnectionState.connected;
      default:
        return ConnectionState.disconnected;
    }
  }
}

/// Represents a battery warning
class BatteryWarning {
  final num level;
  final bool charging;
  final String message;

  BatteryWarning({
    required this.level,
    required this.charging,
    required this.message,
  });

  factory BatteryWarning.fromJson(Map<String, dynamic> json) {
    return BatteryWarning(
      level: json['level'] as num? ?? 0,
      charging: json['charging'] as bool? ?? false,
      message: json['message'] as String? ?? 'Battery level critical',
    );
  }
}
