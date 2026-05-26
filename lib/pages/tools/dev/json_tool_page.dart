import 'package:flutter/material.dart';
import 'dart:convert';

class JsonToolPage extends StatefulWidget {
  const JsonToolPage({super.key});
  @override
  State<JsonToolPage> createState() => _JsonToolPageState();
}

class _JsonToolPageState extends State<JsonToolPage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('JSON工具')),
      body: Column(
        children: [
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(8),
            child: Wrap(
              spacing: 8,
              children: [
                FilledButton(onPressed: _formatJson, child: const Text('格式化')),
                OutlinedButton(onPressed: _compressJson, child: const Text('压缩')),
                OutlinedButton(onPressed: _validateJson, child: const Text('校验')),
                OutlinedButton(onPressed: _clear, child: const Text('清空')),
              ],
            ),
          ),
          
          // 输入输出区域
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _inputController,
                      decoration: const InputDecoration(
                        labelText: '输入JSON',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TextField(
                      controller: _outputController,
                      decoration: const InputDecoration(
                        labelText: '输出结果',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      readOnly: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_inputController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _outputController.text = formatted;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON格式错误: $e')),
      );
    }
  }

  void _compressJson() {
    try {
      final decoded = jsonDecode(_inputController.text);
      _outputController.text = jsonEncode(decoded);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON格式错误: $e')),
      );
    }
  }

  void _validateJson() {
    try {
      jsonDecode(_inputController.text);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('JSON格式正确'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('JSON格式错误: $e')),
      );
    }
  }

  void _clear() {
    _inputController.clear();
    _outputController.clear();
  }
}
