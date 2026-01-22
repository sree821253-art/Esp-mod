import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/room.dart';
import 'room_detail_screen.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    NeonText(
                      text: 'Rooms',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppTheme.neonCyan
                            : Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${provider.rooms.length} rooms configured',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                GlassCard(
                  onTap: () => _showAddRoomDialog(context),
                  padding: const EdgeInsets.all(12),
                  glowEffect: true,
                  child: Icon(
                    Icons.add,
                    color: isDark
                        ? AppTheme.neonCyan
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),

          // Rooms Grid
          Expanded(
            child: provider.rooms.isEmpty
                ? Center(
                    child: GlassCard(
                      padding: const EdgeInsets.all(32),
                      margin: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.room_preferences_outlined,
                            size: 64,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No rooms yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tap + to add your first room',
                            style: TextStyle(
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => _showAddRoomDialog(context),
                            icon: const Icon(Icons.add),
                            label: const Text('Add Room'),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: provider.rooms.length,
                    itemBuilder: (context, index) {
                      final room = provider.rooms[index];
                      final devices = provider.getDevicesForRoom(room.id);
                      final activeCount =
                          devices.where((d) => d.isOn).length;

                      return _RoomGridCard(
                        room: room,
                        deviceCount: devices.length,
                        activeCount: activeCount,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room),
                            ),
                          );
                        },
                        onEdit: () => _showEditRoomDialog(context, room),
                        onDelete: () => _showDeleteRoomDialog(context, room),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showAddRoomDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController();
    RoomType selectedType = RoomType.livingRoom;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.add_home_outlined,
                color:
                    isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Add Room'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                Text(
                  'Room Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RoomType.values.map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? type.color.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? type.color
                                : (isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 16,
                              color: isSelected
                                  ? type.color
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? type.color
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.black54),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a room name')),
                  );
                  return;
                }

                final provider = context.read<AppProvider>();
                provider.addRoom(Room(
                  id: const Uuid().v4(),
                  name: nameController.text.trim(),
                  type: selectedType,
                ));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${nameController.text} added'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditRoomDialog(BuildContext context, Room room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nameController = TextEditingController(text: room.name);
    RoomType selectedType = room.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
          title: Row(
            children: [
              Icon(
                Icons.edit_outlined,
                color:
                    isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              const Text('Edit Room'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Room Name',
                    prefixIcon: Icon(Icons.label_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 20),
                Text(
                  'Room Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: RoomType.values.map((type) {
                    final isSelected = selectedType == type;
                    return GestureDetector(
                      onTap: () => setState(() => selectedType = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? type.color.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected
                                ? type.color
                                : (isDark ? Colors.white24 : Colors.black12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type.icon,
                              size: 16,
                              color: isSelected
                                  ? type.color
                                  : (isDark ? Colors.white54 : Colors.black54),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected
                                    ? type.color
                                    : (isDark
                                        ? Colors.white54
                                        : Colors.black54),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a room name')),
                  );
                  return;
                }

                final provider = context.read<AppProvider>();
                provider.updateRoom(room.copyWith(
                  name: nameController.text.trim(),
                  type: selectedType,
                ));

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Room updated'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteRoomDialog(BuildContext context, Room room) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.read<AppProvider>();
    final devices = provider.getDevicesForRoom(room.id);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
        title: Row(
          children: [
            Icon(Icons.delete_outline, color: AppTheme.neonRed),
            const SizedBox(width: 8),
            const Text('Delete Room'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${room.name}"?',
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (devices.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.neonAmber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.neonAmber.withOpacity(0.3)),
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
                        'This room has ${devices.length} device(s). They will be unassigned.',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
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
              provider.deleteRoom(room.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${room.name} deleted'),
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

class _RoomGridCard extends StatelessWidget {
  final Room room;
  final int deviceCount;
  final int activeCount;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RoomGridCard({
    required this.room,
    required this.deviceCount,
    required this.activeCount,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassCard(
      onTap: onTap,
      glowEffect: activeCount > 0,
      padding: EdgeInsets.zero,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon and status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: room.type.color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        room.type.icon,
                        color: room.type.color,
                        size: 28,
                      ),
                    ),
                    PopupMenuButton(
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      color: isDark ? AppTheme.circuitDarkAlt : Colors.white,
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          onTap: onEdit,
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit,
                                color: isDark
                                    ? AppTheme.neonCyan
                                    : Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              const Text('Edit'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          onTap: onDelete,
                          child: const Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: AppTheme.neonRed,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text('Delete'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Room name
                Text(
                  room.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  room.type.displayName,
                  style: TextStyle(
                    fontSize: 12,
                    color: room.type.color,
                  ),
                ),
                const SizedBox(height: 12),
                // Stats row
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.devices,
                      value: '$deviceCount',
                      label: 'devices',
                      color: isDark ? AppTheme.neonCyan : Colors.blue,
                    ),
                    const SizedBox(width: 16),
                    _MiniStat(
                      icon: Icons.power,
                      value: '$activeCount',
                      label: 'active',
                      color: activeCount > 0
                          ? AppTheme.neonGreen
                          : Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Active indicator
          if (activeCount > 0)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.neonGreen,
                  boxShadow: isDark
                      ? [
                          BoxShadow(
                            color: AppTheme.neonGreen.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
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
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
