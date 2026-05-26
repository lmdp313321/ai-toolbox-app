import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

/// AI表格助手页面 - 支持文件上传
class AiExcelPage extends StatefulWidget {
  const AiExcelPage({super.key});

  @override
  State<AiExcelPage> createState() => _AiExcelPageState();
}

class _AiExcelPageState extends State<AiExcelPage> {
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  String _selectedFunction = 'generate';
  bool _isLoading = false;
  String? _fileName;
  
  final Map<String, String> _functions = {
    'generate': '生成表格',
    'analyze': '数据分析',
    'formula': '生成公式',
    'clean': '数据清洗',
  };
  
  final Map<String, String> _functionHints = {
    'generate': '描述你需要的表格，例如：创建一个员工信息表，包含姓名、部门、入职日期',
    'analyze': '粘贴表格数据或上传CSV文件',
    'formula': '描述公式需求，例如：计算A列平均值，排除空值',
    'clean': '粘贴需要清洗的数据或上传CSV文件',
  };
  
  /// 选择文件
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls', 'txt'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final extension = fileName.split('.').last.toLowerCase();
        
        setState(() {
          _fileName = fileName;
        });
        
        String content;
        if (extension == 'csv' || extension == 'txt') {
          // 直接读取文本文件
          content = await file.readAsString();
        } else {
          // Excel文件提示 - 读取前100字节用于显示文件名信息
          content = '''📁 文件: $fileName

⚠️ 格式不支持直接读取

当前仅支持以下格式：
• CSV (.csv) - 推荐 ✅
• 纯文本 (.txt) ✅

💡 Excel转换方法：
1. 用Excel打开文件
2. 点击"文件" → "另存为"
3. 选择"CSV UTF-8 (逗号分隔)(*.csv)"
4. 重新上传CSV文件

📊 在线转换工具：
• https://convertio.co/zh/xlsx-csv/
• https://tableconvert.com/'''
;
        }
        
        setState(() {
          _dataController.text = content;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已加载: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('文件读取失败: $e')),
      );
    }
  }
  
  Future<void> _process() async {
    if (_dataController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入数据或上传文件')),
      );
      return;
    }
    
    final apiProvider = Provider.of<ApiProvider>(context, listen: false);
    if (!apiProvider.hasValidConfig) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _resultController.clear();
    });
    
    try {
      final prompt = _buildPrompt();
      
      final response = await AiService.chat(
        messages: [
          {'role': 'system', 'content': '你是一个Excel/表格处理专家。'},
          {'role': 'user', 'content': prompt},
        ],
        config: apiProvider.activeConfig!,
      );
      
      setState(() {
        _resultController.text = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _resultController.text = '错误: $e';
        _isLoading = false;
      });
    }
  }
  
  String _buildPrompt() {
    final data = _dataController.text.trim();
    
    switch (_selectedFunction) {
      case 'generate':
        return '请根据以下需求生成表格结构和示例数据：\n\n$data\n\n请以Markdown表格格式输出。';
      case 'analyze':
        return '请分析以下表格数据，计算关键指标并给出洞察：\n\n$data\n\n请提供：\n1. 数据概览（行数、列数）\n2. 统计分析（平均值、最大值、最小值等）\n3. 数据洞察和建议';
      case 'formula':
        return '请为以下需求生成Excel公式：\n\n$data\n\n请说明公式的作用和使用方法。';
      case 'clean':
        return '请帮我清洗以下数据，处理空值、重复和格式问题：\n\n$data\n\n请输出清洗后的数据，并说明做了哪些处理。';
      default:
        return data;
    }
  }
  
  void _copyResult() {
    if (_resultController.text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _resultController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }
  
  void _clearAll() {
    setState(() {
      _dataController.clear();
      _resultController.clear();
      _fileName = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📊 AI表格助手'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearAll,
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // 功能选择
          Container(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _functions.entries.map((entry) {
                final isSelected = _selectedFunction == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedFunction = entry.key;
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ),
          
          // 输入输出区
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _buildInputPanel(),
                ),
                Expanded(
                  child: _buildResultPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInputPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.table_chart, size: 18),
                const SizedBox(width: 8),
                const Text('输入数据', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                // 文件上传按钮
                ElevatedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.upload_file, size: 16),
                  label: const Text('上传文件'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // 显示已上传文件名
          if (_fileName != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              color: Colors.green[50],
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已加载: $_fileName',
                      style: TextStyle(fontSize: 12, color: Colors.green[700]),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 16, color: Colors.green[700]),
                    onPressed: () {
                      setState(() {
                        _fileName = null;
                        _dataController.clear();
                      });
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          Expanded(
            child: TextField(
              controller: _dataController,
              decoration: InputDecoration(
                hintText: _functionHints[_selectedFunction],
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(12),
              ),
              maxLines: null,
              expands: true,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _process,
                    icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                    label: Text(_isLoading ? '处理中...' : '开始处理'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResultPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_fix_high, size: 18),
                const SizedBox(width: 8),
                const Text('AI结果', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: _copyResult,
                  tooltip: '复制结果',
                ),
              ],
            ),
          ),
          Expanded(
            child: TextField(
              controller: _resultController,
              decoration: const InputDecoration(
                hintText: '结果将显示在这里...',
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: null,
              expands: true,
              readOnly: true,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _dataController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}