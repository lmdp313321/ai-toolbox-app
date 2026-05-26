import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 代码格式化页面 - JSON/XML/HTML格式化
class CodeFormatPage extends StatefulWidget {
  const CodeFormatPage({super.key});

  @override
  State<CodeFormatPage> createState() => _CodeFormatPageState();
}

class _CodeFormatPageState extends State<CodeFormatPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  String _selectedFormat = 'JSON';

  final List<String> _formats = ['JSON', 'XML', 'HTML', 'SQL'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }

  void _format() {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入代码')),
      );
      return;
    }

    try {
      String formatted;
      switch (_selectedFormat) {
        case 'JSON':
          final jsonData = json.decode(input);
          formatted = const JsonEncoder.withIndent('  ').convert(jsonData);
          break;
        case 'XML':
          formatted = _formatXML(input);
          break;
        case 'HTML':
          formatted = _formatHTML(input);
          break;
        case 'SQL':
          formatted = _formatSQL(input);
          break;
        default:
          formatted = input;
      }
      _outputController.text = formatted;
    } catch (e) {
      _outputController.text = '格式化错误: $e';
    }
  }

  void _minify() {
    final input = _inputController.text.trim();
    if (input.isEmpty) return;

    try {
      String minified;
      switch (_selectedFormat) {
        case 'JSON':
          final jsonData = json.decode(input);
          minified = json.encode(jsonData);
          break;
        default:
          minified = input.replaceAll(RegExp(r'\s+'), ' ').trim();
      }
      _outputController.text = minified;
    } catch (e) {
      _outputController.text = '压缩错误: $e';
    }
  }

  void _escape() {
    final input = _inputController.text;
    _outputController.text = input
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  void _unescape() {
    final input = _inputController.text;
    _outputController.text = input
        .replaceAll('\\"', '"')
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\\\', '\\');
  }

  String _formatXML(String xml) {
    // 简化的XML格式化
    var indent = 0;
    final result = <String>[];
    final lines = xml.replaceAll('><', '>\n<').split('\n');
    
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      
      if (trimmed.startsWith('</')) indent--;
      result.add('  ' * indent + trimmed);
      if (trimmed.startsWith('<') && !trimmed.startsWith('</') && !trimmed.endsWith('/>')) {
        indent++;
      }
      if (trimmed.endsWith('/>') || trimmed.endsWith('</')) indent--;
    }
    
    return result.join('\n');
  }

  String _formatHTML(String html) {
    // 简化的HTML格式化
    return _formatXML(html);
  }

  String _formatSQL(String sql) {
    // 简化的SQL格式化
    final keywords = ['SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'ORDER BY', 
                      'GROUP BY', 'HAVING', 'JOIN', 'LEFT JOIN', 'RIGHT JOIN',
                      'INNER JOIN', 'INSERT INTO', 'UPDATE', 'DELETE FROM'];
    
    var formatted = sql;
    for (final keyword in keywords) {
      formatted = formatted.replaceAllMapped(
        RegExp(keyword, caseSensitive: false),
        (match) => '\n${keyword}',
      );
    }
    
    return formatted.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('代码格式化'),
        actions: [
          // 格式选择
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedFormat,
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: const TextStyle(color: Colors.white),
                items: _formats.map((f) => DropdownMenuItem(
                  value: f,
                  child: Text(f, style: const TextStyle(color: Colors.white)),
                )).toList(),
                onChanged: (v) => setState(() => _selectedFormat = v!),
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '输入'),
            Tab(text: '输出'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 输入页面
                _buildInputTab(),
                // 输出页面
                _buildOutputTab(),
              ],
            ),
          ),
          
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: SafeArea(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton.icon(
                    onPressed: _format,
                    icon: const Icon(Icons.format_align_left),
                    label: const Text('格式化'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _minify,
                    icon: const Icon(Icons.compress),
                    label: const Text('压缩'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _escape,
                    icon: const Icon(Icons.code),
                    label: const Text('转义'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _unescape,
                    icon: const Icon(Icons.raw_on),
                    label: const Text('去转义'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      _inputController.clear();
                      _outputController.clear();
                    },
                    icon: const Icon(Icons.clear_all),
                    label: const Text('清空'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputTab() {
    return Column(
      children: [
        Expanded(
          child: TextField(
            controller: _inputController,
            decoration: const InputDecoration(
              hintText: '输入原始代码...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            maxLines: null,
            expands: true,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        
        // 快捷示例
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('示例: ', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('JSON'),
                  onPressed: () {
                    _inputController.text = '{"name":"test","items":[1,2,3],"active":true}';
                  },
                ),
                const SizedBox(width: 8),
                ActionChip(
                  label: const Text('XML'),
                  onPressed: () {
                    _inputController.text = '<root><item id="1">text</item></root>';
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOutputTab() {
    return Column(
      children: [
        Expanded(
          child: Container(
            color: Colors.grey[900],
            child: TextField(
              controller: _outputController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              maxLines: null,
              expands: true,
              readOnly: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                color: Colors.green,
              ),
            ),
          ),
        ),
        
        // 复制按钮
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _outputController.text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
                  );
                },
                icon: const Icon(Icons.copy),
                label: const Text('复制结果'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
