import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';

/// 备忘录页面 - 简化版（无富文本依赖）
class MemoPage extends StatefulWidget {
  const MemoPage({super.key});

  @override
  State<MemoPage> createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  final AppDatabase _db = AppDatabase();
  List<Map<String, dynamic>> _memos = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _memos = await _db.getMemos(
        search: _searchController.text.isNotEmpty ? _searchController.text : null,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('备忘录'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索备忘录...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _loadData();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (_) => _loadData(),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _memos.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _memos.length,
                  itemBuilder: (context, index) => _buildMemoCard(_memos[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.note_add, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无备忘录', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角添加', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMemoCard(Map<String, dynamic> memo) {
    final isPinned = memo['isPinned'] == 1;
    final createdAt = DateTime.tryParse(memo['createdAt'] ?? '') ?? DateTime.now();
    
    return Dismissible(
      key: Key(memo['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteMemo(memo['id']),
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: isPinned
              ? const Icon(Icons.push_pin, color: Colors.orange)
              : const Icon(Icons.note, color: Colors.blue),
          title: Text(
            memo['title']?.toString().isNotEmpty == true
                ? memo['title']
                : '无标题',
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Text(
                memo['content']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          isThreeLine: true,
          onTap: () => _showAddDialog(memo: memo),
        ),
      ),
    );
  }

  Future<void> _showAddDialog({Map<String, dynamic>? memo}) async {
    final isEdit = memo != null;
    final titleController = TextEditingController(text: memo?['title'] ?? '');
    final contentController = TextEditingController(text: memo?['content'] ?? '');
    bool isPinned = memo?['isPinned'] == 1;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Expanded(child: Text(isEdit ? '编辑备忘录' : '新建备忘录')),
              IconButton(
                icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                    color: isPinned ? Colors.orange : null),
                onPressed: () => setState(() => isPinned = !isPinned),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '标题',
                    hintText: '输入标题（可选）',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '内容',
                    hintText: '输入备忘录内容',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 8,
                ),
              ],
            ),
          ),
          actions: [
            if (isEdit)
              TextButton(
                onPressed: () async {
                  await _db.deleteMemo(memo['id']);
                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text('删除', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () async {
                final data = {
                  'title': titleController.text.isNotEmpty ? titleController.text : null,
                  'content': contentController.text,
                  'isPinned': isPinned ? 1 : 0,
                };

                if (isEdit) {
                  await _db.updateMemo(memo['id'], data);
                } else {
                  await _db.addMemo(data);
                }

                Navigator.pop(context);
                _loadData();
              },
              child: Text(isEdit ? '更新' : '保存'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteMemo(int id) async {
    await _db.deleteMemo(id);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}