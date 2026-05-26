import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// HTML转义工具
/// 支持HTML实体编码和解码
/// 版本: v3.1.0
/// 开发者: 40305583
class HtmlEscapePage extends StatefulWidget {
  const HtmlEscapePage({super.key});

  @override
  State<HtmlEscapePage> createState() => _HtmlEscapePageState();
}

class _HtmlEscapePageState extends State<HtmlEscapePage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  
  bool _isEncoding = true; // true=编码, false=解码

  /// HTML实体映射表
  static final Map<String, String> _htmlEntities = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#x27;',
    '/': '&#x2F;',
    '`': '&#x60;',
    '=': '&#x3D;',
    '!': '&#33;',
    '@': '&#64;',
    '#': '&#35;',
    '\$': '&#36;',
    '%': '&#37;',
    '(': '&#40;',
    ')': '&#41;',
    '+': '&#43;',
    '{': '&#123;',
    '}': '&#125;',
    '[': '&#91;',
    ']': '&#93;',
    ' ': '&nbsp;', // 可选：是否转义空格
  };

  /// 反向映射表（用于解码）
  late final Map<String, String> _reverseEntities = {
    for (final entry in _htmlEntities.entries) entry.value: entry.key
  };

  /// 添加数字实体支持
  static final RegExp _numericEntityPattern = RegExp(r'&#(\d+);');
  static final RegExp _hexEntityPattern = RegExp(r'&#x([0-9a-fA-F]+);');

  /// 编码HTML
  String _encodeHtml(String input) {
    String result = input;
    // 先转义&，避免重复转义
    result = result.replaceAll('&', '&amp;');
    // 再转义其他字符
    for (final entry in _htmlEntities.entries) {
      if (entry.key != '&') {
        result = result.replaceAll(entry.key, entry.value);
      }
    }
    return result;
  }

  /// 解码HTML
  String _decodeHtml(String input) {
    String result = input;
    
    // 解码命名实体
    for (final entry in _reverseEntities.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    
    // 解码十进制数字实体 &#123;
    result = result.replaceAllMapped(_numericEntityPattern, (match) {
      final code = int.tryParse(match.group(1) ?? '');
      if (code != null && code >= 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });
    
    // 解码十六进制数字实体 &#x7B;
    result = result.replaceAllMapped(_hexEntityPattern, (match) {
      final code = int.tryParse(match.group(1) ?? '', radix: 16);
      if (code != null && code >= 0 && code <= 0x10FFFF) {
        return String.fromCharCode(code);
      }
      return match.group(0) ?? '';
    });
    
    return result;
  }

  /// 执行转换
  void _convert() {
    final input = _inputController.text;
    if (input.isEmpty) {
      _outputController.clear();
      return;
    }

    try {
      final output = _isEncoding ? _encodeHtml(input) : _decodeHtml(input);
      _outputController.text = output;
    } catch (e) {
      _outputController.text = '转换失败: $e';
    }
  }

  /// 清空
  void _clear() {
    _inputController.clear();
    _outputController.clear();
  }

  /// 粘贴
  Future<void> _paste() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        _inputController.text = data!.text!;
        _convert();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('粘贴失败: $e')),
      );
    }
  }

  /// 复制输出
  void _copyOutput() {
    final text = _outputController.text;
    if (text.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  /// 交换输入输出
  void _swap() {
    final temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
    setState(() {
      _isEncoding = !_isEncoding;
    });
    _convert();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔤 HTML转义'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // 模式切换
          _buildModeSelector(),
          
          // 输入输出区域
          Expanded(
            child: Row(
              children: [
                // 输入区
                Expanded(
                  child: _buildInputPanel(),
                ),
                // 交换按钮
                _buildSwapButton(),
                // 输出区
                Expanded(
                  child: _buildOutputPanel(),
                ),
              ],
            ),
          ),
          
          // 底部按钮栏
          _buildBottomBar(),
        ],
      ),
    );
  }

  /// 构建模式选择器
  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          const Text('模式:', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 16),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: true,
                label: Text('编码'),
                icon: Icon(Icons.arrow_forward),
              ),
              ButtonSegment(
                value: false,
                label: Text('解码'),
                icon: Icon(Icons.arrow_back),
              ),
            ],
            selected: {_isEncoding},
            onSelectionChanged: (selected) {
              setState(() {
                _isEncoding = selected.first;
              });
              _convert();
            },
          ),
        ],
      ),
    );
  }

  /// 构建输入面板
  Widget _buildInputPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.text_fields, size: 18, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  '原始文本',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste, size: 18),
                  label: const Text('粘贴'),
                ),
              ],
            ),
          ),
          // 输入框
          Expanded(
            child: TextField(
              controller: _inputController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: '在此输入文本...',
              ),
              maxLines: null,
              expands: true,
              onChanged: (_) => _convert(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建交换按钮
  Widget _buildSwapButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _swap,
            icon: const Icon(Icons.swap_horiz),
            tooltip: '交换',
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建输出面板
  Widget _buildOutputPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 标题栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.transform, size: 18, color: Colors.green[700]),
                const SizedBox(width: 8),
                Text(
                  _isEncoding ? 'HTML实体' : '解码结果',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: _copyOutput,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('复制'),
                ),
              ],
            ),
          ),
          // 输出框
          Expanded(
            child: TextField(
              controller: _outputController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
                hintText: '转换结果...',
              ),
              maxLines: null,
              expands: true,
              readOnly: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建底部栏
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '常用HTML实体对照',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildEntityChip('&', '&amp;'),
                _buildEntityChip('<', '&lt;'),
                _buildEntityChip('>', '&gt;'),
                _buildEntityChip('"', '&quot;'),
                _buildEntityChip("'", '&#x27;'),
                _buildEntityChip('空格', '&nbsp;'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建实体对照Chip
  Widget _buildEntityChip(String original, String entity) {
    return Chip(
      label: Text('$original → $entity'),
      backgroundColor: Colors.white,
      side: BorderSide(color: Colors.grey[300]!),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}