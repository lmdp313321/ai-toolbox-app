import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

/// AI代码助手页面
class AiCodePage extends StatefulWidget {
  const AiCodePage({super.key});

  @override
  State<AiCodePage> createState() => _AiCodePageState();
}

class _AiCodePageState extends State<AiCodePage> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  String _selectedFunction = 'generate'; // generate, explain, optimize, fix, review
  String _selectedLanguage = 'python';
  bool _isLoading = false;
  
  final Map<String, String> _functions = {
    'generate': '生成代码',
    'explain': '解释代码',
    'optimize': '优化代码',
    'fix': '修复Bug',
    'review': '代码审查',
  };
  
  final Map<String, String> _languages = {
    'python': 'Python',
    'javascript': 'JavaScript',
    'java': 'Java',
    'cpp': 'C++',
    'csharp': 'C#',
    'go': 'Go',
    'rust': 'Rust',
    'dart': 'Dart',
    'sql': 'SQL',
    'html': 'HTML/CSS',
  };
  
  Future<void> _processCode() async {
    if (_codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入代码或需求')),
      );
      return;
    }
    
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    if (!apiProvider.hasValidConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultController.clear();
    });
    
    try {
      final prompt = _buildPrompt();
      
      final response = await AiService.chat(
        messages: [
          {'role': 'system', 'content': '你是一个专业的编程助手，擅长多种编程语言。'},
          {'role': 'user', 'content': prompt},
        ],
        config: apiProvider.activeConfig!,
      );
      
      setState(() {
        _resultController.text = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultController.text = '错误: $e';
        _isLoading = false;
      });
    }
  }
  
  String _buildPrompt() {
    final code = _codeController.text.trim();
    final lang = _languages[_selectedLanguage]!;
    
    switch (_selectedFunction) {
      case 'generate':
        return '请用$lang编写以下功能的代码：\n\n$code\n\n要求：\n1. 代码要有注释\n2. 包含示例用法\n3. 考虑边界情况';
      case 'explain':
        return '请详细解释以下$lang代码的功能和工作原理：\n\n```$_selectedLanguage\n$code\n```\n\n请分步骤解释，并对关键行进行说明。';
      case 'optimize':
        return '请优化以下$lang代码，提升性能和可读性：\n\n```$_selectedLanguage\n$code\n```\n\n请说明优化前后的对比。';
      case 'fix':
        return '请找出以下$lang代码中的Bug并修复：\n\n```$_selectedLanguage\n$code\n```\n\n请说明问题原因和修复方案。';
      case 'review':
        return '请对以下$lang代码进行审查：\n\n```$_selectedLanguage\n$code\n```\n\n请从以下方面评价：\n1. 代码规范\n2. 潜在问题\n3. 改进建议';
      default:
        return code;
    }
  }
  
  void _copyResult() {
    if (_resultController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _clearAll() {
    setState(() {
      _codeController.clear();
      _resultController.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💻 AI代码助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // 功能选择栏
          _buildFunctionBar(),
          
          // 主内容区
          Expanded(
            child: Row(
              children: [
                // 输入区
                Expanded(
                  child: _buildInputPanel(),
                ),
                // 结果区
                Expanded(
                  child: _buildResultPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFunctionBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 功能选择
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _functions.entries.map((entry) {
                  final isSelected = _selectedFunction == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFunction = entry.key;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          
          // 语言选择
          if (_selectedFunction == 'generate')
            DropdownButton<String>(
              value: _selectedLanguage,
              underline: const SizedBox(),
              items: _languages.entries.map((entry) {
                return DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedLanguage = value;
                  });
                }
              },
            ),
        ],
      ),
    );
  }
  
  Widget _buildInputPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.code, size: 18),
                const SizedBox(width: 8),
                Text(
                  _selectedFunction == 'generate' ? '需求描述' : '代码输入',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                hintText: '在此输入代码或需求...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: null,
              expands: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _processCode,
                    icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                    label: Text(_isLoading ? '处理中...' : _functions[_selectedFunction]!),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 18),
                const SizedBox(width: 8),
                const Text(
                  'AI结果',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyResult,
                  tooltip: '复制',
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _resultController,
              decoration: const InputDecoration(
                hintText: 'AI结果将显示在这里...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: null,
              expands: true,
              readOnly: true,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _codeController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
