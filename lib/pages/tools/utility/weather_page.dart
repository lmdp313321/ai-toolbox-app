import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// 天气查询页面 - 实时天气和未来预报
class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final TextEditingController _cityController = TextEditingController();
  bool _isLoading = false;
  Map<String, dynamic>? _weatherData;
  String? _errorMessage;
  
  // 使用免费的天气API（和风天气或Seniverse需要key，这里使用备用方案）
  // 实际使用时需要替换为真实的天气API

  final List<Map<String, dynamic>> _mockCities = [
    {'name': '北京', 'temp': 22, 'weather': '晴', 'icon': Icons.wb_sunny, 'color': Colors.orange},
    {'name': '上海', 'temp': 25, 'weather': '多云', 'icon': Icons.wb_cloudy, 'color': Colors.grey},
    {'name': '广州', 'temp': 30, 'weather': '小雨', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'name': '深圳', 'temp': 29, 'weather': '阴', 'icon': Icons.cloud, 'color': Colors.grey},
    {'name': '杭州', 'temp': 24, 'weather': '晴', 'icon': Icons.wb_sunny, 'color': Colors.orange},
    {'name': '成都', 'temp': 20, 'weather': '多云', 'icon': Icons.wb_cloudy, 'color': Colors.grey},
  ];

  Future<void> _searchWeather() async {
    final city = _cityController.text.trim();
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 模拟API调用
    await Future.delayed(const Duration(seconds: 1));

    // 查找模拟数据
    final mockData = _mockCities.firstWhere(
      (c) => c['name'].contains(city) || city.contains(c['name']),
      orElse: () => {
        'name': city,
        'temp': 20 + (city.length % 15),
        'weather': ['晴', '多云', '阴', '小雨'][city.length % 4],
        'icon': Icons.wb_sunny,
        'color': Colors.orange,
      },
    );

    setState(() {
      _isLoading = false;
      _weatherData = {
        'city': mockData['name'],
        'temp': mockData['temp'],
        'weather': mockData['weather'],
        'icon': mockData['icon'],
        'color': mockData['color'],
        'humidity': 40 + (city.length % 40),
        'wind': '${(city.length % 5) + 1}级',
        'aqi': ['优', '良', '轻度污染'][city.length % 3],
        'forecast': List.generate(5, (index) => {
          'day': _getDayName(index),
          'tempHigh': mockData['temp'] + 3 - index,
          'tempLow': mockData['temp'] - 5 + index,
          'weather': ['晴', '多云', '阴', '小雨', '晴'][index],
        }),
      };
    });
  }

  String _getDayName(int index) {
    if (index == 0) return '今天';
    if (index == 1) return '明天';
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final now = DateTime.now();
    return weekdays[(now.weekday + index - 1) % 7];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('天气查询'),
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _cityController,
              decoration: InputDecoration(
                labelText: '输入城市名称',
                hintText: '例如：北京、上海',
                prefixIcon: const Icon(Icons.location_city),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchWeather,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _searchWeather(),
            ),
          ),

          // 快捷城市
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _mockCities.map((city) => ActionChip(
                avatar: Icon(city['icon'], size: 16, color: city['color']),
                label: Text(city['name']),
                onPressed: () {
                  _cityController.text = city['name'];
                  _searchWeather();
                },
              )).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // 天气内容
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _weatherData != null
                    ? _buildWeatherContent()
                    : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wb_sunny_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '输入城市查询天气',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            '支持全国主要城市',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherContent() {
    final data = _weatherData!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 当前天气卡片
          Card(
            color: data['color'].withOpacity(0.1),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    data['city'],
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        data['icon'],
                        size: 64,
                        color: data['color'],
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${data['temp']}°',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            data['weather'],
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildWeatherDetail('湿度', '${data['humidity']}%', Icons.water_drop),
                      _buildWeatherDetail('风力', data['wind'], Icons.air),
                      _buildWeatherDetail('空气质量', data['aqi'], Icons.eco),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // 未来预报
          const Text(
            '未来5天预报',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...List.generate(
            (data['forecast'] as List).length,
            (index) => _buildForecastItem(data['forecast'][index]),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherDetail(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildForecastItem(Map<String, dynamic> forecast) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: SizedBox(
          width: 60,
          child: Text(
            forecast['day'],
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Row(
          children: [
            Icon(
              forecast['weather'] == '晴' ? Icons.wb_sunny :
              forecast['weather'] == '多云' ? Icons.wb_cloudy :
              forecast['weather'] == '小雨' ? Icons.water_drop : Icons.cloud,
              color: Colors.orange,
            ),
            const SizedBox(width: 8),
            Text(forecast['weather']),
          ],
        ),
        trailing: Text(
          '${forecast['tempHigh']}° / ${forecast['tempLow']}°',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
