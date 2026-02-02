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

  // Get device status - WITH DETAILED DEBUG LOGGING
  // Get device status - WITH DETAILED DEBUG LOGGING
  Future<Map<String, dynamic>?> getDeviceStatus(String ipAddress, String deviceName) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/status'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        
        // DEBUG: Print raw response
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('ESP RESPONSE from $ipAddress');
          print('Raw body: "$body"');
          print('Body length: ${body.length}');
        }
        
        // Parse response
        final Map<String, dynamic> status = {
          'online': true,
          'isOn': false,
          'physicalSwitchOn': false,
          'timestamp': DateTime.now().toIso8601String(),
        };
        
        // Split by comma and parse key-value pairs
        final parts = body.toLowerCase().split(',');
        
        if (kDebugMode) {
          print('Split into ${parts.length} parts: $parts');
        }
        
        for (final part in parts) {
          if (part.contains(':')) {
            final kv = part.split(':');
            if (kv.length == 2) {
              final key = kv[0].trim();
              final value = kv[1].trim();
              
              if (kDebugMode) {
                print('Parsing: "$key" = "$value"');
              }
              
              switch (key) {
                case 'relay':
                  status['isOn'] = value == 'on' || value == '1';
                  if (kDebugMode) print('  → isOn: ${status['isOn']}');
                  break;
                  
                case 'switch':
                  status['physicalSwitchOn'] = value == 'on' || value == '1';
                  if (kDebugMode) print('  → physicalSwitchOn: ${status['physicalSwitchOn']}');
                  break;
                  
                case 'water':
                case 'level':
                  final waterLevel = int.tryParse(value);
                  if (waterLevel != null) {
                    status['waterLevel'] = waterLevel;
                    if (kDebugMode) print('  → waterLevel: $waterLevel');
                  } else {
                    if (kDebugMode) print('  → ERROR: Could not parse water level from "$value"');
                  }
                  break;
                  
                case 'lpg':
                  final lpg = double.tryParse(value);
                  if (lpg != null) {
                    status['lpgValue'] = lpg;
                    if (kDebugMode) print('  → lpgValue: $lpg');
                  }
                  break;
                  
                case 'co':
                  final co = double.tryParse(value);
                  if (co != null) {
                    status['coValue'] = co;
                    if (kDebugMode) print('  → coValue: $co');
                  }
                  break;
                  
                case 'battery':
                  final battery = int.tryParse(value);
                  if (battery != null) {
                    status['batteryLevel'] = battery;
                    if (kDebugMode) print('  → batteryLevel: $battery');
                  } else {
                    if (kDebugMode) print('  → ERROR: Could not parse battery from "$value"');
                  }
                  break;
                  
                case 'brightness':
                  final brightness = int.tryParse(value);
                  if (brightness != null) {
                    status['brightness'] = brightness;
                    if (kDebugMode) print('  → brightness: $brightness');
                  }
                  break;
                  
                case 'speed':
                  final speed = int.tryParse(value);
                  if (speed != null) {
                    status['fanSpeed'] = speed;
                    if (kDebugMode) print('  → fanSpeed: $speed');
                  }
                  break;
                  
                default:
                  if (kDebugMode) print('  → Unknown key: "$key"');
              }
            }
          } else {
            // Fallback for simple "on"/"off" response
            status['isOn'] = body.toLowerCase().contains('on') || body == '1';
            status['physicalSwitchOn'] = status['isOn'];
          }
        }
        
        // DEBUG: Print final parsed status
        if (kDebugMode) {
          print('Final parsed status:');
          status.forEach((key, value) {
            print('  $key: $value');
          });
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

  // NEW: Get status from child device (for battery, sensors, etc.)
  Future<Map<String, dynamic>?> getChildStatus(String childIpAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$childIpAddress/status'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final body = response.body.trim();
        
        if (kDebugMode) {
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          print('CHILD STATUS from $childIpAddress');
          print('Raw body: "$body"');
        }
        
        final Map<String, dynamic> status = {};
        final parts = body.toLowerCase().split(',');
        
        for (final part in parts) {
          if (part.contains(':')) {
            final kv = part.split(':');
            if (kv.length == 2) {
              final key = kv[0].trim();
              final value = kv[1].trim();
              
              switch (key) {
                case 'battery':
                  final battery = int.tryParse(value);
                  if (battery != null) {
                    status['childBatteryLevel'] = battery;
                    if (kDebugMode) print('  → childBatteryLevel: $battery');
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
                  
                case 'lpg':
                  final lpg = double.tryParse(value);
                  if (lpg != null) {
                    status['lpgValue'] = lpg;
                    if (kDebugMode) print('  → lpgValue: $lpg');
                  }
                  break;
                  
                case 'co':
                  final co = double.tryParse(value);
                  if (co != null) {
                    status['coValue'] = co;
                    if (kDebugMode) print('  → coValue: $co');
                  }
                  break;
              }
            }
          }
        }
        
        if (kDebugMode) {
          print('Final child status:');
          status.forEach((key, value) {
            print('  $key: $value');
          });
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        }
        
        return status;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR fetching child status from $childIpAddress: $e');
      }
      return null;
    }
  }

  // Turn device ON
  // Turn device ON
  Future<bool> turnDeviceOn(String ipAddress, String deviceName) async {
    try {
      // Try /<deviceName>/on first
      var response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/on'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) return true;
      
      // Fallback to /<deviceName>/1
      response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/1'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR turning ON device at $ipAddress/$deviceName: $e');
      }
      return false;
    }
  }

  // Turn device OFF
  // Turn device OFF
  Future<bool> turnDeviceOff(String ipAddress, String deviceName) async {
    try {
      // Try /<deviceName>/off first
      var response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/off'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) return true;
      
      // Fallback to /<deviceName>/0
      response = await http
          .get(Uri.parse('http://$ipAddress/$deviceName/0'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      if (kDebugMode) {
        print('ERROR turning OFF device at $ipAddress/$deviceName: $e');
      }
      return false;
    }
  }

  // Toggle device state
  // Toggle device state
  Future<bool> toggleDevice(String ipAddress, String deviceName, bool currentState) async {
    if (currentState) {
      return turnDeviceOff(ipAddress, deviceName);
    } else {
      return turnDeviceOn(ipAddress, deviceName);
    }
  }

  // Set brightness for lights (if your ESP supports PWM)
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
        // Parse sensor data from response
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
    
    // Create futures for all requests
    final futures = ipAddresses.map((ip) => testConnection(ip));
    
    // Wait for all to complete
    final responses = await Future.wait(futures);
    
    // Map results
    for (int i = 0; i < ipAddresses.length; i++) {
      results[ipAddresses[i]] = responses[i];
    }
    
    return results;
  }
}
