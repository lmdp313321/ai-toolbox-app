import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../../../core/storage/app_database.dart';

/// 读书笔记页面 - 书籍管理与阅读进度（支持封面上传）
class ReadingNotesPage extends StatefulWidget {
  const ReadingNotesPage({super.key});

  @override
  State<ReadingNotesPage> createState() => _ReadingNotesPageState();
}

class _ReadingNotesPageState extends State<ReadingNotesPage> {
  final AppDatabase _db = AppDatabase();
  final ImagePicker _picker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  
  List<Map<String, dynamic>> _books = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, reading, completed

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _books = await _db.getBooks();
      if (_filter != 'all') {
        _books = _books.where((b) => b['status'] == _filter).toList();
      }
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
        title: const Text('读书笔记'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'reading', child: Text('在读')),
              const PopupMenuItem(value: 'completed', child: Text('已读完')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _books.isEmpty
              ? _buildEmptyState()
              : _buildBookGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBookDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.menu_book, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无书籍', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角添加书籍', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildBookGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        final book = _books[index];
        final progress = book['totalPages'] > 0
            ? (book['currentPage'] / book['totalPages'] * 100).toInt()
            : 0;
        final isCompleted = book['status'] == 'completed';
        final coverPath = book['coverPath'] as String?;
        
        return GestureDetector(
          onTap: () => _showBookDetail(book),
          child: Card(
            elevation: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // 封面图片
                      coverPath != null && coverPath.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.file(
                                File(coverPath),
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultCover(book);
                                },
                              ),
                            )
                          : _buildDefaultCover(book),
                      // 状态标签
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green : Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isCompleted ? '已读完' : '在读',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book['title'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (book['author'] != null && book['author'].isNotEmpty)
                        Text(
                          book['author'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: book['totalPages'] > 0 ? book['currentPage'] / book['totalPages'] : 0,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(isCompleted ? Colors.green : Colors.blue),
                        minHeight: 4,
                      ),
                      const SizedBox(height: 2),
                      Text('$progress%', style: TextStyle(color: Colors.grey[600], fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDefaultCover(Map<String, dynamic> book) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final color = colors[book['id'] % colors.length];
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.6)],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book, size: 48, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 8),
              Text(
                book['title'],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBook(int id) async {
    await _db.deleteBook(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('书籍已删除')),
    );
  }

  Future<void> _showAddBookDialog({String? initialCoverPath}) async {
    final titleController = TextEditingController();
    final authorController = TextEditingController();
    final totalPagesController = TextEditingController();
    final currentPageController = TextEditingController(text: '0');
    String status = 'reading';
    String? coverPath = initialCoverPath;
    
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('添加书籍', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                // 封面上传
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 1200,
                      );
                      if (image != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final coverDir = Directory('${appDir.path}/book_covers');
                        if (!await coverDir.exists()) {
                          await coverDir.create(recursive: true);
                        }
                        final newPath = '${coverDir.path}/${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
                        await File(image.path).copy(newPath);
                        setModalState(() => coverPath = newPath);
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!, width: 1),
                      ),
                      child: coverPath != null && coverPath!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(coverPath!),
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 4),
                                Text('点击上传封面', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '书名 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: '作者',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalPagesController,
                        decoration: const InputDecoration(
                          labelText: '总页数',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: currentPageController,
                        decoration: const InputDecoration(
                          labelText: '当前页',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('状态'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('在读'),
                        selected: status == 'reading',
                        onSelected: (selected) {
                          if (selected) setModalState(() => status = 'reading');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('已读完'),
                        selected: status == 'completed',
                        onSelected: (selected) {
                          if (selected) setModalState(() => status = 'completed');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (titleController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入书名')),
                        );
                        return;
                      }
                      
                      final totalPages = int.tryParse(totalPagesController.text) ?? 0;
                      final currentPage = int.tryParse(currentPageController.text) ?? 0;
                      
                      await _db.addBook({
                        'title': titleController.text.trim(),
                        'author': authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                        'totalPages': totalPages,
                        'currentPage': currentPage,
                        'status': status,
                        'coverPath': coverPath,
                      });
                      
                      Navigator.pop(context);
                      _loadData();
                    },
                    child: const Text('保存'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showBookDetail(Map<String, dynamic> book) async {
    final notes = await _db.getBookNotes(book['id']);
    final coverPath = book['coverPath'] as String?;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // 头部
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 封面
                    coverPath != null && coverPath.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(coverPath),
                              width: 80,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildSmallDefaultCover(book);
                              },
                            ),
                          )
                        : _buildSmallDefaultCover(book),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  book['title'],
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showEditBookDialog(book);
                                },
                              ),
                            ],
                          ),
                          if (book['author'] != null && book['author'].isNotEmpty)
                            Text('作者: ${book['author']}', style: TextStyle(color: Colors.grey[700])),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: book['totalPages'] > 0 ? book['currentPage'] / book['totalPages'] : 0,
                            backgroundColor: Colors.grey[300],
                          ),
                          const SizedBox(height: 4),
                          Text('${book['currentPage']}/${book['totalPages']} 页'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // 笔记列表
              Expanded(
                child: notes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text('暂无笔记', style: TextStyle(color: Colors.grey[600])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: notes.length,
                        itemBuilder: (context, index) {
                          final note = notes[index];
                          return Card(
                            child: ListTile(
                              title: Text(note['content'] ?? ''),
                              subtitle: Text('第${note['page'] ?? '?'}页 · ${note['date'] ?? ''}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, size: 20),
                                onPressed: () async {
                                  await _db.deleteBookNote(note['id']);
                                  Navigator.pop(context);
                                  _showBookDetail(book);
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
              
              // 添加笔记按钮
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showAddNoteDialog(book['id']);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('添加笔记'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmallDefaultCover(Map<String, dynamic> book) {
    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.teal];
    final color = colors[book['id'] % colors.length];
    return Container(
      width: 80,
      height: 110,
      decoration: BoxDecoration(
        color: color.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.menu_book, size: 40, color: Colors.white.withOpacity(0.9)),
      ),
    );
  }

  Future<void> _showEditBookDialog(Map<String, dynamic> book) async {
    final titleController = TextEditingController(text: book['title']);
    final authorController = TextEditingController(text: book['author'] ?? '');
    final totalPagesController = TextEditingController(text: book['totalPages'].toString());
    final currentPageController = TextEditingController(text: book['currentPage'].toString());
    String status = book['status'];
    String? coverPath = book['coverPath'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('编辑书籍', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                
                // 封面上传
                Center(
                  child: GestureDetector(
                    onTap: () async {
                      final XFile? image = await _picker.pickImage(
                        source: ImageSource.gallery,
                        maxWidth: 800,
                        maxHeight: 1200,
                      );
                      if (image != null) {
                        final appDir = await getApplicationDocumentsDirectory();
                        final coverDir = Directory('${appDir.path}/book_covers');
                        if (!await coverDir.exists()) {
                          await coverDir.create(recursive: true);
                        }
                        final newPath = '${coverDir.path}/${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
                        await File(image.path).copy(newPath);
                        setModalState(() => coverPath = newPath);
                      }
                    },
                    child: Container(
                      width: 120,
                      height: 160,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[400]!, width: 1),
                      ),
                      child: coverPath != null && coverPath!.isNotEmpty
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(coverPath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.edit, size: 16, color: Colors.white),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey[600]),
                                const SizedBox(height: 4),
                                Text('点击上传封面', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '书名 *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: authorController,
                  decoration: const InputDecoration(
                    labelText: '作者',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalPagesController,
                        decoration: const InputDecoration(
                          labelText: '总页数',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: currentPageController,
                        decoration: const InputDecoration(
                          labelText: '当前页',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                const Text('状态'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('在读'),
                        selected: status == 'reading',
                        onSelected: (selected) {
                          if (selected) setModalState(() => status = 'reading');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('已读完'),
                        selected: status == 'completed',
                        onSelected: (selected) {
                          if (selected) setModalState(() => status = 'completed');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final totalPages = int.tryParse(totalPagesController.text) ?? 0;
                      final currentPage = int.tryParse(currentPageController.text) ?? 0;
                      
                      await _db.updateBook(book['id'], {
                        'title': titleController.text.trim(),
                        'author': authorController.text.trim().isEmpty ? null : authorController.text.trim(),
                        'totalPages': totalPages,
                        'currentPage': currentPage,
                        'status': status,
                        'coverPath': coverPath,
                      });
                      
                      Navigator.pop(context);
                      _loadData();
                    },
                    child: const Text('保存'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showAddNoteDialog(int bookId) async {
    final contentController = TextEditingController();
    final pageController = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('添加笔记', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            TextField(
              controller: pageController,
              decoration: const InputDecoration(
                labelText: '页码（可选）',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                labelText: '笔记内容',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  if (contentController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请输入笔记内容')),
                    );
                    return;
                  }
                  
                  await _db.addBookNote({
                    'bookId': bookId,
                    'content': contentController.text.trim(),
                    'page': pageController.text.trim().isEmpty ? null : int.tryParse(pageController.text.trim()),
                    'date': _dateFormat.format(DateTime.now()),
                  });
                  
                  Navigator.pop(context);
                  _loadData();
                },
                child: const Text('保存'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
