import 'package:flutter/material.dart';

class RadixToolPage extends StatefulWidget {
  const RadixToolPage({super.key});
  @override
  State<RadixToolPage> createState() => _RadixToolPageState();
}

class _RadixToolPageState extends State<RadixToolPage> {
  final TextEditingController _inputController = TextEditingController();
  int _fromBase = 10;
  int _toBase = 2;
  String _result = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('进制转换')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _fromBase,
                    decoration: const InputDecoration(labelText: '源进制'),
                    items: [2, 8, 10, 16].map((b) => DropdownMenuItem(value: b, child: Text('$b进制'))).toList(),
                    onChanged: (v) => setState(() => _fromBase = v!),
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _toBase,
                    decoration: const InputDecoration(labelText: '目标进制'),
                    items: [2, 8, 10, 16].map((b) => DropdownMenuItem(value: b, child: Text('$b进制'))).toList(),
                    onChanged: (v) => setState(() => _toBase = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(labelText: '输入数值'),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _convert, child: const Text('转换')),
            const SizedBox(height: 16),
            Text('结果: $_result', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  void _convert() {
    try {
      final decimal = int.parse(_inputController.text, radix: _fromBase);
      setState(() {
        _result = decimal.toRadixString(_toBase).toUpperCase();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转换失败: $e')),
      );
    }
  }
}
