import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/storage/app_database.dart';

/// 习惯打卡页面
class HabitPage extends StatefulWidget {
  const HabitPage({super.key});

  @override
  State<HabitPage> createState() => _HabitPageState();
}

class _HabitPageState extends State<HabitPage> {
  final _db = AppDatabase();
  List<Habit> _habits = [];
  DateTime _selectedDate = DateTime.now();

  // 预设习惯图标
  final Map<String, IconData> _habitIcons = {
    '喝水': Icons.water_drop,
    '运动': Icons.fitness_center,
    '阅读': Icons.book,
    '早起': Icons.wb_sunny,
    '早睡': Icons.bedtime,
    '冥想': Icons.self_improvement,
    '学习': Icons.school,
    '写作': Icons.edit,
    '音乐': Icons.music_note,
    '绘画': Icons.brush,
    '自定义': Icons.star,
  };

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final habits = await _db.getAllHabits();
    setState(() {
      _habits = habits;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('习惯打卡'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _habits.isEmpty ? _buildEmptyState() : _buildHabitList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('还没有习惯', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _showAddHabitDialog,
            child: const Text('创建习惯'),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitList() {
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _habits.length,
      itemBuilder: (context, index) {
        final habit = _habits[index];
        final isCompleted = habit.checkDates.contains(dateStr);
        return _buildHabitCard(habit, isCompleted, dateStr);
      },
    );
  }

  Widget _buildHabitCard(Habit habit, bool isCompleted, String dateStr) {
    final icon = _habitIcons[habit.icon] ?? Icons.star;
    final streak = _calculateStreak(habit);
    final totalDays = habit.checkDates.length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showHabitDetail(habit),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isCompleted ? Color(habit.color) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isCompleted ? Colors.white : Colors.grey,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              
              // 信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '连续 $streak 天 · 累计 $totalDays 次',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // 本周打卡情况
                    _buildWeekIndicator(habit),
                  ],
                ),
              ),
              
              // 打卡按钮
              Checkbox(
                value: isCompleted,
                onChanged: (value) => _toggleHabit(habit, dateStr, value!),
                activeColor: Color(habit.color),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 本周打卡指示器
  Widget _buildWeekIndicator(Habit habit) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    
    return Row(
      children: List.generate(7, (index) {
        final date = weekStart.add(Duration(days: index));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final isChecked = habit.checkDates.contains(dateStr);
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        
        return Container(
          width: 20,
          height: 20,
          margin: const EdgeInsets.only(right: 4),
          decoration: BoxDecoration(
            color: isChecked ? Color(habit.color) : Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: isToday ? Border.all(color: Color(habit.color), width: 2) : null,
          ),
          child: Center(
            child: Text(
              ['一', '二', '三', '四', '五', '六', '日'][index],
              style: TextStyle(
                fontSize: 9,
                color: isChecked ? Colors.white : Colors.grey,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 计算连续天数
  int _calculateStreak(Habit habit) {
    if (habit.checkDates.isEmpty) return 0;
    
    final sorted = habit.checkDates.toList()..sort();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    
    int streak = 0;
    DateTime? lastDate;
    
    // 从今天往前检查
    for (var i = sorted.length - 1; i >= 0; i--) {
      final parts = sorted[i].split('-');
      final date = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
      
      if (sorted[i] == todayStr) {
        streak = 1;
        lastDate = date;
      } else if (lastDate != null) {
        final expected = lastDate.subtract(const Duration(days: 1));
        if (date.year == expected.year && date.month == expected.month && date.day == expected.day) {
          streak++;
          lastDate = date;
        } else {
          break;
        }
      }
    }
    
    return streak;
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _toggleHabit(Habit habit, String dateStr, bool completed) async {
    final updatedDates = Set<String>.from(habit.checkDates);
    if (completed) {
      updatedDates.add(dateStr);
    } else {
      updatedDates.remove(dateStr);
    }
    
    final updated = Habit(
      id: habit.id,
      name: habit.name,
      icon: habit.icon,
      color: habit.color,
      reminderTime: habit.reminderTime,
      checkDates: updatedDates,
      createdAt: habit.createdAt,
    );
    
    await _db.updateHabit(updated);
    _loadHabits();
  }

  void _showAddHabitDialog() {
    showDialog(
      context: context,
      builder: (context) => AddHabitDialog(
        icons: _habitIcons,
        onSave: _loadHabits,
      ),
    );
  }

  void _showHabitDetail(Habit habit) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => HabitDetailSheet(
        habit: habit,
        icons: _habitIcons,
        onUpdate: _loadHabits,
      ),
    );
  }
}

/// 添加习惯对话框
class AddHabitDialog extends StatefulWidget {
  final Map<String, IconData> icons;
  final VoidCallback onSave;

  const AddHabitDialog({
    super.key,
    required this.icons,
    required this.onSave,
  });

  @override
  State<AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<AddHabitDialog> {
  final _nameController = TextEditingController();
  String _selectedIcon = '自定义';
  Color _selectedColor = Colors.blue;
  TimeOfDay? _reminderTime;

  final List<Color> _colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建习惯'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 名称
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '习惯名称',
                hintText: '例如：每天喝水8杯',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            
            // 图标选择
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('选择图标', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.icons.keys.map((name) {
                final isSelected = _selectedIcon == name;
                return ChoiceChip(
                  avatar: Icon(widget.icons[name], size: 18),
                  label: Text(name),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIcon = name),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // 颜色选择
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('选择颜色', style: TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colors.map((color) {
                final isSelected = _selectedColor == color;
                return InkWell(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected 
                          ? Border.all(color: Colors.white, width: 3)
                          : null,
                      boxShadow: isSelected
                          ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]
                          : null,
                    ),
                    child: isSelected 
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // 提醒时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('每日提醒'),
              subtitle: Text(_reminderTime?.format(context) ?? '未设置'),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _reminderTime ?? const TimeOfDay(hour: 9, 0),
                );
                if (picked != null) {
                  setState(() => _reminderTime = picked);
                }
              },
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
          child: const Text('创建'),
        ),
      ],
    );
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入习惯名称')),
      );
      return;
    }

    final db = AppDatabase();
    await db.insertHabit(Habit(
      name: _nameController.text.trim(),
      icon: _selectedIcon,
      color: _selectedColor.value,
      reminderTime: _reminderTime != null 
          ? '${_reminderTime!.hour.toString().padLeft(2, '0')}:${_reminderTime!.minute.toString().padLeft(2, '0')}'
          : null,
      checkDates: {},
      createdAt: DateTime.now().toIso8601String(),
    ));

    widget.onSave();
    Navigator.pop(context);
  }
}

/// 习惯详情
class HabitDetailSheet extends StatelessWidget {
  final Habit habit;
  final Map<String, IconData> icons;
  final VoidCallback onUpdate;

  const HabitDetailSheet({
    super.key,
    required this.habit,
    required this.icons,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // 标题栏
              AppBar(
                title: Text(habit.name),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteHabit(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              
              // 统计
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // 累计统计
                    _buildStatsCard(),
                    const SizedBox(height: 16),
                    
                    // 月度趋势图
                    _buildTrendChart(),
                    const SizedBox(height: 16),
                    
                    // 本月日历
                    _buildCalendar(),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard() {
    final now = DateTime.now();
    final thisMonth = habit.checkDates.where((d) {
      return d.startsWith('${now.year}-${now.month.toString().padLeft(2, '0')}');
    }).length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('累计打卡', '${habit.checkDates.length}天'),
            _buildStatItem('本月打卡', '$thisMonth天'),
            _buildStatItem('完成率', '${_calcCompletionRate()}%'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _calcCompletionRate() {
    if (habit.checkDates.isEmpty) return '0';
    
    final first = DateTime.parse(habit.checkDates.reduce((a, b) => a.compareTo(b) < 0 ? a : b));
    final days = DateTime.now().difference(first).inDays + 1;
    final rate = (habit.checkDates.length / days * 100).clamp(0, 100);
    return rate.toStringAsFixed(0);
  }

  Widget _buildTrendChart() {
    // 近7天数据
    final now = DateTime.now();
    final spots = <FlSpot>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final isChecked = habit.checkDates.contains(dateStr);
      spots.add(FlSpot((6 - i).toDouble(), isChecked ? 1 : 0));
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('近7天趋势', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minY: 0,
                  maxY: 1.2,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Color(habit.color),
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(habit.color).withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.month}月打卡', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(daysInMonth, (index) {
                final day = index + 1;
                final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final isChecked = habit.checkDates.contains(dateStr);
                
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isChecked ? Color(habit.color) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isChecked ? Colors.white : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteHabit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除习惯'),
        content: const Text('确定要删除这个习惯吗？所有打卡记录也将被删除。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final db = AppDatabase();
      await db.deleteHabit(habit.id!);
      onUpdate();
      Navigator.pop(context);
    }
  }
}
