import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

class AiWritingPage extends StatefulWidget {
  const AiWritingPage({super.key});

  @override
  State<AiWritingPage> createState() => _AiWritingPageState();
}

class _AiWritingPageState extends State<AiWritingPage> {
  int _selectedFunction = 0; // 0:翻译 1:摘要 2:改写 3:扩写 4:缩写
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _isLoading = false;
  
  final List<String> _functions = ['翻译', '摘要', '改写', '扩写', '缩写'];
  final List<String> _functionIcons = ['🌐', '📋', '✏️', '📝', '✂️'];
  
  // 翻译相关
  String _sourceLang = '自动检测';
  String _targetLang = '英语';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI写作'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // 显示历史记录
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 功能选择
          Container(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_functions.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_functionIcons[index]),
                          const SizedBox(width: 4),
                          Text(_functions[index]),
                        ],
                      ),
                      selected: _selectedFunction == index,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFunction = index;
                          });
                        }
                      },
                    ),
                  );
                }),
              ),
            ),
          ),
          
          // 翻译设置（仅翻译功能显示）
          if (_selectedFunction == 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _sourceLang,
                      decoration: const InputDecoration(
                        labelText: '源语言',
                        border: OutlineInputBorder(),
                      ),
                      items: ['自动检测', '中文', '英语', '日语', '韩语', '法语', '德语']
                          .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _sourceLang = value!;
                        });
                      },
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.arrow_forward),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _targetLang,
                      decoration: const InputDecoration(
                        labelText: '目标语言',
                        border: OutlineInputBorder(),
                      ),
                      items: ['英语', '中文', '日语', '韩语', '法语', '德语']
                          .map((lang) => DropdownMenuItem(value: lang, child: Text(lang)))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _targetLang = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // 输入区域
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _inputController,
                decoration: const InputDecoration(
                  hintText: '输入要处理的文本...',
                  border: OutlineInputBorder(),
                ),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
              ),
            ),
          ),
          
          // 操作按钮
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _inputController.clear();
                      _outputController.clear();
                    },
                    child: const Text('清空'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _processText,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_functions[_selectedFunction]),
                  ),
                ),
              ],
            ),
          ),
          
          // 输出区域
          if (_outputController.text.isNotEmpty || _isLoading)
            Container(
              height: 200,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _outputController,
                      decoration: null,
                      maxLines: null,
                      expands: true,
                      readOnly: true,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          // 复制结果
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('复制'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
  
  Future<void> _processText() async {
    final input = _inputController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入文本')),
      );
      return;
    }
    
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    final activeConfig = apiProvider.activeConfig;
    
    if (activeConfig == null || activeConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      Navigator.pushNamed(context, '/settings/api');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      String prompt;
      switch (_selectedFunction) {
        case 0: // 翻译
          prompt = '请将以下文本从${_sourceLang == '自动检测' ? '' : _sourceLang}翻译成$_targetLang，只输出翻译结果：\n\n$input';
          break;
        case 1: // 摘要
          prompt = '请为以下文本生成简洁的摘要，突出主要内容：\n\n$input';
          break;
        case 2: // 改写
          prompt = '请改写以下文本，保持原意但使用不同的表达方式：\n\n$input';
          break;
        case 3: // 扩写
          prompt = '请扩展以下文本，增加更多细节和内容：\n\n$input';
          break;
        case 4: // 缩写
          prompt = '请精简以下文本，保留核心信息：\n\n$input';
          break;
        default:
          prompt = input;
      }
      
      final response = await AiService.chat(
        messages: [{'role': 'user', 'content': prompt}],
        config: activeConfig,
      );
      
      setState(() {
        _outputController.text = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('处理失败: $e')),
      );
    }
  }
}
