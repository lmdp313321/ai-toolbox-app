import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Markdown笔记页面 - 富文本笔记编辑
class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<Map<String, dynamic>> _notes = [];
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  void _loadNotes() {
    // 加载示例数据
    setState(() {
      _notes.addAll([
        {
          'id': 1,
          'title': 'Flutter学习笔记',
          'content': '# Flutter学习笔记\n\n## 基础组件\n- StatelessWidget\n- StatefulWidget\n\n## 状态管理\n- setState\n- Provider\n- Riverpod',
          'tags': ['Flutter', '学习'],
          'updateTime': DateTime.now().subtract(const Duration(days: 1)),
        },
        {
          'id': 2,
          'title': '项目计划',
          'content': '# AI工具箱项目\n\n## 功能列表\n- [x] AI对话\n- [x] AI绘画\n- [ ] 语音助手\n\n## 发布计划\n预计本月完成初版',
          'tags': ['项目', '计划'],
          'updateTime': DateTime.now().subtract(const Duration(days: 3)),
        },
      ]);
    });
  }

  List<Map<String, dynamic>> get _filteredNotes {
    if (_searchQuery.isEmpty) return _notes;
    return _notes.where((note) {
      return note['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
             note['content'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _addNote() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          onSave: (note) {
            setState(() {
              _notes.insert(0, {
                'id': DateTime.now().millisecondsSinceEpoch,
                ...note,
                'updateTime': DateTime.now(),
              });
            });
          },
        ),
      ),
    );
  }

  void _editNote(Map<String, dynamic> note) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteEditPage(
          note: note,
          onSave: (updated) {
            setState(() {
              final index = _notes.indexWhere((n) => n['id'] == note['id']);
              if (index >= 0) {
                _notes[index] = {
                  ...note,
                  ...updated,
                  'updateTime': DateTime.now(),
                };
              }
            });
          },
        ),
      ),
    );
  }

  void _deleteNote(Map<String, dynamic> note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除笔记'),
        content: Text('确定要删除 "${note['title']}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _notes.removeWhere((n) => n['id'] == note['id']));
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (diff.inHours < 24) return '${diff.inHours}小时前';
    if (diff.inDays < 7) return '${diff.inDays}天前';
    return '${time.month}/${time.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Markdown笔记'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NoteSearchDelegate(_notes),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索笔记...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          
          // 笔记列表
          Expanded(
            child: _filteredNotes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.note_alt, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('暂无笔记', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _addNote,
                          child: const Text('创建第一篇笔记'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredNotes.length,
                    itemBuilder: (context, index) {
                      final note = _filteredNotes[index];
                      return _buildNoteCard(note);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoteCard(Map<String, dynamic> note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _editNote(note),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note['title'],
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') _editNote(note);
                      if (value == 'delete') _deleteNote(note);
                      if (value == 'share') _shareNote(note);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('编辑')),
                      const PopupMenuItem(value: 'share', child: Text('分享')),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('删除', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _getPreview(note['content']),
                style: TextStyle(color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  // 标签
                  ...((note['tags'] as List?) ?? []).take(3).map((tag) => 
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(tag, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(note['updateTime']),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPreview(String content) {
    // 移除Markdown标记
    return content
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll('\n', ' ')
        .trim();
  }

  void _shareNote(Map<String, dynamic> note) {
    Clipboard.setData(ClipboardData(text: note['content']));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('笔记内容已复制')),
    );
  }
}

/// 笔记编辑页面
class NoteEditPage extends StatefulWidget {
  final Map<String, dynamic>? note;
  final Function(Map<String, dynamic>) onSave;

  const NoteEditPage({super.key, this.note, required this.onSave});

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  bool _isPreview = false;

  @override
  void initState() {
    super.initState();
    if (widget.note != null) {
      _titleController.text = widget.note!['title'];
      _contentController.text = widget.note!['content'];
      _tagsController.text = (widget.note!['tags'] as List?)?.join(', ') ?? '';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题')),
      );
      return;
    }

    widget.onSave({
      'title': _titleController.text.trim(),
      'content': _contentController.text,
      'tags': _tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList(),
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? '新建笔记' : '编辑笔记'),
        actions: [
          IconButton(
            icon: Icon(_isPreview ? Icons.edit : Icons.preview),
            onPressed: () => setState(() => _isPreview = !_isPreview),
            tooltip: _isPreview ? '编辑' : '预览',
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
            tooltip: '保存',
          ),
        ],
      ),
      body: Column(
        children: [
          // 标题输入
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '标题',
                hintText: '输入笔记标题',
                border: OutlineInputBorder(),
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          
          // 标签输入
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: '标签',
                hintText: '用逗号分隔，如：工作, 学习',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.tag),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 内容区域
          Expanded(
            child: _isPreview
                ? _buildPreview()
                : TextField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      hintText: '支持Markdown格式...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.all(16),
                    ),
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
          ),
          
          // Markdown提示
          if (!_isPreview)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMarkdownTip('# 标题'),
                    _buildMarkdownTip('**粗体**'),
                    _buildMarkdownTip('*斜体*'),
                    _buildMarkdownTip('- 列表'),
                    _buildMarkdownTip('[链接]()'),
                    _buildMarkdownTip('`代码`'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final content = _contentController.text;
    final lines = content.split('\n');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lines.length,
      itemBuilder: (context, index) {
        return _buildMarkdownLine(lines[index]);
      },
    );
  }

  Widget _buildMarkdownLine(String line) {
    // 标题
    if (line.startsWith('# ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          line.substring(2),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (line.startsWith('## ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          line.substring(3),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }
    if (line.startsWith('### ')) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          line.substring(4),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    }
    
    // 列表项
    if (line.startsWith('- ') || line.startsWith('* ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• ', style: TextStyle(fontSize: 16)),
            Expanded(child: _buildFormattedText(line.substring(2))),
          ],
        ),
      );
    }
    
    // 复选框
    if (line.startsWith('- [ ] ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.check_box_outline_blank, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(line.substring(6))),
          ],
        ),
      );
    }
    if (line.startsWith('- [x] ')) {
      return Padding(
        padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
        child: Row(
          children: [
            const Icon(Icons.check_box, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(child: Text(line.substring(6), style: const TextStyle(decoration: TextDecoration.lineThrough))),
          ],
        ),
      );
    }
    
    // 普通文本
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _buildFormattedText(line),
    );
  }

  Widget _buildFormattedText(String text) {
    // 简单的Markdown格式解析
    final spans = <TextSpan>[];
    var remaining = text;
    
    while (remaining.isNotEmpty) {
      // 粗体 **text**
      final boldMatch = RegExp(r'\*\*(.+?)\*\*').firstMatch(remaining);
      // 斜体 *text*
      final italicMatch = RegExp(r'\*(.+?)\*').firstMatch(remaining);
      // 代码 `text`
      final codeMatch = RegExp(r'`(.+?)`').firstMatch(remaining);
      
      final matches = [
        if (boldMatch != null) ('bold', boldMatch),
        if (italicMatch != null) ('italic', italicMatch),
        if (codeMatch != null) ('code', codeMatch),
      ];
      
      if (matches.isEmpty) {
        spans.add(TextSpan(text: remaining));
        break;
      }
      
      matches.sort((a, b) => a.$2.start.compareTo(b.$2.start));
      final first = matches.first;
      
      if (first.$2.start > 0) {
        spans.add(TextSpan(text: remaining.substring(0, first.$2.start)));
      }
      
      switch (first.$1) {
        case 'bold':
          spans.add(TextSpan(
            text: first.$2.group(1),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ));
          break;
        case 'italic':
          spans.add(TextSpan(
            text: first.$2.group(1),
            style: const TextStyle(fontStyle: FontStyle.italic),
          ));
          break;
        case 'code':
          spans.add(TextSpan(
            text: first.$2.group(1),
            style: TextStyle(
              fontFamily: 'monospace',
              backgroundColor: Colors.grey[200],
            ),
          ));
          break;
      }
      
      remaining = remaining.substring(first.$2.end);
    }
    
    return RichText(text: TextSpan(children: spans, style: const TextStyle(color: Colors.black)));
  }

  Widget _buildMarkdownTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(tip, style: const TextStyle(fontSize: 11)),
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

/// 搜索委托
class NoteSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> notes;

  NoteSearchDelegate(this.notes);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final results = notes.where((note) {
      return note['title'].toString().toLowerCase().contains(query.toLowerCase()) ||
             note['content'].toString().toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return const Center(child: Text('没有找到相关笔记'));
    }

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final note = results[index];
        return ListTile(
          title: Text(note['title']),
          subtitle: Text(
            note['content'].toString().replaceAll('\n', ' '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => close(context, note['title']),
        );
      },
    );
  }
}
