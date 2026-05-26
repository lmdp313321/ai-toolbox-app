import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeToolPage extends StatefulWidget {
  const TimeToolPage({super.key});
  @override
  State<TimeToolPage> createState() => _TimeToolPageState();
}

class _TimeToolPageState extends State<TimeToolPage> {
  final TextEditingController _timestampController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  String _currentTime = '';
  String _currentTimezone = 'UTC+8';

  @override
  void initState() {
    super.initState();
    _updateCurrentTime();
  }

  void _updateCurrentTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      _timestampController.text = (now.millisecondsSinceEpoch ~/ 1000).toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('时间工具')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('当前时间: $_currentTime', style: Theme.of(context).textTheme.titleMedium),
            Text('时区: $_currentTimezone'),
            const SizedBox(height: 24),
            
            // 时间戳转日期
            const Text('时间戳转日期', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _timestampController,
              decoration: const InputDecoration(
                labelText: '时间戳(秒)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _timestampToDate, child: const Text('转换')),
            const SizedBox(height: 24),
            
            // 日期转时间戳
            const Text('日期转时间戳', style: TextStyle(fontWeight: FontWeight.bold)),
            TextField(
              controller: _dateController,
              decoration: const InputDecoration(
                labelText: '日期 (yyyy-MM-dd HH:mm:ss)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: _dateToTimestamp, child: const Text('转换')),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _updateCurrentTime,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  void _timestampToDate() {
    try {
      final timestamp = int.parse(_timestampController.text);
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(date))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转换失败: $e')),
      );
    }
  }

  void _dateToTimestamp() {
    try {
      final date = DateFormat('yyyy-MM-dd HH:mm:ss').parse(_dateController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${date.millisecondsSinceEpoch ~/ 1000}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转换失败: $e')),
      );
    }
  }
}
