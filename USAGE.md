# How to Use smart_ring Plugin in Your Flutter Project

## Step 1: Add the Plugin to Your Project

Open your Flutter project's `pubspec.yaml` file and add the plugin as a dependency:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  smart_ring:
    git:
      url: https://github.com/YOUR_USERNAME/smart_ring.git
      ref: main
```

**Important:** Replace `YOUR_USERNAME` with your actual GitHub username.

## Step 2: Install Dependencies

Run the following command in your project directory:

```bash
flutter pub get
```

## Step 3: Configure Android Permissions

The plugin automatically includes Bluetooth and location permissions. However, for Android 12+ (API 31+), you need to request runtime permissions in your app.

### Add to your app's `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.BLUETOOTH" />
<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

### Request Runtime Permissions in Your Dart Code:

```dart
import 'package:permission_handler/permission_handler.dart';

// Request permissions
await Permission.bluetoothScan.request();
await Permission.bluetoothConnect.request();
await Permission.location.request();
```

## Step 4: Use the Plugin in Your Code

### Basic Example:

```dart
import 'package:flutter/material.dart';
import 'package:smart_ring/smart_ring.dart';

class SmartRingExample extends StatefulWidget {
  @override
  _SmartRingExampleState createState() => _SmartRingExampleState();
}

class _SmartRingExampleState extends State<SmartRingExample> {
  final SmartRing _smartRing = SmartRing();
  String? _deviceAddress;
  int? _batteryLevel;
  int? _heartRate;

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // Listen for scanned devices
    // Note: You'll need to implement method channel listeners
    // or use the platform interface methods
  }

  Future<void> _startScan() async {
    try {
      await _smartRing.startScan();
      print('Scanning started...');
    } catch (e) {
      print('Error starting scan: $e');
    }
  }

  Future<void> _connectToDevice(String address) async {
    try {
      await _smartRing.connectToDevice(deviceAddress: address);
      setState(() {
        _deviceAddress = address;
      });
    } catch (e) {
      print('Error connecting: $e');
    }
  }

  Future<void> _getBatteryLevel() async {
    try {
      await _smartRing.getBatteryLevel();
    } catch (e) {
      print('Error getting battery: $e');
    }
  }

  Future<void> _startHeartRateMeasurement() async {
    try {
      await _smartRing.startHeartRateMeasurement(attempts: 2);
    } catch (e) {
      print('Error starting measurement: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Smart Ring Example')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _startScan,
            child: Text('Start Scan'),
          ),
          ElevatedButton(
            onPressed: () => _connectToDevice('XX:XX:XX:XX:XX:XX'),
            child: Text('Connect'),
          ),
          ElevatedButton(
            onPressed: _getBatteryLevel,
            child: Text('Get Battery'),
          ),
          ElevatedButton(
            onPressed: _startHeartRateMeasurement,
            child: Text('Measure Heart Rate'),
          ),
          if (_batteryLevel != null)
            Text('Battery: $_batteryLevel%'),
          if (_heartRate != null)
            Text('Heart Rate: $_heartRate bpm'),
        ],
      ),
    );
  }
}
```

## Available Methods

- `startScan()` - Start scanning for nearby devices
- `connectToDevice(deviceAddress: String)` - Connect to a specific device
- `disconnect()` - Disconnect from the current device
- `startTemperatureMeasurement(attempts: int)` - Measure body temperature
- `startHeartRateMeasurement(attempts: int)` - Measure heart rate
- `startHrvMeasurement(attempts: int)` - Measure HRV
- `startStressMeasurement(attempts: int)` - Measure stress level
- `startBloodOxygenMeasurement(attempts: int)` - Measure SpO2
- `startFullMeasurement(attempts: int)` - Run all measurements in sequence
- `getBatteryLevel()` - Get current battery level
- `getMeasurementStatus()` - Get current measurement status
- `stopAllMeasurements()` - Stop all ongoing measurements

## Troubleshooting

### Build Errors

If you encounter build errors related to the AAR file or Maven repository:

1. Make sure you've run `flutter pub get`
2. Clean and rebuild:
   ```bash
   flutter clean
   flutter pub get
   flutter build apk
   ```

### Permission Issues

- Make sure you've requested runtime permissions for Bluetooth and Location
- Check that your `AndroidManifest.xml` includes all required permissions
- For Android 12+, ensure `BLUETOOTH_CONNECT` and `BLUETOOTH_SCAN` permissions are requested at runtime

### Connection Issues

- Ensure Bluetooth is enabled on the device
- Make sure the smart ring is in pairing mode
- Check that location services are enabled (required for BLE scanning on Android)

## Support

For issues, questions, or contributions, please visit the [GitHub repository](https://github.com/YOUR_USERNAME/smart_ring).

