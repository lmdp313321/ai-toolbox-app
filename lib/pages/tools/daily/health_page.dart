import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/app_database.dart';

class HealthPage extends StatefulWidget {
  const HealthPage({super.key});

  @override
  State<HealthPage> createState() => _HealthPageState();
}

class _HealthPageState extends State<HealthPage> {
  final AppDatabase _db = AppDatabase();
  List<Map<String, dynamic>> _weightRecords = [];
  List<Map<String, dynamic>> _bpRecords = [];
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');
  bool _isLoading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      _weightRecords = await _db.getHealthRecords('weight');
      _bpRecords = await _db.getHealthRecords('blood_pressure');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载健康数据失败: $e')),
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
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                    ? _buildWeightTab()
                    : _buildBloodPressureTab(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildTabBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, '体重'),
          _buildTabItem(1, '血压'),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String text) {
    final isSelected = _selectedTab == index;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? null : Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  // ========== 体重 tab ==========
  Widget _buildWeightTab() {
    return Column(
      children: [
        _buildSummaryCard('weight'),
        Expanded(child: _buildWeightLineChart()),
      ],
    );
  }

  Widget _buildSummaryCard(String type) {
    final records = type == 'weight' ? _weightRecords : _bpRecords;
    if (records.isEmpty) return const SizedBox.shrink();
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(type == 'weight' ? '体重记录' : '血压记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [_buildLatestRecord(records), ..._buildStats(records, type)],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatestRecord(List<Map<String, dynamic>> records) {
    final record = records.first;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('最新记录', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '${record['value']}${record['unit'] ?? (record['type'] == 'weight' ? ' kg' : ' mmHg')}',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        ),
        Text(_dateFormat.format(DateTime.parse(record['createdAt']!))),
      ],
    );
  }

  List<Widget> _buildStats(List<Map<String, dynamic>> records, String type) {
    final values = records.map((r) => r['value'] as double).toList();
    final max = values.reduce((a, b) => a > b ? a : b);
    final min = values.reduce((a, b) => a < b ? a : b);
    final avg = values.reduce((a, b) => a + b) / values.length;
    
    return [
      _buildStatItem('最高', '$max${type == 'weight' ? ' kg' : ' mmHg'}'),
      _buildStatItem('最低', '$min${type == 'weight' ? ' kg' : ' mmHg'}'),
      _buildStatItem('平均', '${avg.toStringAsFixed(2)}${type == 'weight' ? ' kg' : ' mmHg'}'),
    ];
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    );
  }

  Widget _buildWeightLineChart() {
    if (_weightRecords.isEmpty) return _buildEmptyState('体重');
    
    final spots = _weightRecords.map((r) {
      final date = DateTime.parse(r['createdAt']!);
      final value = r['value'] as double;
      return FlSpot(date.millisecondsSinceEpoch.toDouble(), value);
    }).toList();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 32),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Text(_dateFormat.format(date).split(' ')[0]);
                },
                reservedSize: 24,
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              dotData: FlDotData(show: true),
              color: Theme.of(context).colorScheme.primary,
              belowBarData: BarAreaData(show: true, color: Theme.of(context).primaryColor.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }

  // ========== 血压 tab ==========
  Widget _buildBloodPressureTab() {
    return Column(
      children: [
        _buildSummaryCard('blood_pressure'),
        Expanded(child: _buildBloodPressureChart()),
      ],
    );
  }

  Widget _buildBloodPressureChart() {
    if (_bpRecords.isEmpty) return _buildEmptyState('血压');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bpRecords.length,
      itemBuilder: (context, index) => _buildBpItem(_bpRecords[index]),
    );
  }

  Widget _buildBpItem(Map<String, dynamic> record) {
    final values = (record['value'] as double).toString().split('|').map((s) => double.parse(s)).toList();
    
    return Card(
      child: ListTile(
        title: Row(
          children: [
            Text('${values[0]}/${values[1]} mmHg', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Chip(
              label: Text(
                values[0] > 120 || values[1] > 80 ? '偏高' : '正常',
                style: TextStyle(
                  color: values[0] > 120 || values[1] > 80 ? Colors.red : Colors.green,
                ),
              ),
              backgroundColor: values[0] > 120 || values[1] > 80 ? Colors.red[50] : Colors.green[50],
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(_dateFormat.format(DateTime.parse(record['createdAt']!))),
            if (record['note'] != null) ...[
              const SizedBox(height: 4),
              Text(record['note'] as String, style: TextStyle(color: Colors.grey[700])),
            ],
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _deleteRecord(record['id']),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String type) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(size: 72, Icons.monitor_weight, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无$type数据', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _showAddRecordDialog() async {
    final type = _selectedTab == 0 ? 'weight' : 'blood_pressure';
    final valueController = TextEditingController();
    final noteController = TextEditingController();
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
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(type == 'weight' ? '添加体重记录' : '添加血压记录', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 20),
            TextField(
              controller: valueController,
              decoration: InputDecoration(
                labelText: type == 'weight' ? '体重（kg）' : '血压（收缩压|舒张压，例：120|80）',
                hintText: type == 'weight' ? '60.5' : '120|80',
                border: const OutlineInputBorder(),
                prefixIcon: Icon(type == 'weight' ? Icons.fitness_center : Icons.favorite),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      double? value;
                      String? unit;
                      
                      if (type == 'weight') {
                        value = double.tryParse(valueController.text);
                        unit = 'kg';
                      } else if (type == 'blood_pressure') {
                        final parts = valueController.text.split('|');
                        try {
                          value = double.parse('${parts[0]}.${parts[1]}'); // 存储为 120.80
                        } catch (_) {
                          value = null;
                        }
                        unit = 'mmHg';
                      }
                      
                      if (value == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('请输入有效的数据格式')),
                        );
                        return;
                      }
                      
                      await _db.addHealthRecord({
                        'type': type,
                        'value': type == 'weight' ? value : valueController.text,
                        'unit': unit,
                        'note': noteController.text.isNotEmpty ? noteController.text : null,
                        'date': DateTime.now().toIso8601String(),
                      });
                      
                      Navigator.pop(context);
                      _loadData();
                    },
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRecord(int? id) async {
    if (id == null) return;
    
    await _db.deleteHealthRecord(id);
    _loadData();
  }
}