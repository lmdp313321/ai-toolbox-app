import 'package:flutter/material.dart';
import 'dart:convert';

class EncodingToolPage extends StatefulWidget {
  const EncodingToolPage({super.key});
  @override
  State<EncodingToolPage> createState() => _EncodingToolPageState();
}

class _EncodingToolPageState extends State<EncodingToolPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  int _selectedType = 0; // 0: Base64, 1: URL, 2: Unicode, 3: Hex
  bool _isEncode = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('编码转换')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 类型选择
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Base64')),
                ButtonSegment(value: 1, label: Text('URL')),
                ButtonSegment(value: 2, label: Text('Unicode')),
                ButtonSegment(value: 3, label: Text('Hex')),
              ],
              selected: {_selectedType},
              onSelectionChanged: (v) => setState(() => _selectedType = v.first),
            ),
            const SizedBox(height: 16),
            
            // 方向切换
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('编码')),
                ButtonSegment(value: false, label: Text('解码')),
              ],
              selected: {_isEncode},
              onSelectionChanged: (v) => setState(() => _isEncode = v.first),
            ),
            const SizedBox(height: 16),
            
            // 输入
            TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                labelText: '输入',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // 转换按钮
            FilledButton(
              onPressed: _convert,
              child: Text(_isEncode ? '编码' : '解码'),
            ),
            const SizedBox(height: 16),
            
            // 输出
            TextField(
              controller: _outputController,
              decoration: const InputDecoration(
                labelText: '输出',
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

  void _convert() {
    final input = _inputController.text;
    String output = '';
    
    try {
      switch (_selectedType) {
        case 0: // Base64
          output = _isEncode 
              ? base64Encode(utf8.encode(input))
              : utf8.decode(base64Decode(input));
          break;
        case 1: // URL
          output = _isEncode
              ? Uri.encodeComponent(input)
              : Uri.decodeComponent(input);
          break;
        case 2: // Unicode
          if (_isEncode) {
            output = input.codeUnits.map((c) => '\\u${c.toRadixString(16).padLeft(4, '0')}').join();
          } else {
            output = input.replaceAllMapped(
              RegExp(r'\\u([0-9a-fA-F]{4})'),
              (m) => String.fromCharCode(int.parse(m.group(1)!, radix: 16)),
            );
          }
          break;
        case 3: // Hex
          if (_isEncode) {
            output = input.codeUnits.map((c) => c.toRadixString(16).padLeft(2, '0')).join();
          } else {
            output = String.fromCharCodes(
              List.generate(input.length ~/ 2, (i) => int.parse(input.substring(i * 2, i * 2 + 2), radix: 16)),
            );
          }
          break;
      }
      _outputController.text = output;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('转换失败: $e')),
      );
    }
  }
}
