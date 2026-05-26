import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DrinkReminderPage extends StatefulWidget {
  const DrinkReminderPage({super.key});
  @override
  State<DrinkReminderPage> createState() => _DrinkReminderPageState();
}

class _DrinkReminderPageState extends State<DrinkReminderPage> {
  int _cups = 0;
  static const _target = 8;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final saved = prefs.getString('drink_$today');
    if (saved != null) setState(() => _cups = int.parse(saved));
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('drink_$today', _cups.toString());
  }

  @override
  Widget build(BuildContext context) {
    final progress = _cups / _target;
    return Scaffold(
      appBar: AppBar(title: const Text('喝水提醒')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('今日饮水', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              SizedBox(
                width: 200, height: 200,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 16,
                      backgroundColor: Colors.blue.shade100,
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$_cups', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
                        Text('/ $_target 杯', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('喝了一杯 (250ml)'),
                onPressed: () {
                  setState(() {
                    if (_cups < _target) _cups++;
                  });
                  _save();
                },
              ),
              if (_cups >= _target)
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Text('🎉 今日饮水达标！', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.green)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
