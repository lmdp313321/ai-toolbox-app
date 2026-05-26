import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/storage/app_database.dart';

/// 购物清单页面 - 购物列表管理
class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final AppDatabase _db = AppDatabase();
  
  List<Map<String, dynamic>> _items = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, pending, completed

  final List<Map<String, dynamic>> _categories = [
    {'name': '生鲜', 'icon': Icons.local_grocery_store, 'color': Colors.green},
    {'name': '食品', 'icon': Icons.fastfood, 'color': Colors.orange},
    {'name': '日用', 'icon': Icons.cleaning_services, 'color': Colors.blue},
    {'name': '服装', 'icon': Icons.checkroom, 'color': Colors.purple},
    {'name': '电子', 'icon': Icons.devices, 'color': Colors.teal},
    {'name': '其他', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _items = await _db.getShoppingItems();
      if (_filter == 'pending') {
        _items = _items.where((i) => i['isCompleted'] != 1).toList();
      } else if (_filter == 'completed') {
        _items = _items.where((i) => i['isCompleted'] == 1).toList();
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
    final pendingCount = _items.where((i) => i['isCompleted'] != 1).length;
    final completedCount = _items.where((i) => i['isCompleted'] == 1).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('购物清单'),
        actions: [
          // 筛选
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filter = value);
              _loadData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('全部')),
              const PopupMenuItem(value: 'pending', child: Text('待购')),
              const PopupMenuItem(value: 'completed', child: Text('已购')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          if (completedCount > 0)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearCompleted,
              tooltip: '清空已购',
            ),
        ],
      ),
      body: Column(
        children: [
          // 统计
          if (_items.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStatChip('待购', pendingCount, Colors.orange),
                  const SizedBox(width: 16),
                  _buildStatChip('已购', completedCount, Colors.green),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? _buildEmptyState()
                    : _buildItemList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 10,
        child: Text('$count', style: const TextStyle(fontSize: 10, color: Colors.white)),
      ),
      label: Text(label),
      backgroundColor: color.withOpacity(0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('购物清单为空', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角添加商品', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    // 按分类分组
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final item in _items) {
      final category = item['category'] ?? '其他';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedItems.length,
      itemBuilder: (context, index) {
        final category = groupedItems.keys.elementAt(index);
        final items = groupedItems[category]!;
        final categoryInfo = _categories.firstWhere(
          (c) => c['name'] == category,
          orElse: () => _categories.last,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类标题
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(categoryInfo['icon'] as IconData, color: categoryInfo['color'] as Color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    category,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: categoryInfo['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('(${items.length})', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
            ),
            // 商品列表
            ...items.map((item) => _buildItemTile(item)),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final isCompleted = item['isCompleted'] == 1;
    return Dismissible(
      key: Key(item['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item['id']),
      child: Card(
        child: ListTile(
          leading: Checkbox(
            value: isCompleted,
            onChanged: (value) => _toggleItem(item['id'], !isCompleted),
          ),
          title: Text(
            item['name'],
            style: TextStyle(
              decoration: isCompleted ? TextDecoration.lineThrough : null,
              color: isCompleted ? Colors.grey : null,
            ),
          ),
          subtitle: item['quantity'] != null && item['quantity'].isNotEmpty
              ? Text('数量: ${item['quantity']}')
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (item['price'] != null)
                Text(
                  '¥${item['price']}',
                  style: TextStyle(
                    color: isCompleted ? Colors.grey : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _showEditDialog(item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleItem(int id, bool isCompleted) async {
    await _db.updateShoppingItem(id, {'isCompleted': isCompleted ? 1 : 0});
    _loadData();
  }

  Future<void> _deleteItem(int id) async {
    await _db.deleteShoppingItem(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('商品已删除')),
    );
  }

  Future<void> _clearCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清空'),
        content: const Text('确定要清空所有已购商品吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清空'),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final completedItems = _items.where((i) => i['isCompleted'] == 1).toList();
      for (final item in completedItems) {
        await _db.deleteShoppingItem(item['id']);
      }
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已清空已购商品')),
      );
    }
  }

  Future<void> _showAddDialog() async {
    final nameController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    String category = '生鲜';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('添加商品', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '商品名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: '数量',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: '单价',
                        prefixText: '¥',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('分类'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = category == c['name'];
                  return ChoiceChip(
                    avatar: Icon(c['icon'] as IconData, size: 18, color: isSelected ? Colors.white : c['color'] as Color),
                    label: Text(c['name'] as String),
                    selected: isSelected,
                    selectedColor: c['color'] as Color,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    onSelected: (selected) {
                      if (selected) setModalState(() => category = c['name'] as String);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入商品名称')),
                      );
                      return;
                    }
                    
                    final price = priceController.text.isEmpty
                        ? null
                        : double.tryParse(priceController.text);
                    
                    await _db.addShoppingItem({
                      'name': nameController.text.trim(),
                      'quantity': quantityController.text.isEmpty ? null : quantityController.text,
                      'price': price,
                      'category': category,
                      'isCompleted': 0,
                    });
                    
                    Navigator.pop(context);
                    _loadData();
                  },
                  child: const Text('添加'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(Map<String, dynamic> item) async {
    final nameController = TextEditingController(text: item['name']);
    final quantityController = TextEditingController(text: item['quantity'] ?? '');
    final priceController = TextEditingController(
      text: item['price'] != null ? item['price'].toString() : '',
    );
    String category = item['category'] ?? '其他';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('编辑商品', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '商品名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: quantityController,
                      decoration: const InputDecoration(
                        labelText: '数量',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      decoration: const InputDecoration(
                        labelText: '单价',
                        prefixText: '¥',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              const Text('分类'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final isSelected = category == c['name'];
                  return ChoiceChip(
                    avatar: Icon(c['icon'] as IconData, size: 18, color: isSelected ? Colors.white : c['color'] as Color),
                    label: Text(c['name'] as String),
                    selected: isSelected,
                    selectedColor: c['color'] as Color,
                    labelStyle: TextStyle(color: isSelected ? Colors.white : null),
                    onSelected: (selected) {
                      if (selected) setModalState(() => category = c['name'] as String);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final price = priceController.text.isEmpty
                        ? null
                        : double.tryParse(priceController.text);
                    
                    await _db.updateShoppingItem(item['id'], {
                      'name': nameController.text.trim(),
                      'quantity': quantityController.text.isEmpty ? null : quantityController.text,
                      'price': price,
                      'category': category,
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
    );
  }
}
