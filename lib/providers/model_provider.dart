import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// 模型类型
enum ModelType {
  chat,      // 对话模型
  image,     // 绘画模型
  embedding, // 嵌入模型
}

/// 模型配置
class ModelConfig {
  String id;
  String name;           // 显示名称（用户自定义）
  String modelId;        // 实际模型ID（如 Qwen/Qwen2.5-72B-Instruct）
  String apiSourceId;    // 所属API源（siliconflow/nvidia等）
  ModelType type;        // 模型类型
  bool enabled;
  int sort;
  
  ModelConfig({
    required this.id,
    required this.name,
    required this.modelId,
    required this.apiSourceId,
    required this.type,
    this.enabled = true,
    this.sort = 0,
  });
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'modelId': modelId,
    'apiSourceId': apiSourceId,
    'type': type.name,
    'enabled': enabled,
    'sort': sort,
  };
  
  factory ModelConfig.fromJson(Map<String, dynamic> json) => ModelConfig(
    id: json['id'],
    name: json['name'],
    modelId: json['modelId'],
    apiSourceId: json['apiSourceId'],
    type: ModelType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => ModelType.chat,
    ),
    enabled: json['enabled'] ?? true,
    sort: json['sort'] ?? 0,
  );
  
  ModelConfig copyWith({
    String? id,
    String? name,
    String? modelId,
    String? apiSourceId,
    ModelType? type,
    bool? enabled,
    int? sort,
  }) {
    return ModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      modelId: modelId ?? this.modelId,
      apiSourceId: apiSourceId ?? this.apiSourceId,
      type: type ?? this.type,
      enabled: enabled ?? this.enabled,
      sort: sort ?? this.sort,
    );
  }
}

/// 预设模型库
class ModelPresets {
  /// 硅基流动 - 对话模型
  static const Map<String, String> siliconChatModels = {
    'Qwen/Qwen2.5-72B-Instruct': 'Qwen2.5-72B',
    'Qwen/Qwen2.5-32B-Instruct': 'Qwen2.5-32B',
    'Qwen/Qwen2.5-14B-Instruct': 'Qwen2.5-14B',
    'Qwen/Qwen2.5-7B-Instruct': 'Qwen2.5-7B',
    'deepseek-ai/DeepSeek-V3': 'DeepSeek-V3',
    'deepseek-ai/DeepSeek-R1': 'DeepSeek-R1',
    'THUDM/glm-4-9b-chat': 'GLM-4-9B',
    '01-ai/Yi-1.5-34B-Chat-16K': 'Yi-1.5-34B',
    'meta-llama/Llama-3.3-70B-Instruct': 'Llama-3.3-70B',
  };
  
  /// 硅基流动 - 绘画模型
  static const Map<String, String> siliconImageModels = {
    'Qwen/Qwen2.5-VL': 'Qwen-Image',
    'Qwen/Qwen2.5-VL-Instruct': 'Qwen-Image-Edit',
    'kwaivgi/kolors': 'Kolors',
    'black-forest-labs/FLUX.1-schnell': 'FLUX.1-schnell',
    'black-forest-labs/FLUX.1-dev': 'FLUX.1-dev',
    'stabilityai/stable-diffusion-3-5-large': 'SD-3.5-Large',
    'stabilityai/stable-diffusion-3-medium': 'SD-3-Medium',
    'stabilityai/stable-diffusion-xl-base-1.0': 'SD-XL',
  };
  
  /// 英伟达 - 对话模型
  static const Map<String, String> nvidiaChatModels = {
    'meta/llama-3.1-405b-instruct': 'Llama-3.1-405B',
    'meta/llama-3.1-70b-instruct': 'Llama-3.1-70B',
    'meta/llama-3.1-8b-instruct': 'Llama-3.1-8B',
    'mistralai/mistral-large': 'Mistral-Large',
    'nvidia/nemotron-4-340b-instruct': 'Nemotron-4-340B',
  };
  
  /// 英伟达 - 绘画模型
  static const Map<String, String> nvidiaImageModels = {
    'stabilityai/stable-diffusion-xl': 'SD-XL-NVIDIA',
  };
  
  /// DeepSeek
  static const Map<String, String> deepseekModels = {
    'deepseek-chat': 'DeepSeek-V3',
    'deepseek-reasoner': 'DeepSeek-R1',
  };
  
  /// 获取某API源的所有预设模型
  static Map<String, String> getModelsForSource(String apiSourceId, ModelType type) {
    switch (apiSourceId) {
      case 'siliconflow':
        return type == ModelType.image ? siliconImageModels : siliconChatModels;
      case 'nvidia':
        return type == ModelType.image ? nvidiaImageModels : nvidiaChatModels;
      case 'deepseek':
        return deepseekModels;
      default:
        return {};
    }
  }
}

/// 模型管理Provider
class ModelProvider extends ChangeNotifier {
  static const String _modelsKey = 'model_configs';
  static const String _activeChatModelKey = 'active_chat_model';
  static const String _activeImageModelKey = 'active_image_model';
  
  List<ModelConfig> _models = [];
  String _activeChatModelId = '';
  String _activeImageModelId = '';
  
  List<ModelConfig> get models => _models;
  String get activeChatModelId => _activeChatModelId;
  String get activeImageModelId => _activeImageModelId;
  
  /// 获取所有启用的对话模型
  List<ModelConfig> get chatModels => _models
      .where((m) => m.type == ModelType.chat && m.enabled)
      .toList()
    ..sort((a, b) => a.sort.compareTo(b.sort));
  
  /// 获取所有启用的绘画模型
  List<ModelConfig> get imageModels => _models
      .where((m) => m.type == ModelType.image && m.enabled)
      .toList()
    ..sort((a, b) => a.sort.compareTo(b.sort));
  
  /// 获取当前激活的对话模型
  ModelConfig? get activeChatModel {
    try {
      return _models.firstWhere(
        (m) => m.id == _activeChatModelId && m.enabled,
      );
    } catch (e) {
      return chatModels.isNotEmpty ? chatModels.first : null;
    }
  }
  
  /// 获取当前激活的绘画模型
  ModelConfig? get activeImageModel {
    try {
      return _models.firstWhere(
        (m) => m.id == _activeImageModelId && m.enabled,
      );
    } catch (e) {
      return imageModels.isNotEmpty ? imageModels.first : null;
    }
  }
  
  /// 获取某API源的所有模型
  List<ModelConfig> getModelsForSource(String apiSourceId, {ModelType? type}) {
    var list = _models.where((m) => m.apiSourceId == apiSourceId);
    if (type != null) {
      list = list.where((m) => m.type == type);
    }
    return list.toList()..sort((a, b) => a.sort.compareTo(b.sort));
  }
  
  ModelProvider() {
    _loadModels();
  }
  
  Future<void> _loadModels() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 加载模型配置
    final modelsJson = prefs.getString(_modelsKey);
    if (modelsJson != null) {
      final List<dynamic> list = jsonDecode(modelsJson);
      _models = list.map((e) => ModelConfig.fromJson(e)).toList();
    } else {
      // 默认配置
      _models = _getDefaultModels();
    }
    
    // 加载激活的模型
    _activeChatModelId = prefs.getString(_activeChatModelKey) ?? '';
    _activeImageModelId = prefs.getString(_activeImageModelKey) ?? '';
    
    notifyListeners();
  }
  
  List<ModelConfig> _getDefaultModels() {
    return [
      // 硅基流动 - 对话
      ModelConfig(
        id: 'sf_qwen72b',
        name: 'Qwen2.5-72B',
        modelId: 'Qwen/Qwen2.5-72B-Instruct',
        apiSourceId: 'siliconflow',
        type: ModelType.chat,
        sort: 0,
      ),
      ModelConfig(
        id: 'sf_deepseek_v3',
        name: 'DeepSeek-V3',
        modelId: 'deepseek-ai/DeepSeek-V3',
        apiSourceId: 'siliconflow',
        type: ModelType.chat,
        sort: 1,
      ),
      // 硅基流动 - 绘画
      ModelConfig(
        id: 'sf_flux_schnell',
        name: 'FLUX.1-schnell',
        modelId: 'black-forest-labs/FLUX.1-schnell',
        apiSourceId: 'siliconflow',
        type: ModelType.image,
        sort: 0,
      ),
      ModelConfig(
        id: 'sf_sd35',
        name: 'SD-3.5-Large',
        modelId: 'stabilityai/stable-diffusion-3-5-large',
        apiSourceId: 'siliconflow',
        type: ModelType.image,
        sort: 1,
      ),
      // 英伟达 - 对话
      ModelConfig(
        id: 'nv_llama405b',
        name: 'Llama-3.1-405B',
        modelId: 'meta/llama-3.1-405b-instruct',
        apiSourceId: 'nvidia',
        type: ModelType.chat,
        sort: 2,
      ),
      // DeepSeek
      ModelConfig(
        id: 'ds_v3',
        name: 'DeepSeek-V3',
        modelId: 'deepseek-chat',
        apiSourceId: 'deepseek',
        type: ModelType.chat,
        sort: 3,
      ),
    ];
  }
  
  /// 保存到本地
  Future<void> _saveModels() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modelsKey, jsonEncode(_models.map((e) => e.toJson()).toList()));
  }
  
  /// 添加模型
  Future<void> addModel(ModelConfig model) async {
    _models.add(model);
    await _saveModels();
    notifyListeners();
  }
  
  /// 更新模型
  Future<void> updateModel(ModelConfig model) async {
    final index = _models.indexWhere((m) => m.id == model.id);
    if (index != -1) {
      _models[index] = model;
      await _saveModels();
      notifyListeners();
    }
  }
  
  /// 删除模型
  Future<void> deleteModel(String id) async {
    _models.removeWhere((m) => m.id == id);
    await _saveModels();
    notifyListeners();
  }
  
  /// 设置激活的对话模型
  Future<void> setActiveChatModel(String id) async {
    _activeChatModelId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeChatModelKey, id);
    notifyListeners();
  }
  
  /// 设置激活的绘画模型
  Future<void> setActiveImageModel(String id) async {
    _activeImageModelId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_activeImageModelKey, id);
    notifyListeners();
  }
  
  /// 批量添加预设模型
  Future<void> addPresetModels(String apiSourceId, ModelType type, List<String> modelIds) async {
    final presets = ModelPresets.getModelsForSource(apiSourceId, type);
    final existingModelIds = _models
        .where((m) => m.apiSourceId == apiSourceId && m.type == type)
        .map((m) => m.modelId)
        .toSet();
    
    int sort = _models.where((m) => m.type == type).length;
    
    for (final modelId in modelIds) {
      if (existingModelIds.contains(modelId)) continue;
      
      final name = presets[modelId] ?? modelId.split('/').last;
      _models.add(ModelConfig(
        id: '${apiSourceId}_${type.name}_${DateTime.now().millisecondsSinceEpoch}_$sort',
        name: name,
        modelId: modelId,
        apiSourceId: apiSourceId,
        type: type,
        sort: sort++,
      ));
    }
    
    await _saveModels();
    notifyListeners();
  }
  
  /// 重置为默认
  Future<void> resetToDefault() async {
    _models = _getDefaultModels();
    await _saveModels();
    notifyListeners();
  }
}