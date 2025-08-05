import 'package:flutter/material.dart';
import '../models/daily_goal.dart';
import '../services/database_service.dart';
import '../widgets/goal_card.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  List<DailyGoal> _goals = [];
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals() async {
    final goals = await DatabaseService.instance.getTodayGoals();
    setState(() {
      _goals = goals;
    });
  }

  Future<void> _toggleGoal(DailyGoal goal) async {
    if (goal.type == GoalType.checkbox) {
      goal.isCompleted = !goal.isCompleted;
    }
    await DatabaseService.instance.updateGoal(goal);
    _loadGoals();
  }

  Future<void> _incrementGoal(DailyGoal goal) async {
    if (goal.type == GoalType.counter) {
      goal.currentCount++;
      if (goal.currentCount >= (goal.targetCount ?? 1)) {
        goal.isCompleted = true;
      }
    }
    await DatabaseService.instance.updateGoal(goal);
    _loadGoals();
  }

  void _showAddGoalDialog() {
    GoalType selectedType = GoalType.checkbox;
    int targetCount = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Add Daily Goal',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Goal Title',
                  hintText: 'e.g., Take vitamins, Exercise, Read',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Goal Type',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<GoalType>(
                      title: const Text('Checkbox'),
                      subtitle: const Text('Complete once'),
                      value: GoalType.checkbox,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setModalState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<GoalType>(
                      title: const Text('Counter'),
                      subtitle: const Text('Track multiple'),
                      value: GoalType.counter,
                      groupValue: selectedType,
                      onChanged: (value) {
                        setModalState(() {
                          selectedType = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              if (selectedType == GoalType.counter) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Target Count: '),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        if (targetCount > 1) {
                          setModalState(() {
                            targetCount--;
                          });
                        }
                      },
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$targetCount',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    IconButton(
                      onPressed: () {
                        setModalState(() {
                          targetCount++;
                        });
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_titleController.text.isNotEmpty) {
                      final goal = DailyGoal(
                        title: _titleController.text,
                        type: selectedType,
                        targetCount: selectedType == GoalType.counter ? targetCount : null,
                        date: DateTime.now(),
                      );
                      await DatabaseService.instance.addDailyGoal(goal);
                      _titleController.clear();
                      if (mounted) {
                        Navigator.pop(context);
                        _loadGoals();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Add Goal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Goals'),
        centerTitle: true,
      ),
      body: _goals.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No goals yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first goal',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadGoals,
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, bottom: 100),
          itemCount: _goals.length,
          itemBuilder: (context, index) {
            final goal = _goals[index];
            return GoalCard(
              goal: goal,
              onTap: () => _toggleGoal(goal),
              onIncrement: goal.type == GoalType.counter
                  ? () => _incrementGoal(goal)
                  : null,
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      ),
    );
  }
}