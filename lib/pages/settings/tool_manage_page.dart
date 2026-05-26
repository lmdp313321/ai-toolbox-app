import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tool_provider.dart';
import '../../core/config/tool_config.dart';

class ToolManagePage extends StatelessWidget {
  const ToolManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    final toolProvider = Provider.of<ToolProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('工具管理'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: toolProvider.allCategories.length,
        itemBuilder: (context, index) {
          final category = toolProvider.allCategories[index];
          final tools = toolProvider.allTools
              .where((t) => t['categoryId'] == category['id'])
              .toList();
          
          return ExpansionTile(
            leading: Text(category['icon'] as String, style: const TextStyle(fontSize: 24)),
            title: Text(category['name'] as String),
            subtitle: Text('${tools.where((t) => toolProvider.isToolVisible(t['id'] as String)).length}/${tools.length} 个工具可见'),
            children: tools.map((tool) {
              final isVisible = toolProvider.isToolVisible(tool['id'] as String);
              
              return SwitchListTile(
                secondary: Text(tool['icon'] as String, style: const TextStyle(fontSize: 20)),
                title: Text(tool['name'] as String),
                subtitle: Text(tool['description'] as String),
                value: isVisible,
                onChanged: (value) {
                  toolProvider.toggleToolVisibility(tool['id'] as String);
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
