import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

/// AI学习助手页面
class AiLearnPage extends StatefulWidget {
  const AiLearnPage({super.key});

  @override
  State<AiLearnPage> createState() => _AiLearnPageState();
}

class _AiLearnPageState extends State<AiLearnPage> {
  final TextEditingController _topicController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  String _selectedFunction = 'explain'; // explain, quiz, roadmap, summarize
  String _difficulty = 'beginner'; // beginner, intermediate, advanced
  bool _isLoading = false;
  
  final Map<String, String> _functions = {
    'explain': '概念解释',
    'quiz': '生成测验',
    'roadmap': '学习路线',
    'summarize': '知识总结',
  };
  
  final Map<String, String> _difficulties = {
    'beginner': '入门',
    'intermediate': '进阶',
    'advanced': '高级',
  };
  
  Future<void> _process() async {
    if (_topicController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入学习主题')),
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
          {'role': 'system', 'content': '你是一个专业的学习助手和教育专家。'},
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
    final topic = _topicController.text.trim();
    final level = _difficulties[_difficulty]!;
    
    switch (_selectedFunction) {
      case 'explain':
        return '请用通俗易懂的方式解释"$topic"这个概念，适合$level水平的学习者。\n\n请包含：\n1. 核心概念\n2. 实际例子\n3. 常见误区';
      case 'quiz':
        return '请为"$topic"生成5道${_difficulties[_difficulty]}难度的测试题，并附上答案和解析。';
      case 'roadmap':
        return '请为"$topic"设计一个完整的学习路线图，从入门到精通，包含各个阶段的学习内容和推荐资源。';
      case 'summarize':
        return '请总结"$topic"的核心知识点，以思维导图或要点列表的形式呈现。';
      default:
        return topic;
    }
  }
  
  void _copyResult() {
    if (_resultController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制')),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 AI学习助手'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 功能选择
            const Text('学习功能', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _functions.entries.map((entry) {
                final isSelected = _selectedFunction == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFunction = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // 难度选择
            const Text('难度等级', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: _difficulties.entries.map((entry) {
                return ButtonSegment(
                  value: entry.key,
                  label: Text(entry.value),
                );
              }).toList(),
              selected: {_difficulty},
              onSelectionChanged: (value) {
                setState(() {
                  _difficulty = value.first;
                });
              },
            ),
            const SizedBox(height: 24),
            
            // 主题输入
            TextField(
              controller: _topicController,
              decoration: const InputDecoration(
                labelText: '学习主题',
                hintText: '例如：机器学习、微积分、Python编程',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
            ),
            const SizedBox(height: 16),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _process,
                icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.psychology),
                label: Text(_isLoading ? '学习中...' : '开始学习'),
              ),
            ),
            const SizedBox(height: 24),
            
            // 结果
            if (_resultController.text.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lightbulb, color: Colors.amber),
                          const SizedBox(width: 8),
                          const Text(
                            '学习内容',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: _copyResult,
                          ),
                        ],
                      ),
                      const Divider(),
                      SelectableText(_resultController.text),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _topicController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
