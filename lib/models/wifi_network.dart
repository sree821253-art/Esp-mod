class WifiNetwork {
  final String id;
  String ssid;
  String password;
  DateTime addedAt;

  WifiNetwork({
    required this.id,
    required this.ssid,
    required this.password,
    DateTime? addedAt,
  }) : addedAt = addedAt ?? DateTime.now();

  WifiNetwork copyWith({
    String? id,
    String? ssid,
    String? password,
    DateTime? addedAt,
  }) {
    return WifiNetwork(
      id: id ?? this.id,
      ssid: ssid ?? this.ssid,
      password: password ?? this.password,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ssid': ssid,
        'password': password,
        'addedAt': addedAt.toIso8601String(),
      };

  factory WifiNetwork.fromJson(Map<String, dynamic> json) => WifiNetwork(
        id: json['id'],
        ssid: json['ssid'],
        password: json['password'],
        addedAt: json['addedAt'] != null
            ? DateTime.parse(json['addedAt'])
            : DateTime.now(),
      );
}
