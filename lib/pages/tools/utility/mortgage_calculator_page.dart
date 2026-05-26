import 'dart:math';
import 'package:flutter/material.dart';

/// 房贷计算器 - 等额本息/等额本金
class MortgageCalculatorPage extends StatefulWidget {
  const MortgageCalculatorPage({super.key});

  @override
  State<MortgageCalculatorPage> createState() => _MortgageCalculatorPageState();
}

class _MortgageCalculatorPageState extends State<MortgageCalculatorPage> {
  // 输入参数
  double _loanAmount = 100; // 万元
  int _loanYears = 30;
  double _annualRate = 3.9; // 年利率%
  int _repaymentType = 0; // 0: 等额本息, 1: 等额本金

  // 计算结果
  Map<String, dynamic>? _result;

  void _calculate() {
    final principal = _loanAmount * 10000; // 转为元
    final months = _loanYears * 12;
    final monthlyRate = _annualRate / 100 / 12;

    if (_repaymentType == 0) {
      // 等额本息
      // 月供 = 贷款本金 × 月利率 × (1+月利率)^还款月数 / [(1+月利率)^还款月数 - 1]
      final powValue = pow(1 + monthlyRate, months);
      final monthlyPayment = principal * monthlyRate * powValue / (powValue - 1);
      final totalPayment = monthlyPayment * months;
      final totalInterest = totalPayment - principal;

      _result = {
        'monthlyPayment': monthlyPayment,
        'totalPayment': totalPayment,
        'totalInterest': totalInterest,
        'months': months,
        'type': '等额本息',
      };
    } else {
      // 等额本金
      // 每月还款 = 贷款本金/还款月数 + (贷款本金-累计已还本金) × 月利率
      final monthlyPrincipal = principal / months;
      final firstMonthPayment = monthlyPrincipal + principal * monthlyRate;
      final lastMonthPayment = monthlyPrincipal + monthlyPrincipal * monthlyRate;
      
      // 总利息 = (还款月数+1) × 贷款本金 × 月利率 / 2
      final totalInterest = (months + 1) * principal * monthlyRate / 2;
      final totalPayment = principal + totalInterest;

      _result = {
        'monthlyPrincipal': monthlyPrincipal,
        'firstMonthPayment': firstMonthPayment,
        'lastMonthPayment': lastMonthPayment,
        'totalPayment': totalPayment,
        'totalInterest': totalInterest,
        'months': months,
        'type': '等额本金',
      };
    }

    setState(() {});
  }

  String _formatMoney(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(2)}万';
    }
    return amount.toStringAsFixed(0);
  }

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('房贷计算器'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 贷款金额
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('贷款金额', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_loanAmount.toStringAsFixed(0)}万', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _loanAmount,
                      min: 10,
                      max: 1000,
                      divisions: 99,
                      label: '${_loanAmount.toStringAsFixed(0)}万',
                      onChanged: (v) {
                        setState(() {
                          _loanAmount = v;
                          _calculate();
                        });
                      },
                    ),
                    // 快捷按钮
                    Wrap(
                      spacing: 8,
                      children: [50, 100, 150, 200, 300].map((amount) => ActionChip(
                        label: Text('${amount}万'),
                        onPressed: () {
                          setState(() {
                            _loanAmount = amount.toDouble();
                            _calculate();
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 贷款年限
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('贷款年限', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('$_loanYears年', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _loanYears.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: '$_loanYears年',
                      onChanged: (v) {
                        setState(() {
                          _loanYears = v.toInt();
                          _calculate();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 年利率
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('年利率', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${_annualRate.toStringAsFixed(2)}%', 
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: _annualRate,
                      min: 2.0,
                      max: 6.0,
                      divisions: 80,
                      label: '${_annualRate.toStringAsFixed(2)}%',
                      onChanged: (v) {
                        setState(() {
                          _annualRate = v;
                          _calculate();
                        });
                      },
                    ),
                    // 快捷利率
                    Wrap(
                      spacing: 8,
                      children: [3.1, 3.3, 3.9, 4.2, 4.9].map((rate) => ActionChip(
                        label: Text('${rate}%'),
                        onPressed: () {
                          setState(() {
                            _annualRate = rate;
                            _calculate();
                          });
                        },
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 还款方式
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('还款方式', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SegmentedButton<int>(
                      segments: const [
                        ButtonSegment(
                          value: 0, 
                          label: Text('等额本息'),
                          tooltip: '每月还款额相同',
                        ),
                        ButtonSegment(
                          value: 1, 
                          label: Text('等额本金'),
                          tooltip: '每月本金相同，利息递减',
                        ),
                      ],
                      selected: {_repaymentType},
                      onSelectionChanged: (set) {
                        setState(() {
                          _repaymentType = set.first;
                          _calculate();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _repaymentType == 0 
                        ? '等额本息：每月还款金额固定，前期利息多，适合收入稳定者'
                        : '等额本金：每月还款递减，总利息较少，前期还款压力大',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 计算结果
            if (_result != null) ...[
              const Text('计算结果', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // 月供
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _repaymentType == 0 
                                ? '每月还款'
                                : '首月还款 / 末月还款',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _repaymentType == 0
                                ? '¥${_result!['monthlyPayment'].toStringAsFixed(0)}'
                                : '¥${_result!['firstMonthPayment'].toStringAsFixed(0)} / ¥${_result!['lastMonthPayment'].toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // 详细数据
                      Row(
                        children: [
                          Expanded(
                            child: _buildResultItem('贷款总额', '${_loanAmount.toStringAsFixed(0)}万'),
                          ),
                          Expanded(
                            child: _buildResultItem('支付利息', _formatMoney(_result!['totalInterest'])),
                          ),
                          Expanded(
                            child: _buildResultItem('还款总额', _formatMoney(_result!['totalPayment'])),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 对比
              _buildComparisonCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildComparisonCard() {
    // 计算另一种方式的对比
    final principal = _loanAmount * 10000;
    final months = _loanYears * 12;
    final monthlyRate = _annualRate / 100 / 12;

    double otherInterest;
    String otherType;

    if (_repaymentType == 0) {
      // 当前是等额本息，计算等额本金
      otherType = '等额本金';
      otherInterest = (months + 1) * principal * monthlyRate / 2;
    } else {
      // 当前是等额本金，计算等额本息
      otherType = '等额本息';
      final powValue = pow(1 + monthlyRate, months);
      final monthlyPayment = principal * monthlyRate * powValue / (powValue - 1);
      otherInterest = monthlyPayment * months - principal;
    }

    final interestDiff = _result!['totalInterest'] - otherInterest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('方式对比', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(_result!['type'], style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoney(_result!['totalInterest']),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.swap_horiz, color: Colors.grey),
                Expanded(
                  child: Column(
                    children: [
                      Text(otherType, style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        _formatMoney(otherInterest),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: interestDiff > 0 ? Colors.green[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    interestDiff > 0 ? Icons.savings : Icons.info,
                    size: 16,
                    color: interestDiff > 0 ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    interestDiff > 0
                      ? '${_result!['type']}比$otherType多付${_formatMoney(interestDiff.abs())}利息'
                      : '${_result!['type']}比$otherType节省${_formatMoney(interestDiff.abs())}利息',
                    style: TextStyle(
                      fontSize: 12,
                      color: interestDiff > 0 ? Colors.green[700] : Colors.orange[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
