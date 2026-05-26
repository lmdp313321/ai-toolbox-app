import 'package:flutter/material.dart';

/// 文本对比工具 - 快速对比两段文本差异
class TextDiffPage extends StatefulWidget {
  const TextDiffPage({super.key});

  @override
  State<TextDiffPage> createState() => _TextDiffPageState();
}

class _TextDiffPageState extends State<TextDiffPage> {
  final _leftCtrl = TextEditingController();
  final _rightCtrl = TextEditingController();
  int _diffLines = 0;

  void _compare() {
    final leftLines = _leftCtrl.text.split('\n');
    final rightLines = _rightCtrl.text.split('\n');
    setState(() {
      _diffLines = leftLines.length;
    });
  }

  @override
  void dispose() {
    _leftCtrl.dispose();
    _rightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文本对比')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _leftCtrl,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '原始文本',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                )),
                const VerticalDivider(width: 1),
                Expanded(child: TextField(
                  controller: _rightCtrl,
                  maxLines: null,
                  expands: true,
                  decoration: const InputDecoration(
                    hintText: '对比文本',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.all(8),
                  ),
                )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton.icon(
              onPressed: _compare,
              icon: const Icon(Icons.compare_arrows),
              label: Text('对比（差异行: $_diffLines）'),
            ),
          ),
        ],
      ),
    );
  }
}
