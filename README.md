# smart_ring

A Flutter plugin for connecting and interacting with smart ring devices via Bluetooth Low Energy (BLE).

## Features

- 🔍 Scan for nearby smart ring devices
- 🔌 Connect and disconnect from devices
- 📊 Measure various health metrics:
  - Body temperature
  - Heart rate
  - HRV (Heart Rate Variability)
  - Stress level
  - Blood oxygen (SpO2)
- 🔋 Battery level monitoring
- 📈 Full measurement sequence support
- ⚙️ Retry mechanism for failed measurements

## Installation

Add this to your package's `pubspec.yaml` file:

### From GitHub (Recommended)

```yaml
dependencies:
  smart_ring:
    git:
      url: https://github.com/YOUR_USERNAME/smart_ring.git
      ref: main  # or use a specific tag/commit
```

Replace `YOUR_USERNAME` with your GitHub username.

### From a specific branch or tag

```yaml
dependencies:
  smart_ring:
    git:
      url: https://github.com/YOUR_USERNAME/smart_ring.git
      ref: v0.0.1  # Use a specific tag
```

Or use a specific commit:

```yaml
dependencies:
  smart_ring:
    git:
      url: https://github.com/YOUR_USERNAME/smart_ring.git
      ref: abc123def456  # Use a specific commit hash
```

### From a local path (for development)

```yaml
dependencies:
  smart_ring:
    path: ../smart_ring
```

## Usage

### Import the package

```dart
import 'package:smart_ring/smart_ring.dart';
```

### Initialize and use

```dart
final smartRing = SmartRing();

// Start scanning for devices
await smartRing.startScan();

// Connect to a device
await smartRing.connectToDevice(deviceAddress: 'XX:XX:XX:XX:XX:XX');

// Start a measurement
await smartRing.startHeartRateMeasurement(attempts: 2);

// Get battery level
await smartRing.getBatteryLevel();

// Disconnect
await smartRing.disconnect();
```

## Platform Support

- ✅ Android (minSdk: 24, compileSdk: 36, Java 17)
- ❌ iOS (not yet implemented)

## Requirements

### Android

- Minimum SDK: 24 (Android 7.0)
- Target SDK: 36
- Java 17
- Bluetooth permissions (automatically included)

### Permissions

The plugin automatically includes the following permissions in `AndroidManifest.xml`:

- `BLUETOOTH`
- `BLUETOOTH_ADMIN`
- `BLUETOOTH_CONNECT`
- `BLUETOOTH_SCAN`
- `BLUETOOTH_ADVERTISE`
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`
- `NEARBY_WIFI_DEVICES`

Make sure to request runtime permissions in your app for location and Bluetooth (Android 12+).

## Example

See the `example/` directory for a complete example app.

## License

See the [LICENSE](LICENSE) file for details.
