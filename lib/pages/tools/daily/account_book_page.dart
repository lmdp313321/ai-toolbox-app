import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/app_database.dart';

/// 记账本页面
class AccountBookPage extends StatefulWidget {
  const AccountBookPage({super.key});

  @override
  State<AccountBookPage> createState() => _AccountBookPageState();
}

class _AccountBookPageState extends State<AccountBookPage> {
  final _db = AppDatabase();
  List<AccountRecord> _records = [];
  double _monthIncome = 0;
  double _monthExpense = 0;
  String _selectedType = 'all'; // all, income, expense
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  // 支出分类
  final Map<String, IconData> _expenseCategories = {
    '餐饮': Icons.restaurant,
    '交通': Icons.directions_car,
    '购物': Icons.shopping_bag,
    '娱乐': Icons.movie,
    '医疗': Icons.local_hospital,
    '教育': Icons.school,
    '住房': Icons.home,
    '其他': Icons.more_horiz,
  };

  // 收入分类
  final Map<String, IconData> _incomeCategories = {
    '工资': Icons.work,
    '奖金': Icons.card_giftcard,
    '投资': Icons.trending_up,
    '兼职': Icons.timer,
    '其他': Icons.more_horiz,
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final records = await _db.getAccountRecords(
      year: _selectedYear,
      month: _selectedMonth,
      type: _selectedType == 'all' ? null : _selectedType,
    );
    final stats = await _db.getAccountStats(_selectedYear, _selectedMonth);
    
    setState(() {
      _records = records;
      _monthIncome = stats['income'] ?? 0;
      _monthExpense = stats['expense'] ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('记账本'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: _showStatsDialog,
            tooltip: '统计',
          ),
        ],
      ),
      body: Column(
        children: [
          // 月度概览卡片
          _buildMonthSummaryCard(),
          
          // 筛选器
          _buildFilterBar(),
          
          // 记录列表
          Expanded(
            child: _records.isEmpty
                ? _buildEmptyState()
                : _buildRecordList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddRecordDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 月度概览卡片
  Widget _buildMonthSummaryCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 月份选择
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '$_selectedYear年$_selectedMonth月',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 收支显示
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAmountColumn('收入', _monthIncome, Colors.green),
                _buildAmountColumn('支出', _monthExpense, Colors.red),
                _buildAmountColumn('结余', _monthIncome - _monthExpense, 
                  _monthIncome >= _monthExpense ? Colors.green : Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountColumn(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '¥${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'all', label: Text('全部')),
          ButtonSegment(value: 'expense', label: Text('支出')),
          ButtonSegment(value: 'income', label: Text('收入')),
        ],
        selected: {_selectedType},
        onSelectionChanged: (Set<String> newSelection) {
          setState(() {
            _selectedType = newSelection.first;
          });
          _loadData();
        },
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, 
               size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('本月还没有记录', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddRecordDialog,
            child: const Text('记一笔'),
          ),
        ],
      ),
    );
  }

  /// 记录列表
  Widget _buildRecordList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        return _buildRecordItem(record);
      },
    );
  }

  Widget _buildRecordItem(AccountRecord record) {
    final isExpense = record.type == 'expense';
    final categories = isExpense ? _expenseCategories : _incomeCategories;
    final icon = categories[record.category] ?? Icons.help_outline;
    
    return Dismissible(
      key: Key(record.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteRecord(record.id!),
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense ? Colors.red[100] : Colors.green[100],
            child: Icon(icon, color: isExpense ? Colors.red : Colors.green),
          ),
          title: Text(record.category),
          subtitle: Text('${record.date.substring(5)} · ${record.note ?? ''}'),
          trailing: Text(
            '${isExpense ? '-' : '+'}¥${record.amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isExpense ? Colors.red : Colors.green,
            ),
          ),
        ),
      ),
    );
  }

  /// 切换月份
  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth += delta;
      if (_selectedMonth > 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else if (_selectedMonth < 1) {
        _selectedMonth = 12;
        _selectedYear--;
      }
    });
    _loadData();
  }

  /// 显示添加记录对话框
  void _showAddRecordDialog() {
    showDialog(
      context: context,
      builder: (context) => AddRecordDialog(
        onSave: _loadData,
      ),
    );
  }

  /// 显示统计对话框
  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AccountStatsDialog(
        year: _selectedYear,
        month: _selectedMonth,
        expenseCategories: _expenseCategories,
      ),
    );
  }

  /// 删除记录
  Future<void> _deleteRecord(int id) async {
    await _db.deleteAccountRecord(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已删除')),
    );
  }
}

/// 添加记录对话框
class AddRecordDialog extends StatefulWidget {
  final VoidCallback onSave;
  
  const AddRecordDialog({super.key, required this.onSave});

  @override
  State<AddRecordDialog> createState() => _AddRecordDialogState();
}

class _AddRecordDialogState extends State<AddRecordDialog> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  String _type = 'expense';
  String _category = '餐饮';
  DateTime _date = DateTime.now();

  final List<String> _expenseCategories = ['餐饮', '交通', '购物', '娱乐', '医疗', '教育', '住房', '其他'];
  final List<String> _incomeCategories = ['工资', '奖金', '投资', '兼职', '其他'];

  @override
  Widget build(BuildContext context) {
    final categories = _type == 'expense' ? _expenseCategories : _incomeCategories;
    
    return AlertDialog(
      title: const Text('记一笔'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 类型选择
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('支出')),
                ButtonSegment(value: 'income', label: Text('收入')),
              ],
              selected: {_type},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _type = newSelection.first;
                  _category = categories.first;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // 金额输入
            TextField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: '金额',
                prefixText: '¥',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 分类选择
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: categories.map((c) => 
                DropdownMenuItem(value: c, child: Text(c))
              ).toList(),
              onChanged: (value) => setState(() => _category = value!),
            ),
            const SizedBox(height: 16),
            
            // 日期选择
            ListTile(
              title: const Text('日期'),
              subtitle: Text('${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            
            // 备注
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
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
          onPressed: _save,
          child: const Text('保存'),
        ),
      ],
    );
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入有效金额')),
      );
      return;
    }

    final db = AppDatabase();
    await db.insertAccountRecord(AccountRecord(
      amount: amount,
      type: _type,
      category: _category,
      date: '${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}',
      note: _noteController.text.isEmpty ? null : _noteController.text,
      createdAt: DateTime.now().toIso8601String(),
    ));

    widget.onSave();
    Navigator.pop(context);
  }
}

/// 统计对话框
class AccountStatsDialog extends StatefulWidget {
  final int year;
  final int month;
  final Map<String, IconData> expenseCategories;
  
  const AccountStatsDialog({
    super.key, 
    required this.year, 
    required this.month,
    required this.expenseCategories,
  });

  @override
  State<AccountStatsDialog> createState() => _AccountStatsDialogState();
}

class _AccountStatsDialogState extends State<AccountStatsDialog> {
  final _db = AppDatabase();
  Map<String, double> _categoryStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getAccountCategoryStats(widget.year, widget.month);
    setState(() {
      _categoryStats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final total = _categoryStats.values.fold<double>(0, (sum, v) => sum + v);
    
    return AlertDialog(
      title: Text('${widget.year}年${widget.month}月支出分析'),
      content: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _categoryStats.isEmpty
              ? const Text('本月暂无支出记录')
              : SizedBox(
                  width: double.maxFinite,
                  height: 300,
                  child: Column(
                    children: [
                      // 饼图
                      SizedBox(
                        height: 180,
                        child: PieChart(
                          PieChartData(
                            sections: _buildPieSections(total),
                            sectionsSpace: 2,
                            centerSpaceRadius: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 图例
                      Expanded(
                        child: ListView(
                          children: _categoryStats.entries.map((e) {
                            final percent = total > 0 ? (e.value / total * 100).toStringAsFixed(1) : '0';
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                widget.expenseCategories[e.key] ?? Icons.help_outline,
                                color: _getColor(e.key),
                              ),
                              title: Text(e.key),
                              trailing: Text('¥${e.value.toStringAsFixed(0)} ($percent%)'),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('关闭'),
        ),
      ],
    );
  }

  List<PieChartSectionData> _buildPieSections(double total) {
    final colors = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
    ];
    
    int index = 0;
    return _categoryStats.entries.map((e) {
      final color = colors[index % colors.length];
      index++;
      return PieChartSectionData(
        value: e.value,
        title: '',
        color: color,
        radius: 50,
      );
    }).toList();
  }

  Color _getColor(String category) {
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.green, 
                    Colors.blue, Colors.indigo, Colors.purple, Colors.pink];
    final keys = _categoryStats.keys.toList();
    return colors[keys.indexOf(category) % colors.length];
  }
}
