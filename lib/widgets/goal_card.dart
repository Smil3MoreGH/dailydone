import 'package:flutter/material.dart';
import '../models/daily_goal.dart';

class GoalCard extends StatelessWidget {
  final DailyGoal goal;
  final VoidCallback onTap;
  final VoidCallback? onIncrement;

  const GoalCard({
    super.key,
    required this.goal,
    required this.onTap,
    this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompleted = goal.type == GoalType.checkbox
        ? goal.isCompleted
        : goal.currentCount >= (goal.targetCount ?? 1);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted
                ? Colors.green.withOpacity(0.3)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Checkbox or counter icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.2)
                    : (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0)),
                shape: BoxShape.circle,
              ),
              child: goal.type == GoalType.checkbox
                  ? Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.circle_outlined,
                color: isCompleted
                    ? Colors.green
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
                size: 28,
              )
                  : Center(
                child: Text(
                  '${goal.currentCount}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isCompleted
                        ? Colors.green
                        : (isDark ? Colors.white : const Color(0xFF212121)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Goal title and progress
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF212121),
                      decoration: isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  if (goal.type == GoalType.counter) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Target: ${goal.targetCount} times',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action button for counter type
            if (goal.type == GoalType.counter && !isCompleted)
              IconButton(
                onPressed: onIncrement,
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}