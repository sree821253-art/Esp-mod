import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/device.dart';
import '../models/room.dart';
import 'room_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Start initial sync after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AppProvider>();
      if (!provider.isSyncing) {
        provider.syncDevices();
      }
    });
  }

  void _showAuthDialog(BuildContext context, VoidCallback onSuccess) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor:
            isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
            const SizedBox(width: 8),
            const Text('Authentication Required'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the auth key to proceed:',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Auth Key',
                prefixIcon: Icon(Icons.key),
              ),
              onSubmitted: (value) {
                if (value == AppProvider.authKey) {
                  Navigator.pop(context);
                  onSuccess();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid auth key'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
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
              if (controller.text == AppProvider.authKey) {
                Navigator.pop(context);
                onSuccess();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid auth key'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  void _executeMasterSwitch(bool turnOn) async {
    final provider = context.read<AppProvider>();
    final lights = provider.lightDevices;

    if (lights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No light devices found')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              turnOn
                  ? 'Turning on all lights...'
                  : 'Turning off all lights...',
            ),
          ],
        ),
      ),
    );

    final success = await provider.masterSwitch(AppProvider.authKey, turnOn);
    if (!mounted) return;

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'All lights ${turnOn ? 'turned on' : 'turned off'} successfully'
              : 'Some lights failed to respond',
        ),
        backgroundColor: success ? Colors.green : Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          // App Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // App title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        NeonText(
                          text: provider.appName,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppTheme.neonCyan
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: provider.appMode == AppMode.remote
                                    ? AppTheme.neonGreen
                                    : AppTheme.neonAmber,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              provider.appMode == AppMode.remote
                                  ? 'Remote Mode'
                                  : 'Local Auto',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Theme toggle
                  _ThemeToggle(
                    isDark: isDark,
                    onToggle: () => provider.toggleTheme(),
                  ),
                ],
              ),
            ),
          ),

          // Sync Progress
          if (provider.isSyncing)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(
                                isDark
                                    ? AppTheme.neonCyan
                                    : Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Syncing device states...',
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: provider.syncProgress,
                          backgroundColor: isDark
                              ? AppTheme.circuitLine
                              : Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            isDark
                                ? AppTheme.neonCyan
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(provider.syncProgress * 100).toInt()}% complete',
                        style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Quick Stats
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.devices,
                      label: 'Total Devices',
                      value: '${provider.devices.length}',
                      color: isDark
                          ? AppTheme.neonCyan
                          : Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.wifi,
                      label: 'Online',
                      value: '${provider.onlineDevices.length}',
                      color: AppTheme.neonGreen,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.power,
                      label: 'Active',
                      value: '${provider.activeDevices.length}',
                      color: AppTheme.neonAmber,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Fetch Status & Master Switch
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.sync,
                      label: 'Fetch Status',
                      onTap: provider.isSyncing
                          ? null
                          : () => provider.syncDevices(),
                      isLoading: provider.isSyncing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.lightbulb,
                      label: 'Master Switch',
                      onTap: () {
                        _showAuthDialog(context, () {
                          _showMasterSwitchOptions();
                        });
                      },
                      color: AppTheme.neonAmber,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rooms Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rooms Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '${provider.rooms.length} rooms',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Rooms Grid
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: provider.rooms.isEmpty
                ? SliverToBoxAdapter(
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.room_preferences_outlined,
                            size: 48,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rooms added yet',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Go to Rooms tab to add rooms',
                            style: TextStyle(
                              color: isDark ? Colors.white38 : Colors.black38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = provider.rooms[index];
                        final roomDevices = provider.getDevicesForRoom(room.id);
                        final activeCount =
                            roomDevices.where((d) => d.isOn).length;

                        return _RoomCard(
                          room: room,
                          deviceCount: roomDevices.length,
                          activeCount: activeCount,
                          devices: roomDevices.take(4).toList(),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => RoomDetailScreen(room: room),
                              ),
                            );
                          },
                        );
                      },
                      childCount: provider.rooms.length,
                    ),
                  ),
          ),

          // Unassigned devices
          if (provider.getDevicesForRoom(null).isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Unassigned Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: provider
                        .getDevicesForRoom(null)
                        .map((device) => _UnassignedDeviceItem(device: device))
                        .toList(),
                  ),
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  void _showMasterSwitchOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Master Switch',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Control all light devices at once',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _executeMasterSwitch(true);
                      },
                      icon: const Icon(Icons.lightbulb),
                      label: const Text('Turn All ON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonGreen.withOpacity(0.2),
                        foregroundColor: AppTheme.neonGreen,
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: AppTheme.neonGreen),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _executeMasterSwitch(false);
                      },
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Turn All OFF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.neonRed.withOpacity(0.2),
                        foregroundColor: AppTheme.neonRed,
                        padding: const EdgeInsets.all(16),
                        side: const BorderSide(color: AppTheme.neonRed),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
          color: isDark
              ? AppTheme.circuitLine
              : Colors.grey.shade200,
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
                  color: (isDark ? AppTheme.neonCyan : Colors.amber)
                      .withOpacity(0.5),
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              shadows: isDark
                  ? [
                      Shadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 5,
                      ),
                    ]
                  : null,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonColor =
        color ?? (isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor);

    return GlassCard(
      onTap: onTap,
      glowEffect: !isLoading,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(buttonColor),
              ),
            )
          else
            Icon(icon, color: buttonColor, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: buttonColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final Room room;
  final int deviceCount;
  final int activeCount;
  final List<Device> devices;
  final VoidCallback onTap;

  const _RoomCard({
    required this.room,
    required this.deviceCount,
    required this.activeCount,
    required this.devices,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      glowEffect: activeCount > 0,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: room.type.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  room.type.icon,
                  color: room.type.color,
                  size: 20,
                ),
              ),
              const Spacer(),
              if (activeCount > 0)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.neonGreen,
                    boxShadow: isDark
                        ? [
                            BoxShadow(
                              color: AppTheme.neonGreen.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            room.name,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '$deviceCount devices • $activeCount active',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
          ),
          if (devices.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: devices.take(4).map((device) {
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: device.isOn
                          ? device.type.color.withOpacity(0.2)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      device.type.icon,
                      size: 14,
                      color: device.isOn ? device.type.color : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnassignedDeviceItem extends StatelessWidget {
  final Device device;

  const _UnassignedDeviceItem({required this.device});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: device.type.color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              device.type.icon,
              color: device.type.color,
              size: 20,
            ),
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
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  device.ipAddress,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: device.isOnline ? AppTheme.neonGreen : AppTheme.neonRed,
            ),
          ),
        ],
      ),
    );
  }
}
