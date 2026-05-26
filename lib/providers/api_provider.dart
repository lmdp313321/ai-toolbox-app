import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// API配置模型（支持多模型）
class ApiConfig {
  final String id;
  final String name;
  String apiKey;
  String baseUrl;
  String model;
  List<String> models;  // 多个模型ID
  bool enabled;
  int sort;
  
  ApiConfig({
    required this.id,
    required this.name,
    this.apiKey = '',
    this.baseUrl = '',
    this.model = '',
    this.models = const [],
    this.enabled = true,
    this.sort = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
    'models': models,
    'enabled': enabled,
    'sort': sort,
  };
  
  factory ApiConfig.fromJson(Map<String, dynamic> json) => ApiConfig(
    id: json['id'],
    name: json['name'],
    apiKey: json['apiKey'] ?? '',
    baseUrl: json['baseUrl'] ?? '',
    model: json['model'] ?? '',
    models: (json['models'] as List?)?.cast<String>() ?? [],
    enabled: json['enabled'] ?? true,
    sort: json['sort'] ?? 0,
  );
  
  /// 切换模型
  String getNextModel() {
    if (models.isEmpty) return model;
    final idx = models.indexOf(model);
    return idx >= 0 && idx < models.length - 1 ? models[idx + 1] : models.first;
  }
}

/// API Provider - 管理所有API配置（自由添加+多模型+自动切换）
class ApiProvider extends ChangeNotifier {
  static const String _apiConfigsKey = 'api_configs';
  static const String _activeApiKey = 'active_api';
  static const String _activeModelKey = 'active_model';
  
  List<ApiConfig> _configs = [];
  String _activeApiId = '';
  String _activeModel = '';
  
  List<ApiConfig> get configs => _configs;
  String get activeApiId => _activeApiId;
  String get activeModel => _activeModel;
  
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
  
  /// 获取下一个可用API（自动切换用）
  ApiConfig? getNextAvailable() {
    if (_configs.isEmpty) return null;
    final currentIdx = _configs.indexWhere((c) => c.id == _activeApiId);
    for (int i = 1; i <= _configs.length; i++) {
      final next = _configs[(currentIdx + i) % _configs.length];
      if (next.enabled && next.apiKey.isNotEmpty) return next;
    }
    return null;
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
      // 首次使用：预填你的API Key
      _configs = _getDefaultConfigs();
      _saveConfigs();
    }
    
    // 加载激活的API和模型
    _activeApiId = prefs.getString(_activeApiKey) ?? '';
    _activeModel = prefs.getString(_activeModelKey) ?? '';
    
    notifyListeners();
  }
  
  /// 保存所有配置
  Future<void> _saveConfigs() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _configs.map((c) => c.toJson()).toList();
    await prefs.setString(_apiConfigsKey, jsonEncode(jsonList));
  }
  
  /// 切换激活的API
  Future<void> switchApi(String apiId) async {
    _activeApiId = apiId;
    final config = _configs.cast<ApiConfig?>().firstWhere(
      (c) => c?.id == apiId, orElse: () => null);
    if (config != null && config.models.isNotEmpty) {
      _activeModel = config.model;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeApiKey, apiId);
    if (_activeModel.isNotEmpty) {
      await prefs.setString(_activeModelKey, _activeModel);
    }
    notifyListeners();
  }
  
  /// 获取当前激活模型的完整名称
  String get activeModelName {
    if (_activeModel.isNotEmpty) return _activeModel;
    return activeConfig?.model ?? '';
  }
  
  /// 切换模型
  Future<void> switchModel(String modelId) async {
    _activeModel = modelId;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeModelKey, modelId);
    notifyListeners();
  }
  
  /// 添加API提供商
  Future<void> addApi(ApiConfig config) async {
    _configs.add(config);
    if (_configs.length == 1) {
      _activeApiId = config.id;
    }
    await _saveConfigs();
    notifyListeners();
  }
  
  /// 更新API配置
  Future<void> updateApi(String id, {
    String? name,
    String? apiKey,
    String? baseUrl,
    String? model,
    List<String>? models,
    bool? enabled,
  }) async {
    final idx = _configs.indexWhere((c) => c.id == id);
    if (idx < 0) return;
    final c = _configs[idx];
    // name是final，需要重建对象
    if (apiKey != null || baseUrl != null || model != null || models != null || enabled != null) {
      _configs[idx] = ApiConfig(
        id: c.id,
        name: name ?? c.name,
        apiKey: apiKey ?? c.apiKey,
        baseUrl: baseUrl ?? c.baseUrl,
        model: model ?? c.model,
        models: models ?? c.models,
        enabled: enabled ?? c.enabled,
        sort: c.sort,
      );
    }
    await _saveConfigs();
    notifyListeners();
  }
  
  /// 删除API配置
  Future<void> deleteApi(String id) async {
    _configs.removeWhere((c) => c.id == id);
    if (_activeApiId == id) {
      _activeApiId = _configs.isNotEmpty ? _configs.first.id : '';
    }
    await _saveConfigs();
    notifyListeners();
  }
  
  /// 添加模型到API提供商
  Future<void> addModel(String apiId, String modelId) async {
    final idx = _configs.indexWhere((c) => c.id == apiId);
    if (idx < 0) return;
    final c = _configs[idx];
    final newModels = List<String>.from(c.models)..add(modelId);
    _configs[idx] = ApiConfig(
      id: c.id, name: c.name,
      apiKey: c.apiKey, baseUrl: c.baseUrl,
      model: c.model, models: newModels,
      enabled: c.enabled, sort: c.sort,
    );
    await _saveConfigs();
    notifyListeners();
  }
  
  /// 删除模型
  Future<void> removeModel(String apiId, String modelId) async {
    final idx = _configs.indexWhere((c) => c.id == apiId);
    if (idx < 0) return;
    final c = _configs[idx];
    final newModels = List<String>.from(c.models)..remove(modelId);
    _configs[idx] = ApiConfig(
      id: c.id, name: c.name,
      apiKey: c.apiKey, baseUrl: c.baseUrl,
      model: c.model, models: newModels,
      enabled: c.enabled, sort: c.sort,
    );
    await _saveConfigs();
    notifyListeners();
  }
  
  /// 获取默认API配置（预填你的API Key）
  List<ApiConfig> _getDefaultConfigs() {
    return [
      ApiConfig(
        id: 'deepseek',
        name: 'DeepSeek',
        baseUrl: 'https://api.deepseek.com/v1',
        apiKey: 'YOUR_DEEPSEEK_API_KEY',
        model: 'deepseek-chat',
        models: ['deepseek-chat', 'deepseek-reasoner'],
        sort: 0,
      ),
      ApiConfig(
        id: 'siliconflow',
        name: '硅基流动',
        baseUrl: 'https://api.siliconflow.cn/v1',
        apiKey: 'YOUR_SILICONFLOW_API_KEY',
        model: 'Qwen/Qwen2.5-72B-Instruct',
        models: ['Qwen/Qwen2.5-72B-Instruct', 'deepseek-ai/DeepSeek-V3'],
        sort: 1,
      ),
      ApiConfig(
        id: 'kimi',
        name: '月之Kimi',
        baseUrl: 'https://api.moonshot.cn/v1',
        apiKey: 'YOUR_KIMI_API_KEY',
        model: 'kimi-k2.5',
        models: ['kimi-k2.5', 'moonshot-v1-8k', 'moonshot-v1-32k'],
        sort: 2,
      ),
      ApiConfig(
        id: 'openrouter',
        name: 'OpenRouter',
        baseUrl: 'https://openrouter.ai/api/v1',
        apiKey: 'YOUR_OPENROUTER_API_KEY',
        model: 'openai/gpt-4o-mini',
        models: ['openai/gpt-4o-mini', 'anthropic/claude-3.5-haiku'],
        sort: 3,
      ),
      ApiConfig(
        id: 'baidu_ocr',
        name: '百度OCR',
        baseUrl: 'https://aip.baidubce.com',
        apiKey: 'YOUR_BAIDU_OCR_API_KEY',
        model: 'accurate',
        sort: 4,
      ),
      ApiConfig(
        id: 'tencent_ocr',
        name: '腾讯云OCR',
        baseUrl: 'https://ocr.tencentcloudapi.com',
        apiKey: 'YOUR_TENCENT_OCR_API_SECRET_ID',
        model: 'GeneralBasicOCR',
        sort: 5,
      ),
      ApiConfig(
        id: 'nvidia',
        name: '英伟达 NIM',
        baseUrl: 'https://integrate.api.nvidia.com/v1',
        apiKey: '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',
        model: 'meta/llama-3.1-405b-instruct',
        sort: 6,
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
