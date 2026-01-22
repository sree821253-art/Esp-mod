class NetworkConfig {
  final String deviceId;
  final String staticIP;
  final String gateway;
  final String subnet;
  final bool isParent;
  final String? parentIP; // For child devices

  NetworkConfig({
    required this.deviceId,
    required this.staticIP,
    required this.gateway,
    this.subnet = '255.255.255.0',
    this.isParent = false,
    this.parentIP,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'staticIP': staticIP,
    'gateway': gateway,
    'subnet': subnet,
    'isParent': isParent,
    'parentIP': parentIP,
  };

  factory NetworkConfig.fromJson(Map<String, dynamic> json) => NetworkConfig(
    deviceId: json['deviceId'],
    staticIP: json['staticIP'],
    gateway: json['gateway'],
    subnet: json['subnet'] ?? '255.255.255.0',
    isParent: json['isParent'] ?? false,
    parentIP: json['parentIP'],
  );
}
