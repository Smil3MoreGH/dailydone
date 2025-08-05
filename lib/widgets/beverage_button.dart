import 'package:flutter/material.dart';
import '../models/beverage_type.dart';

class BeverageButton extends StatelessWidget {
  final BeverageType type;
  final int amount;
  final VoidCallback onTap;

  const BeverageButton({
    super.key,
    required this.type,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: type.color.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: type.color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: type.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                type.icon,
                color: type.color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${amount}ml',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF212121),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}