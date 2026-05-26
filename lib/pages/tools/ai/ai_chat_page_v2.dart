import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../models/chat_models.dart';
import '../../../core/storage/chat_database.dart';
import '../../../services/ai_source_manager.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/model_provider.dart';
import 'package:uuid/uuid.dart';

/// AI对话页面 V2 - 支持4源切换和聊天记录
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> with SingleTickerProviderStateMixin {
  // 当前AI源
  AISourceType _currentSource = AISourceType.deepseekWeb;
  
  // 当前会话
  String? _currentSessionId;
  
  // 聊天记录
  final List<ChatMessage> _messages = [];
  
  // WebView控制器（网页版AI）
  WebViewController? _webViewController;
  
  // 文本控制器（API模式）
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // 状态
  bool _isLoading = false;
  bool _showHistory = false;
  
  // 数据库
  final ChatDatabase _db = ChatDatabase();
  
  @override
  void initState() {
    super.initState();
    _initWebView();
    _createNewSession();
  }

  /// 初始化WebView（网页版AI）
  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // 加载进度
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {},
          onWebResourceError: (WebResourceError error) {},
        ),
      );
  }

  /// 创建新会话
  Future<void> _createNewSession() async {
    final sessionId = await _db.createSession(
      '新对话 ${_formatDateTime(DateTime.now())}',
      _currentSource.code,
    );
    setState(() {
      _currentSessionId = sessionId;
      _messages.clear();
    });
    
    // 如果是网页版，加载对应URL
    if (_isWebViewMode) {
      _loadWebView();
    }
  }

  /// 加载网页版AI
  void _loadWebView() {
    if (_webViewController != null) {
      final url = AISourceManager().getWebUrl(_currentSource);
      _webViewController!.loadRequest(Uri.parse(url));
    }
  }

  /// 切换AI源
  void _switchSource(AISourceType source) {
    if (_currentSource == source) return;
    
    setState(() {
      _currentSource = source;
    });
    
    // 创建新会话
    _createNewSession();
  }

  /// 发送消息（API模式）
  Future<void> _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;
    if (_isWebViewMode) return;
    
    final content = _textController.text.trim();
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    
    // 获取当前选中的模型
    final currentModel = modelProvider.activeChatModel;
    if (currentModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置对话模型')),
      );
      return;
    }
    
    // 获取模型对应的API配置
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
    
    // 添加用户消息
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      sessionId: _currentSessionId!,
      role: 'user',
      content: content,
      timestamp: DateTime.now(),
    );
    
    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });
    
    await _db.addMessage(userMessage);
    _textController.clear();
    _scrollToBottom();
    
    try {
      // 构建消息历史
      final history = _messages.map((m) => {
        'role': m.role,
        'content': m.content,
      }).toList();
      
      // 创建带模型信息的配置
      final configWithModel = apiConfig;
      configWithModel.model = currentModel.modelId;
      
      // 调用API
      final response = await AISourceManager().sendApiMessage(
        source: _currentSource,
        messages: history,
        config: configWithModel,
      );
      
      // 添加AI回复
      final aiMessage = ChatMessage(
        id: const Uuid().v4(),
        sessionId: _currentSessionId!,
        role: 'assistant',
        content: response,
        timestamp: DateTime.now(),
        model: currentModel.modelId,
      );
      
      setState(() {
        _messages.add(aiMessage);
        _isLoading = false;
      });
      
      await _db.addMessage(aiMessage);
      _scrollToBottom();
      
    } catch (e) {
      // 添加错误消息
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        sessionId: _currentSessionId!,
        role: 'assistant',
        content: '错误: $e',
        timestamp: DateTime.now(),
        isError: true,
      );
      
      setState(() {
        _messages.add(errorMessage);
        _isLoading = false;
      });
      
      await _db.addMessage(errorMessage);
    }
  }

  /// 滚动到底部
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// 加载历史会话
  Future<void> _loadSession(String sessionId) async {
    final session = await _db.getSession(sessionId);
    if (session == null) return;
    
    setState(() {
      _currentSessionId = sessionId;
      _currentSource = AISourceType.fromCode(session.aiSource);
      _messages.clear();
      _messages.addAll(session.messages);
    });
    
    // 如果是网页版，加载URL
    if (_isWebViewMode) {
      _loadWebView();
    }
  }

  /// 格式化时间
  String _formatDateTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  /// 判断是否网页版模式
  bool get _isWebViewMode => _currentSource.isWebView;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getAppBarTitle()),
        actions: [
          // 模型选择按钮（仅在API模式显示）
          if (!_isWebViewMode) _buildModelSelector(),
          // AI源切换按钮
          _buildSourceSwitcher(),
          // 历史记录按钮
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showHistoryDialog(),
          ),
          // 新建对话按钮
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNewSession,
          ),
        ],
      ),
      body: Column(
        children: [
          // AI源指示器
          _buildSourceIndicator(),
          
          // 聊天内容区域
          Expanded(
            child: _isWebViewMode 
              ? _buildWebView() 
              : _buildChatList(),
          ),
          
          // 输入区域（仅API模式显示）
          if (!_isWebViewMode) _buildInputArea(),
        ],
      ),
    );
  }

  /// 获取标题
  String _getAppBarTitle() {
    final config = AISourceManager().getSourceConfig(_currentSource);
    return '${config.icon} ${config.name}';
  }

  /// 构建模型选择器
  Widget _buildModelSelector() {
    return Consumer2<ModelProvider, ApiProvider>(
      builder: (context, modelProvider, apiProvider, child) {
        final currentModel = modelProvider.activeChatModel;
        
        return IconButton(
          icon: const Icon(Icons.psychology),
          tooltip: currentModel?.name ?? '选择模型',
          onPressed: () => _showModelSelector(context),
        );
      },
    );
  }
  
  /// 显示模型选择器
  void _showModelSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Consumer2<ModelProvider, ApiProvider>(
            builder: (context, modelProvider, apiProvider, child) {
              final models = modelProvider.chatModels;
              final activeId = modelProvider.activeChatModelId;
              
              if (models.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('暂无对话模型'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/settings/models');
                        },
                        child: const Text('去添加模型'),
                      ),
                    ],
                  ),
                );
              }
              
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          '选择对话模型',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(context, '/settings/models');
                          },
                          icon: const Icon(Icons.settings),
                          label: const Text('管理'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: models.length,
                      itemBuilder: (context, index) {
                        final model = models[index];
                        final isActive = model.id == activeId;
                        final config = apiProvider.configs
                            .firstWhere((c) => c.id == model.apiSourceId,
                              orElse: () => ApiConfig(id: '', name: '未知'));
                        final hasKey = config.apiKey.isNotEmpty;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                            child: Icon(
                              Icons.chat,
                              color: isActive ? Colors.white : Colors.grey[700],
                            ),
                          ),
                          title: Text(
                            model.name,
                            style: TextStyle(
                              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${config.name} · ${model.modelId}'),
                              if (!hasKey)
                                Text(
                                  'API Key未配置',
                                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                                ),
                            ],
                          ),
                          trailing: isActive
                              ? Icon(Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary)
                              : null,
                          selected: isActive,
                          enabled: hasKey,
                          onTap: () {
                            modelProvider.setActiveChatModel(model.id);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已切换到 ${model.name}')),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 构建AI源切换器
  Widget _buildSourceSwitcher() {
    return PopupMenuButton<AISourceType>(
      icon: const Icon(Icons.swap_horiz),
      tooltip: '切换AI',
      onSelected: _switchSource,
      itemBuilder: (context) {
        return AISourceType.values.map((source) {
          final config = AISourceManager().getSourceConfig(source);
          return PopupMenuItem(
            value: source,
            child: Row(
              children: [
                Text(config.icon),
                const SizedBox(width: 8),
                Text('${config.name} (${config.type})'),
                if (source == _currentSource)
                  const Icon(Icons.check, size: 16),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  /// 构建AI源指示器
  Widget _buildSourceIndicator() {
    final config = AISourceManager().getSourceConfig(_currentSource);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: config.color.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: config.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${config.name} ${config.type}',
            style: TextStyle(
              color: config.color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (_isWebViewMode)
            const Text('网页版 - 登录后即可使用', style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  /// 构建WebView（网页版AI）
  Widget _buildWebView() {
    return WebViewWidget(controller: _webViewController!);
  }

  /// 构建聊天列表（API模式）
  Widget _buildChatList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('开始新对话', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }
    
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  /// 构建消息气泡
  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.role == 'user';
    final isError = message.isError;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isError
            ? Colors.red[100]
            : isUser
              ? Theme.of(context).primaryColor
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDateTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: isUser ? Colors.white70 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: '输入消息...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _isLoading ? null : _sendMessage,
              icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示历史记录对话框
  void _showHistoryDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('历史记录'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: FutureBuilder<List<ChatSession>>(
            future: _db.getAllSessions(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('暂无历史记录'));
              }
              
              final sessions = snapshot.data!;
              return ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final source = AISourceType.fromCode(session.aiSource);
                  final config = AISourceManager().getSourceConfig(source);
                  
                  return ListTile(
                    leading: Text(config.icon),
                    title: Text(session.title),
                    subtitle: Text('${config.name} · ${_formatDateTime(session.updatedAt)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: () async {
                        await _db.deleteSession(session.id);
                        if (mounted) {
                          setState(() {});
                          Navigator.pop(context);
                          _showHistoryDialog();
                        }
                      },
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _loadSession(session.id);
                    },
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
