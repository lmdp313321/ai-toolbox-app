import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/model_provider.dart';
import '../../providers/api_provider.dart';

/// 模型管理页面
class ModelManagePage extends StatefulWidget {
  const ModelManagePage({super.key});

  @override
  State<ModelManagePage> createState() => _ModelManagePageState();
}

class _ModelManagePageState extends State<ModelManagePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模型管理'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.chat), text: '对话模型'),
            Tab(icon: Icon(Icons.image), text: '绘画模型'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddModelDialog(),
            tooltip: '添加模型',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'preset') {
                _showAddPresetDialog();
              } else if (value == 'reset') {
                _showResetConfirm();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'preset',
                child: Row(
                  children: [
                    Icon(Icons.library_add),
                    SizedBox(width: 8),
                    Text('添加预设模型'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore),
                    SizedBox(width: 8),
                    Text('重置为默认'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildModelList(ModelType.chat),
          _buildModelList(ModelType.image),
        ],
      ),
    );
  }
  
  Widget _buildModelList(ModelType type) {
    return Consumer2<ModelProvider, ApiProvider>(
      builder: (context, modelProvider, apiProvider, child) {
        final models = type == ModelType.chat 
            ? modelProvider.chatModels 
            : modelProvider.imageModels;
        
        final activeId = type == ModelType.chat
            ? modelProvider.activeChatModelId
            : modelProvider.activeImageModelId;
        
        if (models.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.extension_off, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('暂无${type == ModelType.chat ? "对话" : "绘画"}模型', 
                  style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _showAddPresetDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('添加预设模型'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: models.length,
          itemBuilder: (context, index) {
            final model = models[index];
            final isActive = model.id == activeId;
            final apiConfig = apiProvider.configs
                .firstWhere((c) => c.id == model.apiSourceId, 
                  orElse: () => ApiConfig(id: '', name: '未知'));
            
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              color: isActive ? Theme.of(context).colorScheme.primaryContainer : null,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive 
                      ? Theme.of(context).colorScheme.primary 
                      : Colors.grey[300],
                  child: Icon(
                    type == ModelType.chat ? Icons.chat : Icons.image,
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
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '当前使用',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isActive)
                      IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: () => _setActiveModel(type, model.id),
                        tooltip: '设为默认',
                      ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showEditModelDialog(model);
                        } else if (value == 'delete') {
                          _showDeleteConfirm(model);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('编辑'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              const Icon(Icons.delete, color: Colors.red),
                              const SizedBox(width: 8),
                              Text('删除', style: TextStyle(color: Colors.red[700])),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () => _setActiveModel(type, model.id),
              ),
            );
          },
        );
      },
    );
  }
  
  void _setActiveModel(ModelType type, String id) {
    final provider = context.read<ModelProvider>();
    if (type == ModelType.chat) {
      provider.setActiveChatModel(id);
    } else {
      provider.setActiveImageModel(id);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已切换默认模型')),
    );
  }
  
  void _showAddModelDialog() {
    final type = _tabController.index == 0 ? ModelType.chat : ModelType.image;
    final nameController = TextEditingController();
    final modelIdController = TextEditingController();
    String selectedApiSource = 'siliconflow';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加${type == ModelType.chat ? "对话" : "绘画"}模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  hintText: '如: Qwen2.5-72B',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelIdController,
                decoration: InputDecoration(
                  labelText: '模型ID',
                  hintText: type == ModelType.chat 
                      ? '如: Qwen/Qwen2.5-72B-Instruct'
                      : '如: black-forest-labs/FLUX.1-schnell',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<ApiProvider>(
                builder: (context, apiProvider, child) {
                  return DropdownButtonFormField<String>(
                    value: selectedApiSource,
                    decoration: const InputDecoration(
                      labelText: 'API源',
                      border: OutlineInputBorder(),
                    ),
                    items: apiProvider.configs
                        .where((c) => c.enabled)
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => selectedApiSource = v!,
                  );
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.isEmpty || modelIdController.text.isEmpty) {
                return;
              }
              
              final provider = context.read<ModelProvider>();
              provider.addModel(ModelConfig(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                modelId: modelIdController.text,
                apiSourceId: selectedApiSource,
                type: type,
                sort: provider.models.length,
              ));
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('模型添加成功')),
              );
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  void _showEditModelDialog(ModelConfig model) {
    final nameController = TextEditingController(text: model.name);
    final modelIdController = TextEditingController(text: model.modelId);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('编辑模型'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '显示名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: modelIdController,
                decoration: const InputDecoration(
                  labelText: '模型ID',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<ModelProvider>();
              provider.updateModel(model.copyWith(
                name: nameController.text,
                modelId: modelIdController.text,
              ));
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showAddPresetDialog() {
    final type = _tabController.index == 0 ? ModelType.chat : ModelType.image;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('添加预设${type == ModelType.chat ? "对话" : "绘画"}模型'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildPresetSection('硅基流动', 'siliconflow', type),
              _buildPresetSection('英伟达', 'nvidia', type),
              if (type == ModelType.chat)
                _buildPresetSection('DeepSeek', 'deepseek', type),
            ],
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
  
  Widget _buildPresetSection(String title, String apiSourceId, ModelType type) {
    final presets = ModelPresets.getModelsForSource(apiSourceId, type);
    if (presets.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleSmall),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presets.entries.map((entry) {
            return ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: Text(entry.value),
              onPressed: () {
                final provider = context.read<ModelProvider>();
                provider.addPresetModels(apiSourceId, type, [entry.key]);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('已添加 ${entry.value}')),
                );
              },
            );
          }).toList(),
        ),
        const Divider(),
      ],
    );
  }
  
  void _showDeleteConfirm(ModelConfig model) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除模型 "${model.name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<ModelProvider>();
              provider.deleteModel(model.id);
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
  
  void _showResetConfirm() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置确认'),
        content: const Text('确定要重置为默认模型配置吗？自定义的模型将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final provider = context.read<ModelProvider>();
              provider.resetToDefault();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已重置为默认配置')),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('重置'),
          ),
        ],
      ),
    );
  }
}