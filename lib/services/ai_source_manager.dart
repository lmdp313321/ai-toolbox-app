import 'package:flutter/material.dart';
import '../models/chat_models.dart';
import '../providers/api_provider.dart';
import 'ai_service.dart';

/// AI源管理器 - 统一管理4个AI源
class AISourceManager {
  static final AISourceManager _instance = AISourceManager._internal();
  factory AISourceManager() => _instance;
  AISourceManager._internal();

  /// 获取所有可用的AI源
  List<AISourceType> get availableSources => AISourceType.values;

  /// 获取AI源配置
  AISourceConfig getSourceConfig(AISourceType source) {
    switch (source) {
      case AISourceType.deepseekWeb:
        return AISourceConfig(
          name: 'DeepSeek',
          type: '网页版',
          url: 'https://chat.deepseek.com',
          icon: '🐋',
          color: Colors.blue,
        );
      case AISourceType.doubaoWeb:
        return AISourceConfig(
          name: '豆包',
          type: '网页版',
          url: 'https://www.doubao.com/chat',
          icon: '🟢',
          color: Colors.green,
        );
      case AISourceType.siliconApi:
        return AISourceConfig(
          name: '硅基流动',
          type: 'API',
          url: 'https://api.siliconflow.cn',
          icon: '⚡',
          color: Colors.orange,
        );
      case AISourceType.nvidiaApi:
        return AISourceConfig(
          name: '英伟达',
          type: 'API',
          url: 'https://integrate.api.nvidia.com',
          icon: '🔷',
          color: Colors.teal,
        );
    }
  }

  /// 判断是否使用WebView
  bool isWebView(AISourceType source) {
    return source.isWebView;
  }

  /// 判断是否使用API
  bool isApi(AISourceType source) {
    return !source.isWebView;
  }

  /// 获取网页版AI的URL
  String getWebUrl(AISourceType source) {
    switch (source) {
      case AISourceType.deepseekWeb:
        return 'https://chat.deepseek.com';
      case AISourceType.doubaoWeb:
        return 'https://www.doubao.com/chat';
      default:
        throw Exception('${source.name} 不是网页版AI');
    }
  }

  /// 发送API消息（硅基流动/英伟达）
  Future<String> sendApiMessage({
    required AISourceType source,
    required List<Map<String, dynamic>> messages,
    required ApiConfig config,
  }) async {
    if (isWebView(source)) {
      throw Exception('${source.name} 是网页版，请使用WebView');
    }

    return await AiService.chat(
      messages: messages,
      config: config,
    );
  }

  /// 流式发送API消息
  Stream<String> sendApiMessageStream({
    required AISourceType source,
    required List<Map<String, dynamic>> messages,
    required ApiConfig config,
  }) async* {
    if (isWebView(source)) {
      throw Exception('${source.name} 是网页版，请使用WebView');
    }

    await for (final chunk in AiService.chatStream(
      messages: messages,
      config: config,
    )) {
      yield chunk;
    }
  }
}

/// AI源配置
class AISourceConfig {
  final String name;
  final String type;
  final String url;
  final String icon;
  final Color color;

  AISourceConfig({
    required this.name,
    required this.type,
    required this.url,
    required this.icon,
    required this.color,
  });
}
