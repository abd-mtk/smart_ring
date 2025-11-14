import 'dart:async';
import 'package:fpdart/fpdart.dart';
import 'smart_ring_platform_interface.dart';
import 'smart_ring_errors.dart';

// Export classes for public use
export 'smart_ring_platform_interface.dart'
    show
        MeasurementError,
        MeasurementStatus,
        ScannedDevice,
        ConnectionState,
        BatteryWarning;
export 'smart_ring_errors.dart'
    show
        Failure,
        SmartRingFailure,
        SmartRingConnectionException,
        SmartRingDecodeException;

/// Main class for interacting with Smart Ring devices
class SmartRing {
  final SmartRingPlatform _platform = SmartRingPlatform.instance;

  /// Get the platform version
  Future<Either<SmartRingFailure, String>> getPlatformVersion() {
    return _platform.getPlatformVersion();
  }

  // ==================== Connection Methods ====================

  /// Start scanning for nearby Smart Ring devices
  Future<Either<SmartRingFailure, Unit>> startScan() {
    return _platform.startScan();
  }

  /// Connect to a Smart Ring device by its address
  ///
  /// [deviceAddress] - The Bluetooth MAC address of the device (e.g., "XX:XX:XX:XX:XX:XX")
  Future<Either<SmartRingFailure, Unit>> connectToDevice(String deviceAddress) {
    return _platform.connectToDevice(deviceAddress);
  }

  /// Disconnect from the currently connected device
  Future<Either<SmartRingFailure, Unit>> disconnect() {
    return _platform.disconnect();
  }

  /// Get the current measurement status
  Future<Either<SmartRingFailure, MeasurementStatus>> getMeasurementStatus() {
    return _platform.getMeasurementStatus();
  }

  /// Stop all ongoing measurements
  Future<Either<SmartRingFailure, Unit>> stopAllMeasurements() {
    return _platform.stopAllMeasurements();
  }

  // ==================== Measurement Methods ====================

  /// Start a temperature measurement
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startTemperatureMeasurement({
    int attempts = 2,
  }) {
    return _platform.startTemperatureMeasurement(attempts: attempts);
  }

  /// Start a heart rate measurement
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startHeartRateMeasurement({
    int attempts = 2,
  }) {
    return _platform.startHeartRateMeasurement(attempts: attempts);
  }

  /// Start an HRV (Heart Rate Variability) measurement
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startHrvMeasurement({
    int attempts = 2,
  }) {
    return _platform.startHrvMeasurement(attempts: attempts);
  }

  /// Start a stress level measurement
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startStressMeasurement({
    int attempts = 2,
  }) {
    return _platform.startStressMeasurement(attempts: attempts);
  }

  /// Start a blood oxygen (SpO2) measurement
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startBloodOxygenMeasurement({
    int attempts = 2,
  }) {
    return _platform.startBloodOxygenMeasurement(attempts: attempts);
  }

  /// Start a full measurement sequence (temperature, HRV, heart rate, stress, blood oxygen)
  ///
  /// [attempts] - Number of retry attempts if measurement fails (default: 2)
  ///
  /// Returns `Either<SmartRingFailure, bool>` where bool is `true` if the measurement was started successfully, `false` if another measurement is in progress
  Future<Either<SmartRingFailure, bool>> startFullMeasurement({
    int attempts = 2,
  }) {
    return _platform.startFullMeasurement(attempts: attempts);
  }

  // ==================== Measurement Streams ====================

  /// Stream of temperature measurements in Celsius (using num type)
  Stream<num> get temperatureStream => _platform.temperatureStream;

  /// Stream of heart rate measurements in BPM (using num type)
  Stream<num> get heartRateStream => _platform.heartRateStream;

  /// Stream of real-time heart rate updates in BPM (using num type)
  Stream<num> get realtimeHeartRateStream => _platform.realtimeHeartRateStream;

  /// Stream of HRV (Heart Rate Variability) measurements (using num type)
  Stream<num> get hrvStream => _platform.hrvStream;

  /// Stream of stress level measurements (0-100) (using num type)
  Stream<num> get stressStream => _platform.stressStream;

  /// Stream of blood oxygen (SpO2) measurements in percentage (0-100) (using num type)
  Stream<num> get bloodOxygenStream => _platform.bloodOxygenStream;

  /// Stream of measurement errors
  Stream<MeasurementError> get measurementErrorStream =>
      _platform.measurementErrorStream;

  /// Stream of measurement status updates
  Stream<MeasurementStatus> get measurementStatusStream =>
      _platform.measurementStatusStream;

  /// Stream that emits when full measurement sequence is complete
  Stream<bool> get fullMeasurementCompleteStream =>
      _platform.fullMeasurementCompleteStream;

  // ==================== Connection Streams ====================

  /// Stream of scanned devices
  Stream<ScannedDevice> get deviceScannedStream =>
      _platform.deviceScannedStream;

  /// Stream that emits when device scan is complete
  Stream<void> get scanCompleteStream => _platform.scanCompleteStream;

  /// Stream of connection state changes
  Stream<ConnectionState> get connectionStateStream =>
      _platform.connectionStateStream;

  /// Stream of connection errors
  Stream<String> get connectionErrorStream => _platform.connectionErrorStream;

  // ==================== Battery Methods ====================

  /// Request the current battery level from the device
  Future<Either<SmartRingFailure, Unit>> getBatteryLevel() {
    return _platform.getBatteryLevel();
  }

  /// Stream of battery level updates (0-100) (using num type)
  Stream<num> get batteryStream => _platform.batteryStream;

  /// Stream of battery warnings (emitted when battery is low)
  Stream<BatteryWarning> get batteryWarningStream =>
      _platform.batteryWarningStream;

  // ==================== Timing Streams ====================

  /// Stream of temperature timing state changes
  Stream<bool> get temperatureTimingStateStream =>
      _platform.temperatureTimingStateStream;

  /// Stream of heart rate timing interval updates (using num type)
  Stream<num> get heartRateTimingIntervalStream =>
      _platform.heartRateTimingIntervalStream;

  /// Stream of HRV timing interval updates (using num type)
  Stream<num> get hrvTimingIntervalStream => _platform.hrvTimingIntervalStream;

  /// Stream of blood oxygen timing interval updates (using num type)
  Stream<num> get bloodOxygenTimingIntervalStream =>
      _platform.bloodOxygenTimingIntervalStream;
}
