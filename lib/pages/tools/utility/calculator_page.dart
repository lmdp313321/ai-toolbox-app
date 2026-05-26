import 'package:flutter/material.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _expression = '';
  double _num1 = 0;
  String _op = '';

  void _press(String key) {
    setState(() {
      if (key == 'C') {
        _display = '0';
        _expression = '';
        _num1 = 0;
        _op = '';
      } else if (key == '+' || key == '-' || key == '*' || key == '/') {
        _num1 = double.parse(_display);
        _op = key;
        _expression = '$_num1 $key';
        _display = '0';
      } else if (key == '=') {
        final num2 = double.parse(_display);
        double result = 0;
        switch (_op) {
          case '+': result = _num1 + num2; break;
          case '-': result = _num1 - num2; break;
          case '*': result = _num1 * num2; break;
          case '/': result = num2 != 0 ? _num1 / num2 : 0; break;
        }
        _display = result == result.roundToDouble() ? result.toInt().toString() : result.toStringAsFixed(2);
        _expression = '';
        _op = '';
      } else if (key == '.') {
        if (!_display.contains('.')) _display += '.';
      } else {
        if (_display == '0') _display = '';
        _display += key;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('计算器')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_expression, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text(_display, style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w300)),
                ],
              ),
            ),
          ),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildButtons() {
    const keys = [
      ['C', '+/-', '%', '/'],
      ['7', '8', '9', '*'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: keys.map((row) => Row(
          children: row.map((key) => Expanded(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: ElevatedButton(
                onPressed: () => _press(key),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: ['+', '-', '*', '/', '='].contains(key) ? Theme.of(context).colorScheme.primary : null,
                  foregroundColor: ['+', '-', '*', '/', '='].contains(key) ? Colors.white : null,
                ),
                child: Text(key, style: const TextStyle(fontSize: 20)),
              ),
            ),
          )).toList(),
        )).toList(),
      ),
    );
  }
}
