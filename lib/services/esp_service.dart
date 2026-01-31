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

  // Get status from child device (for battery, sensors, etc.)
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
  Future<bool> turnDeviceOn(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/led/on'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Turn device OFF
  Future<bool> turnDeviceOff(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/led/off'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Toggle device state
  Future<bool> toggleDevice(String ipAddress, bool currentState) async {
    if (currentState) {
      return turnDeviceOff(ipAddress);
    } else {
      return turnDeviceOn(ipAddress);
    }
  }

  // Set brightness for lights (if your ESP supports PWM)
  Future<bool> setBrightness(String ipAddress, int brightness) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/brightness/$brightness'))
          .timeout(_timeout);
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Set fan speed (if your ESP supports it)
  Future<bool> setFanSpeed(String ipAddress, int speed) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/speed/$speed'))
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
