import 'dart:async';
import 'package:http/http.dart' as http;

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

  // Get device status
  Future<Map<String, dynamic>?> getDeviceStatus(String ipAddress) async {
    try {
      final response = await http
          .get(Uri.parse('http://$ipAddress/status'))
          .timeout(_timeout);
      
      if (response.statusCode == 200) {
        final body = response.body.toLowerCase().trim();
        
        // Parse response - expecting "on" or "off" or "1" or "0"
        bool isOn = body.contains('on') || body == '1';
        
        return {
          'online': true,
          'isOn': isOn,
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      return null;
    } catch (e) {
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
        // You may need to adjust this based on your ESP's response format
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
