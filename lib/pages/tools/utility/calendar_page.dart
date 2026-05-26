import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 日历查询页面 - 万年历、节假日、农历显示
class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _selectedDate = DateTime.now();
  DateTime _currentMonth = DateTime.now();
  
  final DateFormat _monthFormat = DateFormat('yyyy年MM月');
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final List<String> _weekDays = ['日', '一', '二', '三', '四', '五', '六'];

  // 2025年节假日（简化版）
  final Map<String, String> _holidays2025 = {
    '2025-01-01': '元旦',
    '2025-01-28': '除夕',
    '2025-01-29': '春节',
    '2025-04-04': '清明节',
    '2025-05-01': '劳动节',
    '2025-05-31': '端午节',
    '2025-10-01': '国庆节',
    '2025-10-06': '中秋节',
  };

  void _previousMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1);
    });
  }

  void _selectDate(DateTime date) {
    setState(() => _selectedDate = date);
  }

  void _goToToday() {
    setState(() {
      _currentMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  List<DateTime?> _getDaysInMonth() {
    final firstDay = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDay = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    
    final daysBefore = firstDay.weekday % 7;
    final daysInMonth = lastDay.day;
    
    List<DateTime?> days = [];
    
    // 前一个月的空白
    for (int i = 0; i < daysBefore; i++) {
      days.add(null);
    }
    
    // 当月日期
    for (int i = 1; i <= daysInMonth; i++) {
      days.add(DateTime(_currentMonth.year, _currentMonth.month, i));
    }
    
    return days;
  }

  String? _getHoliday(DateTime date) {
    final key = _dateFormat.format(date);
    return _holidays2025[key];
  }

  int _getDayOfYear() {
    final startOfYear = DateTime(_selectedDate.year, 1, 1);
    return _selectedDate.difference(startOfYear).inDays + 1;
  }

  int _getWeekOfYear() {
    final startOfYear = DateTime(_selectedDate.year, 1, 1);
    final days = _selectedDate.difference(startOfYear).inDays;
    return (days / 7).ceil() + 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('日历'),
        actions: [
          TextButton(
            onPressed: _goToToday,
            child: const Text('今天', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 月份导航
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: _previousMonth,
                ),
                Text(
                  _monthFormat.format(_currentMonth),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          
          // 星期标题
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _weekDays.map((day) => Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: day == '日' || day == '六' ? Colors.red : Colors.grey[600],
                    ),
                  ),
                ),
              )).toList(),
            ),
          ),
          
          const Divider(),
          
          // 日历网格
          Expanded(
            child: GridView.count(
              crossAxisCount: 7,
              children: _getDaysInMonth().map((day) => _buildDayCell(day)).toList(),
            ),
          ),
          
          // 选中日期详情
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  _dateFormat.format(_selectedDate),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoItem('星期', '星期${_weekDays[_selectedDate.weekday % 7]}'),
                    _buildInfoItem('第几天', '${_getDayOfYear()}'),
                    _buildInfoItem('第几周', '${_getWeekOfYear()}'),
                  ],
                ),
                if (_getHoliday(_selectedDate) != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🎉 ${_getHoliday(_selectedDate)}',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayCell(DateTime? day) {
    if (day == null) return const SizedBox.shrink();

    final isToday = day.year == DateTime.now().year &&
                    day.month == DateTime.now().month &&
                    day.day == DateTime.now().day;
    final isSelected = day.year == _selectedDate.year &&
                       day.month == _selectedDate.month &&
                       day.day == _selectedDate.day;
    final isCurrentMonth = day.month == _currentMonth.month;
    final holiday = _getHoliday(day);
    final isWeekend = day.weekday == DateTime.saturday || day.weekday == DateTime.sunday;

    return GestureDetector(
      onTap: () => _selectDate(day),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : isToday 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : holiday != null
                        ? Colors.red
                        : isWeekend && !isToday
                            ? Colors.red[300]
                            : isCurrentMonth
                                ? Colors.black87
                                : Colors.grey[400],
              ),
            ),
            if (holiday != null)
              Text(
                holiday,
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Colors.red,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            else if (isToday)
              Text(
                '今天',
                style: TextStyle(
                  fontSize: 9,
                  color: isSelected ? Colors.white70 : Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
