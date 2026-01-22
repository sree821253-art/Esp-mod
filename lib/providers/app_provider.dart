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
Timer? _autoSyncTimer; // ADD THIS LINE
  final _uuid = const Uuid();

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
  
  // Start auto-sync every 10 seconds
  _startAutoSync();
}

void _startAutoSync() {
  _autoSyncTimer?.cancel();
  _autoSyncTimer = Timer.periodic(const Duration(seconds: 10), (_) {
    if (!_isSyncing && !_isSimulationEnabled) {
      syncDevices();
    }
  });
}

void _stopAutoSync() {
  _autoSyncTimer?.cancel();
  _autoSyncTimer = null;
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
  Future<void> syncDevices() async {
    _isSyncing = true;
    _syncProgress = 0;
    notifyListeners();

    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.sync,
      action: 'Device sync started',
    );

    final totalDevices = _devices.length;
    if (totalDevices == 0) {
      await Future.delayed(const Duration(seconds: 2));
      _syncProgress = 1.0;
      _isSyncing = false;
      notifyListeners();
      return;
    }

    int onlineCount = 0;

    for (int i = 0; i < _devices.length; i++) {
      final device = _devices[i];

      // Use REAL HTTP communication
      final status = await _espService.getDeviceStatus(device.ipAddress);

      if (status != null) {
        _devices[i] = device.copyWith(
          isOnline: true,
          isOn: status['isOn'] ?? false,
          lastSeen: DateTime.now(),
        );
        onlineCount++;
      } else {
        _devices[i] = device.copyWith(
          isOnline: false,
          lastSeen: DateTime.now(),
        );
      }

      _syncProgress = (i + 1) / totalDevices;
      notifyListeners();
      
      // Small delay between requests to avoid overwhelming network
      await Future.delayed(const Duration(milliseconds: 200));
    }

    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.sync,
      action: 'Device sync completed',
      details: '$onlineCount/${_devices.length} devices online',
    );

    _isSyncing = false;
    _saveToStorage();
    notifyListeners();
  }

  // Master Switch - REAL HTTP COMMUNICATION
  Future<bool> masterSwitch(String key, bool turnOn) async {
    if (key != authKey) return false;

    final lights = lightDevices;
    int successCount = 0;
    int failCount = 0;

    for (final light in lights) {
      bool success;
      
      if (turnOn) {
        success = await _espService.turnDeviceOn(light.ipAddress);
      } else {
        success = await _espService.turnDeviceOff(light.ipAddress);
      }

      if (success) {
        final index = _devices.indexWhere((d) => d.id == light.id);
        if (index != -1) {
          _devices[index] = _devices[index].copyWith(
            isOn: turnOn,
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

  // Toggle Device - REAL HTTP COMMUNICATION
  Future<bool> toggleDevice(String id) async {
  final index = _devices.indexWhere((d) => d.id == id);
  if (index == -1) return false;

  final device = _devices[index];
  
  // Allow manual override even in Local Auto mode
  if (_appMode == AppMode.localAuto) {
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.info,
      action: 'Manual override in Local Auto mode',
    );
  }
    final newState = !device.isOn;

    // Use REAL HTTP communication
    bool success;
    if (newState) {
      success = await _espService.turnDeviceOn(device.ipAddress);
    } else {
      success = await _espService.turnDeviceOff(device.ipAddress);
    }

    if (success) {
      _devices[index] = device.copyWith(
        isOn: newState,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
      _addLog(
        deviceId: device.id,
        deviceName: device.name,
        type: newState ? LogType.deviceOn : LogType.deviceOff,
        action: newState ? 'Turned ON' : 'Turned OFF',
      );
      _saveToStorage();
      notifyListeners();
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
        action: 'Command failed - Device offline',
      );
      notifyListeners();
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
      
      // Send to ESP in background
      final success = await _espService.setBrightness(
        device.ipAddress,
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
      
      // Send to ESP in background
      final success = await _espService.setFanSpeed(
        device.ipAddress,
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

  // FIXED: Actually remove devices instead of just unassigning
  _devices.removeWhere((d) => d.roomId == id);
      
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
  
  // Detect if generating for parent or child
  final device = _devices.isNotEmpty ? _devices.first : null;
  final isParent = device?.isParent ?? false;
  
  buffer.writeln('/*');
  buffer.writeln(' * $appName - ${isParent ? 'PARENT (ESP32)' : 'CHILD (ESP8266)'} Controller');
  buffer.writeln(' * Generated: ${DateTime.now().toIso8601String()}');
  buffer.writeln(' */');
  buffer.writeln();
  
  if (isParent) {
    buffer.writeln('#include <WiFi.h>  // ESP32');
    buffer.writeln('#include <WebServer.h>');
    buffer.writeln('WebServer server(80);');
  } else {
    buffer.writeln('#include <ESP8266WiFi.h>  // ESP8266');
    buffer.writeln('#include <ESP8266WebServer.h>');
    buffer.writeln('ESP8266WebServer server(80);');
  }
  
  buffer.writeln();
  buffer.writeln('// ========== NETWORK CONFIGURATION ==========');
  
  if (_wifiNetworks.isNotEmpty) {
    buffer.writeln('const char* WIFI_SSID = "${_wifiNetworks.first.ssid}";');
    buffer.writeln('const char* WIFI_PASSWORD = "${_encryptionEnabled ? '********' : _wifiNetworks.first.password}";');
  }
  
  buffer.writeln();
  buffer.writeln('// Static IP Configuration');
  final staticIP = device?.staticIP ?? (isParent ? '192.168.1.100' : '192.168.1.101');
  buffer.writeln('IPAddress local_IP($staticIP);');
  buffer.writeln('IPAddress gateway(192, 168, 1, 1);');
  buffer.writeln('IPAddress subnet(255, 255, 255, 0);');
  
  if (!isParent && device?.parentId != null) {
    final parent = _devices.firstWhere((d) => d.id == device.parentId, orElse: () => device);
    buffer.writeln('const char* PARENT_IP = "${parent.ipAddress}";');
  }
  
  final gpioPin = device?.gpioPin ?? 2;
  final statusPin = device?.statusGpioPin ?? 4;
  
  buffer.writeln();
  buffer.writeln('const int CONTROL_PIN = $gpioPin;');
  buffer.writeln('const int STATUS_PIN = $statusPin;');
  buffer.writeln('bool ledState = false;');
  buffer.writeln();
  
  buffer.writeln('void setup() {');
  buffer.writeln('  Serial.begin(115200);');
  buffer.writeln('  pinMode(CONTROL_PIN, OUTPUT);');
  buffer.writeln('  pinMode(STATUS_PIN, INPUT_PULLUP);');
  buffer.writeln('  digitalWrite(CONTROL_PIN, LOW);');
  buffer.writeln('  ');
  buffer.writeln('  // Configure static IP');
  buffer.writeln('  if (!WiFi.config(local_IP, gateway, subnet)) {');
  buffer.writeln('    Serial.println("Static IP Failed!");');
  buffer.writeln('  }');
  buffer.writeln('  ');
  buffer.writeln('  WiFi.mode(WIFI_STA);');
  buffer.writeln('  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);');
  buffer.writeln('  Serial.print("Connecting");');
  buffer.writeln('  int attempts = 0;');
  buffer.writeln('  while (WiFi.status() != WL_CONNECTED && attempts < 30) {');
  buffer.writeln('    delay(500);');
  buffer.writeln('    Serial.print(".");');
  buffer.writeln('    attempts++;');
  buffer.writeln('  }');
  buffer.writeln('  ');
  buffer.writeln('  if (WiFi.status() == WL_CONNECTED) {');
  buffer.writeln('    Serial.println("\\nConnected!");');
  buffer.writeln('    Serial.print("IP: ");');
  buffer.writeln('    Serial.println(WiFi.localIP());');
  buffer.writeln('  }');
  buffer.writeln('  ');
  buffer.writeln('  server.on("/", handleRoot);');
  buffer.writeln('  server.on("/status", handleStatus);');
  buffer.writeln('  server.on("/led/on", handleLedOn);');
  buffer.writeln('  server.on("/led/off", handleLedOff);');
  buffer.writeln('  server.begin();');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('void loop() {');
  buffer.writeln('  server.handleClient();');
  buffer.writeln('  ');
  buffer.writeln('  // Monitor physical switch');
  buffer.writeln('  bool actualState = !digitalRead(STATUS_PIN);');
  buffer.writeln('  if (actualState != ledState) {');
  buffer.writeln('    ledState = actualState;');
  buffer.writeln('    digitalWrite(CONTROL_PIN, ledState ? HIGH : LOW);');
  if (!isParent && device?.parentId != null) {
    buffer.writeln('    notifyParent(); // Inform parent of state change');
  }
  buffer.writeln('  }');
  buffer.writeln('}');
  buffer.writeln();
  
  // Add handlers
  buffer.writeln('void handleRoot() {');
  buffer.writeln('  String html = "<h1>${isParent ? 'PARENT' : 'CHILD'} Device</h1>";');
  buffer.writeln('  html += "<p>IP: " + WiFi.localIP().toString() + "</p>";');
  buffer.writeln('  html += "<p>Status: " + String(ledState ? "ON" : "OFF") + "</p>";');
  buffer.writeln('  server.send(200, "text/html", html);');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('void handleStatus() {');
  buffer.writeln('  bool actualState = !digitalRead(STATUS_PIN);');
  buffer.writeln('  ledState = actualState;');
  buffer.writeln('  server.send(200, "text/plain", ledState ? "on" : "off");');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('void handleLedOn() {');
  buffer.writeln('  ledState = true;');
  buffer.writeln('  digitalWrite(CONTROL_PIN, HIGH);');
  buffer.writeln('  server.send(200, "text/plain", "ON");');
  buffer.writeln('}');
  buffer.writeln();
  buffer.writeln('void handleLedOff() {');
  buffer.writeln('  ledState = false;');
  buffer.writeln('  digitalWrite(CONTROL_PIN, LOW);');
  buffer.writeln('  server.send(200, "text/plain", "OFF");');
  buffer.writeln('}');
  
  if (!isParent && device?.parentId != null) {
    buffer.writeln();
    buffer.writeln('void notifyParent() {');
    buffer.writeln('  // TODO: Send HTTP request to parent');
    buffer.writeln('  // WiFiClient client;');
    buffer.writeln('  // client.connect(PARENT_IP, 80);');
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
  _autoSyncTimer?.cancel(); // ADD THIS LINE
  super.dispose();
}
}
