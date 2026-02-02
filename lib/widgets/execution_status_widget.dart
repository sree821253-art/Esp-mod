import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

class ExecutionStatusBanner extends StatelessWidget {
  const ExecutionStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (provider.executionStatus.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine color based on status
    Color statusColor = AppTheme.neonAmber;
    IconData statusIcon = Icons.hourglass_bottom;
    
    if (provider.executionStatus.contains('✅')) {
      statusColor = AppTheme.neonGreen;
      statusIcon = Icons.check_circle;
    } else if (provider.executionStatus.contains('❌')) {
      statusColor = AppTheme.neonRed;
      statusIcon = Icons.error;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: statusColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (!provider.executionStatus.contains('✅') && 
              !provider.executionStatus.contains('❌'))
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(statusColor),
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              provider.executionStatus,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
