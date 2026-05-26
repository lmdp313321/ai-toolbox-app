import 'package:flutter/material.dart';

/// 单位换算页面 - 支持长度、重量、温度、面积、体积、速度等多种单位
class UnitConvertPage extends StatefulWidget {
  const UnitConvertPage({super.key});

  @override
  State<UnitConvertPage> createState() => _UnitConvertPageState();
}

class _UnitConvertPageState extends State<UnitConvertPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 当前选中的分类
  final List<Map<String, dynamic>> _categories = [
    {'name': '长度', 'icon': Icons.straighten},
    {'name': '重量', 'icon': Icons.scale},
    {'name': '温度', 'icon': Icons.thermostat},
    {'name': '面积', 'icon': Icons.crop_square},
    {'name': '体积', 'icon': Icons.invert_colors},
    {'name': '速度', 'icon': Icons.speed},
  ];

  // 单位定义
  final Map<String, List<Map<String, dynamic>>> _units = {
    '长度': [
      {'name': '米', 'symbol': 'm', 'rate': 1.0},
      {'name': '千米', 'symbol': 'km', 'rate': 1000.0},
      {'name': '厘米', 'symbol': 'cm', 'rate': 0.01},
      {'name': '毫米', 'symbol': 'mm', 'rate': 0.001},
      {'name': '英寸', 'symbol': 'in', 'rate': 0.0254},
      {'name': '英尺', 'symbol': 'ft', 'rate': 0.3048},
      {'name': '码', 'symbol': 'yd', 'rate': 0.9144},
      {'name': '里', 'symbol': 'li', 'rate': 500.0},
    ],
    '重量': [
      {'name': '千克', 'symbol': 'kg', 'rate': 1.0},
      {'name': '克', 'symbol': 'g', 'rate': 0.001},
      {'name': '毫克', 'symbol': 'mg', 'rate': 0.000001},
      {'name': '吨', 'symbol': 't', 'rate': 1000.0},
      {'name': '磅', 'symbol': 'lb', 'rate': 0.453592},
      {'name': '盎司', 'symbol': 'oz', 'rate': 0.0283495},
      {'name': '斤', 'symbol': 'jin', 'rate': 0.5},
      {'name': '两', 'symbol': 'liang', 'rate': 0.05},
    ],
    '温度': [
      {'name': '摄氏度', 'symbol': '°C', 'type': 'celsius'},
      {'name': '华氏度', 'symbol': '°F', 'type': 'fahrenheit'},
      {'name': '开尔文', 'symbol': 'K', 'type': 'kelvin'},
    ],
    '面积': [
      {'name': '平方米', 'symbol': 'm²', 'rate': 1.0},
      {'name': '平方千米', 'symbol': 'km²', 'rate': 1000000.0},
      {'name': '公顷', 'symbol': 'ha', 'rate': 10000.0},
      {'name': '亩', 'symbol': 'mu', 'rate': 666.667},
      {'name': '平方英尺', 'symbol': 'ft²', 'rate': 0.092903},
      {'name': '平方英寸', 'symbol': 'in²', 'rate': 0.00064516},
    ],
    '体积': [
      {'name': '升', 'symbol': 'L', 'rate': 1.0},
      {'name': '毫升', 'symbol': 'mL', 'rate': 0.001},
      {'name': '立方米', 'symbol': 'm³', 'rate': 1000.0},
      {'name': '加仑(美)', 'symbol': 'gal', 'rate': 3.78541},
      {'name': '夸脱', 'symbol': 'qt', 'rate': 0.946353},
      {'name': '品脱', 'symbol': 'pt', 'rate': 0.473176},
    ],
    '速度': [
      {'name': '米/秒', 'symbol': 'm/s', 'rate': 1.0},
      {'name': '千米/时', 'symbol': 'km/h', 'rate': 0.277778},
      {'name': '英里/时', 'symbol': 'mph', 'rate': 0.44704},
      {'name': '节', 'symbol': 'kn', 'rate': 0.514444},
      {'name': '马赫', 'symbol': 'Mach', 'rate': 340.3},
    ],
  };

  String _inputValue = '1';
  String _fromUnit = '';
  String _toUnit = '';
  String _result = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(_onTabChanged);
    _initUnits();
  }

  void _initUnits() {
    final category = _categories[0]['name'];
    final units = _units[category]!;
    _fromUnit = units[0]['name'];
    _toUnit = units[1]['name'];
    _calculate();
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      final category = _categories[_tabController.index]['name'];
      final units = _units[category]!;
      setState(() {
        _fromUnit = units[0]['name'];
        _toUnit = units[1]['name'];
        _calculate();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _calculate() {
    final category = _categories[_tabController.index]['name'];
    final units = _units[category]!;
    
    double input;
    try {
      input = double.parse(_inputValue);
    } catch (e) {
      setState(() => _result = '');
      return;
    }

    double result;

    if (category == '温度') {
      result = _convertTemperature(input, _fromUnit, _toUnit);
    } else {
      final fromRate = units.firstWhere((u) => u['name'] == _fromUnit)['rate'];
      final toRate = units.firstWhere((u) => u['name'] == _toUnit)['rate'];
      result = input * fromRate / toRate;
    }

    setState(() {
      if (result == result.toInt().toDouble()) {
        _result = result.toInt().toString();
      } else {
        _result = result.toStringAsFixed(6).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
      }
    });
  }

  double _convertTemperature(double value, String from, String to) {
    if (from == to) return value;

    // 先转为摄氏度
    double celsius;
    switch (from) {
      case '摄氏度':
        celsius = value;
        break;
      case '华氏度':
        celsius = (value - 32) * 5 / 9;
        break;
      case '开尔文':
        celsius = value - 273.15;
        break;
      default:
        celsius = value;
    }

    // 再转为目标单位
    switch (to) {
      case '摄氏度':
        return celsius;
      case '华氏度':
        return celsius * 9 / 5 + 32;
      case '开尔文':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  void _swapUnits() {
    setState(() {
      final temp = _fromUnit;
      _fromUnit = _toUnit;
      _toUnit = temp;
      _calculate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('单位换算'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((c) => Tab(
            icon: Icon(c['icon'] as IconData),
            text: c['name'] as String,
          )).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((c) => _buildConvertTab(c['name'] as String)).toList(),
      ),
    );
  }

  Widget _buildConvertTab(String category) {
    final units = _units[category]!;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 输入区域
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('输入数值', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: TextEditingController(text: _inputValue),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '输入数值',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _inputValue = '';
                            _result = '';
                          });
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      _inputValue = value;
                      _calculate();
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 单位选择
          Row(
            children: [
              Expanded(
                child: _buildUnitDropdown('从', _fromUnit, units, (value) {
                  setState(() {
                    _fromUnit = value!;
                    _calculate();
                  });
                }),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: _swapUnits,
              ),
              Expanded(
                child: _buildUnitDropdown('到', _toUnit, units, (value) {
                  setState(() {
                    _toUnit = value!;
                    _calculate();
                  });
                }),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 结果区域
          Card(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('换算结果', style: TextStyle(fontSize: 14, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SelectableText(
                    _result.isEmpty ? '-' : _result,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  if (_result.isNotEmpty)
                    Text(
                      units.firstWhere((u) => u['name'] == _toUnit)['symbol'] ?? '',
                      style: TextStyle(
                        fontSize: 18,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const Spacer(),
          
          // 快捷数字键盘
          _buildNumberPad(),
        ],
      ),
    );
  }

  Widget _buildUnitDropdown(String label, String value, List<Map<String, dynamic>> units, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          value: value,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: units.map((u) => DropdownMenuItem<String>(
            value: u['name'] as String,
            child: Text('${u['name']} (${u['symbol'] ?? u['type'] ?? ''})'),
          )).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildNumberPad() {
    final buttons = [
      ['7', '8', '9'],
      ['4', '5', '6'],
      ['1', '2', '3'],
      ['.', '0', '⌫'],
    ];

    return Column(
      children: buttons.map((row) => Row(
        children: row.map((btn) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => _onNumberPadPressed(btn),
              child: Text(
                btn,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        )).toList(),
      )).toList(),
    );
  }

  void _onNumberPadPressed(String btn) {
    if (btn == '⌫') {
      if (_inputValue.isNotEmpty) {
        setState(() {
          _inputValue = _inputValue.substring(0, _inputValue.length - 1);
          if (_inputValue.isEmpty) _inputValue = '0';
          _calculate();
        });
      }
    } else if (btn == '.') {
      if (!_inputValue.contains('.')) {
        setState(() {
          _inputValue += '.';
          _calculate();
        });
      }
    } else {
      setState(() {
        if (_inputValue == '0') {
          _inputValue = btn;
        } else {
          _inputValue += btn;
        }
        _calculate();
      });
    }
  }
}
