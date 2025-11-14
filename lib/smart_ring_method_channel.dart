import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import 'smart_ring_platform_interface.dart';
import 'smart_ring_errors.dart';

/// An implementation of [SmartRingPlatform] that uses method channels.
class MethodChannelSmartRing extends SmartRingPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('smart_ring');
  final eventChannel = const EventChannel('smart_ring_events');

  // Stream controllers
  final _temperatureController = StreamController<num>.broadcast();
  final _heartRateController = StreamController<num>.broadcast();
  final _realtimeHeartRateController = StreamController<num>.broadcast();
  final _hrvController = StreamController<num>.broadcast();
  final _stressController = StreamController<num>.broadcast();
  final _bloodOxygenController = StreamController<num>.broadcast();
  final _measurementErrorController =
      StreamController<MeasurementError>.broadcast();
  final _measurementStatusController =
      StreamController<MeasurementStatus>.broadcast();
  final _fullMeasurementCompleteController = StreamController<bool>.broadcast();
  final _deviceScannedController = StreamController<ScannedDevice>.broadcast();
  final _scanCompleteController = StreamController<void>.broadcast();
  final _connectionStateController =
      StreamController<ConnectionState>.broadcast();
  final _connectionErrorController = StreamController<String>.broadcast();
  final _batteryController = StreamController<num>.broadcast();
  final _batteryWarningController =
      StreamController<BatteryWarning>.broadcast();
  final _temperatureTimingStateController = StreamController<bool>.broadcast();
  final _heartRateTimingIntervalController = StreamController<num>.broadcast();
  final _hrvTimingIntervalController = StreamController<num>.broadcast();
  final _bloodOxygenTimingIntervalController =
      StreamController<num>.broadcast();

  StreamSubscription<dynamic>? _eventSubscription;

  MethodChannelSmartRing() {
    _setupEventListeners();
  }

  void _setupEventListeners() {
    _eventSubscription = eventChannel.receiveBroadcastStream().listen((
      dynamic event,
    ) {
      if (event is Map) {
        _processEvent(event['event'] as String?, event['data']);
      }
    }, onError: (error) => debugPrint('Event channel error: $error'));

    methodChannel.setMethodCallHandler((call) async {
      _processEvent(call.method, call.arguments);
    });
  }

  void _processEvent(String? eventType, dynamic data) {
    try {
      switch (eventType) {
        case 'bodyTemperature':
          _addIfNum(data, _temperatureController);
          break;
        case 'heartRate':
          _addIfNum(data, _heartRateController);
          break;
        case 'realtimeHeartRate':
          _addIfNum(data, _realtimeHeartRateController);
          break;
        case 'hrv':
          _addIfNum(data, _hrvController);
          break;
        case 'stress':
          _addIfNum(data, _stressController);
          break;
        case 'bloodOxygen':
          _addIfNum(data, _bloodOxygenController);
          break;
        case 'measurementError':
          _parseJsonAndAdd<MeasurementError>(
            data,
            MeasurementError.fromJson,
            _measurementErrorController,
          );
          break;
        case 'measurementStatus':
          _parseJsonAndAdd<MeasurementStatus>(
            data,
            MeasurementStatus.fromJson,
            _measurementStatusController,
          );
          break;
        case 'fullMeasurementComplete':
          _fullMeasurementCompleteController.add(true);
          break;
        case 'onDeviceScanned':
          _parseDevice(data);
          break;
        case 'onScanComplete':
          _scanCompleteController.add(null);
          break;
        case 'onConnectionStateChanged':
          if (data is String) {
            final state = int.tryParse(data);
            if (state != null) {
              _connectionStateController.add(ConnectionState.fromInt(state));
            }
          }
          break;
        case 'connectionError':
          if (data is String) {
            _connectionErrorController.add(data);
          }
          break;
        case 'onBattery':
        case 'onRealTimeBattery':
          _addIfNum(data, _batteryController);
          break;
        case 'batteryWarning':
          _parseJsonAndAdd<BatteryWarning>(
            data,
            BatteryWarning.fromJson,
            _batteryWarningController,
          );
          break;
        case 'temperatureTimingState':
          if (data is String) {
            _temperatureTimingStateController.add(data.toLowerCase() == 'true');
          }
          break;
        case 'heartRateTimingInterval':
          _addIfNum(data, _heartRateTimingIntervalController);
          break;
        case 'hrvTimingInterval':
          _addIfNum(data, _hrvTimingIntervalController);
          break;
        case 'bloodOxygenTimingInterval':
          _addIfNum(data, _bloodOxygenTimingIntervalController);
          break;
      }
    } catch (e) {
      debugPrint('Error processing event: $e');
    }
  }

  void _addIfNum(dynamic data, StreamController<num> controller) {
    if (data is String) {
      final value = num.tryParse(data);
      if (value != null) controller.add(value);
    }
  }

  void _parseJsonAndAdd<T>(
    dynamic data,
    T Function(Map<String, dynamic>) fromJson,
    StreamController<T> controller,
  ) {
    if (data is! String) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      controller.add(fromJson(json));
    } catch (e) {
      debugPrint('Error parsing JSON: $e');
    }
  }

  void _parseDevice(dynamic data) {
    try {
      if (data is String) {
        final json = jsonDecode(data) as Map<String, dynamic>;
        _deviceScannedController.add(ScannedDevice.fromJson(json));
      } else if (data is Map) {
        _deviceScannedController.add(
          ScannedDevice.fromJson(Map<String, dynamic>.from(data)),
        );
      }
    } catch (e) {
      debugPrint('Error parsing device: $e');
    }
  }

  Exception? _convertPlatformExceptionToCustomException(
    PlatformException error,
    String operation,
  ) {
    final opLower = operation.toLowerCase();

    switch (error.code) {
      case 'BATTERY_ERROR':
        return SmartRingBatteryException(
          type: SmartRingFailureType.battery,
          reasons: [
            error.message ?? 'Battery error',
            error.details?.toString() ?? '',
          ],
        );
      case 'NO_CONNECTION':
        return SmartRingConnectionException(
          type: SmartRingFailureType.connection,
          reasons: [
            error.message ?? 'No connection',
            error.details?.toString() ?? '',
          ],
        );
    }

    if (opLower.contains('scan')) {
      return SmartRingScanException(
        type: SmartRingFailureType.scan,
        reasons: [
          error.message ?? 'Scan error',
          error.details?.toString() ?? '',
        ],
      );
    }

    if (opLower.contains('battery')) {
      return SmartRingBatteryException(
        type: SmartRingFailureType.battery,
        reasons: [
          error.message ?? 'Battery error',
          error.details?.toString() ?? '',
        ],
      );
    }

    if (opLower.contains('connect')) {
      return SmartRingConnectionException(
        type: SmartRingFailureType.connection,
        reasons: [
          error.message ?? 'Connection error',
          error.details?.toString() ?? '',
        ],
      );
    }

    final failureType = _getFailureTypeFromOperation(opLower);
    if (failureType != SmartRingFailureType.unknown) {
      return SmartRingMeasurementException(
        type: failureType,
        reasons: [
          error.message ?? 'Measurement error',
          error.details?.toString() ?? '',
        ],
      );
    }

    return null;
  }

  SmartRingFailureType _getFailureTypeFromOperation(String operation) {
    final opLower = operation.toLowerCase();
    return SmartRingFailureType.values.firstWhere(
      (e) => e.pluginName == opLower,
      orElse: () => SmartRingFailureType.unknown,
    );
  }

  Either<SmartRingFailure, T> _handleError<T>(
    dynamic error,
    String operation,
    SmartRingFailureType defaultType,
  ) {
    switch (error) {
      case SmartRingConnectionException():
        return Left(
          SmartRingFailure(
            type: error.type,
            message: error.message,
            reasons: error.reasons,
          ),
        );

      case SmartRingDecodeException():
        return Left(
          SmartRingFailure(
            type: error.type,
            message: error.message,
            reasons: error.reasons,
          ),
        );

      case SmartRingScanException():
        return Left(
          SmartRingFailure(
            type: error.type,
            message: error.message,
            reasons: error.reasons,
          ),
        );

      case SmartRingBatteryException():
        return Left(
          SmartRingFailure(
            type: error.type,
            message: error.message,
            reasons: error.reasons,
          ),
        );

      case SmartRingMeasurementException():
        return Left(
          SmartRingFailure(
            type: error.type,
            message: error.message,
            reasons: error.reasons,
          ),
        );

      case PlatformException():
        final customException = _convertPlatformExceptionToCustomException(
          error,
          operation,
        );
        if (customException != null) {
          return _handleError<T>(customException, operation, defaultType);
        }

        final reasons = <String>[
          error.code.isNotEmpty ? error.code : 'UNKNOWN_CODE',
          error.message ?? 'No error message',
          if (error.details != null) error.details.toString(),
        ];

        return Left(
          SmartRingFailure(
            type: defaultType,
            message: 'Platform error during $operation',
            reasons: reasons,
          ),
        );

      case FormatException():
        return Left(
          SmartRingFailure(
            type: SmartRingFailureType.unknown,
            message: 'Format error during $operation',
            reasons: [error.message, error.source ?? ''],
          ),
        );

      case Exception():
        return Left(
          SmartRingFailure(
            type: defaultType,
            message: 'Exception during $operation',
            reasons: [error.toString()],
          ),
        );

      default:
        return Left(
          SmartRingFailure(
            type: SmartRingFailureType.unknown,
            message: 'Unknown error during $operation',
            reasons: [error.toString()],
          ),
        );
    }
  }

  @override
  Future<Either<SmartRingFailure, String>> getPlatformVersion() async {
    try {
      final version = await methodChannel.invokeMethod<String>(
        'getPlatformVersion',
      );
      return version != null
          ? Right(version)
          : Left(
              SmartRingFailure(
                type: SmartRingFailureType.platform,
                message: 'Platform version is null',
                reasons: [],
              ),
            );
    } catch (e) {
      return _handleError<String>(
        e,
        'getPlatformVersion',
        SmartRingFailureType.platform,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, Unit>> startScan() async {
    try {
      await methodChannel.invokeMethod('startScan');
      return const Right(unit);
    } catch (e) {
      return _handleError<Unit>(e, 'startScan', SmartRingFailureType.scan);
    }
  }

  @override
  Future<Either<SmartRingFailure, Unit>> connectToDevice(
    String deviceAddress,
  ) async {
    try {
      await methodChannel.invokeMethod('connectToDevice', {
        'deviceAddress': deviceAddress,
      });
      return const Right(unit);
    } catch (e) {
      return _handleError<Unit>(
        e,
        'connectToDevice',
        SmartRingFailureType.connection,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, Unit>> disconnect() async {
    try {
      await methodChannel.invokeMethod('disconnect');
      return const Right(unit);
    } catch (e) {
      return _handleError<Unit>(
        e,
        'disconnect',
        SmartRingFailureType.connection,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, MeasurementStatus>>
  getMeasurementStatus() async {
    try {
      final statusMap = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(
        'getMeasurementStatus',
      );
      if (statusMap != null) {
        try {
          return Right(
            MeasurementStatus.fromJson(Map<String, dynamic>.from(statusMap)),
          );
        } catch (e) {
          throw SmartRingDecodeException(
            type: SmartRingFailureType.unknown,
            reasons: ['Failed to decode measurement status: ${e.toString()}'],
          );
        }
      }
      return Right(
        MeasurementStatus(
          temperature: false,
          heartRate: false,
          hrv: false,
          stress: false,
          bloodOxygen: false,
          fullMeasurement: false,
          anyMeasurement: false,
        ),
      );
    } catch (e) {
      return _handleError<MeasurementStatus>(
        e,
        'getMeasurementStatus',
        SmartRingFailureType.unknown,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, Unit>> stopAllMeasurements() async {
    try {
      await methodChannel.invokeMethod('stopAllMeasurements');
      return const Right(unit);
    } catch (e) {
      return _handleError<Unit>(
        e,
        'stopAllMeasurements',
        SmartRingFailureType.anyMeasurement,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startTemperatureMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startTemperatureMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startTemperatureMeasurement',
        SmartRingFailureType.temperature,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startHeartRateMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startHeartRateMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startHeartRateMeasurement',
        SmartRingFailureType.heartRate,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startHrvMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startHrvMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startHrvMeasurement',
        SmartRingFailureType.hrv,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startStressMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startStressMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startStressMeasurement',
        SmartRingFailureType.stress,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startBloodOxygenMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startBloodOxygenMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startBloodOxygenMeasurement',
        SmartRingFailureType.bloodOxygen,
      );
    }
  }

  @override
  Future<Either<SmartRingFailure, bool>> startFullMeasurement({
    int attempts = 2,
  }) async {
    try {
      final result = await methodChannel.invokeMethod<bool>(
        'startFullMeasurement',
        {'attempts': attempts},
      );
      return Right(result ?? false);
    } catch (e) {
      return _handleError<bool>(
        e,
        'startFullMeasurement',
        SmartRingFailureType.fullMeasurement,
      );
    }
  }

  @override
  Stream<num> get temperatureStream => _temperatureController.stream;

  @override
  Stream<num> get heartRateStream => _heartRateController.stream;

  @override
  Stream<num> get realtimeHeartRateStream =>
      _realtimeHeartRateController.stream;

  @override
  Stream<num> get hrvStream => _hrvController.stream;

  @override
  Stream<num> get stressStream => _stressController.stream;

  @override
  Stream<num> get bloodOxygenStream => _bloodOxygenController.stream;

  @override
  Stream<MeasurementError> get measurementErrorStream =>
      _measurementErrorController.stream;

  @override
  Stream<MeasurementStatus> get measurementStatusStream =>
      _measurementStatusController.stream;

  @override
  Stream<bool> get fullMeasurementCompleteStream =>
      _fullMeasurementCompleteController.stream;

  @override
  Stream<ScannedDevice> get deviceScannedStream =>
      _deviceScannedController.stream;

  @override
  Stream<void> get scanCompleteStream => _scanCompleteController.stream;

  @override
  Stream<ConnectionState> get connectionStateStream =>
      _connectionStateController.stream;

  @override
  Stream<String> get connectionErrorStream => _connectionErrorController.stream;

  @override
  Future<Either<SmartRingFailure, Unit>> getBatteryLevel() async {
    try {
      await methodChannel.invokeMethod('getBatteryLevel');
      return const Right(unit);
    } catch (e) {
      return _handleError<Unit>(
        e,
        'getBatteryLevel',
        SmartRingFailureType.battery,
      );
    }
  }

  @override
  Stream<num> get batteryStream => _batteryController.stream;

  @override
  Stream<BatteryWarning> get batteryWarningStream =>
      _batteryWarningController.stream;

  @override
  Stream<bool> get temperatureTimingStateStream =>
      _temperatureTimingStateController.stream;

  @override
  Stream<num> get heartRateTimingIntervalStream =>
      _heartRateTimingIntervalController.stream;

  @override
  Stream<num> get hrvTimingIntervalStream =>
      _hrvTimingIntervalController.stream;

  @override
  Stream<num> get bloodOxygenTimingIntervalStream =>
      _bloodOxygenTimingIntervalController.stream;

  void dispose() {
    _eventSubscription?.cancel();
    _temperatureController.close();
    _heartRateController.close();
    _realtimeHeartRateController.close();
    _hrvController.close();
    _stressController.close();
    _bloodOxygenController.close();
    _measurementErrorController.close();
    _measurementStatusController.close();
    _fullMeasurementCompleteController.close();
    _deviceScannedController.close();
    _scanCompleteController.close();
    _connectionStateController.close();
    _connectionErrorController.close();
    _batteryController.close();
    _batteryWarningController.close();
    _temperatureTimingStateController.close();
    _heartRateTimingIntervalController.close();
    _hrvTimingIntervalController.close();
    _bloodOxygenTimingIntervalController.close();
  }
}
