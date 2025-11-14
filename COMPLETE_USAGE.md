# Smart Ring Plugin - Complete Usage Guide

This guide demonstrates how to use all features of the Smart Ring plugin including all measurement types, streams, and connection management.

## Table of Contents

1. [Basic Setup](#basic-setup)
2. [Connection Management](#connection-management)
3. [Temperature Measurement](#temperature-measurement)
4. [Heart Rate Measurement](#heart-rate-measurement)
5. [HRV Measurement](#hrv-measurement)
6. [Stress Measurement](#stress-measurement)
7. [Blood Oxygen Measurement](#blood-oxygen-measurement)
8. [Full Measurement](#full-measurement)
9. [Battery Management](#battery-management)
10. [Complete Example](#complete-example)

## Basic Setup

```dart
import 'package:smart_ring/smart_ring.dart';
import 'dart:async';

final SmartRing smartRing = SmartRing();
```

## Connection Management

### Scanning for Devices

```dart
// Start scanning
await smartRing.startScan();

// Listen to scanned devices
smartRing.deviceScannedStream.listen((device) {
  print('Found device: ${device.name} at ${device.address}');
});

// Listen to scan completion
smartRing.scanCompleteStream.listen((_) {
  print('Scan completed');
});
```

### Connecting to a Device

```dart
// Connect to a device
await smartRing.connectToDevice('XX:XX:XX:XX:XX:XX');

// Listen to connection state changes
smartRing.connectionStateStream.listen((state) {
  switch (state) {
    case ConnectionState.disconnected:
      print('Disconnected');
      break;
    case ConnectionState.connecting:
      print('Connecting...');
      break;
    case ConnectionState.connected:
      print('Connected');
      break;
  }
});

// Listen to connection errors
smartRing.connectionErrorStream.listen((error) {
  print('Connection error: $error');
});
```

### Disconnecting

```dart
await smartRing.disconnect();
```

## Temperature Measurement

```dart
// Start measurement
final success = await smartRing.startTemperatureMeasurement(attempts: 3);

// Listen to temperature readings
smartRing.temperatureStream.listen((temperature) {
  print('Temperature: ${temperature.toStringAsFixed(1)}°C');
});

// Listen to errors
smartRing.measurementErrorStream.listen((error) {
  if (error.type == 'temperature') {
    print('Temperature error: ${error.errorMessage}');
  }
});
```

## Heart Rate Measurement

```dart
// Start measurement
final success = await smartRing.startHeartRateMeasurement(attempts: 3);

// Listen to heart rate readings
smartRing.heartRateStream.listen((heartRate) {
  print('Heart Rate: $heartRate BPM');
});

// Listen to real-time heart rate updates
smartRing.realtimeHeartRateStream.listen((heartRate) {
  print('Real-time Heart Rate: $heartRate BPM');
});

// Listen to timing intervals
smartRing.heartRateTimingIntervalStream.listen((interval) {
  print('Heart Rate timing interval: $interval');
});
```

## HRV Measurement

```dart
// Start measurement
final success = await smartRing.startHrvMeasurement(attempts: 3);

// Listen to HRV readings
smartRing.hrvStream.listen((hrv) {
  print('HRV: $hrv');
});

// Listen to timing intervals
smartRing.hrvTimingIntervalStream.listen((interval) {
  print('HRV timing interval: $interval');
});
```

## Stress Measurement

```dart
// Start measurement
final success = await smartRing.startStressMeasurement(attempts: 3);

// Listen to stress readings (0-100)
smartRing.stressStream.listen((stress) {
  print('Stress Level: $stress%');
  if (stress > 70) {
    print('High stress level detected!');
  }
});
```

## Blood Oxygen Measurement

```dart
// Start measurement
final success = await smartRing.startBloodOxygenMeasurement(attempts: 3);

// Listen to SpO2 readings (0-100%)
smartRing.bloodOxygenStream.listen((spo2) {
  print('Blood Oxygen: $spo2%');
});

// Listen to timing intervals
smartRing.bloodOxygenTimingIntervalStream.listen((interval) {
  print('Blood Oxygen timing interval: $interval');
});
```

## Full Measurement

Run all measurements in sequence:

```dart
// Start full measurement sequence
final success = await smartRing.startFullMeasurement(attempts: 3);

// Listen to all measurement streams
smartRing.temperatureStream.listen((temp) {
  print('Temperature: ${temp.toStringAsFixed(1)}°C');
});

smartRing.hrvStream.listen((hrv) {
  print('HRV: $hrv');
});

smartRing.heartRateStream.listen((hr) {
  print('Heart Rate: $hr BPM');
});

smartRing.stressStream.listen((stress) {
  print('Stress: $stress%');
});

smartRing.bloodOxygenStream.listen((spo2) {
  print('SpO2: $spo2%');
});

// Listen to completion
smartRing.fullMeasurementCompleteStream.listen((_) {
  print('Full measurement sequence completed!');
});
```

## Battery Management

```dart
// Request battery level
await smartRing.getBatteryLevel();

// Listen to battery updates
smartRing.batteryStream.listen((battery) {
  print('Battery: $battery%');
});

// Listen to battery warnings (emitted when battery < 15%)
smartRing.batteryWarningStream.listen((warning) {
  print('Battery Warning: ${warning.message}');
  print('Battery Level: ${warning.level}%');
  print('Charging: ${warning.charging}');
});
```

## Measurement Status

```dart
// Get current status
final status = await smartRing.getMeasurementStatus();
print('Temperature measuring: ${status.temperature}');
print('Heart rate measuring: ${status.heartRate}');
print('Any measurement in progress: ${status.anyMeasurement}');

// Listen to status updates
smartRing.measurementStatusStream.listen((status) {
  if (status.temperature) {
    print('Temperature measurement in progress...');
  }
  if (status.anyMeasurement) {
    print('A measurement is currently running');
  }
});
```

## Stop All Measurements

```dart
await smartRing.stopAllMeasurements();
```

## Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:smart_ring/smart_ring.dart';
import 'dart:async';

class SmartRingExample extends StatefulWidget {
  @override
  _SmartRingExampleState createState() => _SmartRingExampleState();
}

class _SmartRingExampleState extends State<SmartRingExample> {
  final SmartRing _smartRing = SmartRing();
  
  // State variables
  List<ScannedDevice> _devices = [];
  ConnectionState _connectionState = ConnectionState.disconnected;
  double? _temperature;
  int? _heartRate;
  int? _hrv;
  int? _stress;
  int? _bloodOxygen;
  int? _battery;
  bool _isScanning = false;
  bool _isMeasuring = false;
  
  // Stream subscriptions
  StreamSubscription<ScannedDevice>? _deviceSub;
  StreamSubscription<ConnectionState>? _connectionSub;
  StreamSubscription<double>? _tempSub;
  StreamSubscription<int>? _hrSub;
  StreamSubscription<int>? _hrvSub;
  StreamSubscription<int>? _stressSub;
  StreamSubscription<int>? _spo2Sub;
  StreamSubscription<int>? _batterySub;
  StreamSubscription<MeasurementStatus>? _statusSub;

  @override
  void initState() {
    super.initState();
    _setupStreams();
  }

  void _setupStreams() {
    // Device scanning
    _deviceSub = _smartRing.deviceScannedStream.listen((device) {
      setState(() {
        if (!_devices.any((d) => d.address == device.address)) {
          _devices.add(device);
        }
      });
    });

    // Connection state
    _connectionSub = _smartRing.connectionStateStream.listen((state) {
      setState(() {
        _connectionState = state;
      });
    });

    // Measurements
    _tempSub = _smartRing.temperatureStream.listen((temp) {
      setState(() => _temperature = temp);
    });

    _hrSub = _smartRing.heartRateStream.listen((hr) {
      setState(() => _heartRate = hr);
    });

    _hrvSub = _smartRing.hrvStream.listen((hrv) {
      setState(() => _hrv = hrv);
    });

    _stressSub = _smartRing.stressStream.listen((stress) {
      setState(() => _stress = stress);
    });

    _spo2Sub = _smartRing.bloodOxygenStream.listen((spo2) {
      setState(() => _bloodOxygen = spo2);
    });

    // Battery
    _batterySub = _smartRing.batteryStream.listen((battery) {
      setState(() => _battery = battery);
    });

    // Status
    _statusSub = _smartRing.measurementStatusStream.listen((status) {
      setState(() => _isMeasuring = status.anyMeasurement);
    });
  }

  Future<void> _startScan() async {
    setState(() {
      _devices.clear();
      _isScanning = true;
    });
    await _smartRing.startScan();
    _smartRing.scanCompleteStream.listen((_) {
      setState(() => _isScanning = false);
    });
  }

  Future<void> _connect(ScannedDevice device) async {
    await _smartRing.connectToDevice(device.address);
  }

  Future<void> _startFullMeasurement() async {
    await _smartRing.startFullMeasurement(attempts: 3);
  }

  Future<void> _getBattery() async {
    await _smartRing.getBatteryLevel();
  }

  @override
  void dispose() {
    _deviceSub?.cancel();
    _connectionSub?.cancel();
    _tempSub?.cancel();
    _hrSub?.cancel();
    _hrvSub?.cancel();
    _stressSub?.cancel();
    _spo2Sub?.cancel();
    _batterySub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Ring Example')),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Connection Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Connection: $_connectionState', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isScanning ? null : _startScan,
                    child: Text(_isScanning ? 'Scanning...' : 'Scan for Devices'),
                  ),
                  if (_devices.isNotEmpty) ...[
                    SizedBox(height: 8),
                    ..._devices.map((device) => ListTile(
                      title: Text(device.name),
                      subtitle: Text(device.address),
                      trailing: ElevatedButton(
                        onPressed: () => _connect(device),
                        child: Text('Connect'),
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
          
          // Battery Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Battery: ${_battery ?? "N/A"}%'),
                  ElevatedButton(
                    onPressed: _getBattery,
                    child: Text('Get Battery'),
                  ),
                ],
              ),
            ),
          ),
          
          // Measurements Section
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Measurements', 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  if (_temperature != null)
                    Text('Temperature: ${_temperature!.toStringAsFixed(1)}°C'),
                  if (_heartRate != null)
                    Text('Heart Rate: $_heartRate BPM'),
                  if (_hrv != null)
                    Text('HRV: $_hrv'),
                  if (_stress != null)
                    Text('Stress: $_stress%'),
                  if (_bloodOxygen != null)
                    Text('SpO2: $_bloodOxygen%'),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _isMeasuring ? null : _startFullMeasurement,
                    child: Text(_isMeasuring ? 'Measuring...' : 'Start Full Measurement'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

## API Reference

### Request Methods

- `Future<void> startScan()` - Start scanning for devices
- `Future<void> connectToDevice(String address)` - Connect to device
- `Future<void> disconnect()` - Disconnect from device
- `Future<MeasurementStatus> getMeasurementStatus()` - Get current status
- `Future<void> stopAllMeasurements()` - Stop all measurements
- `Future<bool> startTemperatureMeasurement({int attempts = 2})` - Start temperature measurement
- `Future<bool> startHeartRateMeasurement({int attempts = 2})` - Start heart rate measurement
- `Future<bool> startHrvMeasurement({int attempts = 2})` - Start HRV measurement
- `Future<bool> startStressMeasurement({int attempts = 2})` - Start stress measurement
- `Future<bool> startBloodOxygenMeasurement({int attempts = 2})` - Start SpO2 measurement
- `Future<bool> startFullMeasurement({int attempts = 2})` - Start full measurement sequence
- `Future<void> getBatteryLevel()` - Request battery level

### Streams

**Measurements:**
- `Stream<double> temperatureStream` - Temperature readings
- `Stream<int> heartRateStream` - Heart rate readings
- `Stream<int> realtimeHeartRateStream` - Real-time heart rate
- `Stream<int> hrvStream` - HRV readings
- `Stream<int> stressStream` - Stress level readings
- `Stream<int> bloodOxygenStream` - SpO2 readings
- `Stream<MeasurementError> measurementErrorStream` - Measurement errors
- `Stream<MeasurementStatus> measurementStatusStream` - Status updates
- `Stream<bool> fullMeasurementCompleteStream` - Full measurement completion

**Connection:**
- `Stream<ScannedDevice> deviceScannedStream` - Scanned devices
- `Stream<void> scanCompleteStream` - Scan completion
- `Stream<ConnectionState> connectionStateStream` - Connection state
- `Stream<String> connectionErrorStream` - Connection errors

**Battery:**
- `Stream<int> batteryStream` - Battery level updates
- `Stream<BatteryWarning> batteryWarningStream` - Battery warnings

**Timing:**
- `Stream<bool> temperatureTimingStateStream` - Temperature timing state
- `Stream<int> heartRateTimingIntervalStream` - Heart rate timing interval
- `Stream<int> hrvTimingIntervalStream` - HRV timing interval
- `Stream<int> bloodOxygenTimingIntervalStream` - SpO2 timing interval

## Best Practices

1. **Always cancel subscriptions** in `dispose()` to prevent memory leaks
2. **Handle errors** by listening to `measurementErrorStream`
3. **Check connection state** before starting measurements
4. **Use measurement status** to show loading indicators
5. **Set appropriate retry attempts** based on your use case
6. **Dispose properly** - cancel all subscriptions when done

