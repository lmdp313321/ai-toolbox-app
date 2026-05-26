import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class VibrationTestPage extends StatefulWidget {
  const VibrationTestPage({super.key});
  @override
  State<VibrationTestPage> createState() => _VibrationTestPageState();
}

class _VibrationTestPageState extends State<VibrationTestPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('震动测试')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.vibration, size: 80, color: Colors.blue),
            const SizedBox(height: 32),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.light),
                    title: const Text('轻触反馈'),
                    trailing: ElevatedButton(
                      onPressed: () => HapticFeedback.lightImpact(),
                      child: const Text('测试'),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.healing),
                    title: const Text('中等反馈'),
                    trailing: ElevatedButton(
                      onPressed: () => HapticFeedback.mediumImpact(),
                      child: const Text('测试'),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.heavy),
                    title: const Text('重触反馈'),
                    trailing: ElevatedButton(
                      onPressed: () => HapticFeedback.heavyImpact(),
                      child: const Text('测试'),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.select_all),
                    title: const Text('选择反馈'),
                    trailing: ElevatedButton(
                      onPressed: () => HapticFeedback.selectionClick(),
                      child: const Text('测试'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
