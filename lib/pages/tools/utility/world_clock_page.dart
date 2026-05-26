import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// 世界时钟页面 - 多时区时钟显示
class WorldClockPage extends StatefulWidget {
  const WorldClockPage({super.key});

  @override
  State<WorldClockPage> createState() => _WorldClockPageState();
}

class _WorldClockPageState extends State<WorldClockPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();
  
  final List<Map<String, dynamic>> _cities = [
    {'name': '北京', 'timezone': 'Asia/Shanghai', 'flag': '🇨🇳'},
    {'name': '东京', 'timezone': 'Asia/Tokyo', 'flag': '🇯🇵'},
    {'name': '伦敦', 'timezone': 'Europe/London', 'flag': '🇬🇧'},
    {'name': '纽约', 'timezone': 'America/New_York', 'flag': '🇺🇸'},
    {'name': '巴黎', 'timezone': 'Europe/Paris', 'flag': '🇫🇷'},
    {'name': '悉尼', 'timezone': 'Australia/Sydney', 'flag': '🇦🇺'},
    {'name': '莫斯科', 'timezone': 'Europe/Moscow', 'flag': '🇷🇺'},
    {'name': '迪拜', 'timezone': 'Asia/Dubai', 'flag': '🇦🇪'},
    {'name': '新加坡', 'timezone': 'Asia/Singapore', 'flag': '🇸🇬'},
    {'name': '洛杉矶', 'timezone': 'America/Los_Angeles', 'flag': '🇺🇸'},
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  DateTime _getCityTime(String timezone) {
    // 简化的时区计算
    final utc = _now.toUtc();
    final offset = _getTimezoneOffset(timezone);
    return utc.add(Duration(hours: offset));
  }

  int _getTimezoneOffset(String timezone) {
    final offsets = {
      'Asia/Shanghai': 8,
      'Asia/Tokyo': 9,
      'Europe/London': 0,
      'America/New_York': -5,
      'Europe/Paris': 1,
      'Australia/Sydney': 11,
      'Europe/Moscow': 3,
      'Asia/Dubai': 4,
      'Asia/Singapore': 8,
      'America/Los_Angeles': -8,
    };
    return offsets[timezone] ?? 0;
  }

  String _getTimeDifference(String timezone) {
    final offset = _getTimezoneOffset(timezone);
    final localOffset = 8; // 假设本地是北京时间
    final diff = offset - localOffset;
    
    if (diff == 0) return '同城';
    if (diff > 0) return '+$diff小时';
    return '$diff小时';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('世界时钟'),
        actions: [
          TextButton(
            onPressed: () => _showAddCityDialog(),
            child: const Text('添加', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _cities.length,
        itemBuilder: (context, index) => _buildClockCard(_cities[index]),
      ),
    );
  }

  Widget _buildClockCard(Map<String, dynamic> city) {
    final cityTime = _getCityTime(city['timezone']);
    final timeFormat = DateFormat('HH:mm');
    final dateFormat = DateFormat('MM-dd EEE');
    final isNight = cityTime.hour < 6 || cityTime.hour >= 18;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 国旗/图标
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isNight ? Colors.indigo[900] : Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  city['flag'],
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // 城市信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    city['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateFormat.format(cityTime),
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTimeDifference(city['timezone']),
                    style: TextStyle(
                      fontSize: 12,
                      color: _getTimeDifference(city['timezone']) == '同城' 
                          ? Colors.green 
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // 时间显示
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  timeFormat.format(cityTime),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isNight ? Icons.nightlight_round : Icons.wb_sunny,
                      size: 16,
                      color: isNight ? Colors.indigo : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isNight ? '夜晚' : '白天',
                      style: TextStyle(
                        fontSize: 12,
                        color: isNight ? Colors.indigo : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCityDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('添加城市', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('功能开发中...', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('关闭'),
            ),
          ],
        ),
      ),
    );
  }
}
