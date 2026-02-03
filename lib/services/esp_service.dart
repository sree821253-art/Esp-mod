import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum DeviceConnectionState { connected, disconnected, connecting }

class EspService {
  static const Duration _timeout = Duration(seconds: 3);
  static const Duration _longTimeout = Duration(seconds: 8); // For ON commands with delay

  // Test connection to a device
  Future<bool> testConnection(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/status'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get device status - ENHANCED with physical switch and battery
  Future<Map<String, dynamic>?> getDeviceStatus(String ipAddress, String deviceName) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/status'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('ESP RESPONSE from $ipAddress');
          print('Raw body: "$body"');
        }
        
        final Map<String, dynamic> status = {
          'online': true,
          'isOn': false,
          'physicalSwitchOn': false,
          'batteryLevel': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Parse response: "relay:on,switch:on,battery:85,water:0,brightness:0"
        final parts = body.toLowerCase().split(',');
        
        for (final part in parts) {
          if (part.contains(':')) {
            final kv = part.split(':');
            if (kv.length == 2) {
              final key = kv[0].trim();
              final value = kv[1].trim();
              
              switch (key) {
                case 'relay':
                  status['isOn'] = value == 'on' || value == '1';
                  if (kDebugMode) print('  → isOn: ${status['isOn']}');
                  break;
                  
                case 'switch':
                  status['physicalSwitchOn'] = value == 'on' || value == '1';
                  if (kDebugMode) print('  → physicalSwitchOn: ${status['physicalSwitchOn']}');
                  break;
                  
                case 'battery':
                  final battery = int.tryParse(value);
                  if (battery != null && battery > 0) {
                    status['batteryLevel'] = battery;
                    if (kDebugMode) print('  → batteryLevel: $battery%');
                  }
                  break;
                  
                case 'water':
                case 'level':
                  final waterLevel = int.tryParse(value);
                  if (waterLevel != null) {
                    status['waterLevel'] = waterLevel;
                    if (kDebugMode) print('  → waterLevel: $waterLevel');
                  }
                  break;
                  
                case 'brightness':
                  final brightness = int.tryParse(value);
                  if (brightness != null && brightness > 0) {
                    status['brightness'] = brightness;
                  }
                  break;
                  
                case 'speed':
                  final speed = int.tryParse(value);
                  if (speed != null && speed > 0) {
                    status['fanSpeed'] = speed;
                  }
                  break;
              }
            }
          }
        }
        
        if (kDebugMode) {
          print('Final parsed status:');
          status.forEach((key, value) => print('  $key: $value'));
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        }
        
        return status;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR fetching status from $ipAddress: $e');
      }
      return null;
    }
  }

  // Turn device ON - WITH POLLING for physical switch confirmation
  Future<Map<String, dynamic>> turnDeviceOn(
    String ipAddress, 
    String deviceName,
    {Function(String)? onStatusUpdate}
  ) async {
    try {
      onStatusUpdate?.call('Sending ON command...');
      
      // Send ON command
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName.on/1'))
          .timeout(_timeout);
      
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Command failed'};
      }
      
      onStatusUpdate?.call('Command sent, waiting for relay activation...');
      
      // Poll for physical switch to turn ON (max 8 seconds)
      final startTime = DateTime.now();
      const maxWait = Duration(seconds: 8);
      const pollInterval = Duration(milliseconds: 500);
      
      while (DateTime.now().difference(startTime) < maxWait) {
        await Future.delayed(pollInterval);
        
        final status = await getDeviceStatus(ipAddress, deviceName);
        
        if (status != null && status['physicalSwitchOn'] == true) {
          onStatusUpdate?.call('✅ Motor started successfully');
          return {
            'success': true,
            'isOn': true,
            'physicalSwitchOn': true,
            'batteryLevel': status['batteryLevel'],
          };
        }
        
        // Update progress
        final elapsed = DateTime.now().difference(startTime).inMilliseconds;
        final progress = (elapsed / maxWait.inMilliseconds * 100).toInt();
        onStatusUpdate?.call('Waiting for motor to start... $progress%');
      }
      
      // Timeout - check one last time
      final finalStatus = await getDeviceStatus(ipAddress, deviceName);
      if (finalStatus != null && finalStatus['physicalSwitchOn'] == true) {
        onStatusUpdate?.call('✅ Motor started');
        return {
          'success': true,
          'isOn': true,
          'physicalSwitchOn': true,
          'batteryLevel': finalStatus['batteryLevel'],
        };
      }
      
      onStatusUpdate?.call('❌ Motor did not start (timeout)');
      return {'success': false, 'message': 'Physical switch did not activate'};
      
    } catch (e) {
      if (kDebugMode) {
        print('ERROR turning ON device at $ipAddress: $e');
      }
      onStatusUpdate?.call('❌ Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Turn device OFF - WITH POLLING for physical switch confirmation
  Future<Map<String, dynamic>> turnDeviceOff(
    String ipAddress, 
    String deviceName,
    {Function(String)? onStatusUpdate}
  ) async {
    try {
      onStatusUpdate?.call('Sending OFF command...');
      
      // Send OFF command - should be INSTANT on ESP32
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName.off/1'))
          .timeout(_timeout);
      
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Command failed'};
      }
      
      onStatusUpdate?.call('Command sent, confirming motor stopped...');
      
      // Poll for physical switch to turn OFF (max 3 seconds for OFF)
      final startTime = DateTime.now();
      const maxWait = Duration(seconds: 3);
      const pollInterval = Duration(milliseconds: 300);
      
      while (DateTime.now().difference(startTime) < maxWait) {
        await Future.delayed(pollInterval);
        
        final status = await getDeviceStatus(ipAddress, deviceName);
        
        if (status != null && status['physicalSwitchOn'] == false) {
          onStatusUpdate?.call('✅ Motor stopped successfully');
          return {
            'success': true,
            'isOn': false,
            'physicalSwitchOn': false,
            'batteryLevel': status['batteryLevel'],
          };
        }
      }
      
      // Check final status
      final finalStatus = await getDeviceStatus(ipAddress, deviceName);
      if (finalStatus != null && finalStatus['physicalSwitchOn'] == false) {
        onStatusUpdate?.call('✅ Motor stopped');
        return {
          'success': true,
          'isOn': false,
          'physicalSwitchOn': false,
          'batteryLevel': finalStatus['batteryLevel'],
        };
      }
      
      onStatusUpdate?.call('❌ Motor did not stop (timeout)');
      return {'success': false, 'message': 'Physical switch still active'};
      
    } catch (e) {
      if (kDebugMode) {
        print('ERROR turning OFF device at $ipAddress: $e');
      }
      onStatusUpdate?.call('❌ Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Toggle device state
  Future<Map<String, dynamic>> toggleDevice(
    String ipAddress, 
    String deviceName, 
    bool currentState,
    {Function(String)? onStatusUpdate}
  ) async {
    if (currentState) {
      return turnDeviceOff(ipAddress, deviceName, onStatusUpdate: onStatusUpdate);
    } else {
      return turnDeviceOn(ipAddress, deviceName, onStatusUpdate: onStatusUpdate);
    }
  }

  // Set brightness for lights (if your ESP supports PWM)
  Future<bool> setBrightness(String ipAddress, String deviceName, int brightness) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/brightness/$brightness'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Set fan speed (if your ESP supports it)
  Future<bool> setFanSpeed(String ipAddress, String deviceName, int speed) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/speed/$speed'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Get sensor data (for gas sensors, water pumps, etc.)
  Future<Map<String, dynamic>?> getSensorData(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/sensors'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        return {
          'lpg': 0.0,
          'co': 0.0,
          'waterLevel': 50,
          'battery': 100,
        };
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Batch status check for multiple devices
  Future<Map<String, bool>> batchStatusCheck(List<String> ipAddresses) async {
    final results = <String, bool>{};
    
    final futures = ipAddresses.map((ip) => testConnection(ip));
    final responses = await Future.wait(futures);
    
    for (int i = 0; i < ipAddresses.length; i++) {
      results[ipAddresses[i]] = responses[i];
    }
    
    return results;
  }
}
