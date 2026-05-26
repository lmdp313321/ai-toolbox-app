import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';

/// 健康记录页面 - 体重/饮水/睡眠/血压记录
class HealthRecordPage extends StatefulWidget {
  const HealthRecordPage({super.key});

  @override
  State<HealthRecordPage> createState() => _HealthRecordPageState();
}

class _HealthRecordPageState extends State<HealthRecordPage> with SingleTickerProviderStateMixin {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  late TabController _tabController;
  
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadData();
      }
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final type = ['weight', 'water', 'sleep', 'blood_pressure'][_tabController.index];
      _records = await _db.getHealthRecords(type);
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
        title: const Text('健康记录'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.monitor_weight), text: '体重'),
            Tab(icon: Icon(Icons.water_drop), text: '饮水'),
            Tab(icon: Icon(Icons.bedtime), text: '睡眠'),
            Tab(icon: Icon(Icons.favorite), text: '血压'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeightTab(),
          _buildWaterTab(),
          _buildSleepTab(),
          _buildBloodPressureTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildWeightTab() {
    return _buildRecordList(
      unit: 'kg',
      icon: Icons.monitor_weight,
      color: Colors.blue,
      valueKey: 'value1',
      hint: '记录每日体重变化',
    );
  }

  Widget _buildWaterTab() {
    return _buildRecordList(
      unit: 'ml',
      icon: Icons.water_drop,
      color: Colors.cyan,
      valueKey: 'value1',
      hint: '记录每日饮水量',
    );
  }

  Widget _buildSleepTab() {
    return _buildRecordList(
      unit: '小时',
      icon: Icons.bedtime,
      color: Colors.indigo,
      valueKey: 'value1',
      hint: '记录每日睡眠时长',
      formatter: (value) => value.toStringAsFixed(1),
    );
  }

  Widget _buildBloodPressureTab() {
    return _buildBPList();
  }

  Widget _buildRecordList({
    required String unit,
    required IconData icon,
    required Color color,
    required String valueKey,
    required String hint,
    String Function(double)? formatter,
  }) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无记录', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text(hint, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    // 计算平均值
    final values = _records.map((r) => r[valueKey] as double).toList();
    final avg = values.reduce((a, b) => a + b) / values.length;

    return Column(
      children: [
        // 统计卡片
        Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('记录次数', '${_records.length}', color),
                _buildStatItem('平均值', formatter?.call(avg) ?? avg.toStringAsFixed(1), color),
                _buildStatItem('最近', formatter?.call(values.first) ?? values.first.toStringAsFixed(1), color),
              ],
            ),
          ),
        ),
        // 记录列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _records.length,
            itemBuilder: (context, index) {
              final record = _records[index];
              final value = record[valueKey] as double;
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
                      backgroundColor: color,
                      child: Icon(icon, color: Colors.white),
                    ),
                    title: Text('${formatter?.call(value) ?? value.toStringAsFixed(1)} $unit'),
                    subtitle: Text(record['date']),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteRecord(record['id']),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBPList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('暂无记录', style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('记录每日血压', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _records.length,
      itemBuilder: (context, index) {
        final record = _records[index];
        final systolic = record['value1'] as double; // 收缩压
        final diastolic = record['value2'] as double; // 舒张压
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
                backgroundColor: Colors.red,
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              title: Text('${systolic.toInt()}/${diastolic.toInt()} mmHg'),
              subtitle: Text(record['date']),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteRecord(record['id']),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _deleteRecord(int id) async {
    await _db.deleteHealthRecord(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已删除')),
    );
  }

  Future<void> _showAddDialog() async {
    final tabIndex = _tabController.index;
    final type = ['weight', 'water', 'sleep', 'blood_pressure'][tabIndex];
    final titles = ['记录体重', '记录饮水', '记录睡眠', '记录血压'];
    final units = ['kg', 'ml', '小时', 'mmHg'];
    
    final value1Controller = TextEditingController();
    final value2Controller = TextEditingController();
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
              Text(titles[tabIndex], style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              // 数值输入
              TextField(
                controller: value1Controller,
                decoration: InputDecoration(
                  labelText: type == 'blood_pressure' ? '收缩压（高压）' : '数值',
                  suffixText: units[tabIndex],
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              
              // 血压需要第二个值
              if (type == 'blood_pressure') ...[
                TextField(
                  controller: value2Controller,
                  decoration: const InputDecoration(
                    labelText: '舒张压（低压）',
                    suffixText: 'mmHg',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),
              ],
              
              // 日期选择
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
                    final value1 = double.tryParse(value1Controller.text);
                    if (value1 == null || value1 <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入有效数值')),
                      );
                      return;
                    }
                    
                    double? value2;
                    if (type == 'blood_pressure') {
                      value2 = double.tryParse(value2Controller.text);
                      if (value2 == null || value2 <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效的舒张压')),
                        );
                        return;
                      }
                    }
                    
                    await _db.addHealthRecord({
                      'type': type,
                      'value1': value1,
                      'value2': value2,
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
