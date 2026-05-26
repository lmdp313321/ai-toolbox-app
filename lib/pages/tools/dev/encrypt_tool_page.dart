import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class EncryptToolPage extends StatefulWidget {
  const EncryptToolPage({super.key});
  @override
  State<EncryptToolPage> createState() => _EncryptToolPageState();
}

class _EncryptToolPageState extends State<EncryptToolPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  int _selectedType = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('加密解密')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('MD5')),
                ButtonSegment(value: 1, label: Text('SHA256')),
                ButtonSegment(value: 2, label: Text('SHA512')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) => setState(() => _selectedType = v.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: '输入文本',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _encrypt, child: const Text('生成哈希')),
            const SizedBox(height: 16),
            TextField(
              controller: _outputController,
              decoration: const InputDecoration(
                labelText: '结果',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              readOnly: true,
            ),
          ],
        ),
      ),
    );
  }

  void _encrypt() {
    final input = _inputController.text;
    if (input.isEmpty) return;
    
    final bytes = utf8.encode(input);
    String result = '';
    
    switch (_selectedType) {
      case 0:
        result = md5.convert(bytes).toString();
        break;
      case 1:
        result = sha256.convert(bytes).toString();
        break;
      case 2:
        result = sha512.convert(bytes).toString();
        break;
    }
    
    _outputController.text = result;
  }
}
