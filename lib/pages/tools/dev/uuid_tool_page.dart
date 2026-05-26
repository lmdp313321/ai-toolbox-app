import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class UuidToolPage extends StatefulWidget {
  const UuidToolPage({super.key});
  @override
  State<UuidToolPage> createState() => _UuidToolPageState();
}

class _UuidToolPageState extends State<UuidToolPage> {
  int _count = 10;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UUID生成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text('生成数量: '),
                Expanded(
                  child: Slider(
                    value: _count.toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: _count.toString(),
                    onChanged: (v) => setState(() => _count = v.round()),
                  ),
                ),
                Text('$_count'),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _generate, child: const Text('生成')),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: null,
                expands: true,
                readOnly: true,
                controller: TextEditingController(text: _result),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.copy),
                  label: const Text('复制全部'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _result = ''),
                  icon: const Icon(Icons.clear),
                  label: const Text('清空'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _generate() {
    final uuid = Uuid();
    setState(() {
      _result = List.generate(_count, (_) => uuid.v4()).join('\n');
    });
  }
}
