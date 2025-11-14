package com.manzo.smart_ring;

import androidx.annotation.NonNull;
import android.content.Context;
import android.util.Log;
import org.json.JSONObject;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.HashMap;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

import com.crrepa.ble.CRPBleClient;
import com.crrepa.ble.conn.CRPBleConnection;
import com.crrepa.ble.scan.bean.CRPScanDevice;
import com.crrepa.ble.scan.callback.CRPScanCallback;
import com.crrepa.ble.conn.listener.CRPBleConnectionStateListener;
import com.crrepa.ble.conn.bean.CRPHistoryBloodOxygenInfo;
import com.crrepa.ble.conn.bean.CRPHistoryHrvInfo;
import com.crrepa.ble.conn.bean.CRPHistoryStressInfo;
import com.crrepa.ble.conn.bean.CRPHistoryTempInfo;
import com.crrepa.ble.conn.bean.CRPTimingBloodOxygenInfo;
import com.crrepa.ble.conn.bean.CRPTimingHrvInfo;
import com.crrepa.ble.conn.listener.CRPBatteryListener;
import com.crrepa.ble.conn.CRPBleDevice;
import com.crrepa.ble.conn.bean.CRPHeartRateInfo;
import com.crrepa.ble.conn.bean.CRPHistoryHeartRateInfo;
import com.crrepa.ble.conn.listener.CRPBloodOxygenChangeListener;
import com.crrepa.ble.conn.listener.CRPHeartRateChangeListener;
import com.crrepa.ble.conn.listener.CRPHrvChangeListener;
import com.crrepa.ble.conn.listener.CRPStressChangeListener;
import com.crrepa.ble.conn.listener.CRPTempChangeListener;
import android.os.Handler;
import android.os.Looper;

public class SmartRingPlugin implements FlutterPlugin, MethodCallHandler {
    private static final String TAG = "SmartRingPlugin";
    private CRPBleClient bleClient;
    private CRPScanCallback scanCallback;
    private MethodChannel channel;
    private EventChannel eventChannel;
    private EventSink eventSink;
    private Context context;
    private CRPBleConnection bleConnection;
    private double lastNonNullTemperature = 0.0;
    
    // Measurement status trackers
    private boolean isMeasuringTemperature = false;
    private boolean isMeasuringHeartRate = false;
    private boolean isMeasuringHrv = false;
    private boolean isMeasuringStress = false;
    private boolean isMeasuringBloodOxygen = false;
    private boolean isFullMeasurementInProgress = false;
    
    // Timeout handlers for measurements
    private Handler timeoutHandler = new Handler(Looper.getMainLooper());
    private static final long MEASUREMENT_TIMEOUT_MS = 90000; // 90 seconds timeout

    // Retry mechanism
    private int retryCount = 0;
    private int maxRetries = 2; // Default value
    private String currentRetryType = "";
    
    // Measurement sequence for full measurement
    private final String[] measurementSequence = {"temperature", "hrv", "heartRate", "stress", "bloodOxygen"};
    private int currentSequenceIndex = 0;
    
    // Connection state tracking
    private int lastConnectionState = 0;
    
    @Override
    public void onMethodCall(MethodCall call, Result result) {
        switch (call.method) {
            case "startScan":
                startScan();
                result.success(null);
                break;

            case "connectToDevice":
                String deviceAddress = call.argument("deviceAddress");
                Log.d(TAG, "Device address: " + deviceAddress);               
                connectToDevice(deviceAddress);
                result.success(null);
                break;

            case "startTemperatureMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    startMeasurement("temperature", false);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "startHeartRateMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    startMeasurement("heartRate", false);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "startHrvMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    startMeasurement("hrv", false);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "startStressMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    startMeasurement("stress", false);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "startBloodOxygenMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    startMeasurement("bloodOxygen", false);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "startFullMeasurement":
                if (!isAnyMeasurementInProgress()) {
                    Integer attempts = call.argument("attempts");
                    retryCount = 0;
                    maxRetries = (attempts != null && attempts > 0) ? attempts : 2;
                    isFullMeasurementInProgress = true;
                    currentSequenceIndex = 0;
                    // Send status update BEFORE starting first measurement
                    sendMeasurementStatusUpdate();
                    startMeasurement(measurementSequence[currentSequenceIndex], true);
                    result.success(true);
                } else {
                    result.success(false);
                }
                break;

            case "getMeasurementStatus":
                Map<String, Boolean> statusMap = new HashMap<>();
                statusMap.put("temperature", isMeasuringTemperature);
                statusMap.put("heartRate", isMeasuringHeartRate);
                statusMap.put("hrv", isMeasuringHrv);
                statusMap.put("stress", isMeasuringStress);
                statusMap.put("bloodOxygen", isMeasuringBloodOxygen);
                statusMap.put("fullMeasurement", isFullMeasurementInProgress);
                statusMap.put("anyMeasurement", isAnyMeasurementInProgress());
                result.success(statusMap);
                break;

            case "stopAllMeasurements":
                stopAllMeasurements();
                result.success(null);
                break;

            case "getBatteryLevel":
                Log.d(TAG, "Manual battery request - checking connection...");
                if (bleConnection != null && lastConnectionState == 2) {
                    try {
                        Log.i(TAG, "MANUAL_BATTERY_REQUEST_SENT - User requested battery level");
                        bleConnection.queryBattery();
                        result.success(null);
                    } catch (Exception e) {
                        Log.e(TAG, "Error querying battery: " + e.getMessage());
                        sendToFlutter("measurementError", createDetailedErrorJson("battery", e));
                        result.error("BATTERY_ERROR", "Failed to query battery: " + e.getMessage(), null);
                    }
                } else {
                    String errorMessage = (bleConnection == null) ? 
                        "No device connected" : 
                        "Device is not connected (connection state: " + lastConnectionState + ")";
                    Log.w(TAG, "BATTERY_REQUEST_REJECTED - " + errorMessage);
                    sendToFlutter("measurementError", createErrorJson("battery", errorMessage));
                    result.error("NO_CONNECTION", errorMessage, null);
                }
                break;

            case "disconnect":
                disconnectFromDevice();
                result.success(null);
                break;

            default:
                result.notImplemented();
                break;
        }
    }

    private boolean isAnyMeasurementInProgress() {
        return isMeasuringTemperature || isMeasuringHeartRate || isMeasuringHrv || 
               isMeasuringStress || isMeasuringBloodOxygen || isFullMeasurementInProgress;
    }

    private void stopAllMeasurements() {
        try {
            if (bleConnection != null) {
                if (isMeasuringTemperature) {
                    try {
                        bleConnection.disableTimingTemp();
                    } catch (Exception e) {
                        Log.e(TAG, "Error disabling temperature: " + e.getMessage());
                    }
                }
                
                if (isMeasuringHeartRate) {
                    try {
                        bleConnection.stopMeasureHeartRate();
                    } catch (Exception e) {
                        Log.e(TAG, "Error stopping heart rate: " + e.getMessage());
                    }
                }

                if (isMeasuringHrv) {
                    try {
                        bleConnection.stopMeasureHrv();
                    } catch (Exception e) {
                        Log.e(TAG, "Error stopping HRV: " + e.getMessage());
                    }
                }

                if (isMeasuringStress) {
                    try {
                        bleConnection.stopMeasureStress();
                    } catch (Exception e) {
                        Log.e(TAG, "Error stopping stress: " + e.getMessage());
                    }
                }

                if (isMeasuringBloodOxygen) {
                    try {
                        bleConnection.stopMeasureBloodOxygen();
                    } catch (Exception e) {
                        Log.e(TAG, "Error stopping blood oxygen: " + e.getMessage());
                    }
                }
            }
            
            // Reset all states
            isMeasuringTemperature = false;
            isMeasuringHeartRate = false;
            isMeasuringHrv = false;
            isMeasuringStress = false;
            isMeasuringBloodOxygen = false;
            isFullMeasurementInProgress = false;
            
            sendMeasurementStatusUpdate();
        } catch (Exception e) {
            Log.e(TAG, "Error in stopAllMeasurements: " + e.getMessage());
        }
    }

    // Centralized method to send measurement status updates
    private void sendMeasurementStatusUpdate() {
        try {
            // Calculate anyMeasurement based on current state
            boolean anyMeasurement = isMeasuringTemperature || isMeasuringHeartRate || 
                                    isMeasuringHrv || isMeasuringStress || 
                                    isMeasuringBloodOxygen || isFullMeasurementInProgress;
            
            Map<String, Boolean> statusMap = new HashMap<>();
            statusMap.put("temperature", isMeasuringTemperature);
            statusMap.put("heartRate", isMeasuringHeartRate);
            statusMap.put("hrv", isMeasuringHrv);
            statusMap.put("stress", isMeasuringStress);
            statusMap.put("bloodOxygen", isMeasuringBloodOxygen);
            statusMap.put("fullMeasurement", isFullMeasurementInProgress);
            statusMap.put("anyMeasurement", anyMeasurement);
            
            String statusJson = new JSONObject(statusMap).toString();
            Log.d(TAG, "Sending measurement status: " + statusJson);
            sendToFlutter("measurementStatus", statusJson);
        } catch (Exception e) {
            Log.e(TAG, "Error creating status JSON: " + e.getMessage());
        }
    }
    
    private String createStatusJson(String measurementType, boolean status) {
        return "{\"type\":\"" + measurementType + "\",\"measuring\":" + status + "}";
    }
    
    private String createErrorJson(String measurementType, String errorMessage) {
        // Escape error message to prevent JSON parsing issues
        String escapedMessage = errorMessage.replace("\"", "\\\"").replace("\n", "\\n");
        return "{\"type\":\"" + measurementType + "\",\"error\":\"" + escapedMessage + "\"}";
    }
    
    private String createDetailedErrorJson(String measurementType, Exception e) {
        String errorType = e.getClass().getSimpleName();
        String errorMessage = e.getMessage() != null ? e.getMessage() : "Unknown error";
        errorMessage = errorMessage.replace("\"", "\\\"").replace("\n", "\\n");
        
        return "{\"type\":\"" + measurementType + 
               "\",\"errorType\":\"" + errorType + 
               "\",\"errorMessage\":\"" + errorMessage + "\"}";
    }
    
    private void startListeners() {
        if (bleConnection != null) {
            try {
                bleConnection.setBatteryListener(batteryListener);
                bleConnection.setTempChangeListener(temperatureChangeListener);
                bleConnection.setHrvChangeListener(hrvChangeListener);
                bleConnection.setHeartRateChangeListener(heartRateChangeListener);
                bleConnection.setStressChangeListener(stressChangeListener);
                bleConnection.setBloodOxygenChangeListener(bloodOxygenChangeListener);
            } catch (Exception e) {
                Log.e(TAG, "Error setting listeners: " + e.getMessage());
            }
        }
    }

    private void sendToFlutter(String eventName, String dataToSend) {
        new Handler(Looper.getMainLooper()).post(new Runnable() {
            @Override
            public void run() {
                if (eventSink != null) {
                    try {
                        Map<String, Object> event = new HashMap<>();
                        event.put("event", eventName);
                        event.put("data", dataToSend);
                        eventSink.success(event);
                    } catch (Exception e) {
                        Log.e(TAG, "Error sending event to Flutter: " + e.getMessage());
                    }
                } else {
                    // Fallback to method channel for backward compatibility
                    if (channel != null) {
                        try {
                            channel.invokeMethod(eventName, dataToSend);
                        } catch (Exception e) {
                            Log.e(TAG, "Error sending to Flutter: " + e.getMessage());
                        }
                    } else {
                        Log.w(TAG, "Event sink and channel are null, cannot send event: " + eventName);
                    }
                }
            }
        });
    }

    private void retryMeasurement(String measurementType, boolean isPartOfSequence) {
        if (retryCount < maxRetries) {
            retryCount++;
            currentRetryType = measurementType;
            Log.d(TAG, "Retrying " + measurementType + " measurement, attempt " + retryCount + " of " + maxRetries);
            
            // Add a small delay before retrying
            timeoutHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    startMeasurement(measurementType, isPartOfSequence);
                }
            }, 2000); // 2 second delay before retry
        } else {
            retryCount = 0;
            currentRetryType = "";
            sendToFlutter("measurementError", createErrorJson(measurementType, 
                        "Measurement failed after " + maxRetries + " attempts"));
                        
            if (isPartOfSequence) {
                handleSequenceFailure(measurementType);
            }
        }
    }
    
    private void handleSequenceFailure(String failedMeasurement) {
        Log.d(TAG, "Handling sequence failure for: " + failedMeasurement);
        if (isFullMeasurementInProgress) {
            // Decide whether to continue sequence or abort
            boolean criticalFailure = 
                                      "heartRate".equals(failedMeasurement);
            //"temperature".equals(failedMeasurement) || 
            if (criticalFailure) {
                // End full measurement on critical failure
                isFullMeasurementInProgress = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createErrorJson("fullMeasurement", 
                            "Critical measurement " + failedMeasurement + " failed after " + maxRetries + " attempts"));
            } else {
                // Try to continue with next measurement in sequence
                proceedToNextMeasurement();
            }
        }
    }
    
    private void proceedToNextMeasurement() {
        if (isFullMeasurementInProgress) {
            currentSequenceIndex++;
            if (currentSequenceIndex < measurementSequence.length) {
                retryCount = 0;
                // Add delay between measurements
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        startMeasurement(measurementSequence[currentSequenceIndex], true);
                    }
                }, 1000); // 1 second delay between measurements
            } else {
                // All measurements complete
                isFullMeasurementInProgress = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("fullMeasurementComplete", "true");
            }
        }
    }
    
    private void startMeasurement(String measurementType, boolean isPartOfSequence) {
        if (bleConnection == null || lastConnectionState != 2) {
            String errorMsg = bleConnection == null ? "No device connected" : "Device not ready (state: " + lastConnectionState + ")";
            sendToFlutter("measurementError", createErrorJson(measurementType, errorMsg));
            if (isPartOfSequence) {
                handleSequenceFailure(measurementType);
            }
            return;
        }
        
        switch (measurementType) {
            case "temperature":
                startTemperatureMeasurement(isPartOfSequence);
                break;
            case "heartRate":
                startHeartRateMeasurement(isPartOfSequence);
                break;
            case "hrv":
                startHrvMeasurement(isPartOfSequence);
                break;
            case "stress":
                startStressMeasurement(isPartOfSequence);
                break;
            case "bloodOxygen":
                startBloodOxygenMeasurement(isPartOfSequence);
                break;
        }
    }

    public void startScan() {
        try {
            bleClient = CRPBleClient.create(context);
            scanCallback = new CRPScanCallback() {
                @Override
                public void onScanning(CRPScanDevice device) {
                    try {
                        Map<String, String> deviceData = new HashMap<>();
                        String deviceName = device.getDevice().getName();
                        String deviceAddress = device.getDevice().getAddress();
                        deviceData.put("name", deviceName != null ? deviceName : "Unknown");
                        deviceData.put("address", deviceAddress != null ? deviceAddress : "");
                        sendToFlutter("onDeviceScanned", new JSONObject(deviceData).toString());
                    } catch (Exception e) {
                        Log.e(TAG, "Error processing scanned device: " + e.getMessage());
                    }
                }

                @Override
                public void onScanComplete(List<CRPScanDevice> list) {
                    sendToFlutter("onScanComplete", "true");
                }
            };
            bleClient.scanDevice(scanCallback, 30000);
        } catch (Exception e) {
            Log.e(TAG, "Error starting scan: " + e.getMessage());
        }
    }

    private void connectToDevice(String deviceAddress) {
        try {
            if (bleClient == null) {
                bleClient = CRPBleClient.create(context);
            }
            
            CRPBleDevice bleDevice = bleClient.getBleDevice(deviceAddress);
            bleConnection = bleDevice.connect();
            bleConnection.setConnectionStateListener(bleConnectionStateListener);
            
            // Add connection timeout
            timeoutHandler.postDelayed(new Runnable() {
                @Override
                public void run() {
                    if (bleConnection != null && lastConnectionState != 2) {
                        Log.w(TAG, "Connection attempt timed out");
                        sendToFlutter("onConnectionStateChanged", "0");
                        sendToFlutter("connectionError", "Connection timed out after 30 seconds");
                        disconnectFromDevice();
                    }
                }
            }, 30000); // 30 second timeout
        } catch (Exception e) {
            Log.e(TAG, "Error connecting to device: " + e.getMessage());
            sendToFlutter("connectionError", "Failed to connect: " + e.getMessage());
        }
    }

    private void disconnectFromDevice() {
        try {
            // Stop any ongoing measurements
            stopAllMeasurements();
            
            if (bleConnection != null) {
                bleConnection.setConnectionStateListener(null);
                bleConnection.close();
                bleConnection = null;
            }
            
            lastConnectionState = 0;
            sendToFlutter("onConnectionStateChanged", "0");
            Log.i(TAG, "Device disconnected successfully.");
        } catch (Exception e) {
            Log.e(TAG, "Error disconnecting: " + e.getMessage());
        }
    }
    
    // Individual measurement methods
    private void startTemperatureMeasurement(boolean isPartOfSequence) {
        if (bleConnection != null && lastConnectionState == 2) {
            isMeasuringTemperature = true;
            sendMeasurementStatusUpdate(); // Send status AFTER setting the flag
            try {
                bleConnection.enableTimingTemp();
                // Set timeout
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (isMeasuringTemperature) {
                            Log.w(TAG, "Temperature measurement timed out");
                            try {
                                bleConnection.disableTimingTemp();
                            } catch (Exception e) {
                                Log.e(TAG, "Error disabling temperature timing: " + e.getMessage());
                            }
                            isMeasuringTemperature = false;
                            sendMeasurementStatusUpdate();
                            retryMeasurement("temperature", isPartOfSequence);
                        }
                    }
                }, MEASUREMENT_TIMEOUT_MS);
            } catch (Exception e) {
                Log.e(TAG, "Error starting temperature measurement: " + e.getMessage());
                isMeasuringTemperature = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("temperature", e));
                
                if (isPartOfSequence) {
                    handleSequenceFailure("temperature");
                }
            }
        }
    }

    private void startHrvMeasurement(boolean isPartOfSequence) {
        if (bleConnection != null && lastConnectionState == 2) {
            isMeasuringHrv = true;
            sendMeasurementStatusUpdate(); // Send status AFTER setting the flag
            try {
                bleConnection.startMeasureHrv();
                
                // Set timeout
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (isMeasuringHrv) {
                            Log.w(TAG, "HRV measurement timed out");
                            try {
                                bleConnection.stopMeasureHrv();
                            } catch (Exception e) {
                                Log.e(TAG, "Error stopping HRV measurement: " + e.getMessage());
                            }
                            isMeasuringHrv = false;
                            sendMeasurementStatusUpdate();
                            retryMeasurement("hrv", isPartOfSequence);
                        }
                    }
                }, MEASUREMENT_TIMEOUT_MS);
            } catch (Exception e) {
                Log.e(TAG, "Error starting HRV measurement: " + e.getMessage());
                isMeasuringHrv = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("hrv", e));
                
                if (isPartOfSequence) {
                    handleSequenceFailure("hrv");
                }
            }
        }
    }
    
    private void startHeartRateMeasurement(boolean isPartOfSequence) {
        if (bleConnection != null && lastConnectionState == 2) {
            isMeasuringHeartRate = true;
            sendMeasurementStatusUpdate(); // Send status AFTER setting the flag
            try {
                bleConnection.startMeasureHeartRate();
                // Set timeout
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (isMeasuringHeartRate) {
                            Log.w(TAG, "Heart rate measurement timed out");
                            try {
                                bleConnection.stopMeasureHeartRate();
                            } catch (Exception e) {
                                Log.e(TAG, "Error stopping heart rate measurement: " + e.getMessage());
                            }
                            isMeasuringHeartRate = false;
                            sendMeasurementStatusUpdate();
                            retryMeasurement("heartRate", isPartOfSequence);
                        }
                    }
                }, MEASUREMENT_TIMEOUT_MS);
            } catch (Exception e) {
                Log.e(TAG, "Error starting heart rate measurement: " + e.getMessage());
                isMeasuringHeartRate = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("heartRate", e));
                
                if (isPartOfSequence) {
                    handleSequenceFailure("heartRate");
                }
            }
        }
    }

    private void startStressMeasurement(boolean isPartOfSequence) {
        if (bleConnection != null && lastConnectionState == 2) {
            isMeasuringStress = true;
            sendMeasurementStatusUpdate(); // Send status AFTER setting the flag
            try {
                bleConnection.startMeasureStress();
                
                // Set timeout
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (isMeasuringStress) {
                            Log.w(TAG, "Stress measurement timed out");
                            try {
                                bleConnection.stopMeasureStress();
                            } catch (Exception e) {
                                Log.e(TAG, "Error stopping stress measurement: " + e.getMessage());
                            }
                            isMeasuringStress = false;
                            sendMeasurementStatusUpdate();
                            retryMeasurement("stress", isPartOfSequence);
                        }
                    }
                }, MEASUREMENT_TIMEOUT_MS);
            } catch (Exception e) {
                Log.e(TAG, "Error starting stress measurement: " + e.getMessage());
                isMeasuringStress = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("stress", e));
                
                if (isPartOfSequence) {
                    handleSequenceFailure("stress");
                }
            }
        }
    }
    
    private void startBloodOxygenMeasurement(boolean isPartOfSequence) {
        if (bleConnection != null && lastConnectionState == 2) {
            isMeasuringBloodOxygen = true;
            sendMeasurementStatusUpdate(); // Send status AFTER setting the flag
            try {
                bleConnection.startMeasureBloodOxygen();
                
                // Set timeout
                timeoutHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (isMeasuringBloodOxygen) {
                            Log.w(TAG, "Blood oxygen measurement timed out");
                            try {
                                bleConnection.stopMeasureBloodOxygen();
                            } catch (Exception e) {
                                Log.e(TAG, "Error stopping blood oxygen measurement: " + e.getMessage());
                            }
                            isMeasuringBloodOxygen = false;
                            sendMeasurementStatusUpdate();
                            retryMeasurement("bloodOxygen", isPartOfSequence);
                        }
                    }
                }, MEASUREMENT_TIMEOUT_MS);
            } catch (Exception e) {
                Log.e(TAG, "Error starting blood oxygen measurement: " + e.getMessage());
                isMeasuringBloodOxygen = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("bloodOxygen", e));
                
                if (isPartOfSequence) {
                    handleSequenceFailure("bloodOxygen");
                }
            }
        }
    }
    
    /////////////////////////Connection Listeners////////////////////////
    private final CRPBleConnectionStateListener bleConnectionStateListener = new CRPBleConnectionStateListener() {
        @Override
        public void onConnectionStateChange(int state) {
            lastConnectionState = state;
            Log.d(TAG, "Connection state changed to: " + state);
            switch (state) {
                case 0: // Disconnected
                    Log.i(TAG, "Device disconnected");
                    resetAllMeasurementStates();
                    sendToFlutter("onConnectionStateChanged", "0");
                    break;
                case 1: // Connecting
                    Log.i(TAG, "Device connecting...");
                    sendToFlutter("onConnectionStateChanged", "1");
                    break;
                case 2: // Connected
                    Log.i(TAG, "Device connected successfully");
                    timeoutHandler.removeCallbacksAndMessages(null);
                    startListeners();
                    sendToFlutter("onConnectionStateChanged", "2");
                    break;
           }
        }
    };
    
    // Reset all measurement states
    private void resetAllMeasurementStates() {
        timeoutHandler.removeCallbacksAndMessages(null);
        
        isMeasuringTemperature = false;
        isMeasuringHeartRate = false;
        isMeasuringHrv = false;
        isMeasuringStress = false;
        isMeasuringBloodOxygen = false;
        isFullMeasurementInProgress = false;
        retryCount = 0;
        currentRetryType = "";
        currentSequenceIndex = 0;
        
        sendMeasurementStatusUpdate();
    }

    /////////////////////////Battery Listeners////////////////////////
    private final CRPBatteryListener batteryListener = new CRPBatteryListener() {
        @Override
        public void onBattery(int batteryLevel) {
            Log.d(TAG, "Battery level: " + batteryLevel);
            sendToFlutter("onBattery", String.valueOf(batteryLevel));

            if (batteryLevel < 15) {
                Map<String, Object> warning = new HashMap<>();
                warning.put("level", batteryLevel);
                warning.put("message", "Battery level critical");
                try {
                    sendToFlutter("batteryWarning", new JSONObject(warning).toString());
                } catch (Exception e) {
                    Log.e(TAG, "Error sending battery warning: " + e.getMessage());
                }
            }
        }

        @Override
        public void onRealTimeBattery(int batteryLevel, int chargingStatus) {
            Log.d(TAG, "Real-time battery level: " + batteryLevel + ", charging status: " + chargingStatus);
            sendToFlutter("onRealTimeBattery", String.valueOf(batteryLevel));
            
            if (batteryLevel < 15) {
                Map<String, Object> warning = new HashMap<>();
                warning.put("level", batteryLevel);
                warning.put("charging", chargingStatus == 1);
                warning.put("message", "Battery level critical");
                try {
                    sendToFlutter("batteryWarning", new JSONObject(warning).toString());
                } catch (Exception e) {
                    Log.e(TAG, "Error sending battery warning: " + e.getMessage());
                }
            }
        }
    };
    
    /////////////////////////HRV Listeners////////////////////////
    private CRPHrvChangeListener hrvChangeListener = new CRPHrvChangeListener() {
        @Override
        public void onHrv(int hrvValue) {
            try {
                Log.d(TAG, "HRV value: " + hrvValue);
                
                // Cancel timeout since we got a response
                timeoutHandler.removeCallbacksAndMessages(null);
                
                try {
                    bleConnection.stopMeasureHrv();
                } catch (Exception e) {
                    Log.e(TAG, "Error stopping HRV measurement: " + e.getMessage());
                }
                
                isMeasuringHrv = false;
                sendMeasurementStatusUpdate();
                
                if (hrvValue > 0) {
                    sendToFlutter("hrv", String.valueOf(hrvValue));
                    
                    if (isFullMeasurementInProgress) {
                        proceedToNextMeasurement();
                    }
                } else {
                    if ("hrv".equals(currentRetryType)) {
                        retryMeasurement("hrv", isFullMeasurementInProgress);
                    } else {
                        sendToFlutter("measurementError", createErrorJson("hrv", "Invalid HRV reading"));
                        
                        if (isFullMeasurementInProgress) {
                            handleSequenceFailure("hrv");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error processing HRV data: " + e.getMessage());
                isMeasuringHrv = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("hrv", e));
                
                if (isFullMeasurementInProgress) {
                    handleSequenceFailure("hrv");
                }
            }
        }

        @Override
        public void onHistoryHrv(List<CRPHistoryHrvInfo> list) {
            Log.d(TAG, "History HRV data received");
        }

        @Override
        public void onTimingInterval(int interval) {
            Log.d(TAG, "HRV timing interval: " + interval);
            sendToFlutter("hrvTimingInterval", String.valueOf(interval));
        }

        @Override
        public void onTimingHrv(CRPTimingHrvInfo hrvInfo) {
            Log.d(TAG, "Timing HRV info received");
        }
    };
    
    /////////////////////////Temperature Listeners////////////////////////
    private CRPTempChangeListener temperatureChangeListener = new CRPTempChangeListener() {
        @Override
        public void onTimingState(boolean state) {
            Log.d(TAG, "Temperature timing state: " + state);
            sendToFlutter("temperatureTimingState", String.valueOf(state));
        }

        @Override
        public void onHistoryTempChange(CRPHistoryTempInfo tempInfo) {
            try {
                List<Float> tempList = tempInfo.getTempList();
                Log.d(TAG, "Temperature measurement received: " + 
                      tempList.stream().map(String::valueOf).collect(Collectors.joining(",")));

                // Cancel timeout since we got a response
                timeoutHandler.removeCallbacksAndMessages(null);

                // Get the first valid temperature reading (current measurement)
                Float currentTemperature = null;
                for (Float temperature : tempList) {
                    if (temperature != null && temperature != 0.0f) {
                        currentTemperature = temperature;
                        lastNonNullTemperature = temperature;
                        break;
                    }
                }
                
                try {
                    bleConnection.disableTimingTemp();
                } catch (Exception e) {
                    Log.e(TAG, "Error disabling temperature timing: " + e.getMessage());
                }
                
                isMeasuringTemperature = false;
                sendMeasurementStatusUpdate();

                if (currentTemperature != null) {
                    sendToFlutter("bodyTemperature", String.format("%.1f", currentTemperature));
                    
                    if (isFullMeasurementInProgress) {
                        proceedToNextMeasurement();
                    }
                } else {
                    // No valid temperature was found
                    if ("temperature".equals(currentRetryType)) {
                        retryMeasurement("temperature", isFullMeasurementInProgress);
                    } else {
                        sendToFlutter("measurementError", createErrorJson("temperature", "No valid temperature reading"));
                        
                        if (isFullMeasurementInProgress) {
                            handleSequenceFailure("temperature");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error processing temperature data: " + e.getMessage());
                isMeasuringTemperature = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("temperature", e));
                
                if (isFullMeasurementInProgress) {
                    handleSequenceFailure("temperature");
                }
            }
        }
    };
    
    /////////////////////////Heart Rate Listeners////////////////////////
    private CRPHeartRateChangeListener heartRateChangeListener = new CRPHeartRateChangeListener() {
        @Override
        public void onTimingInterval(int interval) {
            Log.d(TAG, "Heart rate timing interval: " + interval);
            sendToFlutter("heartRateTimingInterval", String.valueOf(interval));
        }

        @Override
        public void onRealtimeHeartRate(int heartRate) {
            Log.d(TAG, "Real-time heart rate: " + heartRate);
            sendToFlutter("realtimeHeartRate", String.valueOf(heartRate));
        }

        @Override
        public void onHeartRate(int heartRate) {
            try {
                Log.d(TAG, "Heart rate: " + heartRate);
                
                timeoutHandler.removeCallbacksAndMessages(null);
                
                try {
                    bleConnection.stopMeasureHeartRate();
                } catch (Exception e) {
                    Log.e(TAG, "Error stopping heart rate measurement: " + e.getMessage());
                }
                
                isMeasuringHeartRate = false;
                sendMeasurementStatusUpdate();
                
                if (heartRate > 0 && heartRate < 250) { // Valid heart rate range
                    sendToFlutter("heartRate", String.valueOf(heartRate));
                    
                    if (isFullMeasurementInProgress) {
                        proceedToNextMeasurement();
                    }
                } else {
                    if ("heartRate".equals(currentRetryType)) {
                        retryMeasurement("heartRate", isFullMeasurementInProgress);
                    } else {
                        sendToFlutter("measurementError", createErrorJson("heartRate", "Invalid heart rate reading"));
                        
                        if (isFullMeasurementInProgress) {
                            handleSequenceFailure("heartRate");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error processing heart rate data: " + e.getMessage());
                isMeasuringHeartRate = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("heartRate", e));
                
                if (isFullMeasurementInProgress) {
                    handleSequenceFailure("heartRate");
                }
            }
        }

        @Override
        public void onHistoryHeartRate(List<CRPHistoryHeartRateInfo> list) {
            Log.d(TAG, "History heart rate data received");
        }

        @Override
        public void onTimingHeartRate(CRPHeartRateInfo heartRateInfo) {
            Log.d(TAG, "Timing heart rate info received");
        }
    };
    
    ////////////////////////Blood Oxygen Listeners////////////////////////
    private CRPBloodOxygenChangeListener bloodOxygenChangeListener = new CRPBloodOxygenChangeListener() {
        @Override
        public void onTimingInterval(int interval) {
            Log.d(TAG, "Blood oxygen timing interval: " + interval);
            sendToFlutter("bloodOxygenTimingInterval", String.valueOf(interval));
        }

        @Override
        public void onBloodOxygen(int bloodOxygen) {
            try {
                Log.d(TAG, "Blood oxygen: " + bloodOxygen);
                
                timeoutHandler.removeCallbacksAndMessages(null);
                
                try {
                    bleConnection.stopMeasureBloodOxygen();
                } catch (Exception e) {
                    Log.e(TAG, "Error stopping blood oxygen measurement: " + e.getMessage());
                }
                
                isMeasuringBloodOxygen = false;
                sendMeasurementStatusUpdate();

                if (bloodOxygen > 0 && bloodOxygen <= 100) { // Valid blood oxygen range
                    sendToFlutter("bloodOxygen", String.valueOf(bloodOxygen));
                    
                    if (isFullMeasurementInProgress) {
                        isFullMeasurementInProgress = false;
                        sendMeasurementStatusUpdate();
                        sendToFlutter("fullMeasurementComplete", "true");
                    }
                } else {
                    if ("bloodOxygen".equals(currentRetryType)) {
                        retryMeasurement("bloodOxygen", isFullMeasurementInProgress);
                    } else {
                        sendToFlutter("measurementError", createErrorJson("bloodOxygen", "Invalid blood oxygen reading"));
                        
                        if (isFullMeasurementInProgress) {
                            handleSequenceFailure("bloodOxygen");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error processing blood oxygen data: " + e.getMessage());
                isMeasuringBloodOxygen = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("bloodOxygen", e));
                
                if (isFullMeasurementInProgress) {
                    handleSequenceFailure("bloodOxygen");
                }
            }
        }

        @Override
        public void onHistoryBloodOxygen(List<CRPHistoryBloodOxygenInfo> list) {
            Log.d(TAG, "History blood oxygen data received");
        }

        @Override
        public void onTimingBloodOxygen(CRPTimingBloodOxygenInfo bloodOxygenInfo) {
            Log.d(TAG, "Timing blood oxygen info received");
        }
    };
    
    /////////////////////////Stress Listeners////////////////////////
    private CRPStressChangeListener stressChangeListener = new CRPStressChangeListener() {
        @Override
        public void onStressChange(int stress) {
            try {
                Log.d(TAG, "Stress level: " + stress);
                
                timeoutHandler.removeCallbacksAndMessages(null);
                
                try {
                    bleConnection.stopMeasureStress();
                } catch (Exception e) {
                    Log.e(TAG, "Error stopping stress measurement: " + e.getMessage());
                }
                
                isMeasuringStress = false;
                sendMeasurementStatusUpdate();
                
                if (stress >= 0 && stress <= 100) { // Valid stress range
                    sendToFlutter("stress", String.valueOf(stress));
                    
                    if (isFullMeasurementInProgress) {
                        proceedToNextMeasurement();
                    }
                } else {
                    if ("stress".equals(currentRetryType)) {
                        retryMeasurement("stress", isFullMeasurementInProgress);
                    } else {
                        sendToFlutter("measurementError", createErrorJson("stress", "Invalid stress reading"));
                        
                        if (isFullMeasurementInProgress) {
                            handleSequenceFailure("stress");
                        }
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "Error processing stress data: " + e.getMessage());
                isMeasuringStress = false;
                sendMeasurementStatusUpdate();
                sendToFlutter("measurementError", createDetailedErrorJson("stress", e));
                
                if (isFullMeasurementInProgress) {
                    handleSequenceFailure("stress");
                }
            }
        }

        @Override
        public void onHistoryStressChange(List<CRPHistoryStressInfo> list) {
            Log.d(TAG, "History stress data received");
        }
    };

    private void cleanupResources() {
        timeoutHandler.removeCallbacksAndMessages(null);
        resetAllMeasurementStates();
        
        if (bleClient != null) {
            try {
                bleClient.cancelScan();
            } catch (Exception e) {
                Log.e(TAG, "Error canceling scan: " + e.getMessage());
            }
        }
    }
    
    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "smart_ring");
        eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "smart_ring_events");
        context = flutterPluginBinding.getApplicationContext();
        channel.setMethodCallHandler(this);
        
        eventChannel.setStreamHandler(new StreamHandler() {
            @Override
            public void onListen(Object arguments, EventSink events) {
                eventSink = events;
                Log.d(TAG, "Event channel listener attached");
            }

            @Override
            public void onCancel(Object arguments) {
                eventSink = null;
                Log.d(TAG, "Event channel listener cancelled");
            }
        });
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        if (bleConnection != null) {
            stopAllMeasurements();
            bleConnection.close();
        }
        cleanupResources();
        channel.setMethodCallHandler(null);
        eventChannel.setStreamHandler(null);
        channel = null;
        eventChannel = null;
        eventSink = null;
        context = null;
    }
}

