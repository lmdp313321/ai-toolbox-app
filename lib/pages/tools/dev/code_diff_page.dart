import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 代码/文本对比工具
class CodeDiffPage extends StatefulWidget {
  const CodeDiffPage({super.key});

  @override
  State<CodeDiffPage> createState() => _CodeDiffPageState();
}

class _CodeDiffPageState extends State<CodeDiffPage> {
  final TextEditingController _leftController = TextEditingController();
  final TextEditingController _rightController = TextEditingController();
  List<DiffLine> _diffLines = [];
  bool _showIdentical = true;

  void _compare() {
    final leftLines = _leftController.text.split('\n');
    final rightLines = _rightController.text.split('\n');
    
    final maxLines = leftLines.length > rightLines.length 
        ? leftLines.length 
        : rightLines.length;
    
    final result = <DiffLine>[];
    
    for (int i = 0; i < maxLines; i++) {
      final leftLine = i < leftLines.length ? leftLines[i] : null;
      final rightLine = i < rightLines.length ? rightLines[i] : null;
      
      if (leftLine == rightLine) {
        if (_showIdentical) {
          result.add(DiffLine(
            lineNum: i + 1,
            leftContent: leftLine ?? '',
            rightContent: rightLine ?? '',
            type: DiffType.identical,
          ));
        }
      } else {
        result.add(DiffLine(
          lineNum: i + 1,
          leftContent: leftLine ?? '(无)',
          rightContent: rightLine ?? '(无)',
          type: DiffType.different,
        ));
      }
    }
    
    setState(() {
      _diffLines = result;
    });
  }

  void _clear() {
    _leftController.clear();
    _rightController.clear();
    setState(() {
      _diffLines = [];
    });
  }

  void _copyLeft() {
    Clipboard.setData(ClipboardData(text: _leftController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('左侧内容已复制')),
    );
  }

  void _copyRight() {
    Clipboard.setData(ClipboardData(text: _rightController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('右侧内容已复制')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📝 代码/文本对比'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.clear_all),
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // 操作栏
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: _compare,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('开始对比'),
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _showIdentical,
                      onChanged: (v) => setState(() => _showIdentical = v!),
                    ),
                    const Text('显示相同行'),
                  ],
                ),
                const Spacer(),
                Text('差异行数: ${_diffLines.where((l) => l.type == DiffType.different).length}'),
              ],
            ),
          ),
          
          // 输入区域
          Expanded(
            flex: 2,
            child: Row(
              children: [
                // 左侧输入
                Expanded(
                  child: _buildInputPanel(
                    title: '原始文本',
                    controller: _leftController,
                    onCopy: _copyLeft,
                    color: Colors.blue,
                  ),
                ),
                // 右侧输入
                Expanded(
                  child: _buildInputPanel(
                    title: '对比文本',
                    controller: _rightController,
                    onCopy: _copyRight,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          // 对比结果
          if (_diffLines.isNotEmpty)
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text('行号', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text('原始', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          Expanded(
                            flex: 5,
                            child: Text('对比', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _diffLines.length,
                        itemBuilder: (context, index) {
                          final line = _diffLines[index];
                          return _buildDiffRow(line);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInputPanel({
    required String title,
    required TextEditingController controller,
    required VoidCallback onCopy,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: color[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, size: 18, color: color[700]),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color[700])),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: onCopy,
                  tooltip: '复制',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: '在此输入文本...',
              ),
              maxLines: null,
              expands: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiffRow(DiffLine line) {
    final bgColor = line.type == DiffType.identical 
        ? Colors.white 
        : Colors.red[50];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: Text(
              '${line.lineNum}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: line.type == DiffType.different 
                    ? FontWeight.bold 
                    : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              line.leftContent,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                backgroundColor: line.type == DiffType.different 
                    ? Colors.red[100] 
                    : null,
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Text(
              line.rightContent,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                backgroundColor: line.type == DiffType.different 
                    ? Colors.green[100] 
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _leftController.dispose();
    _rightController.dispose();
    super.dispose();
  }
}

enum DiffType { identical, different }

class DiffLine {
  final int lineNum;
  final String leftContent;
  final String rightContent;
  final DiffType type;

  DiffLine({
    required this.lineNum,
    required this.leftContent,
    required this.rightContent,
    required this.type,
  });
}