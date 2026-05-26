import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

/// AI文档助手页面 - 文档上传和分析
class AiDocumentPage extends StatefulWidget {
  const AiDocumentPage({super.key});

  @override
  State<AiDocumentPage> createState() => _AiDocumentPageState();
}

class _AiDocumentPageState extends State<AiDocumentPage> {
  File? _selectedFile;
  String? _fileContent;
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _resultController = TextEditingController();
  
  bool _isLoading = false;
  bool _isParsing = false;
  String _selectedFunction = 'summary'; // summary, qa, extract, translate
  
  final Map<String, String> _functions = {
    'summary': '文档总结',
    'qa': '问答',
    'extract': '提取信息',
    'translate': '翻译',
  };
  
  /// 选择文件
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'pdf', 'doc', 'docx', 'md'],
        allowMultiple: false,
      );
      
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _fileContent = null;
          _resultController.clear();
        });
        
        // 解析文件
        await _parseFile();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择文件失败: $e')),
      );
    }
  }
  
  /// 解析文件内容
  Future<void> _parseFile() async {
    if (_selectedFile == null) return;
    
    setState(() {
      _isParsing = true;
    });
    
    try {
      // 简单实现：只支持txt和md文件
      // PDF和Word需要额外插件
      final extension = _selectedFile!.path.split('.').last.toLowerCase();
      
      if (extension == 'txt' || extension == 'md') {
        final content = await _selectedFile!.readAsString();
        setState(() {
          _fileContent = content;
          _isParsing = false;
        });
      } else {
        setState(() {
          _fileContent = '（${extension.toUpperCase()}文件）\n\n'
              '文件路径: ${_selectedFile!.path}\n'
              '文件大小: ${(_selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB\n\n'
              '提示: 当前版本仅支持TXT/Markdown文件直接解析。\n'
              'PDF/Word文件解析需要额外插件支持。';
          _isParsing = false;
        });
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('解析文件失败: $e')),
      );
    }
  }
  
  /// 处理文档
  Future<void> _processDocument() async {
    if (_fileContent == null || _fileContent!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先上传文档')),
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
      
      // 截取内容（避免超出token限制）
      final content = _fileContent!.length > 8000
        ? '${_fileContent!.substring(0, 8000)}...'
        : _fileContent!;
      
      final response = await AiService.chat(
        messages: [
          {'role': 'system', 'content': '你是一个专业的文档分析助手。'},
          {'role': 'user', 'content': '$prompt\n\n文档内容：\n$content'},
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
    final question = _questionController.text.trim();
    
    switch (_selectedFunction) {
      case 'summary':
        return '请对以上文档进行总结，提炼核心观点和关键信息。';
      case 'qa':
        return question.isEmpty
          ? '请根据以上文档内容，回答可能的关键问题。'
          : '问题：$question\n\n请根据文档内容回答以上问题。';
      case 'extract':
        return question.isEmpty
          ? '请从文档中提取关键信息、数据、日期等重要内容。'
          : '请从文档中提取以下信息：$question';
      case 'translate':
        return '请将以上文档翻译成中文（如果原文是中文则翻译成英文）。';
      default:
        return question;
    }
  }
  
  void _clearAll() {
    setState(() {
      _selectedFile = null;
      _fileContent = null;
      _questionController.clear();
      _resultController.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📄 AI文档助手'),
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
          // 上传区域
          _buildUploadArea(),
          
          // 功能选择
          if (_fileContent != null) _buildFunctionBar(),
          
          // 内容展示区
          if (_fileContent != null)
            Expanded(
              child: Row(
                children: [
                  // 原文
                  Expanded(
                    child: _buildContentPanel(),
                  ),
                  // AI结果
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
  
  Widget _buildUploadArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border.all(
          color: _selectedFile != null ? Colors.green : Colors.grey[300]!,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: _selectedFile != null ? Colors.green[50] : Colors.grey[50],
      ),
      child: Column(
        children: [
          if (_selectedFile == null) ...[
            Icon(
              Icons.cloud_upload,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 12),
            const Text(
              '点击上传文档',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '支持格式: TXT, Markdown, PDF, Word',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ] else ...[
            Row(
              children: [
                Icon(
                  Icons.description,
                  size: 40,
                  color: Colors.green[700],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedFile!.path.split('/').last,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (_isParsing)
                        const Text('解析中...', style: TextStyle(color: Colors.orange))
                      else
                        Text(
                          '${(_fileContent?.length ?? 0)} 字符',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _clearAll,
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _isParsing ? null : _pickFile,
            icon: const Icon(Icons.folder_open),
            label: Text(_selectedFile == null ? '选择文件' : '重新选择'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildFunctionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _functions.entries.map((entry) {
                  final isSelected = _selectedFunction == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedFunction = entry.key;
                          });
                        }
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildContentPanel() {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.description, size: 18),
                SizedBox(width: 8),
                Text('文档内容', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Text(_fileContent ?? ''),
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                const Text('AI分析', style: TextStyle(fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_selectedFunction == 'qa' || _selectedFunction == 'extract')
                  SizedBox(
                    width: 150,
                    child: TextField(
                      controller: _questionController,
                      decoration: const InputDecoration(
                        hintText: '输入问题...',
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _resultController.text.isEmpty
              ? Center(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _processDocument,
                    icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow),
                    label: Text(_isLoading ? '分析中...' : '开始分析'),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Text(_resultController.text),
                ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _resultController.dispose();
    super.dispose();
  }
}
