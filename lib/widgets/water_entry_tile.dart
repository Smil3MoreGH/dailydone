import 'package:flutter/material.dart';
import '../models/water_entry.dart';
import '../utils/helpers.dart';

class WaterEntryTile extends StatelessWidget {
  final WaterEntry entry;

  const WaterEntryTile({
    super.key,
    required this.entry,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: entry.type.color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              entry.type.icon,
              color: entry.type.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.type.label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF212121),
                  ),
                ),
                Text(
                  Helpers.formatTime(entry.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.amount}ml',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: entry.type.color,
            ),
          ),
        ],
      ),
    );
  }
}