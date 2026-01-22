import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/device.dart';
import '../models/room.dart';

class AddDeviceScreen extends StatefulWidget {
  final String? preselectedRoomId;

  const AddDeviceScreen({super.key, this.preselectedRoomId});

  @override
  State<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends State<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ipController = TextEditingController();
  final _gpioController = TextEditingController();

  DeviceType _selectedType = DeviceType.light;
  String? _selectedRoomId;
  bool _hasBattery = false;

  @override
  void initState() {
    super.initState();
    _selectedRoomId = widget.preselectedRoomId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ipController.dispose();
    _gpioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CircuitBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.close,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Add Device',
            style: TextStyle(
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
          ),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Device Name
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Name *',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., Living Room Light',
                            prefixIcon: Icon(Icons.label_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter a device name';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Device Type
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Device Type *',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: DeviceType.values.map((type) {
                            final isSelected = _selectedType == type;
                            return GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedType = type),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? type.color.withOpacity(0.2)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? type.color
                                        : (isDark
                                            ? Colors.white24
                                            : Colors.black12),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected && isDark
                                      ? [
                                          BoxShadow(
                                            color: type.color.withOpacity(0.3),
                                            blurRadius: 8,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      type.icon,
                                      size: 20,
                                      color: isSelected
                                          ? type.color
                                          : (isDark
                                              ? Colors.white54
                                              : Colors.black54),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      type.displayName,
                                      style: TextStyle(
                                        color: isSelected
                                            ? type.color
                                            : (isDark
                                                ? Colors.white54
                                                : Colors.black54),
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
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
                  const SizedBox(height: 16),

                  // IP Address
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'IP Address *',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            hintText: 'e.g., 192.168.1.101',
                            prefixIcon: Icon(Icons.wifi),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter an IP address';
                            }
                            // Basic IP validation
                            final parts = value.split('.');
                            if (parts.length != 4) {
                              return 'Invalid IP address format';
                            }
                            for (final part in parts) {
                              final num = int.tryParse(part);
                              if (num == null || num < 0 || num > 255) {
                                return 'Invalid IP address';
                              }
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional fields
                  GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Optional Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // GPIO Pin
                        TextFormField(
                          controller: _gpioController,
                          decoration: const InputDecoration(
                            labelText: 'GPIO Pin',
                            prefixIcon: Icon(Icons.memory),
                            hintText: 'e.g., 5',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        // Room selection
                        DropdownButtonFormField<String?>(
                          value: _selectedRoomId,
                          decoration: const InputDecoration(
                            labelText: 'Assign to Room',
                            prefixIcon: Icon(Icons.room_preferences),
                          ),
                          dropdownColor:
                              isDark ? AppTheme.circuitDarkAlt : Colors.white,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No room'),
                            ),
                            ...provider.rooms.map((room) {
                              return DropdownMenuItem<String?>(
                                value: room.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      room.type.icon,
                                      size: 18,
                                      color: room.type.color,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(room.name),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedRoomId = value);
                          },
                        ),
                        const SizedBox(height: 16),
                        // Battery toggle
                        Row(
                          children: [
                            Icon(
                              Icons.battery_std,
                              color: isDark
                                  ? AppTheme.neonCyan
                                  : Theme.of(context).primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Battery Powered',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    'Device has a battery',
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
                            Switch(
                              value: _hasBattery,
                              onChanged: (value) {
                                setState(() => _hasBattery = value);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  ElevatedButton(
                    onPressed: _submitForm,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add,
                          color: isDark
                              ? AppTheme.neonCyan
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Add Device',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppTheme.neonCyan : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<AppProvider>();
    final device = Device(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      type: _selectedType,
      ipAddress: _ipController.text.trim(),
      gpioPin: int.tryParse(_gpioController.text),
      roomId: _selectedRoomId,
      hasBattery: _hasBattery,
      batteryLevel: _hasBattery ? 100 : null,
      isOnline: true, // Assume online initially
    );

    provider.addDevice(device);

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device.name} added successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
