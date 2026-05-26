import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';

/// 计算器页面 - 标准计算器，支持历史记录
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _display = '0';
  String _equation = '';
  double _firstOperand = 0;
  String _operator = '';
  bool _shouldResetDisplay = false;
  
  final List<String> _history = [];

  void _onNumberPressed(String number) {
    setState(() {
      if (_display == '0' || _shouldResetDisplay) {
        _display = number;
        _shouldResetDisplay = false;
      } else {
        _display += number;
      }
    });
  }

  void _onOperatorPressed(String operator) {
    setState(() {
      if (_operator.isNotEmpty && !_shouldResetDisplay) {
        _calculate();
      }
      _firstOperand = double.parse(_display);
      _operator = operator;
      _equation = '$_firstOperand ${_getOperatorSymbol(operator)}';
      _shouldResetDisplay = true;
    });
  }

  void _calculate() {
    if (_operator.isEmpty) return;

    final secondOperand = double.parse(_display);
    double result = 0;

    switch (_operator) {
      case '+':
        result = _firstOperand + secondOperand;
        break;
      case '-':
        result = _firstOperand - secondOperand;
        break;
      case '×':
        result = _firstOperand * secondOperand;
        break;
      case '÷':
        if (secondOperand == 0) {
          _showError();
          return;
        }
        result = _firstOperand / secondOperand;
        break;
      case '%':
        result = _firstOperand % secondOperand;
        break;
    }

    final equation = '$_firstOperand ${_getOperatorSymbol(_operator)} $secondOperand = ${result == result.toInt() ? result.toInt() : result}';
    
    setState(() {
      _history.insert(0, equation);
      if (_history.length > 20) _history.removeLast();
      
      _display = result == result.toInt() ? result.toInt().toString() : result.toString();
      _equation = '';
      _operator = '';
      _firstOperand = 0;
      _shouldResetDisplay = true;
    });
  }

  String _getOperatorSymbol(String op) {
    switch (op) {
      case '×': return '×';
      case '÷': return '÷';
      default: return op;
    }
  }

  void _showError() {
    setState(() {
      _display = 'Error';
      _shouldResetDisplay = true;
    });
  }

  void _onClear() {
    setState(() {
      _display = '0';
      _equation = '';
      _firstOperand = 0;
      _operator = '';
      _shouldResetDisplay = false;
    });
  }

  void _onBackspace() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  void _onDecimal() {
    setState(() {
      if (!_display.contains('.')) {
        _display += '.';
      }
    });
  }

  void _onSign() {
    setState(() {
      if (_display != '0') {
        if (_display.startsWith('-')) {
          _display = _display.substring(1);
        } else {
          _display = '-$_display';
        }
      }
    });
  }

  void _onPercent() {
    setState(() {
      final value = double.parse(_display);
      _display = (value / 100).toString();
    });
  }

  void _onSqrt() {
    setState(() {
      final value = double.parse(_display);
      if (value < 0) {
        _showError();
        return;
      }
      _display = sqrt(value).toString();
      _shouldResetDisplay = true;
    });
  }

  void _onSquare() {
    setState(() {
      final value = double.parse(_display);
      _display = (value * value).toString();
      _shouldResetDisplay = true;
    });
  }

  void _showHistory() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('计算历史', style: Theme.of(context).textTheme.titleMedium),
                TextButton(
                  onPressed: () {
                    setState(() => _history.clear());
                    Navigator.pop(context);
                  },
                  child: const Text('清空'),
                ),
              ],
            ),
            const Divider(),
            if (_history.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text('暂无历史记录', style: TextStyle(color: Colors.grey)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) => ListTile(
                    title: Text(_history[index]),
                    onTap: () {
                      final parts = _history[index].split(' = ');
                      if (parts.length == 2) {
                        setState(() => _display = parts[1]);
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
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
        title: const Text('计算器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // 显示屏
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (_equation.isNotEmpty)
                    Text(
                      _equation,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    _display,
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          
          // 键盘
          Expanded(
            flex: 5,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _buildButtonRow(['C', '⌫', '%', '÷'], isTopRow: true),
                  _buildButtonRow(['7', '8', '9', '×']),
                  _buildButtonRow(['4', '5', '6', '-']),
                  _buildButtonRow(['1', '2', '3', '+']),
                  _buildButtonRow(['√', '0', '.', '=']),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons, {bool isTopRow = false}) {
    return Expanded(
      child: Row(
        children: buttons.map((btn) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: _buildButton(btn, isTopRow: isTopRow),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildButton(String text, {bool isTopRow = false}) {
    Color? backgroundColor;
    Color? foregroundColor;

    if (text == 'C' || text == '⌫') {
      backgroundColor = Colors.red[100];
      foregroundColor = Colors.red;
    } else if (['÷', '×', '-', '+', '='].contains(text)) {
      backgroundColor = Theme.of(context).colorScheme.primary;
      foregroundColor = Theme.of(context).colorScheme.onPrimary;
    } else if (text == '%' || text == '√') {
      backgroundColor = Colors.orange[100];
      foregroundColor = Colors.orange;
    }

    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onPressed: () => _onButtonPressed(text),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: foregroundColor,
        ),
      ),
    );
  }

  void _onButtonPressed(String btn) {
    if (btn == 'C') {
      _onClear();
    } else if (btn == '⌫') {
      _onBackspace();
    } else if (btn == '.') {
      _onDecimal();
    } else if (btn == '=') {
      _calculate();
    } else if (['+', '-', '×', '÷', '%'].contains(btn)) {
      _onOperatorPressed(btn);
    } else if (btn == '√') {
      _onSqrt();
    } else {
      _onNumberPressed(btn);
    }
  }
}
