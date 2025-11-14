import 'package:flutter/material.dart';
import 'dart:async';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:smart_ring/smart_ring.dart' hide ConnectionState;
import 'package:smart_ring/smart_ring.dart' as smart_ring show ConnectionState;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Ring Tester',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const SmartRingTester(),
    );
  }
}

class SmartRingTester extends StatefulWidget {
  const SmartRingTester({super.key});

  @override
  State<SmartRingTester> createState() => _SmartRingTesterState();
}

class _SmartRingTesterState extends State<SmartRingTester> {
  final _smartRing = SmartRing();

  // Connection state
  smart_ring.ConnectionState _connectionState =
      smart_ring.ConnectionState.disconnected;
  final List<ScannedDevice> _scannedDevices = [];
  bool _isScanning = false;
  String? _connectedDeviceAddress;
  String? _connectionError;

  // Platform
  String _platformVersion = 'Unknown';

  // Battery
  num? _batteryLevel;
  BatteryWarning? _batteryWarning;

  // Measurements
  num? _temperature;
  num? _heartRate;
  num? _realtimeHeartRate;
  num? _hrv;
  num? _stress;
  num? _bloodOxygen;
  MeasurementStatus? _measurementStatus;
  bool _isMeasuring = false;
  String? _lastError;

  // Timing
  bool? _temperatureTimingState;
  num? _heartRateTimingInterval;
  num? _hrvTimingInterval;
  num? _bloodOxygenTimingInterval;

  // Stream subscriptions
  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _initializePlatform();
    _setupStreams();
  }

  Future<void> _initializePlatform() async {
    final result = await _smartRing.getPlatformVersion();
    result.fold(
      (failure) =>
          setState(() => _platformVersion = 'Error: ${failure.message}'),
      (version) => setState(() => _platformVersion = version),
    );
  }

  void _setupStreams() {
    // Connection streams
    _subscriptions.add(
      _smartRing.connectionStateStream.listen((state) {
        setState(() => _connectionState = state);
      }),
    );

    _subscriptions.add(
      _smartRing.deviceScannedStream.listen((device) {
        setState(() {
          if (!_scannedDevices.any((d) => d.address == device.address)) {
            _scannedDevices.add(device);
          }
        });
      }),
    );

    _subscriptions.add(
      _smartRing.scanCompleteStream.listen((_) {
        setState(() => _isScanning = false);
      }),
    );

    _subscriptions.add(
      _smartRing.connectionErrorStream.listen((error) {
        setState(() => _connectionError = error);
        _showSnackBar('Connection Error: $error', isError: true);
      }),
    );

    // Battery streams
    _subscriptions.add(
      _smartRing.batteryStream.listen((battery) {
        setState(() => _batteryLevel = battery);
      }),
    );

    _subscriptions.add(
      _smartRing.batteryWarningStream.listen((warning) {
        setState(() => _batteryWarning = warning);
        _showSnackBar('Battery Warning: ${warning.message}', isError: true);
      }),
    );

    // Measurement streams
    _subscriptions.add(
      _smartRing.temperatureStream.listen((temp) {
        setState(() => _temperature = temp);
      }),
    );

    _subscriptions.add(
      _smartRing.heartRateStream.listen((hr) {
        setState(() => _heartRate = hr);
      }),
    );

    _subscriptions.add(
      _smartRing.realtimeHeartRateStream.listen((hr) {
        setState(() => _realtimeHeartRate = hr);
      }),
    );

    _subscriptions.add(
      _smartRing.hrvStream.listen((hrv) {
        setState(() => _hrv = hrv);
      }),
    );

    _subscriptions.add(
      _smartRing.stressStream.listen((stress) {
        setState(() => _stress = stress);
      }),
    );

    _subscriptions.add(
      _smartRing.bloodOxygenStream.listen((spo2) {
        setState(() => _bloodOxygen = spo2);
      }),
    );

    _subscriptions.add(
      _smartRing.measurementStatusStream.listen((status) {
        setState(() {
          _measurementStatus = status;
          _isMeasuring = status.anyMeasurement;
        });
      }),
    );

    _subscriptions.add(
      _smartRing.measurementErrorStream.listen((error) {
        setState(() => _lastError = '${error.type}: ${error.errorMessage}');
        _showSnackBar(
          'Measurement Error: ${error.errorMessage}',
          isError: true,
        );
      }),
    );

    _subscriptions.add(
      _smartRing.fullMeasurementCompleteStream.listen((_) {
        _showSnackBar('Full measurement completed!', isError: false);
      }),
    );

    // Timing streams
    _subscriptions.add(
      _smartRing.temperatureTimingStateStream.listen((state) {
        setState(() => _temperatureTimingState = state);
      }),
    );

    _subscriptions.add(
      _smartRing.heartRateTimingIntervalStream.listen((interval) {
        setState(() => _heartRateTimingInterval = interval);
      }),
    );

    _subscriptions.add(
      _smartRing.hrvTimingIntervalStream.listen((interval) {
        setState(() => _hrvTimingInterval = interval);
      }),
    );

    _subscriptions.add(
      _smartRing.bloodOxygenTimingIntervalStream.listen((interval) {
        setState(() => _bloodOxygenTimingInterval = interval);
      }),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _startScan() async {
    setState(() {
      _scannedDevices.clear();
      _isScanning = true;
      _connectionError = null;
    });

    final result = await _smartRing.startScan();
    result.fold((failure) {
      setState(() => _isScanning = false);
      _showSnackBar('Scan failed: ${failure.message}', isError: true);
    }, (_) => _showSnackBar('Scan started', isError: false));
  }

  Future<void> _connectToDevice(ScannedDevice device) async {
    final result = await _smartRing.connectToDevice(device.address);
    result.fold(
      (failure) {
        _showSnackBar('Connection failed: ${failure.message}', isError: true);
      },
      (_) {
        setState(() => _connectedDeviceAddress = device.address);
        _showSnackBar('Connecting to ${device.name}...', isError: false);
      },
    );
  }

  Future<void> _disconnect() async {
    final result = await _smartRing.disconnect();
    result.fold(
      (failure) =>
          _showSnackBar('Disconnect failed: ${failure.message}', isError: true),
      (_) {
        setState(() => _connectedDeviceAddress = null);
        _showSnackBar('Disconnected', isError: false);
      },
    );
  }

  Future<void> _getBatteryLevel() async {
    final result = await _smartRing.getBatteryLevel();
    result.fold(
      (failure) => _showSnackBar(
        'Battery request failed: ${failure.message}',
        isError: true,
      ),
      (_) => _showSnackBar('Battery level requested', isError: false),
    );
  }

  Future<void> _getMeasurementStatus() async {
    final result = await _smartRing.getMeasurementStatus();
    result.fold(
      (failure) => _showSnackBar(
        'Status request failed: ${failure.message}',
        isError: true,
      ),
      (status) => setState(() => _measurementStatus = status),
    );
  }

  Future<void> _startMeasurement(
    Future<Either<SmartRingFailure, bool>> Function({int attempts}) measurement,
    String name,
  ) async {
    final result = await measurement(attempts: 2);
    result.fold(
      (failure) =>
          _showSnackBar('$name failed: ${failure.message}', isError: true),
      (success) => _showSnackBar(
        success ? '$name started' : '$name: Another measurement in progress',
        isError: !success,
      ),
    );
  }

  Future<void> _stopAllMeasurements() async {
    final result = await _smartRing.stopAllMeasurements();
    result.fold(
      (failure) =>
          _showSnackBar('Stop failed: ${failure.message}', isError: true),
      (_) => _showSnackBar('All measurements stopped', isError: false),
    );
  }

  @override
  void dispose() {
    for (var subscription in _subscriptions) {
      subscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Ring Tester'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Platform Info
            _buildSection(
              title: 'Platform Info',
              children: [_buildInfoCard('Platform Version', _platformVersion)],
            ),

            // Connection Section
            _buildSection(
              title: 'Connection',
              children: [
                _buildInfoCard(
                  'Connection State',
                  _connectionState.name.toUpperCase(),
                  color: _getConnectionColor(_connectionState),
                ),
                if (_connectionError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last Error',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _connectionError!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _isScanning ? null : _startScan,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(_isScanning ? 'Scanning...' : 'Start Scan'),
                ),
                if (_scannedDevices.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const Text(
                    'Scanned Devices:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ..._scannedDevices.map(
                    (device) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.watch),
                        title: Text(
                          device.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          device.address,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: ElevatedButton(
                          onPressed:
                              _connectionState ==
                                  smart_ring.ConnectionState.connected
                              ? null
                              : () => _connectToDevice(device),
                          child: const Text('Connect'),
                        ),
                        isThreeLine: false,
                      ),
                    ),
                  ),
                ],
                if (_connectedDeviceAddress != null) ...[
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _disconnect,
                    icon: const Icon(Icons.close),
                    label: const Text('Disconnect'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ],
            ),

            // Battery Section
            _buildSection(
              title: 'Battery',
              children: [
                _buildInfoCard(
                  'Battery Level',
                  _batteryLevel != null ? '${_batteryLevel}%' : 'N/A',
                  color: _getBatteryColor(_batteryLevel),
                ),
                if (_batteryWarning != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Battery Warning',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_batteryWarning!.message} (${_batteryWarning!.level}%, Charging: ${_batteryWarning!.charging})',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: _getBatteryLevel,
                  icon: const Icon(Icons.battery_charging_full),
                  label: const Text('Get Battery Level'),
                ),
              ],
            ),

            // Measurement Status
            _buildSection(
              title: 'Measurement Status',
              children: [
                if (_measurementStatus != null)
                  Column(
                    children: [
                      _buildStatusRow(
                        'Temperature',
                        _measurementStatus!.temperature,
                      ),
                      _buildStatusRow(
                        'Heart Rate',
                        _measurementStatus!.heartRate,
                      ),
                      _buildStatusRow('HRV', _measurementStatus!.hrv),
                      _buildStatusRow('Stress', _measurementStatus!.stress),
                      _buildStatusRow(
                        'Blood Oxygen',
                        _measurementStatus!.bloodOxygen,
                      ),
                      _buildStatusRow(
                        'Full Measurement',
                        _measurementStatus!.fullMeasurement,
                      ),
                      _buildStatusRow(
                        'Any Measurement',
                        _measurementStatus!.anyMeasurement,
                      ),
                    ],
                  )
                else
                  const Text('No status available'),
                ElevatedButton.icon(
                  onPressed: _getMeasurementStatus,
                  icon: const Icon(Icons.info),
                  label: const Text('Get Status'),
                ),
              ],
            ),

            // Measurements Section
            _buildSection(
              title: 'Measurements',
              children: [
                // Temperature
                _buildMeasurementCard(
                  'Temperature',
                  _temperature?.toStringAsFixed(1) ?? 'N/A',
                  '°C',
                  Icons.thermostat,
                  () => _startMeasurement(
                    _smartRing.startTemperatureMeasurement,
                    'Temperature',
                  ),
                ),

                // Heart Rate
                _buildMeasurementCard(
                  'Heart Rate',
                  _heartRate?.toString() ?? 'N/A',
                  'BPM',
                  Icons.favorite,
                  () => _startMeasurement(
                    _smartRing.startHeartRateMeasurement,
                    'Heart Rate',
                  ),
                ),

                // Real-time Heart Rate
                if (_realtimeHeartRate != null)
                  _buildInfoCard(
                    'Real-time Heart Rate',
                    '${_realtimeHeartRate} BPM',
                    color: Colors.pink,
                  ),

                // HRV
                _buildMeasurementCard(
                  'HRV',
                  _hrv?.toString() ?? 'N/A',
                  '',
                  Icons.show_chart,
                  () =>
                      _startMeasurement(_smartRing.startHrvMeasurement, 'HRV'),
                ),

                // Stress
                _buildMeasurementCard(
                  'Stress',
                  _stress?.toString() ?? 'N/A',
                  '%',
                  Icons.mood_bad,
                  () => _startMeasurement(
                    _smartRing.startStressMeasurement,
                    'Stress',
                  ),
                  valueColor: _getStressColor(_stress),
                ),

                // Blood Oxygen
                _buildMeasurementCard(
                  'Blood Oxygen (SpO2)',
                  _bloodOxygen?.toString() ?? 'N/A',
                  '%',
                  Icons.air,
                  () => _startMeasurement(
                    _smartRing.startBloodOxygenMeasurement,
                    'Blood Oxygen',
                  ),
                ),

                const SizedBox(height: 16),

                // Full Measurement
                ElevatedButton.icon(
                  onPressed: _isMeasuring
                      ? null
                      : () => _startMeasurement(
                          _smartRing.startFullMeasurement,
                          'Full Measurement',
                        ),
                  icon: _isMeasuring
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(
                    _isMeasuring ? 'Measuring...' : 'Start Full Measurement',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),

                // Stop All
                ElevatedButton.icon(
                  onPressed: _isMeasuring ? _stopAllMeasurements : null,
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop All Measurements'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),

            // Timing Section
            _buildSection(
              title: 'Timing Information',
              children: [
                if (_temperatureTimingState != null)
                  _buildInfoCard(
                    'Temperature Timing',
                    _temperatureTimingState.toString(),
                  ),
                if (_heartRateTimingInterval != null)
                  _buildInfoCard(
                    'Heart Rate Interval',
                    '${_heartRateTimingInterval}',
                  ),
                if (_hrvTimingInterval != null)
                  _buildInfoCard('HRV Interval', '${_hrvTimingInterval}'),
                if (_bloodOxygenTimingInterval != null)
                  _buildInfoCard(
                    'Blood Oxygen Interval',
                    '${_bloodOxygenTimingInterval}',
                  ),
                if (_temperatureTimingState == null &&
                    _heartRateTimingInterval == null &&
                    _hrvTimingInterval == null &&
                    _bloodOxygenTimingInterval == null)
                  const Text('No timing data available'),
              ],
            ),

            // Errors Section
            if (_lastError != null)
              _buildSection(
                title: 'Last Error',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Error',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastError!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          overflow: TextOverflow.visible,
                          softWrap: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            color: status ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementCard(
    String title,
    String value,
    String unit,
    IconData icon,
    VoidCallback onStart, {
    Color? valueColor,
  }) {
    return Card(
      color: Colors.grey[100],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Icon(icon, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '$value $unit',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isMeasuring ? null : onStart,
                child: const Text('Start Measurement'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getConnectionColor(smart_ring.ConnectionState state) {
    switch (state) {
      case smart_ring.ConnectionState.connected:
        return Colors.green;
      case smart_ring.ConnectionState.connecting:
        return Colors.orange;
      case smart_ring.ConnectionState.disconnected:
        return Colors.red;
    }
  }

  Color _getBatteryColor(num? level) {
    if (level == null) return Colors.grey;
    if (level > 50) return Colors.green;
    if (level > 20) return Colors.orange;
    return Colors.red;
  }

  Color _getStressColor(num? stress) {
    if (stress == null) return Colors.grey;
    if (stress < 30) return Colors.green;
    if (stress < 70) return Colors.orange;
    return Colors.red;
  }
}
