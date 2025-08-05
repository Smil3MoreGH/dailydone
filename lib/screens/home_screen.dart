import 'package:flutter/material.dart';
import '../models/water_entry.dart';
import '../models/beverage_type.dart';
import '../services/database_service.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _currentWaterAmount = 0;
  int _dailyGoal = 2000;
  List<WaterEntry> _todayEntries = [];
  BeverageType _selectedBeverage = BeverageType.water;
  int _selectedAmount = 250;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final goal = await db.getDailyWaterGoal();
    final entries = await db.getTodayWaterEntries();
    final total = await db.getTodayTotalWater();

    setState(() {
      _dailyGoal = goal;
      _todayEntries = entries;
      _currentWaterAmount = total;
    });
  }

  Future<void> _addWaterEntry() async {
    final entry = WaterEntry(
      timestamp: DateTime.now(),
      amount: _selectedAmount,
      type: _selectedBeverage,
    );

    await DatabaseService.instance.addWaterEntry(entry);
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
                      BeverageButton(
                        type: BeverageType.water,
                        amount: 250,
                        onTap: () {
                          setState(() {
                            _selectedBeverage = BeverageType.water;
                            _selectedAmount = 250;
                          });
                          _addWaterEntry();
                        },
                      ),
                      BeverageButton(
                        type: BeverageType.water,
                        amount: 500,
                        onTap: () {
                          setState(() {
                            _selectedBeverage = BeverageType.water;
                            _selectedAmount = 500;
                          });
                          _addWaterEntry();
                        },
                      ),
                    ],
                  ),
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