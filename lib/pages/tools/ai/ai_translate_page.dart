import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/model_provider.dart';
import '../../../services/ai_service.dart';
import '../../../core/storage/app_database.dart';

/// AI翻译 - 专业的多语言翻译工具
/// 版本: v3.1.0
/// 开发者: 40305583
class AiTranslatePage extends StatefulWidget {
  const AiTranslatePage({super.key});

  @override
  State<AiTranslatePage> createState() => _AiTranslatePageState();
}

class _AiTranslatePageState extends State<AiTranslatePage> {
  final TextEditingController _inputController = TextEditingController();
  final TextEditingController _outputController = TextEditingController();
  bool _isLoading = false;
  
  // 语言选择
  String _sourceLang = '自动检测';
  String _targetLang = '英语';
  
  // 常用语言列表
  final List<String> _languages = [
    '自动检测',
    '中文',
    '英语',
    '日语',
    '韩语',
    '法语',
    '德语',
    '俄语',
    '西班牙语',
    '葡萄牙语',
    '意大利语',
    '阿拉伯语',
    '泰语',
    '越南语',
    '印尼语',
  ];
  
  // 快捷翻译历史
  final List<Map<String, String>> _history = [];

  /// 执行翻译
  Future<void> _translate() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要翻译的文本')),
      );
      return;
    }

    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    
    final currentModel = modelProvider.activeChatModel;
    if (currentModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置对话模型')),
      );
      return;
    }
    
    final apiConfig = apiProvider.configs
        .firstWhere((c) => c.id == currentModel.apiSourceId,
          orElse: () => ApiConfig(id: '', name: '未知'));
    
    if (apiConfig.id.isEmpty || apiConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先配置 ${apiConfig.name} 的API Key'),
          action: SnackBarAction(
            label: '去设置',
            onPressed: () => Navigator.pushNamed(context, '/settings/api'),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建翻译提示词
      final prompt = _buildPrompt(text);
      
      // 创建配置对象（使用选中模型的modelId）
      final config = ApiConfig(
        id: apiConfig.id,
        name: apiConfig.name,
        apiKey: apiConfig.apiKey,
        baseUrl: apiConfig.baseUrl,
        model: currentModel.modelId,
      );
      
      // 调用API
      final response = await AiService.chat(
        messages: [
          {'role': 'system', 'content': '你是一个专业翻译助手。只输出翻译结果，不添加任何解释、说明或额外内容。'},
          {'role': 'user', 'content': prompt},
        ],
        config: config,
      );

      setState(() {
        _outputController.text = response;
        _isLoading = false;
      });
      
      // 添加到历史
      _addToHistory(text, response);
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('翻译失败: $e')),
      );
    }
  }

  /// 构建提示词
  String _buildPrompt(String text) {
    final buffer = StringBuffer();
    
    if (_sourceLang == '自动检测') {
      buffer.write('将以下文本翻译成${_targetLang}：\n\n');
    } else {
      buffer.write('将以下${_sourceLang}文本翻译成${_targetLang}：\n\n');
    }
    
    buffer.write(text);
    
    return buffer.toString();
  }

  /// 添加到历史
  void _addToHistory(String source, String target) {
    setState(() {
      _history.insert(0, {
        'source': source.length > 30 ? '${source.substring(0, 30)}...' : source,
        'target': target.length > 30 ? '${target.substring(0, 30)}...' : target,
        'sourceLang': _sourceLang,
        'targetLang': _targetLang,
      });
      // 只保留最近10条
      if (_history.length > 10) {
        _history.removeLast();
      }
    });
  }

  /// 交换语言
  void _swapLanguages() {
    if (_sourceLang == '自动检测') {
      // 自动检测时，交换后需要指定源语言
      setState(() {
        _sourceLang = _targetLang;
        _targetLang = '中文';
      });
    } else {
      setState(() {
        final temp = _sourceLang;
        _sourceLang = _targetLang;
        _targetLang = temp;
      });
    }
    
    // 交换输入输出
    final temp = _inputController.text;
    _inputController.text = _outputController.text;
    _outputController.text = temp;
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
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('粘贴失败: $e')),
      );
    }
  }

  /// 复制结果
  void _copyResult() {
    final text = _outputController.text;
    if (text.isEmpty) return;
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('翻译结果已复制')),
    );
  }

  /// 选择语言
  void _selectLanguage(bool isSource) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isSource ? '选择源语言' : '选择目标语言',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _languages.length,
                itemBuilder: (context, index) {
                  final lang = _languages[index];
                  // 目标语言不能选自动检测
                  if (!isSource && lang == '自动检测') {
                    return const SizedBox.shrink();
                  }
                  
                  final isSelected = isSource 
                      ? _sourceLang == lang 
                      : _targetLang == lang;
                  
                  return ListTile(
                    title: Text(lang),
                    trailing: isSelected 
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    selected: isSelected,
                    onTap: () {
                      setState(() {
                        if (isSource) {
                          _sourceLang = lang;
                        } else {
                          _targetLang = lang;
                        }
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🌐 AI翻译'),
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
          // 语言选择器
          _buildLanguageSelector(),
          
          // 输入区域
          Expanded(
            flex: 1,
            child: _buildInputArea(),
          ),
          
          // 翻译按钮
          _buildTranslateButton(),
          
          // 输出区域
          Expanded(
            flex: 1,
            child: _buildOutputArea(),
          ),
          
          // 历史记录
          if (_history.isNotEmpty) _buildHistorySection(),
        ],
      ),
    );
  }

  /// 构建语言选择器
  Widget _buildLanguageSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          // 源语言
          Expanded(
            child: InkWell(
              onTap: () => _selectLanguage(true),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _sourceLang,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
          
          // 交换按钮
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: IconButton(
              onPressed: _swapLanguages,
              icon: const Icon(Icons.swap_horiz),
              tooltip: '交换语言',
            ),
          ),
          
          // 目标语言
          Expanded(
            child: InkWell(
              onTap: () => _selectLanguage(false),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _targetLang,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.paste, size: 20),
                  onPressed: _paste,
                  tooltip: '粘贴',
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _inputController,
                  builder: (context, value, child) {
                    return Text(
                      '${value.text.length} 字符',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => _inputController.clear(),
                  tooltip: '清空',
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
                hintText: '请输入要翻译的文本...',
              ),
              maxLines: null,
              expands: true,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建翻译按钮
  Widget _buildTranslateButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _isLoading ? null : _translate,
          icon: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.translate),
          label: Text(_isLoading ? '翻译中...' : '开始翻译'),
        ),
      ),
    );
  }

  /// 构建输出区域
  Widget _buildOutputArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // 工具栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 20,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  '翻译结果',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: _copyResult,
                  tooltip: '复制结果',
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
                hintText: '翻译结果将显示在这里...',
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

  /// 构建历史记录区域
  Widget _buildHistorySection() {
    return Container(
      height: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '最近翻译',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _history.clear()),
                child: const Text('清空'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                return Card(
                  margin: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () {
                      _inputController.text = item['source']!.replaceAll('...', '');
                      _outputController.text = item['target']!.replaceAll('...', '');
                    },
                    child: Container(
                      width: 200,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item['sourceLang']} → ${item['targetLang']}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['source']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['target']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _outputController.dispose();
    super.dispose();
  }
}