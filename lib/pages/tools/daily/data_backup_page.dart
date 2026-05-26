import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/storage/app_database.dart';

/// 数据备份页面 - 导出/导入应用数据
class DataBackupPage extends StatefulWidget {
  const DataBackupPage({super.key});

  @override
  State<DataBackupPage> createState() => _DataBackupPageState();
}

class _DataBackupPageState extends State<DataBackupPage> {
  bool _isExporting = false;
  bool _isImporting = false;
  Map<String, int>? _dataStats;

  @override
  void initState() {
    super.initState();
    _loadDataStats();
  }

  Future<void> _loadDataStats() async {
    try {
      final db = await AppDatabase().database;
      
      // 统计各表数据
      final stats = <String, int>{};
      
      final tables = [
        'account_records',
        'schedules',
        'memos',
        'habits',
        'habit_records',
        'health_records',
        'books',
        'book_notes',
        'mood_entries',
        'shopping_items',
        'trips',
        'packing_items',
        'countdowns',
      ];
      
      for (final table in tables) {
        try {
          final result = await db.rawQuery('SELECT COUNT(*) as count FROM $table');
          stats[table] = result.first['count'] as int? ?? 0;
        } catch (e) {
          stats[table] = 0;
        }
      }
      
      setState(() => _dataStats = stats);
    } catch (e) {
      debugPrint('加载数据统计失败: $e');
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    
    try {
      final db = await AppDatabase().database;
      final exportData = <String, dynamic>{
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'data': {},
      };
      
      // 导出所有表数据
      final tables = [
        'account_records',
        'schedules',
        'memos',
        'habits',
        'habit_records',
        'health_records',
        'books',
        'book_notes',
        'mood_entries',
        'shopping_items',
        'trips',
        'packing_items',
        'countdowns',
      ];
      
      for (final table in tables) {
        try {
          final data = await db.query(table);
          exportData['data'][table] = data;
        } catch (e) {
          exportData['data'][table] = [];
        }
      }
      
      // 生成JSON文件
      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportData);
      final bytes = utf8.encode(jsonStr);
      
      // 保存到临时目录
      final tempDir = await getTemporaryDirectory();
      final fileName = 'ai_toolbox_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);
      
      // 分享文件
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'AI工具箱数据备份',
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('数据导出成功')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导出失败: $e')),
      );
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importData() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入数据'),
        content: const Text('导入数据将覆盖现有数据，是否继续？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _showImportInstructions();
            },
            child: const Text('继续'),
          ),
        ],
      ),
    );
  }

  void _showImportInstructions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '数据导入说明',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('1. 将备份文件复制到手机存储'),
            const Text('2. 在文件管理器中找到备份文件'),
            const Text('3. 使用"AI工具箱"打开该文件'),
            const SizedBox(height: 8),
            const Text(
              '注意：导入将覆盖现有数据，建议先导出备份！',
              style: TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('我知道了'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空所有数据'),
        content: const Text('此操作不可恢复！确定要清空所有数据吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('确定清空'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final db = await AppDatabase().database;
        
        // 清空所有表
        final tables = [
          'account_records',
          'schedules',
          'memos',
          'habit_records',
          'health_records',
          'book_notes',
          'mood_entries',
          'shopping_items',
          'packing_items',
          'countdowns',
          'habits',
          'books',
          'trips',
        ];
        
        for (final table in tables) {
          try {
            await db.delete(table);
          } catch (e) {
            debugPrint('清空表 $table 失败: $e');
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有数据已清空')),
        );
        
        _loadDataStats();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('清空失败: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('数据备份'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 数据概览
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '数据概览',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (_dataStats == null)
                      const Center(child: CircularProgressIndicator())
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _dataStats!.entries
                            .where((e) => e.value > 0)
                            .map((e) => Chip(
                                  avatar: const Icon(Icons.storage, size: 16),
                                  label: Text('${_getTableName(e.key)}: ${e.value}'),
                                ))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 导出导入
            const Text(
              '数据管理',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.blue),
              title: const Text('导出数据'),
              subtitle: const Text('将所有数据导出为JSON文件'),
              trailing: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isExporting ? null : _exportData,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.cloud_download, color: Colors.green),
              title: const Text('导入数据'),
              subtitle: const Text('从备份文件恢复数据'),
              trailing: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chevron_right),
              onTap: _isImporting ? null : _importData,
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('清空数据', style: TextStyle(color: Colors.red)),
              subtitle: const Text('删除所有本地数据（不可恢复）'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _clearAllData,
            ),
            
            const SizedBox(height: 24),
            
            // 说明
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '使用说明',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('• 导出的数据包含所有本地记录'),
                    Text('• 建议定期备份重要数据'),
                    Text('• 导入数据前请确认备份文件完整'),
                    Text('• 数据文件格式为JSON，可手动编辑'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTableName(String table) {
    final names = {
      'account_records': '记账',
      'schedules': '日程',
      'memos': '备忘',
      'habits': '习惯',
      'habit_records': '习惯记录',
      'health_records': '健康',
      'books': '书籍',
      'book_notes': '读书笔记',
      'mood_entries': '心情',
      'shopping_items': '购物',
      'trips': '旅行',
      'packing_items': '行李',
      'countdowns': '倒计时',
    };
    return names[table] ?? table;
  }
}
