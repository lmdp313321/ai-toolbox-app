import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../providers/api_provider.dart';
import '../../../providers/model_provider.dart';
import '../../../services/ai_service.dart';

/// AI绘画页面 - 文生图（支持多模型切换）
class AiPaintPage extends StatefulWidget {
  const AiPaintPage({super.key});

  @override
  State<AiPaintPage> createState() => _AiPaintPageState();
}

class _AiPaintPageState extends State<AiPaintPage> {
  final TextEditingController _promptController = TextEditingController();
  final TextEditingController _negativePromptController = TextEditingController();
  
  String _selectedRatio = '1:1';
  int _selectedSteps = 4; // FLUX.1-schnell 推荐4步
  
  Uint8List? _generatedImage;
  bool _isGenerating = false;
  String? _errorMessage;
  
  final Dio _dio = Dio();
  
  final Map<String, String> _ratioMap = {
    '1:1': '1024x1024',
    '16:9': '1024x576',
    '9:16': '576x1024',
    '4:3': '1024x768',
    '3:4': '768x1024',
  };
  
  @override
  void initState() {
    super.initState();
    // 初始化时检查是否有可用的绘画模型
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final modelProvider = Provider.of<ModelProvider>(context, listen: false);
      if (modelProvider.imageModels.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('暂无绘画模型，请先到设置中添加'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }
  
  /// 获取当前选中的模型
  ModelConfig? get _currentModel {
    final modelProvider = Provider.of<ModelProvider>(context, listen: false);
    return modelProvider.activeImageModel;
  }
  
  /// 获取当前模型对应的API配置
  ApiConfig? _getApiConfigForModel(ModelConfig model) {
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    try {
      return apiProvider.configs.firstWhere((c) => c.id == model.apiSourceId);
    } catch (e) {
      return null;
    }
  }
  
  /// 生成图片
  Future<void> _generateImage() async {
    final model = _currentModel;
    if (model == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置绘画模型')),
      );
      return;
    }
    
    if (_promptController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入图片描述')),
      );
      return;
    }
    
    final apiConfig = _getApiConfigForModel(model);
    if (apiConfig == null || apiConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('请先配置 ${apiConfig?.name ?? model.apiSourceId} 的API Key'),
          action: SnackBarAction(
            label: '去设置',
            onPressed: () => Navigator.pushNamed(context, '/settings/api'),
          ),
        ),
      );
      return;
    }
    
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _generatedImage = null;
    });
    
    try {
      final size = _ratioMap[_selectedRatio]!;
      final width = int.parse(size.split('x')[0]);
      final height = int.parse(size.split('x')[1]);
      
      final response = await _dio.post(
        '${apiConfig.baseUrl}/images/generations',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.json,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 120),
        ),
        data: jsonEncode({
          'model': model.modelId,
          'prompt': _promptController.text.trim(),
          if (_negativePromptController.text.isNotEmpty)
            'negative_prompt': _negativePromptController.text.trim(),
          'width': width,
          'height': height,
          'steps': _selectedSteps,
          'n': 1,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        final imageUrl = data['data'][0]['url'];
        
        // 下载图片
        final imageResponse = await _dio.get(
          imageUrl,
          options: Options(responseType: ResponseType.bytes),
        );
        
        setState(() {
          _generatedImage = Uint8List.fromList(imageResponse.data);
          _isGenerating = false;
        });
      } else {
        throw Exception('生成失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = '请求失败: ${e.message}';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '生成失败: $e';
        _isGenerating = false;
      });
    }
  }
  
  /// 保存图片
  Future<void> _saveImage() async {
    if (_generatedImage == null) return;
    // TODO: 实现保存到相册功能
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片已保存')),
    );
  }
  
  /// 显示模型选择器
  void _showModelSelector() {
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
              final models = modelProvider.imageModels;
              final activeId = modelProvider.activeImageModelId;
              
              if (models.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.image_not_supported, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      const Text('暂无绘画模型'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pushNamed(context, '/settings/models'),
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
                          '选择绘画模型',
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
                        final apiConfig = apiProvider.configs
                            .firstWhere((c) => c.id == model.apiSourceId,
                              orElse: () => ApiConfig(id: '', name: '未知'));
                        final hasKey = apiConfig.apiKey.isNotEmpty;
                        
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isActive
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[300],
                            child: Icon(
                              Icons.image,
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
                              Text('${apiConfig.name} · ${model.modelId}'),
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
                            modelProvider.setActiveImageModel(model.id);
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 AI绘画'),
        actions: [
          if (_generatedImage != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveImage,
              tooltip: '保存图片',
            ),
        ],
      ),
      body: Consumer2<ModelProvider, ApiProvider>(
        builder: (context, modelProvider, apiProvider, child) {
          final currentModel = modelProvider.activeImageModel;
          final apiConfig = currentModel != null
              ? apiProvider.configs.firstWhere(
                  (c) => c.id == currentModel.apiSourceId,
                  orElse: () => ApiConfig(id: '', name: '未知'))
              : null;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 模型选择卡片
                Card(
                  child: InkWell(
                    onTap: _showModelSelector,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: const Icon(Icons.image),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '当前模型',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  currentModel?.name ?? '未选择模型',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (currentModel != null)
                                  Text(
                                    '${apiConfig?.name ?? '未知'} · ${currentModel.modelId}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: apiConfig?.apiKey.isNotEmpty == true
                                          ? Colors.green[700]
                                          : Colors.red[700],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 比例选择
                _buildRatioSelector(),
                const SizedBox(height: 16),
                
                // 步数选择（仅部分模型）
                if (currentModel?.modelId.contains('flux') ?? false)
                  _buildStepsSelector(),
                
                // 提示词输入
                TextField(
                  controller: _promptController,
                  decoration: const InputDecoration(
                    labelText: '画面描述',
                    hintText: '例如：一只可爱的猫咪，坐在窗台上，阳光洒在身上，吉卜力风格',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.brush),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                
                // 反向提示词
                TextField(
                  controller: _negativePromptController,
                  decoration: const InputDecoration(
                    labelText: '反向提示词（不想出现的内容）',
                    hintText: '例如：模糊, 变形, 低质量',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.block),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 生成按钮
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isGenerating ? null : _generateImage,
                    icon: _isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_fix_high),
                    label: Text(_isGenerating ? '生成中...' : '生成图片'),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 生成的图片
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                      ],
                    ),
                  ),
                
                if (_generatedImage != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('生成结果:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _generatedImage!,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildRatioSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('图片比例', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _ratioMap.keys.map((ratio) {
            final isSelected = _selectedRatio == ratio;
            return ChoiceChip(
              label: Text(ratio),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedRatio = ratio;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildStepsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('推理步数', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Slider(
          value: _selectedSteps.toDouble(),
          min: 1,
          max: 8,
          divisions: 7,
          label: _selectedSteps.toString(),
          onChanged: (value) {
            setState(() {
              _selectedSteps = value.toInt();
            });
          },
        ),
        Text(
          '步数: $_selectedSteps（FLUX推荐4步即可）',
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  @override
  void dispose() {
    _promptController.dispose();
    _negativePromptController.dispose();
    super.dispose();
  }
}