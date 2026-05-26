import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';

/// 记账本页面 - 收支记录与统计
class AccountingPage extends StatefulWidget {
  const AccountingPage({super.key});

  @override
  State<AccountingPage> createState() => _AccountingPageState();
}

class _AccountingPageState extends State<AccountingPage> {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _monthFormat = DateFormat('yyyy年MM月');
  
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  
  double _totalIncome = 0;
  double _totalExpense = 0;
  
  final List<Map<String, dynamic>> _categories = [
    {'name': '餐饮', 'icon': Icons.restaurant, 'color': Colors.orange},
    {'name': '交通', 'icon': Icons.directions_car, 'color': Colors.blue},
    {'name': '购物', 'icon': Icons.shopping_bag, 'color': Colors.pink},
    {'name': '娱乐', 'icon': Icons.movie, 'color': Colors.purple},
    {'name': '居住', 'icon': Icons.home, 'color': Colors.brown},
    {'name': '医疗', 'icon': Icons.local_hospital, 'color': Colors.red},
    {'name': '教育', 'icon': Icons.school, 'color': Colors.teal},
    {'name': '工资', 'icon': Icons.attach_money, 'color': Colors.green},
    {'name': '理财', 'icon': Icons.trending_up, 'color': Colors.indigo},
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
      final startDate = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final endDate = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
      
      _records = await _db.getAccountRecords(
        startDate: _dateFormat.format(startDate),
        endDate: _dateFormat.format(endDate),
      );
      
      _calculateTotals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _calculateTotals() {
    _totalIncome = 0;
    _totalExpense = 0;
    for (final record in _records) {
      final amount = record['amount'] as double;
      final type = record['type'] as String;
      if (type == 'income') {
        _totalIncome += amount;
      } else {
        _totalExpense += amount;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          _buildSummaryCard(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? _buildEmptyState()
                    : _buildRecordList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
              });
              _loadData();
            },
          ),
          Text(
            _monthFormat.format(_selectedMonth),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    final balance = _totalIncome - _totalExpense;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('收入', _totalIncome, Colors.green),
                _buildSummaryItem('支出', _totalExpense, Colors.red),
                _buildSummaryItem('结余', balance, balance >= 0 ? Colors.blue : Colors.orange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无记录', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角添加收支', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildRecordList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final isIncome = record['type'] == 'income';
        final category = _categories.firstWhere(
          (c) => c['name'] == record['category'],
          orElse: () => _categories.last,
        );
        
        return Dismissible(
          key: Key(record['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteRecord(record['id']),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: category['color'] as Color,
                child: Icon(category['icon'] as IconData, color: Colors.white, size: 20),
              ),
              title: Text(record['category']),
              subtitle: Text('${record['remark'] ?? ''}\n${record['date']}'),
              isThreeLine: record['remark'] != null && record['remark'].isNotEmpty,
              trailing: Text(
                '${isIncome ? '+' : '-'}¥${(record['amount'] as double).toStringAsFixed(2)}',
                style: TextStyle(
                  color: isIncome ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteRecord(int id) async {
    await _db.deleteAccountRecord(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已删除')),
    );
  }

  Future<void> _showAddDialog() async {
    String type = 'expense';
    String category = '餐饮';
    final amountController = TextEditingController();
    final remarkController = TextEditingController();
    DateTime date = DateTime.now();

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
              Text('记一笔', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              // 收支类型
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('支出'),
                      selected: type == 'expense',
                      selectedColor: Colors.red[100],
                      onSelected: (selected) {
                        if (selected) setModalState(() => type = 'expense');
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('收入'),
                      selected: type == 'income',
                      selectedColor: Colors.green[100],
                      onSelected: (selected) {
                        if (selected) setModalState(() => type = 'income');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // 金额
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: '金额',
                  prefixText: '¥',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              
              // 分类
              const Text('分类'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.where((c) {
                  if (type == 'income') {
                    return ['工资', '理财', '其他'].contains(c['name']);
                  }
                  return !['工资', '理财'].contains(c['name']);
                }).map((c) {
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
              
              // 备注
              TextField(
                controller: remarkController,
                decoration: const InputDecoration(
                  labelText: '备注（可选）',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              
              // 日期
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('日期'),
                trailing: Text(_dateFormat.format(date)),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setModalState(() => date = picked);
                  }
                },
              ),
              const SizedBox(height: 16),
              
              // 保存按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(amountController.text);
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入有效金额')),
                      );
                      return;
                    }
                    
                    await _db.addAccountRecord({
                      'amount': amount,
                      'type': type,
                      'category': category,
                      'remark': remarkController.text.isEmpty ? null : remarkController.text,
                      'date': _dateFormat.format(date),
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
