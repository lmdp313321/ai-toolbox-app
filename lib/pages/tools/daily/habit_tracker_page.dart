import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/storage/app_database.dart';

/// 习惯打卡页面 - 简化版（无动画依赖）
class HabitTrackerPage extends StatefulWidget {
  const HabitTrackerPage({super.key});

  @override
  State<HabitTrackerPage> createState() => _HabitTrackerPageState();
}

class _HabitTrackerPageState extends State<HabitTrackerPage> {
  final AppDatabase _db = AppDatabase();
  List<Map<String, dynamic>> _habits = [];
  bool _isLoading = true;
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _habits = await _db.getHabits();
      for (final habit in _habits) {
        final records = await _db.getHabitRecords(habit['id']);
        habit['records'] = records;
        habit['streak'] = await _db.getStreakDays(habit['id']);
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
    final today = _dateFormat.format(DateTime.now());
    final completedToday = _habits.where((h) {
      final records = h['records'] as List? ?? [];
      return records.any((r) => r['date'] == today && r['isCompleted'] == 1);
    }).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯打卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatsCard(completedToday),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _habits.isEmpty
                    ? _buildEmptyState()
                    : _buildHabitList(today),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsCard(int completedToday) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('今日完成', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text(
                    '$completedToday / ${_habits.length}',
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (_habits.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _checkInAll(),
                icon: const Icon(Icons.check_circle),
                label: const Text('一键打卡'),
              ),
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
          Icon(Icons.track_changes, size: 72, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无习惯', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
          const SizedBox(height: 8),
          const Text('点击右下角添加习惯', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildHabitList(String today) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _habits.length,
      itemBuilder: (context, index) => _buildHabitItem(_habits[index], today),
    );
  }

  Widget _buildHabitItem(Map<String, dynamic> habit, String today) {
    final records = habit['records'] as List? ?? [];
    final todayRecord = records.firstWhere(
      (r) => r['date'] == today,
      orElse: () => {'isCompleted': 0},
    );
    final isCompletedToday = todayRecord['isCompleted'] == 1;
    final streak = habit['streak'] ?? 0;

    return Dismissible(
      key: Key(habit['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteHabit(habit['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Checkbox(
            value: isCompletedToday,
            onChanged: (value) => _checkIn(habit['id'], today, value ?? false),
          ),
          title: Text(
            habit['name'] ?? '未命名习惯',
            style: TextStyle(
              decoration: isCompletedToday ? TextDecoration.lineThrough : null,
              color: isCompletedToday ? Colors.grey : null,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (streak > 0)
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: Colors.orange[600]),
                    const SizedBox(width: 4),
                    Text('连续 $streak 天', style: TextStyle(color: Colors.orange[600])),
                  ],
                ),
              const SizedBox(height: 4),
              _buildWeekIndicator(records),
            ],
          ),
          isThreeLine: true,
          onTap: () => _showAddDialog(habit: habit),
        ),
      ),
    );
  }

  Widget _buildWeekIndicator(List records) {
    final weekDays = List.generate(7, (i) {
      final date = DateTime.now().subtract(Duration(days: 6 - i));
      return _dateFormat.format(date);
    });

    return Row(
      children: weekDays.map((day) {
        final isCompleted = records.any((r) => r['date'] == day && r['isCompleted'] == 1);
        final isToday = day == _dateFormat.format(DateTime.now());
        
        return Expanded(
          child: Container(
            margin: const EdgeInsets.all(2),
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? Colors.green : (isToday ? Colors.blue[100] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(4),
              border: isToday ? Border.all(color: Colors.blue) : null,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    day.substring(8),
                    style: TextStyle(fontSize: 10, color: isToday ? Colors.blue : Colors.grey),
                  ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _checkIn(int habitId, String date, bool completed) async {
    await _db.checkInHabit(habitId, date, completed: completed);
    _loadData();
    
    if (completed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 打卡成功！继续保持！'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _checkInAll() async {
    final today = _dateFormat.format(DateTime.now());
    for (final habit in _habits) {
      final records = habit['records'] as List? ?? [];
      final isCompleted = records.any((r) => r['date'] == today && r['isCompleted'] == 1);
      if (!isCompleted) {
        await _db.checkInHabit(habit['id'], today, completed: true);
      }
    }
    _loadData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 全部打卡成功！')),
    );
  }

  Future<void> _showAddDialog({Map<String, dynamic>? habit}) async {
    final isEdit = habit != null;
    final nameController = TextEditingController(text: habit?['name'] ?? '');
    final descController = TextEditingController(text: habit?['description'] ?? '');

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? '编辑习惯' : '新建习惯'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '习惯名称',
                  hintText: '例如：早起、运动、阅读',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  hintText: '补充说明',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          if (isEdit)
            TextButton(
              onPressed: () async {
                await _db.deleteHabit(habit['id']);
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
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请输入习惯名称')),
                );
                return;
              }

              final data = {
                'name': nameController.text,
                'description': descController.text.isNotEmpty ? descController.text : null,
              };

              if (isEdit) {
                await _db.updateHabit(habit['id'], data);
              } else {
                await _db.addHabit(data);
              }

              Navigator.pop(context);
              _loadData();
            },
            child: Text(isEdit ? '更新' : '保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHabit(int id) async {
    await _db.deleteHabit(id);
    _loadData();
  }
}