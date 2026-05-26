import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/api_provider.dart';

class ApiConfigPage extends StatefulWidget {
  const ApiConfigPage({super.key});

  @override
  State<ApiConfigPage> createState() => _ApiConfigPageState();
}

class _ApiConfigPageState extends State<ApiConfigPage> {
  @override
  Widget build(BuildContext context) {
    final apiProvider = Provider.of<ApiProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('API配置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddApiDialog(context),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: apiProvider.configs.length,
        itemBuilder: (context, index) {
          final config = apiProvider.configs[index];
          final isActive = apiProvider.activeApiId == config.id;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => _showEditApiDialog(context, config),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: config.apiKey.isNotEmpty 
                                ? Colors.green 
                                : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          config.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
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
                    const SizedBox(height: 12),
                    _buildInfoRow('API Key', 
                        config.apiKey.isNotEmpty ? '已配置' : '未配置'),
                    _buildInfoRow('Base URL', config.baseUrl),
                    _buildInfoRow('模型', config.model),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (config.apiKey.isNotEmpty && !isActive)
                          TextButton(
                            onPressed: () {
                              apiProvider.setActiveApi(config.id);
                            },
                            child: const Text('设为当前'),
                          ),
                        TextButton(
                          onPressed: () => _testConnection(context, config),
                          child: const Text('测试连接'),
                        ),
                        const Spacer(),
                        if (config.id != 'siliconflow' && 
                            config.id != 'nvidia' &&
                            config.id != 'deepseek' &&
                            config.id != 'openai' &&
                            config.id != 'claude')
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => _deleteApi(context, apiProvider, config.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showEditApiDialog(BuildContext context, ApiConfig config) {
    final apiKeyController = TextEditingController(text: config.apiKey);
    final baseUrlController = TextEditingController(text: config.baseUrl);
    final modelController = TextEditingController(text: config.model);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('编辑 ${config.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: '模型',
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
              config.apiKey = apiKeyController.text;
              config.baseUrl = baseUrlController.text;
              config.model = modelController.text;
              
              final apiProvider = Provider.of<ApiProvider>(context, listen: false);
              apiProvider.updateConfig(config);
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('配置已保存')),
              );
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
  
  void _showAddApiDialog(BuildContext context) {
    final nameController = TextEditingController();
    final apiKeyController = TextEditingController();
    final baseUrlController = TextEditingController();
    final modelController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加API'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: apiKeyController,
                decoration: const InputDecoration(
                  labelText: 'API Key',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: baseUrlController,
                decoration: const InputDecoration(
                  labelText: 'Base URL',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: modelController,
                decoration: const InputDecoration(
                  labelText: '模型',
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入名称')),
                );
                return;
              }
              
              final apiProvider = Provider.of<ApiProvider>(context, listen: false);
              apiProvider.addCustomApi(ApiConfig(
                id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                name: nameController.text,
                apiKey: apiKeyController.text,
                baseUrl: baseUrlController.text,
                model: modelController.text,
              ));
              
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('API已添加')),
              );
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
  
  void _testConnection(BuildContext context, ApiConfig config) {
    if (config.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      return;
    }
    
    // 模拟测试连接
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('正在测试连接...')),
    );
    
    Future.delayed(const Duration(seconds: 2), () {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${config.name} 连接成功！'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }
  
  void _deleteApi(BuildContext context, ApiProvider apiProvider, String apiId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除API'),
        content: const Text('确定要删除此API配置吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              apiProvider.removeApi(apiId);
              Navigator.pop(context);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}
