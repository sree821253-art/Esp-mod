import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/wifi_network.dart';
import '../models/device.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                NeonText(
                  text: 'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? AppTheme.neonCyan
                        : Theme.of(context).primaryColor,
                  ),
                ),
                // Theme toggle
                _ThemeToggle(
                  isDark: isDark,
                  onToggle: () => provider.toggleTheme(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Name
            _SectionHeader(title: 'Application'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.edit,
                    title: 'App Name',
                    subtitle: provider.appName,
                    onTap: () => _showAppNameDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Mode & Control
            _SectionHeader(title: 'Control Mode'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: provider.appMode == AppMode.remote
                        ? Icons.wifi
                        : Icons.smart_toy,
                    title: 'Operation Mode',
                    subtitle: provider.appMode == AppMode.remote
                        ? 'Remote Mode - Manual control'
                        : 'Local Auto - Automatic control',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: provider.appMode == AppMode.remote
                            ? AppTheme.neonGreen.withOpacity(0.2)
                            : AppTheme.neonAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        provider.appMode == AppMode.remote
                            ? 'REMOTE'
                            : 'AUTO',
                        style: TextStyle(
                          color: provider.appMode == AppMode.remote
                              ? AppTheme.neonGreen
                              : AppTheme.neonAmber,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => _showModeDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pump Thresholds
            _SectionHeader(title: 'Pump Thresholds'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _ThresholdSlider(
                    label: 'Minimum Threshold',
                    value: provider.pumpMinThreshold,
                    color: AppTheme.neonRed,
                    onChanged: (value) {
                      if (value < provider.pumpMaxThreshold) {
                        provider.setPumpThresholds(
                          value,
                          provider.pumpMaxThreshold,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _ThresholdSlider(
                    label: 'Maximum Threshold',
                    value: provider.pumpMaxThreshold,
                    color: AppTheme.neonGreen,
                    onChanged: (value) {
                      if (value > provider.pumpMinThreshold) {
                        provider.setPumpThresholds(
                          provider.pumpMinThreshold,
                          value,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.neonAmber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber,
                          color: AppTheme.neonAmber,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Emergency stop at 98% is always enforced',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            _SectionHeader(title: 'Notifications'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: provider.notificationsEnabled
                        ? Icons.notifications_active
                        : Icons.notifications_off,
                    title: 'Enable Notifications',
                    subtitle: 'Receive alerts for device events',
                    trailing: Switch(
                      value: provider.notificationsEnabled,
                      onChanged: (value) {
                        provider.setNotificationsEnabled(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Wi-Fi Networks
            _SectionHeader(title: 'Wi-Fi Networks'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ...provider.wifiNetworks.map((network) => _WifiNetworkTile(
                        network: network,
                        onEdit: () => _showWifiDialog(context, network: network),
                        onDelete: () {
                          provider.deleteWifiNetwork(network.id);
                        },
                      )),
                  if (provider.wifiNetworks.isNotEmpty)
                    const Divider(height: 24),
                  _SettingsTile(
                    icon: Icons.add_circle_outline,
                    title: 'Add Wi-Fi Network',
                    subtitle: 'Save network credentials',
                    onTap: () => _showWifiDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Security
            _SectionHeader(title: 'Security'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: provider.encryptionEnabled
                        ? Icons.lock
                        : Icons.lock_open,
                    title: 'Encrypt Sensitive Data',
                    subtitle: 'Encrypt Wi-Fi credentials and auth key',
                    trailing: Switch(
                      value: provider.encryptionEnabled,
                      onChanged: (value) {
                        provider.setEncryptionEnabled(value);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Simulation
            _SectionHeader(title: 'Development'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: provider.isSimulationEnabled
                        ? Icons.bug_report
                        : Icons.bug_report_outlined,
                    title: 'Hardware Simulation',
                    subtitle: 'Simulate device responses (3s intervals)',
                    trailing: Switch(
                      value: provider.isSimulationEnabled,
                      onChanged: (value) {
                        provider.setSimulationEnabled(value);
                      },
                    ),
                  ),
                  const Divider(height: 24),
                  _SettingsTile(
                    icon: Icons.code,
                    title: 'Arduino Code Generator',
                    subtitle: 'Generate ESP8266/ESP32 sketch',
                    onTap: () => _showArduinoCode(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Device List
            _SectionHeader(title: 'All Devices'),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: provider.devices.isEmpty
                    ? [
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'No devices added',
                              style: TextStyle(
                                color:
                                    isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                          ),
                        ),
                      ]
                    : provider.devices.map((device) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: device.isOnline
                                      ? AppTheme.neonGreen
                                      : AppTheme.neonRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                device.type.icon,
                                color: device.type.color,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      device.name,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                    Text(
                                      device.ipAddress,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white54
                                            : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (device.hasBattery &&
                                  device.batteryLevel != null)
                                Text(
                                  '${device.batteryLevel}%',
                                  style: TextStyle(
                                    color: device.batteryLevel! > 20
                                        ? AppTheme.neonGreen
                                        : AppTheme.neonRed,
                                    fontSize: 12,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _showAppNameDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final controller = TextEditingController(text: provider.appName);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: const Text('App Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter app name',
            prefixIcon: Icon(Icons.edit),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                provider.setAppName(controller.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showModeDialog(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: const Text('Change Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.appMode == AppMode.remote) ...[
              const Text('Switch to Local Auto mode?'),
              const SizedBox(height: 8),
              Text(
                'Devices will operate automatically based on their own logic.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Auth Key',
                  prefixIcon: Icon(Icons.key),
                ),
              ),
            ] else ...[
              const Text('Switch to Remote mode?'),
              const SizedBox(height: 8),
              Text(
                'You will have manual control over all devices.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (provider.appMode == AppMode.remote) {
                if (provider.switchToLocalAuto(keyController.text)) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Switched to Local Auto mode'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid auth key'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                provider.switchToRemote();
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Switched to Remote mode'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }

  void _showWifiDialog(BuildContext context, {WifiNetwork? network}) {
    final provider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ssidController = TextEditingController(text: network?.ssid ?? '');
    final passwordController =
        TextEditingController(text: network?.password ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: Text(network == null ? 'Add Wi-Fi Network' : 'Edit Wi-Fi Network'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: 'SSID',
                prefixIcon: Icon(Icons.wifi),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ssidController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter SSID')),
                );
                return;
              }

              if (network == null) {
                provider.addWifiNetwork(WifiNetwork(
                  id: const Uuid().v4(),
                  ssid: ssidController.text.trim(),
                  password: passwordController.text,
                ));
              } else {
                provider.updateWifiNetwork(network.copyWith(
                  ssid: ssidController.text.trim(),
                  password: passwordController.text,
                ));
              }

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content:
                      Text(network == null ? 'Network added' : 'Network updated'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text(network == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  void _showArduinoCode(BuildContext context) {
    final provider = context.read<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final code = provider.generateArduinoCode();

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Arduino Code',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.copy),
                        color:
                            isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Code copied to clipboard'),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.download),
                        color:
                            isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Saving sketch.ino to Downloads...'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: isDark ? Colors.white54 : Colors.black54,
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Code view
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppTheme.circuitDark
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? AppTheme.neonCyan.withOpacity(0.3)
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: SelectableText(
                    code,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: isDark ? AppTheme.neonGreen : Colors.black87,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.neonCyan.withOpacity(0.1)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color:
                    isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
          ],
        ),
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final ValueChanged<int> onChanged;

  const _ThresholdSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$value%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color,
            inactiveTrackColor: color.withOpacity(0.2),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}

class _WifiNetworkTile extends StatelessWidget {
  final WifiNetwork network;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WifiNetworkTile({
    required this.network,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.wifi,
            color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  network.ssid,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '••••••••',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: isDark ? Colors.white54 : Colors.black54,
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 20),
            color: AppTheme.neonRed,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeToggle({
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 56,
        height: 32,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isDark ? AppTheme.circuitLine : Colors.grey.shade200,
          border: Border.all(
            color: isDark
                ? AppTheme.neonCyan.withOpacity(0.5)
                : Colors.grey.shade300,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppTheme.neonCyan : Colors.amber,
              boxShadow: [
                BoxShadow(
                  color:
                      (isDark ? AppTheme.neonCyan : Colors.amber).withOpacity(0.5),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              size: 16,
              color: isDark ? AppTheme.circuitDark : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
