import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../../core/storage/app_database.dart';

/// 日程管理页面
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final AppDatabase _db = AppDatabase();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<Map<String, dynamic>> _schedules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final date = _dateFormat.format(_selectedDay ?? DateTime.now());
      final schedules = await _db.getSchedules(
        startDate: '$date 00:00:00',
        endDate: '$date 23:59:59',
      );
      
      setState(() {
        _schedules = schedules;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载日程失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日程'),
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = DateTime.now();
              });
              _loadData();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildCalendar(),
          _buildStatsBar(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _schedules.isEmpty
                    ? _buildEmptyState()
                    : _buildScheduleList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsBar() {
    final completed = _schedules.where((s) => s['isCompleted'] == 1).length;
    final total = _schedules.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: LinearProgressIndicator(
        value: total > 0 ? completed / total : 0,
        backgroundColor: Colors.grey[200],
        minHeight: 4,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无日程', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
      firstDay: DateTime.utc(2020, 1, 1),
      lastDay: DateTime.utc(2030, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _calendarFormat,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        _loadData();
      },
      onFormatChanged: (format) => setState(() => _calendarFormat = format),
    );
  }

  Widget _buildScheduleList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _schedules.length,
      itemBuilder: (context, index) {
        final schedule = _schedules[index];
        final isCompleted = schedule['isCompleted'] == 1;
        return _buildScheduleItem(schedule, isCompleted);
      },
    );
  }

  Widget _buildScheduleItem(Map<String, dynamic> schedule, bool isCompleted) {
    final startTime = DateTime.parse(schedule['startTime'] as String);
    final endTime = schedule['endTime'] != null
        ? DateTime.parse(schedule['endTime'] as String)
        : null;
    
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: isCompleted,
          onChanged: (value) => _toggleComplete(schedule['id'] as int, value!),
        ),
        title: Text(
          schedule['title'] as String,
          style: TextStyle(
            decoration: isCompleted ? TextDecoration.lineThrough : null,
            color: isCompleted ? Colors.grey : null,
          ),
        ),
        subtitle: Text(
          '${_timeFormat.format(startTime)}${endTime != null ? ' - ${_timeFormat.format(endTime)}' : ''}'
          '${schedule['description'] != null ? '\n${schedule['description']}' : ''}',
        ),
        isThreeLine: schedule['description'] != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (schedule['isAllDay'] == 1)
              const Chip(label: Text('全天'), padding: EdgeInsets.zero),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showAddDialog(schedule: schedule),
              tooltip: '编辑',
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () => _deleteSchedule(schedule['id'] as int),
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddDialog({Map<String, dynamic>? schedule}) async {
    final isEdit = schedule != null;
    final titleController = TextEditingController(text: schedule?['title'] ?? '');
    final descController = TextEditingController(text: schedule?['description'] ?? '');
    DateTime startTime = isEdit
        ? DateTime.parse(schedule['startTime'])
        : _selectedDay ?? DateTime.now();
    DateTime? endTime = isEdit && schedule['endTime'] != null
        ? DateTime.parse(schedule['endTime'])
        : null;
    bool isAllDay = schedule?['isAllDay'] == 1;

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
              Text(
                isEdit ? '编辑日程' : '添加日程',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: '标题',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('全天事件'),
                value: isAllDay,
                onChanged: (value) => setModalState(() => isAllDay = value),
              ),
              if (!isAllDay) ...[
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('开始时间'),
                  trailing: Text(_dateTimeFormat.format(startTime)),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: startTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time != null) {
                        setModalState(() {
                          startTime = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.access_time_filled),
                  title: const Text('结束时间'),
                  trailing: Text(endTime != null ? _dateTimeFormat.format(endTime!) : '无'),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: endTime ?? startTime,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (date != null) {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime ?? startTime),
                      );
                      if (time != null) {
                        setModalState(() {
                          endTime = DateTime(
                            date.year, date.month, date.day,
                            time.hour, time.minute,
                          );
                        });
                      }
                    }
                  },
                ),
              ],
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述（可选）',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (titleController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入标题')),
                      );
                      return;
                    }

                    final data = {
                      'title': titleController.text,
                      'description': descController.text.isNotEmpty ? descController.text : null,
                      'startTime': isAllDay
                          ? '${_dateFormat.format(startTime)} 00:00:00'
                          : _dateTimeFormat.format(startTime),
                      'endTime': endTime != null ? _dateTimeFormat.format(endTime!) : null,
                      'isAllDay': isAllDay ? 1 : 0,
                      'isCompleted': schedule != null ? schedule['isCompleted'] : 0,
                    };

                    if (isEdit) {
                      await _db.updateSchedule(schedule['id'] as int, data);
                    } else {
                      await _db.addSchedule(data);
                    }

                    Navigator.pop(context);
                    _loadData();
                  },
                  child: Text(isEdit ? '更新' : '保存'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleComplete(int id, bool completed) async {
    await _db.completeSchedule(id, completed);
    _loadData();
  }

  Future<void> _deleteSchedule(int id) async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这个日程吗？'),
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
    
    if (confirm == true) {
      await _db.deleteSchedule(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日程已删除')),
        );
      }
    }
  }
}