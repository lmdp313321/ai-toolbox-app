import 'package:flutter/material.dart';

class AsciiTablePage extends StatefulWidget {
  const AsciiTablePage({super.key});
  @override
  State<AsciiTablePage> createState() => _AsciiTablePageState();
}

class _AsciiTablePageState extends State<AsciiTablePage> {
  final TextEditingController _input = TextEditingController();
  int _base = 10;
  String _result = '';

  void _convert() {
    try {
      final num = int.parse(_input.text, radix: _base);
      setState(() {
        _result = '十进制: $num\n'
            '二进制: ${num.toRadixString(2)}\n'
            '八进制: ${num.toRadixString(8)}\n'
            '十六进制: ${num.toRadixString(16).toUpperCase()}\n'
            'ASCII: ${num >= 32 && num <= 126 ? String.fromCharCode(num) : '不可打印'}';
      });
    } catch (_) {
      setState(() => _result = '请输入有效数字');
    }
  }

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
                DropdownButton<int>(
                  value: _base,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('二进制')),
                    DropdownMenuItem(value: 8, child: Text('八进制')),
                    DropdownMenuItem(value: 10, child: Text('十进制')),
                    DropdownMenuItem(value: 16, child: Text('十六进制')),
                  ],
                  onChanged: (v) => setState(() => _base = v!),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _input,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: '输入数字'),
                    onSubmitted: (_) => _convert(),
                 ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _convert, child: const Text('转换')),
              ],
            ),
            if (_result.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_result, style: const TextStyle(fontFamily: 'monospace', fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
