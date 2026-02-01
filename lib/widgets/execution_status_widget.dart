import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

/// Widget to display execution status during pump operations
/// Shows countdown timers and current operation status
class ExecutionStatusBanner extends StatelessWidget {
  const ExecutionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.executionStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.neonAmber.withValues(alpha: 0.15)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.neonAmber.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: AppTheme.neonAmber.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppTheme.neonAmber : Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'EXECUTING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppTheme.neonAmber : Colors.orange,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.executionStatus,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.hourglass_bottom,
            color: isDark ? AppTheme.neonAmber : Colors.orange,
            size: 20,
          ),
        ],
      ),
    );
  }
}

/// Compact execution indicator for device cards
class CompactExecutionIndicator extends StatelessWidget {
  const CompactExecutionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.executionStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.neonAmber.withValues(alpha: 0.2)
            : Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark
              ? AppTheme.neonAmber.withValues(alpha: 0.5)
              : Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(
                isDark ? AppTheme.neonAmber : Colors.orange,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              provider.executionStatus,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppTheme.neonAmber : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
