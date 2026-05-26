import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CountdownDayPage extends StatefulWidget {
  const CountdownDayPage({super.key});
  @override
  State<CountdownDayPage> createState() => _CountdownDayPageState();
}

class _CountdownDayPageState extends State<CountdownDayPage> {
  List<Map<String, dynamic>> _events = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('countdown_events');
    if (data != null) {
      setState(() => _events = List<Map<String, dynamic>>.from(jsonDecode(data)));
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('countdown_events', jsonEncode(_events));
  }

  void _addEvent() {
    showDialog(
      context: context,
      builder: (ctx) {
        String name = '';
        DateTime date = DateTime.now();
        return AlertDialog(
          title: const Text('添加倒数日'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '事件名称', border: OutlineInputBorder()),
                onChanged: (v) => name = v,
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                icon: const Icon(Icons.calendar_today),
                label: Text('日期: ${date.toIso8601String().substring(0, 10)}'),
                onPressed: () async {
                  final picked = await showDatePicker(context: ctx, initialDate: date, firstDate: DateTime(2020), lastDate: DateTime(2050));
                  if (picked != null) date = picked;
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            FilledButton(onPressed: () {
              if (name.isNotEmpty) {
                setState(() => _events.add({'name': name, 'date': date.toIso8601String()}));
                _save();
                Navigator.pop(ctx);
              }
            }, child: const Text('添加')),
          ],
        );
      },
    );
  }

  int _daysUntil(String dateStr) {
    final date = DateTime.parse(dateStr);
    return date.difference(DateTime.now()).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('倒数日'),
        actions: [IconButton(icon: const Icon(Icons.add), onPressed: _addEvent)],
      ),
      body: _events.isEmpty
          ? const Center(child: Text('暂无倒数日，点击右上角添加'))
          : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (ctx, i) {
                final e = _events[i];
                final days = _daysUntil(e['date'] as String);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(e['name'] as String),
                    subtitle: Text(e['date'].toString().substring(0, 10)),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(days >= 0 ? '$days' : '${days.abs()}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: days >= 0 ? Colors.blue : Colors.orange)),
                        Text(days >= 0 ? '天后' : '已过', style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    onLongPress: () {
                      setState(() => _events.removeAt(i));
                      _save();
                    },
                  ),
                );
              },
            ),
    );
  }
}
