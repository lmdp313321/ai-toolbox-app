import 'package:flutter/material.dart';

class TextToolPage extends StatefulWidget {
  const TextToolPage({super.key});
  @override
  State<TextToolPage> createState() => _TextToolPageState();
}

class _TextToolPageState extends State<TextToolPage> {
  final TextEditingController _inputController = TextEditingController();
  String _stats = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文字处理')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: '输入文本',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (_) => _updateStats(),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: _toUpperCase, child: const Text('大写')),
                FilledButton(onPressed: _toLowerCase, child: const Text('小写')),
                OutlinedButton(onPressed: _toHalfWidth, child: const Text('半角')),
                OutlinedButton(onPressed: _toFullWidth, child: const Text('全角')),
              ],
            ),
            const SizedBox(height: 16),
            Text(_stats, style: Theme.of(context).textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  void _updateStats() {
    final text = _inputController.text;
    setState(() {
      _stats = '字符数: ${text.length}\n'
          '汉字数: ${text.replaceAll(RegExp(r'[^\u4e00-\u9fa5]'), '').length}\n'
          '英文数: ${text.replaceAll(RegExp(r'[^a-zA-Z]'), '').length}\n'
          '数字数: ${text.replaceAll(RegExp(r'[^0-9]'), '').length}\n'
          '行数: ${text.isEmpty ? 0 : text.split('\n').length}';
    });
  }

  void _toUpperCase() => setState(() => _inputController.text = _inputController.text.toUpperCase());
  void _toLowerCase() => setState(() => _inputController.text = _inputController.text.toLowerCase());
  void _toHalfWidth() => setState(() => _inputController.text = _inputController.text);
  void _toFullWidth() => setState(() => _inputController.text = _inputController.text);
}
