/// Abstract base class for failures
sealed class Failure {}

enum SmartRingFailureType {
  platform,
  scan,
  connection,
  battery,
  temperature,
  heartRate,
  hrv,
  stress,
  bloodOxygen,
  fullMeasurement,
  anyMeasurement,
  unknown,
}

extension SmartRingFailureTypeExtension on SmartRingFailureType {
  String get pluginName => switch (this) {
    SmartRingFailureType.platform => 'platform',
    SmartRingFailureType.scan => 'scan',
    SmartRingFailureType.connection => 'connection',
    SmartRingFailureType.battery => 'battery',
    SmartRingFailureType.temperature => 'temperature',
    SmartRingFailureType.heartRate => 'heartrate',
    SmartRingFailureType.hrv => 'hrv',
    SmartRingFailureType.stress => 'stress',
    SmartRingFailureType.bloodOxygen => 'bloodoxygen',
    SmartRingFailureType.fullMeasurement => 'fullmeasurement',
    SmartRingFailureType.anyMeasurement => 'anymeasurement',
    SmartRingFailureType.unknown => 'unknown',
  };
}

/// Smart Ring specific failure
class SmartRingFailure extends Failure {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingFailure({
    required this.type,
    this.message = '',
    this.reasons = const [],
  });

  factory SmartRingFailure.fromJson(Map<String, dynamic> json) {
    return SmartRingFailure(
      type: SmartRingFailureType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SmartRingFailureType.unknown,
      ),
      message: json['message'] ?? '',
      reasons: List<String>.from(json['reasons'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasons};
  }

  @override
  String toString() =>
      'SmartRingFailure(type: $type, message: $message, reasons: $reasons)';
}

/// Smart Ring connection exception
class SmartRingConnectionException implements Exception {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingConnectionException({
    required this.type,
    this.reasons = const [],
    this.message = 'SMART_RING_CONNECTION_ERROR',
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasonString};
  }

  String get reasonString =>
      reasons.isNotEmpty ? reasons.join('\n') : 'NO_REASONS_AVAILABLE';

  @override
  String toString() =>
      'SmartRingConnectionException(type: $type, message: $message, reasons: $reasons)';
}

/// Smart Ring decode exception
class SmartRingDecodeException implements Exception {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingDecodeException({
    required this.type,
    this.reasons = const [],
    this.message = 'SMART_RING_DECODING_ERROR',
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasonString};
  }

  String get reasonString =>
      reasons.isNotEmpty ? reasons.join('\n') : 'NO_REASONS_AVAILABLE';

  @override
  String toString() =>
      'SmartRingDecodeException(type: $type, message: $message, reasons: $reasons)';
}

class SmartRingScanException implements Exception {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingScanException({
    required this.type,
    this.reasons = const [],
    this.message = 'SMART_RING_SCAN_ERROR',
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasonString};
  }

  String get reasonString =>
      reasons.isNotEmpty ? reasons.join('\n') : 'NO_REASONS_AVAILABLE';

  @override
  String toString() =>
      'SmartRingScanException(type: $type, message: $message, reasons: $reasons)';
}

class SmartRingBatteryException implements Exception {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingBatteryException({
    required this.type,
    this.reasons = const [],
    this.message = 'SMART_RING_BATTERY_ERROR',
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasonString};
  }

  String get reasonString =>
      reasons.isNotEmpty ? reasons.join('\n') : 'NO_REASONS_AVAILABLE';

  @override
  String toString() =>
      'SmartRingBatteryException(type: $type, message: $message, reasons: $reasons)';
}

class SmartRingMeasurementException implements Exception {
  final SmartRingFailureType type;
  final List<String> reasons;
  final String message;

  SmartRingMeasurementException({
    required this.type,
    this.reasons = const [],
    this.message = 'SMART_RING_MEASUREMENT_ERROR',
  });

  Map<String, dynamic> toJson() {
    return {'type': type.name, 'message': message, 'reasons': reasonString};
  }

  String get reasonString =>
      reasons.isNotEmpty ? reasons.join('\n') : 'NO_REASONS_AVAILABLE';

  @override
  String toString() =>
      'SmartRingMeasurementException(type: $type, message: $message, reasons: $reasons)';
}
