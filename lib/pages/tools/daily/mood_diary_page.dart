import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/app_database.dart';

/// 心情日记页面 - 情绪记录与统计（带图表）
class MoodDiaryPage extends StatefulWidget {
  const MoodDiaryPage({super.key});

  @override
  State<MoodDiaryPage> createState() => _MoodDiaryPageState();
}

class _MoodDiaryPageState extends State<MoodDiaryPage> {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _monthFormat = DateFormat('yyyy年MM月');
  final DateFormat _dayFormat = DateFormat('MM/dd');
  
  List<Map<String, dynamic>> _entries = [];
  bool _isLoading = true;
  DateTime _selectedMonth = DateTime.now();
  bool _showChart = true;
  
  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😄', 'label': '开心', 'color': Colors.amber, 'value': 5},
    {'emoji': '🙂', 'label': '不错', 'color': Colors.lightGreen, 'value': 4},
    {'emoji': '😐', 'label': '一般', 'color': Colors.grey, 'value': 3},
    {'emoji': '😔', 'label': '低落', 'color': Colors.blue, 'value': 2},
    {'emoji': '😢', 'label': '难过', 'color': Colors.indigo, 'value': 1},
    {'emoji': '😡', 'label': '生气', 'color': Colors.red, 'value': 0},
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
      
      _entries = await _db.getMoodEntries(
        startDate: _dateFormat.format(startDate),
        endDate: _dateFormat.format(endDate),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Map<String, int> _calculateMoodStats() {
    final stats = <String, int>{};
    for (final mood in _moods) {
      stats[mood['label'] as String] = 0;
    }
    for (final entry in _entries) {
      final moodLabel = entry['mood'] as String;
      stats[moodLabel] = (stats[moodLabel] ?? 0) + 1;
    }
    return stats;
  }

  double _getAverageMood() {
    if (_entries.isEmpty) return 0;
    double total = 0;
    for (final entry in _entries) {
      final mood = _moods.firstWhere(
        (m) => m['label'] == entry['mood'],
        orElse: () => _moods[2],
      );
      total += mood['value'] as double;
    }
    return total / _entries.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('心情日记'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.bar_chart : Icons.show_chart),
            onPressed: () => setState(() => _showChart = !_showChart),
            tooltip: _showChart ? '隐藏图表' : '显示图表',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMonthSelector(),
          if (_showChart && _entries.isNotEmpty) _buildMoodChart(),
          _buildStatsSection(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? _buildEmptyState()
                    : _buildEntryList(),
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

  Widget _buildMoodChart() {
    if (_entries.isEmpty) return const SizedBox.shrink();

    // 准备折线图数据
    final sortedEntries = List<Map<String, dynamic>>.from(_entries)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    final spots = <FlSpot>[];
    final dateLabels = <String>[];
    
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final mood = _moods.firstWhere(
        (m) => m['label'] == entry['mood'],
        orElse: () => _moods[2],
      );
      spots.add(FlSpot(i.toDouble(), mood['value'] as double));
      dateLabels.add(_dayFormat.format(DateTime.parse(entry['date'])));
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('心情趋势', style: Theme.of(context).textTheme.titleMedium),
                Text(
                  '平均: ${_getAverageMood().toStringAsFixed(1)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final emojis = {0: '😡', 1: '😢', 2: '😔', 3: '😐', 4: '🙂', 5: '😄'};
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(emojis[value.toInt()] ?? '', style: const TextStyle(fontSize: 16)),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: spots.length > 10 ? (spots.length / 5).ceil().toDouble() : 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= dateLabels.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              dateLabels[value.toInt()],
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.2,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.white,
                            strokeWidth: 2,
                            strokeColor: Colors.blue,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.blue.withOpacity(0.3),
                            Colors.blue.withOpacity(0.05),
                          ],
                        ),
                      ),
                    ),
                  ],
                  minY: 0,
                  maxY: 5,
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final entry = sortedEntries[spot.x.toInt()];
                          final mood = _moods.firstWhere(
                            (m) => m['label'] == entry['mood'],
                            orElse: () => _moods[2],
                          );
                          return LineTooltipItem(
                            '${mood['emoji']} ${entry['date']}',
                            const TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    if (_entries.isEmpty) return const SizedBox.shrink();
    
    final stats = _calculateMoodStats();
    final total = _entries.length;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('本月统计', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _moods.map((mood) {
                final count = stats[mood['label']] ?? 0;
                final percentage = total > 0 ? (count / total * 100).toInt() : 0;
                return Chip(
                  avatar: Text(mood['emoji'] as String, style: const TextStyle(fontSize: 16)),
                  label: Text('$count天'),
                  backgroundColor: (mood['color'] as Color).withOpacity(0.2),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            Text('共记录 $total 天 · 平均心情 ${_getAverageMood().toStringAsFixed(1)}', 
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('😊', style: TextStyle(fontSize: 64, color: Colors.grey[400])),
          const SizedBox(height: 16),
          Text('本月暂无记录', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角记录心情', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEntryList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _entries.length,
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final mood = _moods.firstWhere(
          (m) => m['label'] == entry['mood'],
          orElse: () => _moods[2],
        );
        
        return Dismissible(
          key: Key(entry['id'].toString()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteEntry(entry['id']),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: (mood['color'] as Color).withOpacity(0.2),
                child: Text(mood['emoji'] as String, style: const TextStyle(fontSize: 24)),
              ),
              title: Text('${mood['label']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry['note'] != null && entry['note'].isNotEmpty)
                    Text(entry['note'], maxLines: 2, overflow: TextOverflow.ellipsis),
                  Text(entry['date'], style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteEntry(entry['id']),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _deleteEntry(int id) async {
    await _db.deleteMoodEntry(id);
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('记录已删除')),
    );
  }

  Future<void> _showAddDialog() async {
    String selectedMood = _moods[2]['label'] as String;
    final noteController = TextEditingController();
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
              Text('记录心情', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              const Text('今天感觉如何？'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _moods.map((mood) {
                  final isSelected = selectedMood == mood['label'];
                  return GestureDetector(
                    onTap: () => setModalState(() => selectedMood = mood['label'] as String),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? (mood['color'] as Color).withOpacity(0.3) : null,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected ? Border.all(color: mood['color'] as Color, width: 2) : null,
                      ),
                      child: Column(
                        children: [
                          Text(mood['emoji'] as String, style: const TextStyle(fontSize: 32)),
                          Text(mood['label'] as String, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  labelText: '写点什么（可选）',
                  hintText: '今天发生了什么...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
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
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await _db.addMoodEntry({
                      'mood': selectedMood,
                      'note': noteController.text.isEmpty ? null : noteController.text,
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
