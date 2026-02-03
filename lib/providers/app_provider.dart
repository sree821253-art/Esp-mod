import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
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
  String _executionStatus = '';
  int _pumpMinThreshold = 20;
  int _pumpMaxThreshold = 80;

  final List<Device> _devices = [];
  final List<Room> _rooms = [];
  final List<LogEntry> _logs = [];
  final List<WifiNetwork> _wifiNetworks = [];

  Timer? _simulationTimer;
  Timer? _autoSyncTimer;
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
  String get executionStatus => _executionStatus;
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

  void _startAutoSync() {
  _autoSyncTimer?.cancel();
  _autoSyncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
    if (!_isSyncing && !_isSimulationEnabled) {
      syncDevices(silent: true);  // CHANGED: Add silent: true
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
  void _setExecutionStatus(String status) {
    _executionStatus = status;
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

      _devices[i] = device.copyWith(
        isOnline: random.nextDouble() > 0.1,
        lastSeen: DateTime.now(),
      );

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

      if (device.type == DeviceType.gasSensor) {
        _devices[i] = device.copyWith(
          lpgValue: (random.nextDouble() * 100).clamp(0, 100),
          coValue: (random.nextDouble() * 50).clamp(0, 50),
        );
      }

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
// Sync Devices - SIMPLIFIED (ESP CONTROLS THRESHOLDS)
Future<void> syncDevices({bool silent = false}) async {
  if (_isSyncing) return;
  
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
      _addLog(
        deviceId: 'system',
        deviceName: 'System',
        type: LogType.sync,
        action: 'Device sync completed',
        details: 'No devices to sync',
      );
    }
    _isSyncing = false;
    notifyListeners();
    return;
  }

  int onlineCount = 0;

  for (int i = 0; i < _devices.length; i++) {
    final device = _devices[i];
    
    if (kDebugMode) {
      print('\n╔═══════════════════════════════════════════════════════');
      print('║ SYNCING DEVICE: ${device.name}');
      print('║ IP: ${device.ipAddress}');
      print('╚═══════════════════════════════════════════════════════');
    }

    final status = await _espService.getDeviceStatus(device.ipAddress, device.name);

    if (status != null) {
      if (kDebugMode) {
        print('✓ Got status from ${device.name}');
      }
      
      final updates = <String, dynamic>{
        'isOnline': true,
        'isOn': status['physicalSwitchOn'] ?? status['isOn'] ?? false,  // Physical switch is source of truth
        'physicalSwitchOn': status['physicalSwitchOn'] ?? status['isOn'] ?? false,
        'lastSeen': DateTime.now(),
      };

      // Add sensor data
      if (status['waterLevel'] != null) {
        updates['waterLevel'] = status['waterLevel'];
      }
      if (status['lpgValue'] != null) {
        updates['lpgValue'] = status['lpgValue'];
      }
      if (status['coValue'] != null) {
        updates['coValue'] = status['coValue'];
      }
      if (status['batteryLevel'] != null) {
        updates['batteryLevel'] = status['batteryLevel'];
      }
      if (status['brightness'] != null) {
        updates['brightness'] = status['brightness'];
      }
      if (status['fanSpeed'] != null) {
        updates['fanSpeed'] = status['fanSpeed'];
      }

      // Fetch child battery if configured
      if (device.hasChildBattery && device.childIp != null && device.childIp!.isNotEmpty) {
        if (kDebugMode) {
          print('\n🔋 Fetching child battery from ${device.childIp}...');
        }
        
        final childStatus = await _espService.getChildStatus(device.childIp!);
        
        if (childStatus != null) {
          if (childStatus['childBatteryLevel'] != null) {
            updates['childBatteryLevel'] = childStatus['childBatteryLevel'];
            if (kDebugMode) {
              print('✓ Child battery: ${childStatus['childBatteryLevel']}%');
            }
          }
          
          if (childStatus['waterLevel'] != null) {
            updates['waterLevel'] = childStatus['waterLevel'];
            if (kDebugMode) {
              print('✓ Water level from child: ${childStatus['waterLevel']}%');
            }
          }
        }
      }

      _devices[i] = device.copyWith(
        isOnline: updates['isOnline'],
        isOn: updates['isOn'],
        physicalSwitchOn: updates['physicalSwitchOn'],
        lastSeen: updates['lastSeen'],
        waterLevel: updates['waterLevel'],
        lpgValue: updates['lpgValue'],
        coValue: updates['coValue'],
        batteryLevel: updates['batteryLevel'],
        childBatteryLevel: updates['childBatteryLevel'],
        brightness: updates['brightness'],
        fanSpeed: updates['fanSpeed'],
      );
      
      onlineCount++;
      
      // NO THRESHOLD CONTROL - ESP handles it autonomously
      // App just displays current state from physical switch
      
    } else {
      // Mark device offline after failed poll
      if (kDebugMode) {
        print('⚠️ Failed to get status from ${device.name} - marking offline');
      }
      _devices[i] = device.copyWith(
        isOnline: false,  // FIXED: Actually mark offline
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
      details: '$onlineCount/${_devices.length} devices responding',
    );
  }

  _isSyncing = false;
  _saveToStorage();
  notifyListeners();
  
  if (kDebugMode) {
    print('\n═══════════════════════════════════════════════════════');
    print('SYNC COMPLETE - $onlineCount/$totalDevices responding');
    print('═══════════════════════════════════════════════════════\n');
  }
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
        success = await _espService.turnDeviceOn(light.ipAddress, light.name);
      } else {
        success = await _espService.turnDeviceOff(light.ipAddress, light.name);
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

// Toggle Device - WITH DYNAMIC PHYSICAL SWITCH POLLING
// Toggle Device - WITH MOTOR STATE MACHINE
Future<bool> toggleDevice(String id) async {
  final index = _devices.indexWhere((d) => d.id == id);
  if (index == -1) return false;

  final device = _devices[index];
  
  if (_appMode == AppMode.localAuto) {
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.info,
      action: 'Manual override in Local Auto mode',
    );
  }
  
  // Handle motor vs regular device
  if (device.type == DeviceType.waterPump) {
    return await _toggleMotor(device, index);
  } else {
    return await _toggleStandardDevice(device, index);
  }
}

// NEW METHOD - Motor toggle with state machine
Future<bool> _toggleMotor(Device device, int index) async {
  final newState = !device.isOn;
  final startTime = DateTime.now();
  
  if (newState) {
    // ═══════════ ON SEQUENCE ═══════════
    _setExecutionStatus('🔄 Sending ON pulse...');
    notifyListeners();
    
    final commandSent = await _espService.turnDeviceOn(device.ipAddress, device.name);
    if (!commandSent) {
      _addLog(
        deviceId: device.id,
        deviceName: device.name,
        type: LogType.error,
        action: 'ON command failed - Network error',
      );
      _setExecutionStatus('❌ Command failed');
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _setExecutionStatus('');
      notifyListeners();
      return false;
    }
    
    // Wait 5 seconds for relay execution
    await Future.delayed(const Duration(seconds: 5));
    
    _setExecutionStatus('⏳ Waiting for physical switch (10s timeout)...');
    notifyListeners();
    
    // Poll for 10 seconds
    for (int i = 0; i < 20; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final status = await _espService.getDeviceStatus(device.ipAddress, device.name);
      
      if (status != null && status['physicalSwitchOn'] == true) {
        // SUCCESS
        _devices[index] = device.copyWith(
          isOn: true,
          physicalSwitchOn: true,
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: LogType.deviceOn,
          action: 'Motor ON confirmed',
        );
        
        _setExecutionStatus('✅ Motor ON successful!');
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        _setExecutionStatus('');
        _saveToStorage();
        notifyListeners();
        return true;
      }
      
      // Update countdown
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      _setExecutionStatus('⏳ Confirming... (${elapsed}/15s)');
      notifyListeners();
    }
    
    // TIMEOUT
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.error,
      action: 'ON timeout - Physical switch not responding',
    );
    _setExecutionStatus('❌ Timeout - Try again');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _setExecutionStatus('');
    notifyListeners();
    return false;
    
  } else {
    // ═══════════ OFF SEQUENCE ═══════════
    _setExecutionStatus('🛑 Sending OFF pulse...');
    notifyListeners();
    
    final commandSent = await _espService.turnDeviceOff(device.ipAddress, device.name);
    if (!commandSent) {
      _addLog(
        deviceId: device.id,
        deviceName: device.name,
        type: LogType.error,
        action: 'OFF command failed - Network error',
      );
      _setExecutionStatus('❌ Command failed');
      notifyListeners();
      await Future.delayed(const Duration(seconds: 2));
      _setExecutionStatus('');
      notifyListeners();
      return false;
    }
    
    _setExecutionStatus('⏳ Waiting for physical switch to go LOW...');
    notifyListeners();
    
    // Poll until switch goes LOW (30 second safety timeout)
    while (DateTime.now().difference(startTime).inSeconds < 30) {
      await Future.delayed(const Duration(milliseconds: 500));
      
      final status = await _espService.getDeviceStatus(device.ipAddress, device.name);
      
      if (status != null && status['physicalSwitchOn'] == false) {
        // SUCCESS
        _devices[index] = device.copyWith(
          isOn: false,
          physicalSwitchOn: false,
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        
        _addLog(
          deviceId: device.id,
          deviceName: device.name,
          type: LogType.deviceOff,
          action: 'Motor OFF confirmed',
        );
        
        _setExecutionStatus('✅ Motor OFF successful!');
        notifyListeners();
        await Future.delayed(const Duration(seconds: 1));
        _setExecutionStatus('');
        _saveToStorage();
        notifyListeners();
        return true;
      }
      
      // Update status
      final elapsed = DateTime.now().difference(startTime).inSeconds;
      _setExecutionStatus('⏳ Waiting for switch LOW... (${elapsed}s)');
      notifyListeners();
    }
    
    // TIMEOUT (30 seconds)
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.error,
      action: 'OFF timeout - Motor may still be running',
    );
    _setExecutionStatus('❌ Timeout - Check motor manually');
    notifyListeners();
    await Future.delayed(const Duration(seconds: 2));
    _setExecutionStatus('');
    notifyListeners();
    return false;
  }
}

// NEW METHOD - Standard device toggle
Future<bool> _toggleStandardDevice(Device device, int index) async {
  final newState = !device.isOn;
  
  bool commandSent;
  if (newState) {
    commandSent = await _espService.turnDeviceOn(device.ipAddress, device.name);
  } else {
    commandSent = await _espService.turnDeviceOff(device.ipAddress, device.name);
  }
  
  if (!commandSent) {
    _addLog(
      deviceId: device.id,
      deviceName: device.name,
      type: LogType.error,
      action: 'Command failed - Network error',
    );
    return false;
  }
  
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
}

  // Set Brightness - REAL HTTP COMMUNICATION
  void setBrightness(String id, int brightness) async {
    final index = _devices.indexWhere((d) => d.id == id);
    if (index != -1) {
      final device = _devices[index];
      
      _devices[index] = device.copyWith(brightness: brightness.clamp(0, 100));
      notifyListeners();
      
      final success = await _espService.setBrightness(
        device.ipAddress,
        device.name,  // ADDED
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
      
      _devices[index] = device.copyWith(fanSpeed: speed.clamp(1, 5));
      notifyListeners();
      
      final success = await _espService.setFanSpeed(
        device.ipAddress,
        device.name,  // ADDED
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
    final roomToDelete = _rooms.firstWhere((r) => r.id == id);
    _rooms.removeWhere((r) => r.id == id);
    _devices.removeWhere((d) => d.roomId == id);
    
    _addLog(
      deviceId: 'system',
      deviceName: 'System',
      type: LogType.info,
      action: 'Room deleted: ${roomToDelete.name}',
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
  _logs.removeRange(1000, _logs.length);
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
    final isParent = device?.isParent ?? false;
    
    buffer.writeln('/*');
    buffer.writeln(' * $_appName - ${isParent ? 'PARENT (ESP32)' : 'CHILD (ESP8266)'} Controller');
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
  final parent = _devices.firstWhere(
    (d) => d.id == device!.parentId,
    orElse: () => _devices.first,
  );
  buffer.writeln('const char* PARENT_IP = "${parent.ipAddress}";');
}
    
    // Determine pin configuration based on device type
    String pinDeclarations;
    if (device?.type == DeviceType.waterPump) {
      final onPin = device?.onPin ?? 14;
      final offPin = device?.offPin ?? 27;
      final statusPin = device?.statusGpioPin ?? 4;
      
      pinDeclarations = '''
const int ON_PIN = $onPin;      // Motor ON relay
const int OFF_PIN = $offPin;     // Motor OFF relay
const int STATUS_PIN = $statusPin; // Physical switch input
''';
    } else {
      final gpioPin = device?.gpioPin ?? 2;
      final statusPin = device?.statusGpioPin ?? 4;
      
      pinDeclarations = '''
const int CONTROL_PIN = $gpioPin;
const int STATUS_PIN = $statusPin;
''';
    }
    
    buffer.writeln();
    buffer.writeln(pinDeclarations);
    buffer.writeln('const int STATUS_PIN = $statusPin;');
    buffer.writeln('bool ledState = false;');
    buffer.writeln();
    
    buffer.writeln('void setup() {');
    buffer.writeln('  Serial.begin(115200);');
    
    if (device?.type == DeviceType.waterPump) {
      buffer.writeln('  pinMode(ON_PIN, OUTPUT);');
      buffer.writeln('  pinMode(OFF_PIN, OUTPUT);');
      buffer.writeln('  pinMode(STATUS_PIN, INPUT_PULLUP);');
      buffer.writeln('  digitalWrite(ON_PIN, LOW);');
      buffer.writeln('  digitalWrite(OFF_PIN, LOW);');
    } else {
      buffer.writeln('  pinMode(CONTROL_PIN, OUTPUT);');
      buffer.writeln('  pinMode(STATUS_PIN, INPUT_PULLUP);');
      buffer.writeln('  digitalWrite(CONTROL_PIN, LOW);');
    }
    buffer.writeln('  ');
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
    final deviceName = device?.name.replaceAll(' ', '_').toLowerCase() ?? 'device';
    
    buffer.writeln('  server.on("/", handleRoot);');
    buffer.writeln('  server.on("/$deviceName/status", handleStatus);');
    buffer.writeln('  server.on("/$deviceName/on", handleOn);');
    buffer.writeln('  server.on("/$deviceName/1", handleOn);');
    buffer.writeln('  server.on("/$deviceName/off", handleOff);');
    buffer.writeln('  server.on("/$deviceName/0", handleOff);');
    buffer.writeln('  server.begin();');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void loop() {');
    buffer.writeln('  server.handleClient();');
    buffer.writeln('  ');
    buffer.writeln('  bool actualState = !digitalRead(STATUS_PIN);');
    buffer.writeln('  if (actualState != ledState) {');
    buffer.writeln('    ledState = actualState;');
    buffer.writeln('    digitalWrite(CONTROL_PIN, ledState ? HIGH : LOW);');
    if (!isParent && device?.parentId != null) {
      buffer.writeln('    notifyParent();');
    }
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    
    buffer.writeln('void handleRoot() {');
    buffer.writeln('  String html = "<h1>${isParent ? 'PARENT' : 'CHILD'} Device</h1>";');
    buffer.writeln('  html += "<p>IP: " + WiFi.localIP().toString() + "</p>";');
    buffer.writeln('  html += "<p>Status: " + String(ledState ? "ON" : "OFF") + "</p>";');
    buffer.writeln('  server.send(200, "text/html", html);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('void handleStatus() {');
buffer.writeln('  // Read actual physical switch state');
buffer.writeln('  bool actualState = !digitalRead(STATUS_PIN);');
buffer.writeln('  ledState = actualState;');
buffer.writeln('  ');
buffer.writeln('  // Send both relay and physical switch status');
buffer.writeln('  String response = "relay:";');
buffer.writeln('  response += ledState ? "on" : "off";');
buffer.writeln('  response += ",switch:";');
buffer.writeln('  response += actualState ? "on" : "off";');
buffer.writeln('  ');
buffer.writeln('  server.send(200, "text/plain", response);');
buffer.writeln('  lastCommandTime = millis();');
buffer.writeln('}');
    buffer.writeln();
    if (device?.type == DeviceType.waterPump) {
      buffer.writeln('void handleOn() {');
      buffer.writeln('  digitalWrite(ON_PIN, HIGH);   // Activate ON relay');
      buffer.writeln('  delay(100);');
      buffer.writeln('  digitalWrite(ON_PIN, LOW);    // Pulse complete');
      buffer.writeln('  server.send(200, "text/plain", "ON_PULSE_SENT");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOff() {');
      buffer.writeln('  digitalWrite(OFF_PIN, HIGH);  // Activate OFF relay');
      buffer.writeln('  delay(100);');
      buffer.writeln('  digitalWrite(OFF_PIN, LOW);   // Pulse complete');
      buffer.writeln('  server.send(200, "text/plain", "OFF_PULSE_SENT");');
      buffer.writeln('}');
    } else {
      buffer.writeln('void handleOn() {');
      buffer.writeln('  ledState = true;');
      buffer.writeln('  digitalWrite(CONTROL_PIN, HIGH);');
      buffer.writeln('  server.send(200, "text/plain", "ON");');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void handleOff() {');
      buffer.writeln('  ledState = false;');
      buffer.writeln('  digitalWrite(CONTROL_PIN, LOW);');
      buffer.writeln('  server.send(200, "text/plain", "OFF");');
      buffer.writeln('}');
    }
    
    if (!isParent && device?.parentId != null) {
      buffer.writeln();
      buffer.writeln('void notifyParent() {');
      buffer.writeln('  // TODO: Send HTTP request to parent');
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
        _devices.clear();
        _devices.addAll(devicesList.map((d) => Device.fromJson(d)).toList());
      }

      final roomsJson = prefs.getString('rooms');
      if (roomsJson != null) {
        final List<dynamic> roomsList = jsonDecode(roomsJson);
        _rooms.clear();
        _rooms.addAll(roomsList.map((r) => Room.fromJson(r)).toList());
      }

      final logsJson = prefs.getString('logs');
      if (logsJson != null) {
        final List<dynamic> logsList = jsonDecode(logsJson);
        _logs.clear();
        _logs.addAll(logsList.map((l) => LogEntry.fromJson(l)).toList());
      }

      final wifiJson = prefs.getString('wifiNetworks');
      if (wifiJson != null) {
        final List<dynamic> wifiList = jsonDecode(wifiJson);
        _wifiNetworks.clear();
        _wifiNetworks.addAll(wifiList.map((w) => WifiNetwork.fromJson(w)).toList());
      }

      if (_devices.isEmpty) {
        _addDemoData();
      }
    } catch (e) {
      if (kDebugMode) print('Error loading from storage: $e');
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
      if (kDebugMode) print('Error saving to storage: $e');
    }
  }

  void _addDemoData() {
    _rooms.clear();
    _rooms.addAll([
      Room(id: _uuid.v4(), name: 'Living Room', type: RoomType.livingRoom),
      Room(id: _uuid.v4(), name: 'Kitchen', type: RoomType.kitchen),
      Room(id: _uuid.v4(), name: 'Bedroom', type: RoomType.bedroom),
      Room(id: _uuid.v4(), name: 'Garage', type: RoomType.garage),
    ]);

    _devices.clear();
    _devices.addAll([
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
    ]);

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
