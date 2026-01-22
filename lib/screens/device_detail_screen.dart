import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../widgets/device_controls.dart';
import '../models/device.dart';

class DeviceDetailScreen extends StatefulWidget {
  final Device device;

  const DeviceDetailScreen({super.key, required this.device});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  bool _isToggling = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isRemoteMode = provider.appMode == AppMode.remote;

    // Get fresh device data
    final device = provider.devices.firstWhere(
      (d) => d.id == widget.device.id,
      orElse: () => widget.device,
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
            device.name,
            style: TextStyle(
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
              onPressed: () => _showEditDialog(context, device),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              color: AppTheme.neonRed,
              onPressed: () => _showDeleteDialog(context, device),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Device header card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  glowEffect: device.isOn,
                  child: Column(
                    children: [
                      // Power toggle
                      DevicePowerToggle(
                        isOn: device.isOn,
                        isOnline: device.isOnline,
                        isLoading: _isToggling,
                        activeColor: device.type.color,
                        onToggle: (isRemoteMode &&
                                device.type != DeviceType.gasSensor &&
                                device.type != DeviceType.sensorOnly)
                            ? () async {
                                setState(() => _isToggling = true);
                                await provider.toggleDevice(device.id);
                                if (mounted) {
                                  setState(() => _isToggling = false);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),
                      // Device type
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: device.type.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              device.type.icon,
                              color: device.type.color,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              device.type.displayName,
                              style: TextStyle(
                                color: device.type.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Status text
                      Text(
                        device.isOn ? 'ON' : 'OFF',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: device.isOn
                              ? device.type.color
                              : Colors.grey,
                          shadows: isDark && device.isOn
                              ? [
                                  Shadow(
                                    color: device.type.color.withOpacity(0.5),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Device info card
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Device Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.wifi,
                        label: 'IP Address',
                        value: device.ipAddress,
                        color: isDark ? AppTheme.neonCyan : Colors.blue,
                      ),
                      if (device.gpioPin != null)
                        _InfoRow(
                          icon: Icons.memory,
                          label: 'GPIO Pin',
                          value: '${device.gpioPin}',
                          color: AppTheme.neonAmber,
                        ),
                      _InfoRow(
                        icon: device.isOnline
                            ? Icons.check_circle
                            : Icons.error,
                        label: 'Status',
                        value: device.isOnline ? 'Online' : 'Offline',
                        color: device.isOnline
                            ? AppTheme.neonGreen
                            : AppTheme.neonRed,
                      ),
                      if (device.hasBattery && device.batteryLevel != null)
                        _InfoRow(
                          icon: device.batteryLevel! > 20
                              ? Icons.battery_std
                              : Icons.battery_alert,
                          label: 'Battery',
                          value: '${device.batteryLevel}%',
                          color: device.batteryLevel! > 20
                              ? AppTheme.neonGreen
                              : AppTheme.neonRed,
                        ),
                      _InfoRow(
                        icon: Icons.access_time,
                        label: 'Last Seen',
                        value: _formatLastSeen(device.lastSeen),
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Device-specific controls
                if (device.isOnline) ...[
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Controls',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildDeviceControls(context, device, provider),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Mode indicator
                if (!isRemoteMode)
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.neonAmber,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Device control disabled in Local Auto mode',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Notifications toggle
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        device.notificationsEnabled
                            ? Icons.notifications_active
                            : Icons.notifications_off,
                        color: device.notificationsEnabled
                            ? AppTheme.neonCyan
                            : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Receive alerts for this device',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: device.notificationsEnabled,
                        onChanged: (value) {
                          provider.setDeviceNotifications(device.id, value);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceControls(
    BuildContext context,
    Device device,
    AppProvider provider,
  ) {
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
        return WaterLevelGauge(
          waterLevel: device.waterLevel,
          minThreshold: provider.pumpMinThreshold,
          maxThreshold: provider.pumpMaxThreshold,
          isOn: device.isOn,
          isRemoteMode: provider.appMode == AppMode.remote,
          onManualOn: () async {
            final freshDevice = provider.devices.firstWhere(
              (d) => d.id == device.id,
            );
            if (!freshDevice.isOn) {
              await provider.toggleDevice(device.id);
            }
          },
          onManualOff: () async {
            final freshDevice = provider.devices.firstWhere(
              (d) => d.id == device.id,
            );
            if (freshDevice.isOn) {
              await provider.toggleDevice(device.id);
            }
          },
        );

      case DeviceType.gasSensor:
        return GasSensorDisplay(
          lpgValue: device.lpgValue,
          coValue: device.coValue,
        );

      default:
        return Center(
          child: Text(
            'No controls available',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white54
                  : Colors.black54,
            ),
          ),
        );
    }
  }

  String _formatLastSeen(DateTime lastSeen) {
    final diff = DateTime.now().difference(lastSeen);
    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  void _showEditDialog(BuildContext context, Device device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: device.name);
    final ipController = TextEditingController(text: device.ipAddress);
    final gpioController =
        TextEditingController(text: device.gpioPin?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.edit,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Edit Device'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ipController,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  prefixIcon: Icon(Icons.wifi),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: gpioController,
                decoration: const InputDecoration(
                  labelText: 'GPIO Pin (optional)',
                  prefixIcon: Icon(Icons.memory),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty ||
                  ipController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill required fields')),
                );
                return;
              }

              final provider = context.read<AppProvider>();
              provider.updateDevice(device.copyWith(
                name: nameController.text.trim(),
                ipAddress: ipController.text.trim(),
                gpioPin: int.tryParse(gpioController.text),
              ));

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device updated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Device device) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: Row(
          children: [
            const Icon(Icons.delete_outline, color: AppTheme.neonRed),
            const SizedBox(width: 8),
            const Text('Delete Device'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "${device.name}"?\n\nThis action cannot be undone.',
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final provider = context.read<AppProvider>();
              provider.deleteDevice(device.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to previous screen
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device.name} deleted'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonRed.withOpacity(0.2),
              foregroundColor: AppTheme.neonRed,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
