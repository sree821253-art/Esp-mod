import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../widgets/device_controls.dart';
import '../models/room.dart';
import '../models/device.dart';
import 'device_detail_screen.dart';
import 'add_device_screen.dart';

class RoomDetailScreen extends StatelessWidget {
  final Room room;

  const RoomDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final devices = provider.getDevicesForRoom(room.id);
    final activeCount = devices.where((d) => d.isOn).length;

    // Get fresh room data
    final currentRoom = provider.rooms.firstWhere(
      (r) => r.id == room.id,
      orElse: () => room,
    );

    return CircuitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            currentRoom.name,
            style: TextStyle(
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.add,
                color:
                    isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AddDeviceScreen(preselectedRoomId: room.id),
                  ),
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Stats header
              Padding(
                padding: const EdgeInsets.all(16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: currentRoom.type.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          currentRoom.type.icon,
                          color: currentRoom.type.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentRoom.type.displayName,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _StatBadge(
                                  icon: Icons.devices,
                                  value: '${devices.length}',
                                  label: 'Total',
                                  color: isDark
                                      ? AppTheme.neonCyan
                                      : Theme.of(context).primaryColor,
                                ),
                                const SizedBox(width: 16),
                                _StatBadge(
                                  icon: Icons.power,
                                  value: '$activeCount',
                                  label: 'Active',
                                  color: activeCount > 0
                                      ? AppTheme.neonGreen
                                      : Colors.grey,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Devices list
              Expanded(
                child: devices.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.devices_other,
                              size: 64,
                              color: isDark ? Colors.white24 : Colors.black26,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No devices in this room',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddDeviceScreen(
                                      preselectedRoomId: room.id,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Device'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: devices.length,
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          return _DeviceCard(
                            device: device,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      DeviceDetailScreen(device: device),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 16,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final Device device;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.device,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRemoteMode = provider.appMode == AppMode.remote;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        onTap: onTap,
        glowEffect: device.isOn,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: [
                // Device icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: device.isOn
                        ? device.type.color.withOpacity(0.2)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    device.type.icon,
                    color: device.isOn ? device.type.color : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Device info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              device.name,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Health indicator
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: device.isOnline
                                  ? AppTheme.neonGreen
                                  : AppTheme.neonRed,
                              boxShadow: isDark
                                  ? [
                                      BoxShadow(
                                        color: (device.isOnline
                                                ? AppTheme.neonGreen
                                                : AppTheme.neonRed)
                                            .withOpacity(0.5),
                                        blurRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            device.ipAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          if (device.hasBattery && device.batteryLevel != null) ...[
                            const SizedBox(width: 8),
                            Icon(
                              device.batteryLevel! > 20
                                  ? Icons.battery_std
                                  : Icons.battery_alert,
                              size: 14,
                              color: device.batteryLevel! > 20
                                  ? AppTheme.neonGreen
                                  : AppTheme.neonRed,
                            ),
                            Text(
                              '${device.batteryLevel}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: device.batteryLevel! > 20
                                    ? AppTheme.neonGreen
                                    : AppTheme.neonRed,
                              ),
                            ),
                          ],
                          if (device.isStale) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppTheme.neonAmber.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'STALE',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: AppTheme.neonAmber,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Power toggle
                if (device.type != DeviceType.gasSensor &&
                    device.type != DeviceType.sensorOnly)
                  GestureDetector(
                    onTap: isRemoteMode && device.isOnline
                        ? () => provider.toggleDevice(device.id)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: device.isOn
                            ? device.type.color.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: device.isOn
                              ? device.type.color
                              : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.power_settings_new,
                        color: device.isOn ? device.type.color : Colors.grey,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),

            // Inline controls based on device type
            if (device.isOnline) ...[
              const SizedBox(height: 16),
              _InlineControls(device: device),
            ],
          ],
        ),
      ),
    );
  }
}

class _InlineControls extends StatelessWidget {
  final Device device;

  const _InlineControls({required this.device});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (device.type) {
      case DeviceType.light:
        return LightBrightnessControl(
          brightness: device.brightness,
          isOn: device.isOn,
          onBrightnessChanged: (value) {
            provider.setBrightness(device.id, value);
          },
        );

      case DeviceType.fan:
        return FanSpeedControl(
          speed: device.fanSpeed,
          isOn: device.isOn,
          onSpeedChanged: (value) {
            provider.setFanSpeed(device.id, value);
          },
        );

      case DeviceType.waterPump:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _WaterLevelMini(
              level: device.waterLevel,
              minThreshold: provider.pumpMinThreshold,
              maxThreshold: provider.pumpMaxThreshold,
            ),
            Column(
              children: [
                Text(
                  device.isOn ? 'FILLING' : 'IDLE',
                  style: TextStyle(
                    color: device.isOn
                        ? AppTheme.neonGreen
                        : (isDark ? Colors.white54 : Colors.black54),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                if (device.waterLevel >= 98)
                  const Text(
                    'EMERGENCY STOP',
                    style: TextStyle(
                      color: AppTheme.neonRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        );

      case DeviceType.gasSensor:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _GasValueMini(
              label: 'LPG',
              value: device.lpgValue,
              unit: 'ppm',
              isAlert: device.lpgValue > 50,
            ),
            _GasValueMini(
              label: 'CO',
              value: device.coValue,
              unit: 'ppm',
              isAlert: device.coValue > 25,
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

class _WaterLevelMini extends StatelessWidget {
  final int level;
  final int minThreshold;
  final int maxThreshold;

  const _WaterLevelMini({
    required this.level,
    required this.minThreshold,
    required this.maxThreshold,
  });

  Color get _levelColor {
    if (level >= 98) return AppTheme.neonRed;
    if (level >= maxThreshold) return AppTheme.neonAmber;
    if (level <= minThreshold) return AppTheme.neonRed;
    return AppTheme.neonBlue;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: level / 100,
                strokeWidth: 6,
                backgroundColor: _levelColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation(_levelColor),
              ),
            ),
            Text(
              '$level%',
              style: TextStyle(
                color: _levelColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Water Level',
          style: TextStyle(
            color: isDark ? Colors.white38 : Colors.black38,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

class _GasValueMini extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final bool isAlert;

  const _GasValueMini({
    required this.label,
    required this.value,
    required this.unit,
    required this.isAlert,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isAlert ? AppTheme.neonRed : AppTheme.neonGreen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 10,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
