import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// API配置模型
class ApiConfig {
  final String id;
  final String name;
  String apiKey;
  String baseUrl;
  String model;
  bool enabled;
  int sort;
  
  ApiConfig({
    required this.id,
    required this.name,
    this.apiKey = '',
    this.baseUrl = '',
    this.model = '',
    this.enabled = true,
    this.sort = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
    'enabled': enabled,
    'sort': sort,
  };
  
  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
    id: json['id'],
    name: json['name'],
    apiKey: json['apiKey'] ?? '',
    baseUrl: json['baseUrl'] ?? '',
    model: json['model'] ?? '',
    enabled: json['enabled'] ?? true,
    sort: json['sort'] ?? 0,
  );
}

/// API Provider - 管理所有API配置
class ApiProvider extends ChangeNotifier {
  static const String _apiConfigsKey = 'api_configs';
  static const String _activeApiKey = 'active_api';
  
  List<ApiConfig> _configs = [];
  String _activeApiId = '';
  
  List<ApiConfig> get configs => _configs;
  String get activeApiId => _activeApiId;
  
  ApiConfig? get activeConfig {
    try {
      return _configs.firstWhere((c) => c.id == _activeApiId && c.enabled);
    } catch (e) {
      return _configs.isNotEmpty ? _configs.first : null;
    }
  }
  
  /// 检查当前激活的API配置是否有效
  bool get hasValidConfig {
    final config = activeConfig;
    return config != null && 
           config.apiKey.isNotEmpty && 
           config.baseUrl.isNotEmpty;
  }
  
  ApiProvider() {
    _loadConfigs();
  }
  
  Future<void> _loadConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载保存的配置
    final configsJson = prefs.getString(_apiConfigsKey);
    if (configsJson != null) {
      final List<dynamic> list = jsonDecode(configsJson);
      _configs = list.map((e) => ApiConfig.fromJson(e)).toList();
    } else {
      // 默认配置
      _configs = _getDefaultConfigs();
    }
    
    // 加载激活的API
    _activeApiId = prefs.getString(_activeApiKey) ?? '';
    
    notifyListeners();
  }
  
  List<ApiConfig> _getDefaultConfigs() {
    return [
      ApiConfig(
        id: 'siliconflow',
        name: '硅基流动',
        baseUrl: 'https://api.siliconflow.cn/v1',
        model: 'Qwen/Qwen2.5-72B-Instruct',
        sort: 0,
      ),
      ApiConfig(
        id: 'nvidia',
        name: '英伟达 NIM',
        baseUrl: 'https://integrate.api.nvidia.com/v1',
        model: 'meta/llama-3.1-405b-instruct',
        sort: 1,
      ),
      ApiConfig(
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        model: 'deepseek-chat',
        sort: 2,
      ),
      ApiConfig(
        id: 'openai',
        name: 'OpenAI',
        baseUrl: 'https://api.openai.com/v1',
        model: 'gpt-4o-mini',
        sort: 3,
      ),
      ApiConfig(
        id: 'claude',
        name: 'Claude',
        baseUrl: 'https://api.anthropic.com/v1',
        model: 'claude-3-5-sonnet-20241022',
        sort: 4,
      ),
    ];
  }
  
  Future<void> saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiConfigsKey, jsonEncode(_configs.map((e) => e.toJson()).toList()));
    await prefs.setString(_activeApiKey, _activeApiId);
  }
  
  void updateConfig(ApiConfig config) {
    final index = _configs.indexWhere((c) => c.id == config.id);
    if (index >= 0) {
      _configs[index] = config;
    } else {
      _configs.add(config);
    }
    saveConfigs();
    notifyListeners();
  }
  
  void setActiveApi(String apiId) {
    _activeApiId = apiId;
    saveConfigs();
    notifyListeners();
  }
  
  void addCustomApi(ApiConfig config) {
    _configs.add(config);
    saveConfigs();
    notifyListeners();
  }
  
  void removeApi(String apiId) {
    _configs.removeWhere((c) => c.id == apiId);
    if (_activeApiId == apiId && _configs.isNotEmpty) {
      _activeApiId = _configs.first.id;
    }
    saveConfigs();
    notifyListeners();
  }
}
