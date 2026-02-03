import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/device.dart';
import '../models/room.dart';
import '../models/log_entry.dart';
import '../models/wifi_network.dart';
import '../services/esp_service.dart';
import 'package:flutter/foundation.dart'; // for kDebugMode

enum AppMode { remote, localAuto }

class AppProvider extends ChangeNotifier {
  // Constants
  static const String authKey = 'hodo8212';
  static const int emergencyStopLevel = 98;

  // ESP Service
  final EspService _espService = EspService();

  // State
  bool _isDarkMode = true;
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isSimulationEnabled = false;
  bool _encryptionEnabled = false;
  bool _notificationsEnabled = true;
  double _syncProgress = 0;
  AppMode _appMode = AppMode.remote;
  String _appName = 'Home Circuit';
  int _pumpMinThreshold = 20;
  int _pumpMaxThreshold = 80;

  List<Device> _devices = [];
  List<Room> _rooms = [];
  List<LogEntry> _logs = [];
  List<WifiNetwork> _wifiNetworks = [];

  Timer? _simulationTimer;
  final _uuid = const Uuid();
  // ===== Execution Status =====
String _executionStatus = '';
  String get executionStatus => _executionStatus;

  void _setExecutionStatus(String status) {
    _executionStatus = status;
    notifyListeners();
  }

  void _clearExecutionStatus() {
    Future.delayed(const Duration(seconds: 3), () {
      _executionStatus = '';
      notifyListeners();
    });
  }


  // Getters
  bool get isDarkMode => _isDarkMode;
  bool get isInitialized => _isInitialized;
  bool get isSyncing => _isSyncing;
  bool get isSimulationEnabled => _isSimulationEnabled;
  bool get encryptionEnabled => _encryptionEnabled;
  bool get notificationsEnabled => _notificationsEnabled;
  double get syncProgress => _syncProgress;
  AppMode get appMode => _appMode;
  String get appName => _appName;
  int get pumpMinThreshold => _pumpMinThreshold;
  int get pumpMaxThreshold => _pumpMaxThreshold;

  List<Device> get devices => List.unmodifiable(_devices);
  List<Room> get rooms => List.unmodifiable(_rooms);
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<WifiNetwork> get wifiNetworks => List.unmodifiable(_wifiNetworks);

  List<Device> get onlineDevices =>
      _devices.where((d) => d.isOnline).toList();
  List<Device> get activeDevices => _devices.where((d) => d.isOn).toList();
  List<Device> get lightDevices =>
      _devices.where((d) => d.type == DeviceType.light).toList();

  // Initialize
  Future<void> initialize() async {
    await _loadFromStorage();
    _isInitialized = true;
    notifyListeners();

    if (_isSimulationEnabled) {
      _startSimulation();
    }
     _startAutoSync();
  }
Timer? _autoSyncTimer;
  
  void _startAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isSyncing && !_isSimulationEnabled) {
        syncDevices(silent: true);
      }
    });
  }
  // Theme
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveToStorage();
    notifyListeners();
  }

  void setTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveToStorage();
    notifyListeners();
  }

  // App Name
  void setAppName(String name) {
    _appName = name;
    _saveToStorage();
    notifyListeners();
  }

  // Mode
  bool switchToLocalAuto(String key) {
    if (key != authKey) return false;
    _appMode = AppMode.localAuto;
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Switched to Local Auto mode',
    );
    _saveToStorage();
    notifyListeners();
    return true;
  }

  void switchToRemote() {
    _appMode = AppMode.remote;
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Switched to Remote mode',
    );
    _saveToStorage();
    notifyListeners();
  }

  // Thresholds
  void setPumpThresholds(int min, int max) {
    _pumpMinThreshold = min;
    _pumpMaxThreshold = max;
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.threshold,
      action: 'Pump thresholds updated',
      details: 'Min: $min%, Max: $max%',
    );
    _saveToStorage();
    notifyListeners();
  }

  // Notifications
  void setNotificationsEnabled(bool enabled) {
    _notificationsEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  void setDeviceNotifications(String deviceId, bool enabled) {
    final index = _devices.indexWhere((d) => d.id == deviceId);
    if (index != -1) {
      _devices[index] = _devices[index].copyWith(notificationsEnabled: enabled);
      _saveToStorage();
      notifyListeners();
    }
  }

  // Encryption
  void setEncryptionEnabled(bool enabled) {
    _encryptionEnabled = enabled;
    _saveToStorage();
    notifyListeners();
  }

  // Simulation
  void setSimulationEnabled(bool enabled) {
    _isSimulationEnabled = enabled;
    if (enabled) {
      _startSimulation();
    } else {
      _stopSimulation();
    }
    _saveToStorage();
    notifyListeners();
  }

  void _startSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _runSimulation();
    });
  }

  void _stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  void _runSimulation() {
    final random = math.Random();

    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];

      // Simulate online status
      _devices[i] = device.copyWith(
        isOnline: random.nextDouble() > 0.1,
        lastSeen: DateTime.now(),
      );

      // Simulate water level changes for pumps
      if (device.type == DeviceType.waterPump) {
        int newLevel = device.waterLevel;

        if (device.isOn) {
          newLevel = (device.waterLevel + random.nextInt(5) + 1).clamp(0, 100);
        } else {
          newLevel = (device.waterLevel - random.nextInt(3)).clamp(0, 100);
        }

        bool shouldBeOn = device.isOn;
        if (_appMode == AppMode.remote) {
          if (newLevel <= _pumpMinThreshold && !device.isOn) {
            shouldBeOn = true;
            _addLog(
              deviceId: device.id,
              deviceName: device.name,
              type: LogType.deviceOn,
              action: 'Auto ON - Below minimum threshold',
              details: 'Water level: $newLevel%',
            );
          } else if (newLevel >= _pumpMaxThreshold && device.isOn) {
            shouldBeOn = false;
            _addLog(
              deviceId: device.id,
              deviceName: device.name,
              type: LogType.deviceOff,
              action: 'Auto OFF - Above maximum threshold',
              details: 'Water level: $newLevel%',
            );
          }
        }

        if (newLevel >= emergencyStopLevel && device.isOn) {
          shouldBeOn = false;
          _addLog(
            deviceId: device.id,
            deviceName: device.name,
            type: LogType.warning,
            action: 'EMERGENCY STOP',
            details: 'Water level reached $newLevel%',
          );
        }

        _devices[i] = _devices[i].copyWith(
          waterLevel: newLevel,
          isOn: shouldBeOn,
        );
      }

      // Simulate gas sensor values
      if (device.type == DeviceType.gasSensor) {
        _devices[i] = device.copyWith(
          lpgValue: (random.nextDouble() * 100).clamp(0, 100),
          coValue: (random.nextDouble() * 50).clamp(0, 50),
        );
      }

      // Simulate battery
      if (device.hasBattery && device.batteryLevel != null) {
        _devices[i] = _devices[i].copyWith(
          batteryLevel:
              (device.batteryLevel! - random.nextInt(2)).clamp(0, 100),
        );
      }
    }

    _saveToStorage();
    notifyListeners();
  }

  // Sync - REAL HTTP COMMUNICATION
 Future<void> syncDevices({bool silent = false}) async {
    _isSyncing = true;
    
    if (!silent) {
      _syncProgress = 0;
      notifyListeners();
      
      _addLog(
        deviceId: 'system',
        deviceName: 'System',
        type: LogType.sync,
        action: 'Device sync started',
      );
    }

    final totalDevices = _devices.length;
    if (totalDevices == 0) {
      if (!silent) {
        await Future.delayed(const Duration(seconds: 2));
        _syncProgress = 1.0;
      }
      _isSyncing = false;
      notifyListeners();
      return;
    }

    int onlineCount = 0;
    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];
      
      // Use REAL HTTP communication with device name
      final status = await _espService.getDeviceStatus(device.ipAddress, device.name);

      if (status != null) {
        _devices[i] = device.copyWith(
          isOnline: true,
          isOn: status['isOn'] ?? false,
          physicalSwitchOn: status['physicalSwitchOn'] ?? false,
          batteryLevel: status['batteryLevel'],
          waterLevel: status['waterLevel'] ?? device.waterLevel,
          lastSeen: DateTime.now(),
        );
        onlineCount++;
      } else {
        _devices[i] = device.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        );
      }

      if (!silent) {
        _syncProgress = (i + 1) / totalDevices;
        notifyListeners();
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }

    if (!silent) {
      _addLog(
        deviceId: 'system',
        deviceName: 'System',
        type: LogType.sync,
        action: 'Device sync completed',
        details: '$onlineCount/${_devices.length} devices online',
      );
    }

    _isSyncing = false;
    _saveToStorage();
    notifyListeners();
  }

Future<bool> masterSwitch(String key, bool turnOn) async {
    if (key != authKey) return false;

    final lights = lightDevices;
    int successCount = 0;
    int failCount = 0;

    for (final light in lights) {
      Map<String, dynamic> result;
      
      if (turnOn) {
        result = await _espService.turnDeviceOn(
          light.ipAddress, 
          light.name,
          onStatusUpdate: (status) {
            if (kDebugMode) {
              print('Master Switch - ${light.name}: $status');
            }
          },
        );
      } else {
        result = await _espService.turnDeviceOff(
          light.ipAddress, 
          light.name,
          onStatusUpdate: (status) {
            if (kDebugMode) {
              print('Master Switch - ${light.name}: $status');
            }
          },
        );
      }

      if (result['success'] == true) {
        final index = _devices.indexWhere((d) => d.id == light.id);
        if (index != -1) {
          _devices[index] = _devices[index].copyWith(
            isOn: result['isOn'] ?? turnOn,
            physicalSwitchOn: result['physicalSwitchOn'] ?? turnOn,
            batteryLevel: result['batteryLevel'],
            isOnline: true,
            lastSeen: DateTime.now(),
          );
          successCount++;
        }
        _addLog(
          deviceId: light.id,
          deviceName: light.name,
          type: turnOn ? LogType.deviceOn : LogType.deviceOff,
          action: 'Master Switch: ${turnOn ? 'ON' : 'OFF'}',
        );
      } else {
        failCount++;
        _addLog(
          deviceId: light.id,
          deviceName: light.name,
          type: LogType.error,
          action: 'Master Switch command failed',
          details: result['message'] ?? 'Unknown error',
        );
      }
      
      // Small delay between commands
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Master Switch completed',
      details: 'Success: $successCount, Failed: $failCount',
    );

    _saveToStorage();
    notifyListeners();
    return failCount == 0;
  }




  // Device Management
  void addDevice(Device device) {
    _devices.add(device);
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.info,
      action: 'Device added',
      details: 'Type: ${device.type.displayName}',
    );
    _saveToStorage();
    notifyListeners();
  }

  void updateDevice(Device device) {
    final index = _devices.indexWhere((d) => d.id == device.id);
    if (index != -1) {
      _devices[index] = device;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteDevice(String id) {
    final device = _devices.firstWhere((d) => d.id == id);
    _devices.removeWhere((d) => d.id == id);
    _addLog(
      deviceId: id,
      deviceName: device.name,
      type: LogType.info,
      action: 'Device deleted',
    );
    _saveToStorage();
    notifyListeners();
  }

Future<bool> toggleDevice(String id) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index == -1) return false;

    if (_appMode == AppMode.localAuto) {
      return false;
    }

    final device = _devices[index];
    final newState = !device.isOn;

    // Show status
    _setExecutionStatus(
      newState ? 'Turning ON ${device.name}...' : 'Turning OFF ${device.name}...'
    );

    try {
      // Use REAL HTTP communication with status callbacks
      Map<String, dynamic> result;
      
      if (newState) {
        result = await _espService.turnDeviceOn(
          device.ipAddress,
          device.name,
          onStatusUpdate: (status) {
            _setExecutionStatus(status);
          },
        );
      } else {
        result = await _espService.turnDeviceOff(
          device.ipAddress,
          device.name,
          onStatusUpdate: (status) {
            _setExecutionStatus(status);
          },
        );
      }

      if (result['success'] == true) {
        _devices[index] = device.copyWith(
          isOn: result['isOn'] ?? newState,
          physicalSwitchOn: result['physicalSwitchOn'] ?? newState,
          batteryLevel: result['batteryLevel'],
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: newState ? LogType.deviceOn : LogType.deviceOff,
          action: newState ? 'Turned ON' : 'Turned OFF',
          details: 'Physical switch confirmed: ${result['physicalSwitchOn']}',
        );
        
        _saveToStorage();
        notifyListeners();
        _clearExecutionStatus();
        return true;
      } else {
        _devices[index] = device.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        );
        
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: LogType.error,
          action: 'Command failed',
          details: result['message'] ?? 'Unknown error',
        );
        
        notifyListeners();
        _clearExecutionStatus();
        return false;
      }
    } catch (e) {
      _setExecutionStatus('❌ Error: $e');
      _addLog(
        deviceId: device.id,
        deviceName: device.name,
        type: LogType.error,
        action: 'Exception occurred',
        details: e.toString(),
      );
      _clearExecutionStatus();
      return false;
    }
  }



  // Set Brightness - REAL HTTP COMMUNICATION
  void setBrightness(String id, int brightness) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      
      // Update local state immediately for UI responsiveness
      _devices[index] = device.copyWith(brightness: brightness.clamp(0, 100));
      notifyListeners();
      
      // Send to ESP in background with device name
      final success = await _espService.setBrightness(
        device.ipAddress,
        device.name,
        brightness,
      );
      
      if (!success) {
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: LogType.error,
          action: 'Failed to set brightness',
        );
      }
      
      _saveToStorage();
    }
  }

  // Set Fan Speed - REAL HTTP COMMUNICATION
  void setFanSpeed(String id, int speed) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      
      // Update local state immediately
      _devices[index] = device.copyWith(fanSpeed: speed.clamp(1, 5));
      notifyListeners();
      
      // Send to ESP in background with device name
      final success = await _espService.setFanSpeed(
        device.ipAddress,
        device.name,
        speed,
      );
      
      if (!success) {
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: LogType.error,
          action: 'Failed to set fan speed',
        );
      }
      
      _saveToStorage();
    }
  }

  // Room Management
  void addRoom(Room room) {
    _rooms.add(room);
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Room added: ${room.name}',
    );
    _saveToStorage();
    notifyListeners();
  }

  void updateRoom(Room room) {
    final index = _rooms.indexWhere((r) => r.id == room.id);
    if (index != -1) {
      _rooms[index] = room;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteRoom(String id) {
    final room = _rooms.firstWhere((r) => r.id == id);
    _rooms.removeWhere((r) => r.id == id);
    for (int i = 0; i < _devices.length; i++) {
      if (_devices[i].roomId == id) {
        _devices[i] = _devices[i].copyWith(roomId: null);
      }
    }
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Room deleted: ${room.name}',
    );
    _saveToStorage();
    notifyListeners();
  }

  void moveDevicesToRoom(List<String> deviceIds, String? newRoomId) {
    for (final id in deviceIds) {
      final index = _devices.indexWhere((d) => d.id == id);
      if (index != -1) {
        _devices[index] = _devices[index].copyWith(roomId: newRoomId);
      }
    }
    _saveToStorage();
    notifyListeners();
  }

  List<Device> getDevicesForRoom(String? roomId) {
    return _devices.where((d) => d.roomId == roomId).toList();
  }

  // WiFi Management
  void addWifiNetwork(WifiNetwork network) {
    _wifiNetworks.add(network);
    _saveToStorage();
    notifyListeners();
  }

  void updateWifiNetwork(WifiNetwork network) {
    final index = _wifiNetworks.indexWhere((n) => n.id == network.id);
    if (index != -1) {
      _wifiNetworks[index] = network;
      _saveToStorage();
      notifyListeners();
    }
  }

  void deleteWifiNetwork(String id) {
    _wifiNetworks.removeWhere((n) => n.id == id);
    _saveToStorage();
    notifyListeners();
  }

  // Logs
  void _addLog({
    required String deviceId,
    required String deviceName,
    required LogType type,
    required String action,
    String? details,
  }) {
    _logs.insert(
      0,
      LogEntry(
        id: _uuid.v4(),
        timestamp: DateTime.now(),
        deviceId: deviceId,
        deviceName: deviceName,
        type: type,
        action: action,
        details: details,
      ),
    );
    if (_logs.length > 1000) {
      _logs = _logs.sublist(0, 1000);
    }
  }

  void clearLogs() {
    _logs.clear();
    _saveToStorage();
    notifyListeners();
  }

  List<LogEntry> getFilteredLogs({
    DateTime? startDate,
    DateTime? endDate,
    String? deviceId,
    LogType? logType,
  }) {
    return _logs.where((log) {
      if (startDate != null && log.timestamp.isBefore(startDate)) {
        return false;
      }
      if (endDate != null &&
          log.timestamp.isAfter(endDate.add(const Duration(days: 1)))) {
        return false;
      }
      if (deviceId != null && log.deviceId != deviceId) {
        return false;
      }
      if (logType != null && log.type != logType) {
        return false;
      }
      return true;
    }).toList();
  }

  String exportLogsToCSV(List<LogEntry> entries) {
    final buffer = StringBuffer();
    buffer.writeln('Timestamp,Device,Type,Action,Details');
    for (final entry in entries) {
      buffer.writeln(entry.toCSV());
    }
    return buffer.toString();
  }

  // Arduino Code Generation
  String generateArduinoCode() {
    final buffer = StringBuffer();
    
    final device = _devices.isNotEmpty ? _devices.first : null;
    
    buffer.writeln('/*');
    buffer.writeln(' * $appName - ESP8266/ESP32 Device Controller');
    buffer.writeln(' * Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln(' * Device: ${device?.name ?? "Unknown"}');
    buffer.writeln(' * Compatible with Flutter HTTP endpoints');
    buffer.writeln(' */');
    buffer.writeln();
    buffer.writeln('#include <ESP8266WiFi.h>');
    buffer.writeln('#include <ESP8266WebServer.h>');
    buffer.writeln();
    buffer.writeln('// ========== WIFI CONFIGURATION ==========');
    if (_wifiNetworks.isNotEmpty) {
      buffer.writeln('const char* WIFI_SSID = "${_wifiNetworks.first.ssid}";');
      buffer.writeln(
          'const char* WIFI_PASSWORD = "${_encryptionEnabled ? '********' : _wifiNetworks.first.password}";');
    } else {
      buffer.writeln('const char* WIFI_SSID = "YOUR_WIFI_SSID";');
      buffer.writeln('const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";');
    }
    buffer.writeln();
    
    // Sanitize device name for endpoints
    final deviceName = device?.name.replaceAll(' ', '_').toLowerCase() ?? 'device';
    
    buffer.writeln('// ========== PIN CONFIGURATION ==========');
    
    if (device?.type == DeviceType.waterPump) {
      final onPin = device?.gpioPin ?? 14;
      final offPin = device?.offPin ?? 27;
      
      buffer.writeln('const int ON_PIN = $onPin;   // Motor ON relay');
      buffer.writeln('const int OFF_PIN = $offPin;  // Motor OFF relay');
    } else {
      final gpioPin = device?.gpioPin ?? 2;
      buffer.writeln('const int LED_PIN = $gpioPin;  // GPIO pin for LED/Relay');
    }
    
    buffer.writeln('bool ledState = false;');
    buffer.writeln();
    buffer.writeln('ESP8266WebServer server(80);');
    buffer.writeln();
    buffer.writeln('void setup() {');
    buffer.writeln('  Serial.begin(115200);');
    
    if (device?.type == DeviceType.waterPump) {
      buffer.writeln('  pinMode(ON_PIN, OUTPUT);');
      buffer.writeln('  pinMode(OFF_PIN, OUTPUT);');
      buffer.writeln('  digitalWrite(ON_PIN, LOW);');
      buffer.writeln('  digitalWrite(OFF_PIN, LOW);');
    } else {
      buffer.writeln('  pinMode(LED_PIN, OUTPUT);');
      buffer.writeln('  digitalWrite(LED_PIN, LOW);');
    }
    
    buffer.writeln('  ');
    buffer.writeln('  // Connect to WiFi');
    buffer.writeln('  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);');
    buffer.writeln('  Serial.print("Connecting to WiFi");');
    buffer.writeln('  while (WiFi.status() != WL_CONNECTED) {');
    buffer.writeln('    delay(500);');
    buffer.writeln('    Serial.print(".");');
    buffer.writeln('  }');
    buffer.writeln('  Serial.println("");');
    buffer.writeln('  Serial.print("Connected! IP address: ");');
    buffer.writeln('  Serial.println(WiFi.localIP());');
    buffer.writeln('  ');
    buffer.writeln('  // Setup HTTP endpoints');
    buffer.writeln('  server.on("/$deviceName/status", handleStatus);');
    
    // Different endpoints for motor vs regular devices
    if (device?.type == DeviceType.waterPump) {
      buffer.writeln('  server.on("/$deviceName.on/1", handleOnPulse);');
      buffer.writeln('  server.on("/$deviceName.on/0", handleOnRelease);');
      buffer.writeln('  server.on("/$deviceName.off/1", handleOffPulse);');
      buffer.writeln('  server.on("/$deviceName.off/0", handleOffRelease);');
    } else {
      buffer.writeln('  server.on("/$deviceName/on", handleOn);');
      buffer.writeln('  server.on("/$deviceName/off", handleOff);');
    }
    
    buffer.writeln('  server.begin();');
    buffer.writeln('  Serial.println("HTTP server started");');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void loop() {');
    buffer.writeln('  server.handleClient();');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void handleStatus() {');
    buffer.writeln('  String response = ledState ? "on" : "off";');
    buffer.writeln('  server.send(200, "text/plain", response);');
    buffer.writeln('  Serial.println("Status request: " + response);');
    buffer.writeln('}');
    buffer.writeln();
    
    // Generate appropriate handlers based on device type
    if (device?.type == DeviceType.waterPump) {
      buffer.writeln('void handleOnPulse() {');
      buffer.writeln('  digitalWrite(ON_PIN, HIGH);');
      buffer.writeln('  server.send(200, "text/plain", "ON_RELAY_ACTIVE");');
      buffer.writeln('  Serial.println("ON relay activated");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOnRelease() {');
      buffer.writeln('  digitalWrite(ON_PIN, LOW);');
      buffer.writeln('  server.send(200, "text/plain", "ON_RELAY_OFF");');
      buffer.writeln('  Serial.println("ON relay released");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOffPulse() {');
      buffer.writeln('  digitalWrite(OFF_PIN, HIGH);');
      buffer.writeln('  server.send(200, "text/plain", "OFF_RELAY_ACTIVE");');
      buffer.writeln('  Serial.println("OFF relay activated");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOffRelease() {');
      buffer.writeln('  digitalWrite(OFF_PIN, LOW);');
      buffer.writeln('  server.send(200, "text/plain", "OFF_RELAY_OFF");');
      buffer.writeln('  Serial.println("OFF relay released");');
      buffer.writeln('}');
    } else {
      buffer.writeln('void handleOn() {');
      buffer.writeln('  ledState = true;');
      buffer.writeln('  digitalWrite(LED_PIN, HIGH);');
      buffer.writeln('  server.send(200, "text/plain", "LED turned ON");');
      buffer.writeln('  Serial.println("LED turned ON");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOff() {');
      buffer.writeln('  ledState = false;');
      buffer.writeln('  digitalWrite(LED_PIN, LOW);');
      buffer.writeln('  server.send(200, "text/plain", "LED turned OFF");');
      buffer.writeln('  Serial.println("LED turned OFF");');
      buffer.writeln('}');
    }
    
    return buffer.toString();
  }

  // Storage
  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      _isDarkMode = prefs.getBool('isDarkMode') ?? true;
      _appName = prefs.getString('appName') ?? 'Home Circuit';
      _appMode = AppMode.values[prefs.getInt('appMode') ?? 0];
      _pumpMinThreshold = prefs.getInt('pumpMinThreshold') ?? 20;
      _pumpMaxThreshold = prefs.getInt('pumpMaxThreshold') ?? 80;
      _isSimulationEnabled = prefs.getBool('isSimulationEnabled') ?? false;
      _encryptionEnabled = prefs.getBool('encryptionEnabled') ?? false;
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;

      final devicesJson = prefs.getString('devices');
      if (devicesJson != null) {
        final List<dynamic> devicesList = jsonDecode(devicesJson);
        _devices = devicesList.map((d) => Device.fromJson(d)).toList();
      }

      final roomsJson = prefs.getString('rooms');
      if (roomsJson != null) {
        final List<dynamic> roomsList = jsonDecode(roomsJson);
        _rooms = roomsList.map((r) => Room.fromJson(r)).toList();
      }

      final logsJson = prefs.getString('logs');
      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        _logs = logsList.map((l) => LogEntry.fromJson(l)).toList();
      }

      final wifiJson = prefs.getString('wifiNetworks');
      if (wifiJson != null) {
        final List<dynamic> wifiList = jsonDecode(wifiJson);
        _wifiNetworks = wifiList.map((w) => WifiNetwork.fromJson(w)).toList();
      }

      if (_devices.isEmpty) {
        _addDemoData();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setString('appName', _appName);
      await prefs.setInt('appMode', _appMode.index);
      await prefs.setInt('pumpMinThreshold', _pumpMinThreshold);
      await prefs.setInt('pumpMaxThreshold', _pumpMaxThreshold);
      await prefs.setBool('isSimulationEnabled', _isSimulationEnabled);
      await prefs.setBool('encryptionEnabled', _encryptionEnabled);
      await prefs.setBool('notificationsEnabled', _notificationsEnabled);

      await prefs.setString(
        'devices',
        jsonEncode(_devices.map((d) => d.toJson()).toList()),
      );
      await prefs.setString(
        'rooms',
        jsonEncode(_rooms.map((r) => r.toJson()).toList()),
      );
      await prefs.setString(
        'logs',
        jsonEncode(_logs.map((l) => l.toJson()).toList()),
      );
      await prefs.setString(
        'wifiNetworks',
        jsonEncode(_wifiNetworks.map((w) => w.toJson()).toList()),
      );
    } catch (e) {
      // Handle error silently
    }
  }

  void _addDemoData() {
    _rooms = [
      Room(id: _uuid.v4(), name: 'Living Room', type: RoomType.livingRoom),
      Room(id: _uuid.v4(), name: 'Kitchen', type: RoomType.kitchen),
      Room(id: _uuid.v4(), name: 'Bedroom', type: RoomType.bedroom),
      Room(id: _uuid.v4(), name: 'Garage', type: RoomType.garage),
    ];

    _devices = [
      Device(
        id: _uuid.v4(),
        name: 'Main Light',
        type: DeviceType.light,
        ipAddress: '192.168.1.101',
        gpioPin: 5,
        roomId: _rooms[0].id,
        isOnline: true,
        isOn: true,
        brightness: 80,
      ),
      Device(
        id: _uuid.v4(),
        name: 'Ceiling Fan',
        type: DeviceType.fan,
        ipAddress: '192.168.1.102',
        gpioPin: 4,
        roomId: _rooms[0].id,
        isOnline: true,
        isOn: true,
        fanSpeed: 3,
      ),
      Device(
        id: _uuid.v4(),
        name: 'Kitchen Light',
        type: DeviceType.light,
        ipAddress: '192.168.1.103',
        gpioPin: 12,
        roomId: _rooms[1].id,
        isOnline: true,
        isOn: false,
        brightness: 100,
      ),
      Device(
        id: _uuid.v4(),
        name: 'Water Tank',
        type: DeviceType.waterPump,
        ipAddress: '192.168.1.104',
        gpioPin: 14,
        roomId: _rooms[3].id,
        isOnline: true,
        isOn: false,
        waterLevel: 65,
      ),
      Device(
        id: _uuid.v4(),
        name: 'Gas Detector',
        type: DeviceType.gasSensor,
        ipAddress: '192.168.1.105',
        roomId: _rooms[1].id,
        isOnline: true,
        lpgValue: 12.5,
        coValue: 3.2,
        hasBattery: true,
        batteryLevel: 87,
      ),
      Device(
        id: _uuid.v4(),
        name: 'Bedroom Light',
        type: DeviceType.light,
        ipAddress: '192.168.1.106',
        gpioPin: 13,
        roomId: _rooms[2].id,
        isOnline: false,
        isOn: false,
        brightness: 50,
      ),
    ];

    // Add initial logs
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'App initialized with demo data',
    );
  }

  String generateUuid() => _uuid.v4();

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
