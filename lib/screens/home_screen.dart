import 'package:flutter/material.dart';
import '../models/water_entry.dart';
import '../models/beverage_type.dart';
import '../models/quick_add_button.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';
import '../widgets/water_progress_circle.dart';
import '../widgets/beverage_button.dart';
import '../widgets/water_entry_tile.dart';
import '../widgets/bottom_nav_bar.dart';
import '../utils/constants.dart';
import 'goals_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _currentWaterAmount = 0;
  int _dailyGoal = 2000;
  List<WaterEntry> _todayEntries = [];
  List<QuickAddButton> _quickAddButtons = [];
  BeverageType _selectedBeverage = BeverageType.water;
  int _selectedAmount = 250;
  DateTime? _lastWaterEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Check if we need to reset water reminders
      _checkWaterReminders();
    }
  }

  Future<void> _checkWaterReminders() async {
    if (_lastWaterEntry != null) {
      final timeSinceLastEntry = DateTime.now().difference(_lastWaterEntry!);
      final settings = await DatabaseService.instance.getNotificationSettings();
      final interval = settings['water_reminder_interval'] ?? 30;

      if (timeSinceLastEntry.inMinutes >= interval) {
        // Reschedule water reminders
        await NotificationService.instance.scheduleWaterReminders();
      }
    }
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final goal = await db.getDailyWaterGoal();
    final entries = await db.getTodayWaterEntries();
    final total = await db.getTodayTotalWater();
    final buttons = await db.getQuickAddButtons();

    setState(() {
      _dailyGoal = goal;
      _todayEntries = entries;
      _currentWaterAmount = total;
      _quickAddButtons = buttons;
      if (entries.isNotEmpty) {
        _lastWaterEntry = entries.first.timestamp;
      }
    });
  }

  Future<void> _addWaterEntry() async {
    final entry = WaterEntry(
      timestamp: DateTime.now(),
      amount: _selectedAmount,
      type: _selectedBeverage,
    );

    await DatabaseService.instance.addWaterEntry(entry);
    _lastWaterEntry = DateTime.now();

    // Reschedule water reminders
    await NotificationService.instance.scheduleWaterReminders();

    _loadData();

    // Show success feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added $_selectedAmount ml of ${_selectedBeverage.label}'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _addQuickWaterEntry(QuickAddButton button) async {
    setState(() {
      _selectedBeverage = button.type;
      _selectedAmount = button.amount;
    });
    await _addWaterEntry();
  }

  void _showAddWaterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
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
              'Add Beverage',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Type',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: BeverageType.values.map((type) {
                final isSelected = _selectedBeverage == type;
                return ChoiceChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type.icon,
                        size: 18,
                        color: isSelected ? Colors.white : type.color,
                      ),
                      const SizedBox(width: 8),
                      Text(type.label),
                    ],
                  ),
                  selected: isSelected,
                  selectedColor: type.color,
                  onSelected: (selected) {
                    setState(() {
                      _selectedBeverage = type;
                    });
                    Navigator.pop(context);
                    _showAddWaterDialog();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Amount',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              children: Constants.quickAddAmounts.map((amount) {
                final isSelected = _selectedAmount == amount;
                return ChoiceChip(
                  label: Text('${amount}ml'),
                  selected: isSelected,
                  selectedColor: Theme.of(context).primaryColor,
                  onSelected: (selected) {
                    setState(() {
                      _selectedAmount = amount;
                    });
                    Navigator.pop(context);
                    _showAddWaterDialog();
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addWaterEntry();
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: _selectedBeverage.color,
                ),
                child: Text(
                  'Add $_selectedAmount ml of ${_selectedBeverage.label}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCustomizeQuickAddDialog() {
    List<QuickAddButton> tempButtons = List.from(_quickAddButtons);

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
                'Customize Quick Add',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),
              ...tempButtons.asMap().entries.map((entry) {
                final index = entry.key;
                final button = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: button.type.color.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        button.type.icon,
                        color: button.type.color,
                      ),
                    ),
                    title: Text('${button.amount}ml ${button.type.label}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            _editQuickAddButton(index, tempButtons, setModalState);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            setModalState(() {
                              tempButtons.removeAt(index);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              if (tempButtons.length < 4) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    _addNewQuickAddButton(tempButtons, setModalState);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Button'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await DatabaseService.instance.saveQuickAddButtons(tempButtons);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadData();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Save Changes',
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

  void _editQuickAddButton(int index, List<QuickAddButton> buttons, StateSetter setModalState) {
    final button = buttons[index];
    BeverageType selectedType = button.type;
    int selectedAmount = button.amount;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Quick Add Button'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BeverageType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Beverage Type'),
                items: BeverageType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, color: type.color, size: 20),
                        const SizedBox(width: 8),
                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (ml)',
                  suffixText: 'ml',
                ),
                controller: TextEditingController(text: selectedAmount.toString()),
                onChanged: (value) {
                  selectedAmount = int.tryParse(value) ?? selectedAmount;
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
                setModalState(() {
                  buttons[index] = QuickAddButton(
                    id: button.id,
                    amount: selectedAmount,
                    type: selectedType,
                    position: index,
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _addNewQuickAddButton(List<QuickAddButton> buttons, StateSetter setModalState) {
    BeverageType selectedType = BeverageType.water;
    int selectedAmount = 250;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Quick Add Button'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<BeverageType>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Beverage Type'),
                items: BeverageType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Row(
                      children: [
                        Icon(type.icon, color: type.color, size: 20),
                        const SizedBox(width: 8),
                        Text(type.label),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setDialogState(() {
                    selectedType = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Amount (ml)',
                  suffixText: 'ml',
                ),
                controller: TextEditingController(text: selectedAmount.toString()),
                onChanged: (value) {
                  selectedAmount = int.tryParse(value) ?? selectedAmount;
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
                setModalState(() {
                  buttons.add(QuickAddButton(
                    amount: selectedAmount,
                    type: selectedType,
                    position: buttons.length,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildWaterTab();
      case 1:
        return const GoalsScreen();
      case 2:
        return SettingsScreen(onGoalChanged: _loadData);
      default:
        return _buildWaterTab();
    }
  }

  Widget _buildWaterTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    WaterProgressCircle(
                      currentAmount: _currentWaterAmount,
                      goalAmount: _dailyGoal,
                      entries: _todayEntries,
                    ),
                  ],
                ),
              ),
            ),
            title: const Text('DailyDone'),
            centerTitle: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Add',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 1.3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      ..._quickAddButtons.map((button) => BeverageButton(
                        type: button.type,
                        amount: button.amount,
                        onTap: () => _addQuickWaterEntry(button),
                      )),
                      if (_quickAddButtons.length < 4)
                        GestureDetector(
                          onTap: _showCustomizeQuickAddDialog,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context).dividerColor,
                                width: 2,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  size: 48,
                                  color: Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 8),
                                const Text('Customize'),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_quickAddButtons.length >= 4) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: _showCustomizeQuickAddDialog,
                        icon: const Icon(Icons.edit),
                        label: const Text('Customize Quick Add'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Intake',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      TextButton(
                        onPressed: _showAddWaterDialog,
                        child: const Text('Custom +'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => WaterEntryTile(
                entry: _todayEntries[index],
              ),
              childCount: _todayEntries.length,
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
        onPressed: _showAddWaterDialog,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}