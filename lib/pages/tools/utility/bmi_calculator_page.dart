import 'package:flutter/material.dart';

/// BMI计算器 - 身体质量指数计算
class BmiCalculatorPage extends StatefulWidget {
  const BmiCalculatorPage({super.key});

  @override
  State<BmiCalculatorPage> createState() => _BmiCalculatorPageState();
}

class _BmiCalculatorPageState extends State<BmiCalculatorPage> {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  double? _bmi;
  String _category = '';
  Color _categoryColor = Colors.grey;
  double _height = 170;
  double _weight = 65;
  bool _useSlider = true;

  final List<Map<String, dynamic>> _bmiCategories = [
    {'min': 0, 'max': 18.5, 'name': '偏瘦', 'color': Colors.blue, 'advice': '建议适当增加营养摄入，加强锻炼'},
    {'min': 18.5, 'max': 24, 'name': '正常', 'color': Colors.green, 'advice': '保持良好的饮食和运动习惯'},
    {'min': 24, 'max': 28, 'name': '偏胖', 'color': Colors.orange, 'advice': '建议控制饮食，增加运动量'},
    {'min': 28, 'max': 100, 'name': '肥胖', 'color': Colors.red, 'advice': '建议咨询医生，制定减重计划'},
  ];

  @override
  void initState() {
    super.initState();
    _heightController.text = _height.toStringAsFixed(0);
    _weightController.text = _weight.toStringAsFixed(0);
    _calculateBmi();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _calculateBmi() {
    if (_height <= 0 || _weight <= 0) return;

    // BMI = 体重(kg) / 身高(m)²
    final heightInM = _height / 100;
    final bmi = _weight / (heightInM * heightInM);

    // 确定分类
    final category = _bmiCategories.firstWhere(
      (c) => bmi >= c['min'] && bmi < c['max'],
      orElse: () => _bmiCategories.last,
    );

    setState(() {
      _bmi = bmi;
      _category = category['name'];
      _categoryColor = category['color'];
    });
  }

  void _showDetailInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('BMI分类标准', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ..._bmiCategories.map((c) => ListTile(
              leading: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: c['color'],
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(c['name']),
              subtitle: Text('${c['min']} - ${c['max']}'),
              trailing: Text(c['advice'], style: const TextStyle(fontSize: 12)),
            )).toList(),
            const SizedBox(height: 16),
            Text(
              'BMI（身体质量指数）是国际上常用的衡量人体胖瘦程度以及是否健康的一个标准。',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BMI计算器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showDetailInfo,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 输入模式切换
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('滑块')),
                ButtonSegment(value: false, label: Text('数字')),
              ],
              selected: {_useSlider},
              onSelectionChanged: (set) => setState(() => _useSlider = set.first),
            ),
            
            const SizedBox(height: 24),
            
            // 身高输入
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('身高', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_height.toStringAsFixed(0)} cm', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_useSlider) ...[
                      const SizedBox(height: 8),
                      Slider(
                        value: _height,
                        min: 100,
                        max: 220,
                        divisions: 120,
                        label: '${_height.toStringAsFixed(0)} cm',
                        onChanged: (value) {
                          setState(() {
                            _height = value;
                            _heightController.text = value.toStringAsFixed(0);
                            _calculateBmi();
                          });
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _heightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: 'cm',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final h = double.tryParse(value);
                          if (h != null) {
                            setState(() {
                              _height = h;
                              _calculateBmi();
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 体重输入
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('体重', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_weight.toStringAsFixed(1)} kg', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_useSlider) ...[
                      const SizedBox(height: 8),
                      Slider(
                        value: _weight,
                        min: 30,
                        max: 150,
                        divisions: 240,
                        label: '${_weight.toStringAsFixed(1)} kg',
                        onChanged: (value) {
                          setState(() {
                            _weight = value;
                            _weightController.text = value.toStringAsFixed(1);
                            _calculateBmi();
                          });
                        },
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _weightController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          suffixText: 'kg',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final w = double.tryParse(value);
                          if (w != null) {
                            setState(() {
                              _weight = w;
                              _calculateBmi();
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // BMI结果
            Card(
              color: _categoryColor.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('您的BMI', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Text(
                      _bmi?.toStringAsFixed(1) ?? '--',
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: _categoryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _bmiCategories.firstWhere((c) => c['name'] == _category, 
                        orElse: () => _bmiCategories[1])['advice'],
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 健康建议
            if (_bmi != null) ...[
              const Text('健康建议', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAdviceItem(Icons.restaurant, '饮食建议', 
                        _category == '偏瘦' ? '增加蛋白质和碳水化合物摄入' :
                        _category == '正常' ? '保持均衡饮食，多吃蔬果' :
                        '控制热量摄入，减少油腻食物'),
                      const Divider(),
                      _buildAdviceItem(Icons.fitness_center, '运动建议',
                        _category == '偏瘦' ? '进行力量训练，增加肌肉量' :
                        _category == '正常' ? '保持规律运动，每周150分钟' :
                        '增加有氧运动，如跑步、游泳'),
                      const Divider(),
                      _buildAdviceItem(Icons.monitor_weight, '理想体重',
                        '您的理想体重范围：${((_height / 100) * (_height / 100) * 18.5).toStringAsFixed(1)} - ${((_height / 100) * (_height / 100) * 24).toStringAsFixed(1)} kg'),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdviceItem(IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(content, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      ],
    );
  }
}
