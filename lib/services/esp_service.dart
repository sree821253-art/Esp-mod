import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

enum DeviceConnectionState { connected, disconnected, connecting }

class EspService {
  static const Duration _timeout = Duration(seconds: 3);

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

  // Get device status - reads ACTUAL physical switch state
  Future<Map<String, dynamic>?> getDeviceStatus(String ipAddress, String deviceName) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/status'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('ESP STATUS from $ipAddress');
          print('Raw: "$body"');
        }
        
        final Map<String, dynamic> status = {
          'online': true,
          'isOn': false,
          'physicalSwitchOn': false,
          'batteryLevel': null,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Parse: "relay:on,switch:on,battery:85,water:0,brightness:0"
        final parts = body.toLowerCase().split(',');
        
        for (final part in parts) {
          if (part.contains(':')) {
            final kv = part.split(':');
            if (kv.length == 2) {
              final key = kv[0].trim();
              final value = kv[1].trim();
              
              switch (key) {
                case 'relay':
                  // Relay state (what motor should be doing)
                  status['isOn'] = value == 'on' || value == '1';
                  break;
                  
                case 'switch':
                  // Physical switch state (what motor IS actually doing)
                  status['physicalSwitchOn'] = value == 'on' || value == '1';
                  // IMPORTANT: Use physical switch as source of truth
                  status['isOn'] = value == 'on' || value == '1';
                  if (kDebugMode) print('  → Motor actually: ${status['isOn'] ? "RUNNING" : "STOPPED"}');
                  break;
                  
                case 'battery':
                  final battery = int.tryParse(value);
                  if (battery != null && battery > 0) {
                    status['batteryLevel'] = battery;
                  }
                  break;
                  
                case 'water':
                case 'level':
                  final waterLevel = int.tryParse(value);
                  if (waterLevel != null) {
                    status['waterLevel'] = waterLevel;
                  }
                  break;
              }
            }
          }
        }
        
        if (kDebugMode) {
          print('Final: isOn=${status['isOn']}, physicalSwitch=${status['physicalSwitchOn']}, battery=${status['batteryLevel']}');
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
      
      // Send ON command (ESP32 will wait 5 seconds before pulsing relay)
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName.on/1'))
          .timeout(_timeout);
      
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Command failed'};
      }
      
      onStatusUpdate?.call('Command sent, motor will start in 5 seconds...');
      
      // Poll for physical switch to turn ON
      // ESP32 has 5 second delay, so we poll for up to 8 seconds total
      final startTime = DateTime.now();
      const maxWait = Duration(seconds: 10); // Increased to 10 seconds
      const pollInterval = Duration(milliseconds: 500);
      
      int pollCount = 0;
      while (DateTime.now().difference(startTime) < maxWait) {
        await Future.delayed(pollInterval);
        pollCount++;
        
        final status = await getDeviceStatus(ipAddress, deviceName);
        
        if (status != null) {
          // Check if physical switch is ON
          if (status['physicalSwitchOn'] == true) {
            onStatusUpdate?.call('✅ Motor started successfully');
            return {
              'success': true,
              'isOn': true,
              'physicalSwitchOn': true,
              'batteryLevel': status['batteryLevel'],
            };
          }
          
          // Show progress
          final elapsed = DateTime.now().difference(startTime).inSeconds;
          if (elapsed <= 5) {
            onStatusUpdate?.call('Motor will start in ${5 - elapsed} seconds...');
          } else {
            onStatusUpdate?.call('Waiting for motor to start... (${elapsed}s)');
          }
        }
      }
      
      // Timeout - one final check
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
      
      onStatusUpdate?.call('❌ Motor did not start (timeout after 10s)');
      return {'success': false, 'message': 'Physical switch did not activate'};
      
    } catch (e) {
      if (kDebugMode) {
        print('ERROR turning ON device: $e');
      }
      onStatusUpdate?.call('❌ Error: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  // Turn device OFF - WITH POLLING for confirmation
  Future<Map<String, dynamic>> turnDeviceOff(
    String ipAddress, 
    String deviceName,
    {Function(String)? onStatusUpdate}
  ) async {
    try {
      onStatusUpdate?.call('Sending OFF command...');
      
      // Send OFF command (ESP32 executes immediately)
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName.off/1'))
          .timeout(_timeout);
      
      if (response.statusCode != 200) {
        return {'success': false, 'message': 'Command failed'};
      }
      
      onStatusUpdate?.call('Stopping motor...');
      
      // Poll for physical switch to turn OFF
      final startTime = DateTime.now();
      const maxWait = Duration(seconds: 5); // Longer timeout for OFF
      const pollInterval = Duration(milliseconds: 300);
      
      while (DateTime.now().difference(startTime) < maxWait) {
        await Future.delayed(pollInterval);
        
        final status = await getDeviceStatus(ipAddress, deviceName);
        
        if (status != null) {
          // Check if physical switch is OFF
          if (status['physicalSwitchOn'] == false) {
            onStatusUpdate?.call('✅ Motor stopped successfully');
            return {
              'success': true,
              'isOn': false,
              'physicalSwitchOn': false,
              'batteryLevel': status['batteryLevel'],
            };
          }
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
        print('ERROR turning OFF device: $e');
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

  // Set brightness for lights
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

  // Set fan speed
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
