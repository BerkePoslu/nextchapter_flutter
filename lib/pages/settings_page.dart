import 'package:flutter/material.dart';
import '../main.dart'; // Import to access themeModeNotifier
import 'reading_reminders_page.dart';
import 'reading_statistics_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  ThemeMode get _themeMode => themeModeNotifier.value;

  void _setThemeMode(ThemeMode mode) {
    themeModeNotifier.value = mode;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Allgemein'),
          ),
          ListTile(
            title: const Text('Designmodus'),
            subtitle: Text(_themeMode == ThemeMode.system
                ? 'System'
                : _themeMode == ThemeMode.dark
                    ? 'Dunkel'
                    : 'Hell'),
            trailing: DropdownButton<ThemeMode>(
              value: _themeMode,
              onChanged: (ThemeMode? mode) {
                if (mode != null) _setThemeMode(mode);
              },
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Hell'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dunkel'),
                ),
              ],
            ),
          ),
          ListTile(
            title: const Text('Leseerinnerungen'),
            subtitle:
                const Text('Konfiguriere tägliche Erinnerungen zum Lesen'),
            leading: const Icon(Icons.notifications),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReadingRemindersPage(),
                ),
              );
            },
          ),
          ListTile(
            title: const Text('Lese-Statistiken'),
            subtitle:
                const Text('Detaillierte Einblicke in Ihre Lesegewohnheiten'),
            leading: const Icon(Icons.analytics),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ReadingStatisticsPage(),
                ),
              );
            },
          ),
          const Divider(),
          const ListTile(
            title: Text('Über die App'),
          ),
          ListTile(
            title: const Text('Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info),
          ),
        ],
      ),
    );
  }
}
