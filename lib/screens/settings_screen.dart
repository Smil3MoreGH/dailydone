import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_settings/app_settings.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onGoalChanged;

  const SettingsScreen({super.key, this.onGoalChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _dailyGoal = 2000;
  final _goalController = TextEditingController();

  // Notification settings
  bool _waterReminderEnabled = true;
  int _waterReminderInterval = 30;
  bool _goalReminderEnabled = true;
  int _goalReminderCount = 5;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final goal = await DatabaseService.instance.getDailyWaterGoal();
    final notificationSettings = await DatabaseService.instance.getNotificationSettings();

    setState(() {
      _dailyGoal = goal;
      _goalController.text = (goal / 1000).toStringAsFixed(1);
      _waterReminderEnabled = notificationSettings['water_reminder_enabled'] ?? true;
      _waterReminderInterval = notificationSettings['water_reminder_interval'] ?? 30;
      _goalReminderEnabled = notificationSettings['goal_reminder_enabled'] ?? true;
      _goalReminderCount = notificationSettings['goal_reminder_count'] ?? 5;
    });
  }

  Future<void> _updateDailyGoal() async {
    final goalInLiters = double.tryParse(_goalController.text) ?? 2.0;
    final goalInMl = (goalInLiters * 1000).round();

    await DatabaseService.instance.setDailyWaterGoal(goalInMl);
    setState(() {
      _dailyGoal = goalInMl;
    });

    widget.onGoalChanged?.call();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Daily goal updated to ${goalInLiters}L'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _updateNotificationSettings() async {
    // Check if notifications are enabled first
    final notificationsEnabled = await NotificationService.instance.areNotificationsEnabled();

    if (!notificationsEnabled && (_waterReminderEnabled || _goalReminderEnabled)) {
      // Request permissions if trying to enable notifications
      final granted = await NotificationService.instance.requestPermissions();

      if (!granted) {
        // If permission denied, show a message and disable the toggles
        setState(() {
          _waterReminderEnabled = false;
          _goalReminderEnabled = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Please enable notifications in your device settings'),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // Open app notification settings
                  AppSettings.openAppSettings(type: AppSettingsType.notification);
                },
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }
    }

    await DatabaseService.instance.updateNotificationSetting('water_reminder_enabled', _waterReminderEnabled);
    await DatabaseService.instance.updateNotificationSetting('water_reminder_interval', _waterReminderInterval);
    await DatabaseService.instance.updateNotificationSetting('goal_reminder_enabled', _goalReminderEnabled);
    await DatabaseService.instance.updateNotificationSetting('goal_reminder_count', _goalReminderCount);

    // Update notification schedules
    await NotificationService.instance.updateAllNotifications();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Notification settings updated'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  Future<void> _exportData() async {
    try {
      final filePath = await DatabaseService.instance.exportToCSV();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data exported to: $filePath'),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            action: SnackBarAction(
              label: 'Copy Path',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: filePath));
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.water_drop,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Water Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Daily Goal (Liters)',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _goalController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            suffixText: 'L',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _updateDailyGoal,
                        child: const Text('Update'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current: ${(_dailyGoal / 1000).toStringAsFixed(1)}L',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notifications,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    title: const Text('Water Reminders'),
                    subtitle: const Text('Get reminded to drink water'),
                    value: _waterReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _waterReminderEnabled = value;
                      });
                      _updateNotificationSettings();
                    },
                  ),
                  if (_waterReminderEnabled) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Reminder Interval'),
                      subtitle: Text('Every $_waterReminderInterval minutes'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _waterReminderInterval > 15
                                ? () {
                              setState(() {
                                _waterReminderInterval -= 15;
                              });
                              _updateNotificationSettings();
                            }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_waterReminderInterval',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _waterReminderInterval < 120
                                ? () {
                              setState(() {
                                _waterReminderInterval += 15;
                              });
                              _updateNotificationSettings();
                            }
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Divider(height: 24),
                  SwitchListTile(
                    title: const Text('Goal Reminders'),
                    subtitle: const Text('Get reminded to complete daily goals'),
                    value: _goalReminderEnabled,
                    onChanged: (value) {
                      setState(() {
                        _goalReminderEnabled = value;
                      });
                      _updateNotificationSettings();
                    },
                  ),
                  if (_goalReminderEnabled) ...[
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Daily Reminders'),
                      subtitle: Text('$_goalReminderCount times per day'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: _goalReminderCount > 1
                                ? () {
                              setState(() {
                                _goalReminderCount--;
                              });
                              _updateNotificationSettings();
                            }
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_goalReminderCount',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _goalReminderCount < 10
                                ? () {
                              setState(() {
                                _goalReminderCount++;
                              });
                              _updateNotificationSettings();
                            }
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.palette,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Appearance',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Theme Mode',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: ThemeService.instance.themeMode,
                    builder: (context, themeMode, child) {
                      return SegmentedButton<ThemeMode>(
                        segments: const [
                          ButtonSegment(
                            value: ThemeMode.system,
                            label: Text('System'),
                            icon: Icon(Icons.settings_brightness),
                          ),
                          ButtonSegment(
                            value: ThemeMode.light,
                            label: Text('Light'),
                            icon: Icon(Icons.light_mode),
                          ),
                          ButtonSegment(
                            value: ThemeMode.dark,
                            label: Text('Dark'),
                            icon: Icon(Icons.dark_mode),
                          ),
                        ],
                        selected: {themeMode},
                        onSelectionChanged: (Set<ThemeMode> selection) {
                          ThemeService.instance.setThemeMode(selection.first);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Version'),
                    subtitle: const Text('1.0.0'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Developer'),
                    subtitle: const Text('Built with Flutter & ❤️'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _exportData,
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data (CSV)'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}