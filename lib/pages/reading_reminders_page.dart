import 'package:flutter/material.dart';
import 'dart:ui';
import '../services/notification_service.dart';
import '../main.dart';

class ReadingRemindersPage extends StatefulWidget {
  const ReadingRemindersPage({Key? key}) : super(key: key);

  @override
  State<ReadingRemindersPage> createState() => _ReadingRemindersPageState();
}

class _ReadingRemindersPageState extends State<ReadingRemindersPage> {
  bool _isEnabled = false;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 19, minute: 0);
  final List<bool> _selectedDays = List.generate(7, (index) => false);
  bool _isLoading = true;

  final List<String> _dayNames = [
    'Montag',
    'Dienstag',
    'Mittwoch',
    'Donnerstag',
    'Freitag',
    'Samstag',
    'Sonntag',
  ];

  List<String> _pendingNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final notificationService = NotificationService();

      final isEnabled = await notificationService.isReminderEnabled();
      final time = await notificationService.getReminderTime();
      final days = await notificationService.getReminderDays();

      setState(() {
        _isEnabled = isEnabled;
        _selectedTime = time ?? const TimeOfDay(hour: 19, minute: 0);

        // Reset all days
        for (int i = 0; i < _selectedDays.length; i++) {
          _selectedDays[i] = false;
        }

        // Set selected days (convert from 1-7 to 0-6)
        for (int day in days) {
          if (day >= 1 && day <= 7) {
            _selectedDays[day - 1] = true;
          }
        }

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der Einstellungen: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_isEnabled) {
      await NotificationService().disableReminders();
      return;
    }

    final selectedWeekdays = <int>[];
    for (int i = 0; i < _selectedDays.length; i++) {
      if (_selectedDays[i]) {
        selectedWeekdays.add(i + 1); // Convert from 0-6 to 1-7
      }
    }

    if (selectedWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wähle mindestens einen Tag aus.'),
        ),
      );
      return;
    }

    try {
      await NotificationService().scheduleReadingReminder(
        time: _selectedTime,
        weekdays: selectedWeekdays,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Leseerinnerungen wurden gespeichert!'),
          ),
        );
        // Refresh pending notifications
        _loadPendingNotifications();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
          ),
        );
      }
    }
  }

  Future<void> _loadPendingNotifications() async {
    try {
      final pending = await NotificationService().getPendingNotifications();
      setState(() {
        _pendingNotifications = pending
            .map((n) => 'ID: ${n.id}, Title: ${n.title}, Body: ${n.body}')
            .toList();
      });
    } catch (e) {
      print('Error loading pending notifications: $e');
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return LiquidGlassWrapper(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Leseerinnerungen'),
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return LiquidGlassWrapper(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Leseerinnerungen'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveSettings,
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Enable/Disable Switch
              GlassCard(
                child: SwitchListTile(
                  title: const Text('Leseerinnerungen aktivieren'),
                  subtitle:
                      const Text('Erhalte tägliche Erinnerungen zum Lesen'),
                  value: _isEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _isEnabled = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Time Selection
              GlassCard(
                child: ListTile(
                  title: const Text('Erinnerungszeit'),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  enabled: _isEnabled,
                  onTap: _isEnabled ? _selectTime : null,
                ),
              ),

              const SizedBox(height: 16),

              // Days Selection
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Wochentage',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Wähle die Tage aus, an denen du erinnert werden möchtest:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        children: List.generate(_dayNames.length, (index) {
                          return FilterChip(
                            label: Text(_dayNames[index]),
                            selected: _selectedDays[index],
                            onSelected: _isEnabled
                                ? (bool selected) {
                                    setState(() {
                                      _selectedDays[index] = selected;
                                    });
                                  }
                                : null,
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Info Card
              GlassCard(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Die Erinnerungen werden zu der gewählten Zeit an den ausgewählten Tagen gesendet. Du kannst sie jederzeit in den Einstellungen ändern.',
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Test Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await NotificationService().showTestNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Test-Benachrichtigung gesendet!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.notification_add),
                      label: const Text('Test Sofort'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await NotificationService().scheduleTestNotification();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Test in 5 Sekunden!')),
                          );
                        }
                      },
                      icon: const Icon(Icons.schedule),
                      label: const Text('Test 5s'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saveSettings,
                  icon: const Icon(Icons.save),
                  label: const Text('Einstellungen speichern'),
                ),
              ),

              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
        ),
      ),
    );
  }
}
