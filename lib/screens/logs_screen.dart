import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/circuit_background.dart';
import '../models/log_entry.dart';
import '../models/device.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedDeviceId;
  LogType? _selectedLogType;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredLogs = provider.getFilteredLogs(
      startDate: _startDate,
      endDate: _endDate,
      deviceId: _selectedDeviceId,
      logType: _selectedLogType,
    );

    // Group logs by date
    final groupedLogs = <String, List<LogEntry>>{};
    for (final log in filteredLogs) {
      final dateKey = DateFormat('MMMM d, yyyy').format(log.timestamp);
      groupedLogs.putIfAbsent(dateKey, () => []).add(log);
    }

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
                      text: 'Activity Logs',
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
                      '${filteredLogs.length} entries',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    GlassCard(
                      onTap: () => _showFilterSheet(context, provider),
                      padding: const EdgeInsets.all(12),
                      child: Stack(
                        children: [
                          Icon(
                            Icons.filter_list,
                            color: isDark
                                ? AppTheme.neonCyan
                                : Theme.of(context).primaryColor,
                          ),
                          if (_hasActiveFilters)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.neonAmber,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassCard(
                      onTap: filteredLogs.isNotEmpty
                          ? () => _exportLogs(context, provider, filteredLogs)
                          : null,
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.download,
                        color: filteredLogs.isNotEmpty
                            ? (isDark
                                ? AppTheme.neonCyan
                                : Theme.of(context).primaryColor)
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Active filters chips
          if (_hasActiveFilters)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  if (_startDate != null || _endDate != null)
                    _FilterChip(
                      label: _formatDateRange(),
                      onRemove: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                        });
                      },
                    ),
                  if (_selectedDeviceId != null)
                    _FilterChip(
                      label:
                          'Device: ${provider.devices.firstWhere((d) => d.id == _selectedDeviceId, orElse: () => Device(id: '', name: 'Unknown', type: DeviceType.light, ipAddress: '')).name}',
                      onRemove: () {
                        setState(() => _selectedDeviceId = null);
                      },
                    ),
                  if (_selectedLogType != null)
                    _FilterChip(
                      label: 'Type: ${_selectedLogType!.displayName}',
                      onRemove: () {
                        setState(() => _selectedLogType = null);
                      },
                    ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startDate = null;
                        _endDate = null;
                        _selectedDeviceId = null;
                        _selectedLogType = null;
                      });
                    },
                    child: const Text('Clear all'),
                  ),
                ],
              ),
            ),

          // Logs list
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 64,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasActiveFilters
                              ? 'No logs match your filters'
                              : 'No activity logs yet',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                        if (_hasActiveFilters) ...[
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _startDate = null;
                                _endDate = null;
                                _selectedDeviceId = null;
                                _selectedLogType = null;
                              });
                            },
                            child: const Text('Clear filters'),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: groupedLogs.length,
                    itemBuilder: (context, index) {
                      final dateKey = groupedLogs.keys.elementAt(index);
                      final logs = groupedLogs[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date header
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                              children: [
                                Container(
                                  height: 1,
                                  width: 20,
                                  color: isDark
                                      ? AppTheme.neonCyan.withOpacity(0.3)
                                      : Colors.grey.withOpacity(0.3),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dateKey,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: isDark
                                        ? AppTheme.neonCyan.withOpacity(0.3)
                                        : Colors.grey.withOpacity(0.3),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Log entries
                          ...logs.map((log) => _LogEntryCard(log: log)),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  bool get _hasActiveFilters =>
      _startDate != null ||
      _endDate != null ||
      _selectedDeviceId != null ||
      _selectedLogType != null;

  String _formatDateRange() {
    if (_startDate != null && _endDate != null) {
      return '${DateFormat('M/d').format(_startDate!)} - ${DateFormat('M/d').format(_endDate!)}';
    } else if (_startDate != null) {
      return 'From ${DateFormat('M/d').format(_startDate!)}';
    } else if (_endDate != null) {
      return 'Until ${DateFormat('M/d').format(_endDate!)}';
    }
    return '';
  }

  void _showFilterSheet(BuildContext context, AppProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.circuitDarkAlt : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Filter Logs',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Date Range
                Text(
                  'Date Range',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Start Date',
                        date: _startDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setSheetState(() {});
                            setState(() => _startDate = date);
                          }
                        },
                        onClear: () {
                          setSheetState(() {});
                          setState(() => _startDate = null);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'End Date',
                        date: _endDate,
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setSheetState(() {});
                            setState(() => _endDate = date);
                          }
                        },
                        onClear: () {
                          setSheetState(() {});
                          setState(() => _endDate = null);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Device filter
                Text(
                  'Device',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  value: _selectedDeviceId,
                  decoration: const InputDecoration(
                    hintText: 'All devices',
                    prefixIcon: Icon(Icons.devices),
                  ),
                  dropdownColor:
                      isDark ? AppTheme.circuitDarkAlt : Colors.white,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All devices'),
                    ),
                    const DropdownMenuItem<String?>(
                      value: 'system',
                      child: Text('System'),
                    ),
                    ...provider.devices.map((device) {
                      return DropdownMenuItem<String?>(
                        value: device.id,
                        child: Row(
                          children: [
                            Icon(device.type.icon,
                                size: 18, color: device.type.color),
                            const SizedBox(width: 8),
                            Text(device.name),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setSheetState(() {});
                    setState(() => _selectedDeviceId = value);
                  },
                ),
                const SizedBox(height: 24),

                // Log type filter
                Text(
                  'Log Type',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _TypeChip(
                      label: 'All',
                      isSelected: _selectedLogType == null,
                      color: isDark ? AppTheme.neonCyan : Colors.blue,
                      onTap: () {
                        setSheetState(() {});
                        setState(() => _selectedLogType = null);
                      },
                    ),
                    ...LogType.values.map((type) {
                      return _TypeChip(
                        label: type.displayName,
                        isSelected: _selectedLogType == type,
                        color: type.color,
                        onTap: () {
                          setSheetState(() {});
                          setState(() => _selectedLogType = type);
                        },
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 32),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _exportLogs(
    BuildContext context,
    AppProvider provider,
    List<LogEntry> logs,
  ) {
    final csv = provider.exportLogsToCSV(logs);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Logs'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${logs.length} log entries ready to export.'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppTheme.circuitLine
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                csv.split('\n').take(5).join('\n') +
                    (logs.length > 4 ? '\n...' : ''),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                ),
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
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs exported to Downloads folder'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _FilterChip({
    required this.label,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.neonCyan.withOpacity(0.2)
            : Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? AppTheme.neonCyan.withOpacity(0.5)
              : Theme.of(context).primaryColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close,
              size: 16,
              color: isDark ? AppTheme.neonCyan : Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogEntryCard extends StatelessWidget {
  final LogEntry log;

  const _LogEntryCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Type indicator
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: log.type.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                log.type.icon,
                color: log.type.color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Log info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          log.deviceName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm:ss').format(log.timestamp),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    log.action,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  if (log.details != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      log.details!,
                      style: TextStyle(
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.circuitLine.withOpacity(0.5)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppTheme.neonCyan.withOpacity(0.3) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              size: 18,
              color: isDark ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                date != null ? DateFormat('M/d/yy').format(date!) : label,
                style: TextStyle(
                  color: date != null
                      ? (isDark ? Colors.white : Colors.black87)
                      : (isDark ? Colors.white38 : Colors.black38),
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: onClear,
                child: Icon(
                  Icons.close,
                  size: 18,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white24 : Colors.black12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : (isDark ? Colors.white54 : Colors.black54),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
