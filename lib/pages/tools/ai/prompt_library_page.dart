import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 提示词库页面
class PromptLibraryPage extends StatefulWidget {
  const PromptLibraryPage({super.key});

  @override
  State<PromptLibraryPage> createState() => _PromptLibraryPageState();
}

class _PromptLibraryPageState extends State<PromptLibraryPage> {
  final List<PromptItem> _builtinPrompts = [];
  final List<PromptItem> _customPrompts = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  
  String _selectedCategory = 'all';
  String _searchQuery = '';
  
  final Map<String, String> _categories = {
    'all': '全部',
    'writing': '写作',
    'code': '编程',
    'creative': '创意',
    'analysis': '分析',
    'translation': '翻译',
    'custom': '我的收藏',
  };
  
  @override
  void initState() {
    super.initState();
    _loadBuiltinPrompts();
    _loadCustomPrompts();
  }
  
  /// 加载内置提示词
  void _loadBuiltinPrompts() {
    _builtinPrompts.addAll([
      // 写作类
      PromptItem(
        id: 'writing_1',
        title: '文章润色',
        content: '请对以下文章进行润色，改善语言表达，使其更加流畅和专业：\n\n[你的文章]',
        category: 'writing',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'writing_2',
        title: '生成标题',
        content: '请为以下内容生成5个吸引人的标题：\n\n[你的内容]',
        category: 'writing',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'writing_3',
        title: '写邮件',
        content: '请帮我写一封正式的工作邮件，主题：[主题]，收件人：[收件人]，要点：[要点]',
        category: 'writing',
        isBuiltin: true,
      ),
      
      // 编程类
      PromptItem(
        id: 'code_1',
        title: '代码解释',
        content: '请详细解释以下代码的功能和工作原理：\n\n```\n[你的代码]\n```',
        category: 'code',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'code_2',
        title: '代码重构',
        content: '请重构以下代码，提高可读性和性能：\n\n```\n[你的代码]\n```',
        category: 'code',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'code_3',
        title: 'Debug助手',
        content: '以下代码出现错误：[错误信息]，请帮我找出问题并修复：\n\n```\n[你的代码]\n```',
        category: 'code',
        isBuiltin: true,
      ),
      
      // 创意类
      PromptItem(
        id: 'creative_1',
        title: '头脑风暴',
        content: '请帮我进行头脑风暴，主题：[主题]，目标：[目标]，请提供10个创意点子。',
        category: 'creative',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'creative_2',
        title: '故事创作',
        content: '请根据以下设定创作一个短故事：\n主角：[主角]\n场景：[场景]\n情节：[情节]',
        category: 'creative',
        isBuiltin: true,
      ),
      
      // 分析类
      PromptItem(
        id: 'analysis_1',
        title: '数据分析',
        content: '请对以下数据进行分析和解读：\n\n[你的数据]',
        category: 'analysis',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'analysis_2',
        title: 'SWOT分析',
        content: '请对以下主题进行SWOT分析（优势、劣势、机会、威胁）：\n\n[主题]',
        category: 'analysis',
        isBuiltin: true,
      ),
      
      // 翻译类
      PromptItem(
        id: 'translation_1',
        title: '中英互译',
        content: '请将以下内容翻译成[目标语言]，保持原意和语气：\n\n[内容]',
        category: 'translation',
        isBuiltin: true,
      ),
      PromptItem(
        id: 'translation_2',
        title: '本地化翻译',
        content: '请将以下内容进行本地化翻译，适配[目标地区]的文化习惯：\n\n[内容]',
        category: 'translation',
        isBuiltin: true,
      ),
    ]);
  }
  
  /// 加载自定义提示词
  Future<void> _loadCustomPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString('custom_prompts');
    if (jsonStr != null) {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      setState(() {
        _customPrompts.clear();
        _customPrompts.addAll(
          jsonList.map((j) => PromptItem.fromJson(j)).toList(),
        );
      });
    }
  }
  
  /// 保存自定义提示词
  Future<void> _saveCustomPrompts() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _customPrompts.map((p) => p.toJson()).toList();
    await prefs.setString('custom_prompts', jsonEncode(jsonList));
  }
  
  /// 添加自定义提示词
  void _addCustomPrompt() {
    _titleController.clear();
    _contentController.clear();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加提示词'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  hintText: '例如：周报生成器',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: '提示词内容',
                  hintText: '请帮我生成一份工作周报，本周工作：[工作内容]',
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_titleController.text.isNotEmpty && _contentController.text.isNotEmpty) {
                final newPrompt = PromptItem(
                  id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                  title: _titleController.text,
                  content: _contentController.text,
                  category: 'custom',
                  isBuiltin: false,
                );
                setState(() {
                  _customPrompts.add(newPrompt);
                });
                _saveCustomPrompts();
                Navigator.pop(context);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  /// 删除自定义提示词
  void _deleteCustomPrompt(String id) {
    setState(() {
      _customPrompts.removeWhere((p) => p.id == id);
    });
    _saveCustomPrompts();
  }
  
  /// 使用提示词
  void _usePrompt(PromptItem prompt) {
    // 复制到剪贴板
    Clipboard.setData(ClipboardData(text: prompt.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制：${prompt.title}')),
    );
    
    // 询问是否跳转到AI对话
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示词已复制'),
        content: const Text('是否跳转到AI对话页面使用？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('留在当前页'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/tool/ai_chat');
            },
            child: const Text('去AI对话'),
          ),
        ],
      ),
    );
  }
  
  /// 获取过滤后的提示词列表
  List<PromptItem> get _filteredPrompts {
    final allPrompts = [..._builtinPrompts, ..._customPrompts];
    
    return allPrompts.where((prompt) {
      // 分类过滤
      if (_selectedCategory != 'all' && _selectedCategory != 'custom') {
        if (prompt.category != _selectedCategory) return false;
      }
      if (_selectedCategory == 'custom' && prompt.isBuiltin) return false;
      
      // 搜索过滤
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return prompt.title.toLowerCase().contains(query) ||
               prompt.content.toLowerCase().contains(query);
      }
      
      return true;
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    final filteredPrompts = _filteredPrompts;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 提示词库'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addCustomPrompt,
            tooltip: '添加提示词',
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: '搜索提示词...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          
          // 分类标签
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final entry = _categories.entries.elementAt(index);
                final isSelected = _selectedCategory == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = entry.key;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          
          const Divider(),
          
          // 提示词列表
          Expanded(
            child: filteredPrompts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text('没有找到提示词', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filteredPrompts.length,
                  itemBuilder: (context, index) {
                    final prompt = filteredPrompts[index];
                    return _buildPromptCard(prompt);
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPromptCard(PromptItem prompt) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _usePrompt(prompt),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(prompt.category),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _categories[prompt.category] ?? '其他',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                  const Spacer(),
                  if (!prompt.isBuiltin)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () => _deleteCustomPrompt(prompt.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                prompt.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                prompt.content,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _usePrompt(prompt),
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('使用'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(String category) {
    final colors = {
      'writing': Colors.blue,
      'code': Colors.green,
      'creative': Colors.purple,
      'analysis': Colors.orange,
      'translation': Colors.teal,
      'custom': Colors.pink,
    };
    return colors[category] ?? Colors.grey;
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

/// 提示词数据模型
class PromptItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isBuiltin;

  PromptItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.isBuiltin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isBuiltin': isBuiltin,
    };
  }

  factory PromptItem.fromJson(Map<String, dynamic> json) {
    return PromptItem(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      category: json['category'],
      isBuiltin: json['isBuiltin'] ?? false,
    );
  }
}
