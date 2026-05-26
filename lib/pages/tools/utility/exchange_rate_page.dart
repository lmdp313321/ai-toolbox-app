import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 汇率换算页面 - 多币种汇率换算
class ExchangeRatePage extends StatefulWidget {
  const ExchangeRatePage({super.key});

  @override
  State<ExchangeRatePage> createState() => _ExchangeRatePageState();
}

class _ExchangeRatePageState extends State<ExchangeRatePage> {
  // 货币定义（相对于CNY的汇率）
  final List<Map<String, dynamic>> _currencies = [
    {'code': 'CNY', 'name': '人民币', 'symbol': '¥', 'rate': 1.0, 'flag': '🇨🇳'},
    {'code': 'USD', 'name': '美元', 'symbol': '\$', 'rate': 7.25, 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': '欧元', 'symbol': '€', 'rate': 7.85, 'flag': '🇪🇺'},
    {'code': 'JPY', 'name': '日元', 'symbol': '¥', 'rate': 0.048, 'flag': '🇯🇵'},
    {'code': 'GBP', 'name': '英镑', 'symbol': '£', 'rate': 9.15, 'flag': '🇬🇧'},
    {'code': 'HKD', 'name': '港币', 'symbol': '\$', 'rate': 0.93, 'flag': '🇭🇰'},
    {'code': 'KRW', 'name': '韩元', 'symbol': '₩', 'rate': 0.0054, 'flag': '🇰🇷'},
    {'code': 'AUD', 'name': '澳元', 'symbol': '\$', 'rate': 4.75, 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': '加元', 'symbol': '\$', 'rate': 5.35, 'flag': '🇨🇦'},
    {'code': 'SGD', 'name': '新加坡元', 'symbol': '\$', 'rate': 5.4, 'flag': '🇸🇬'},
    {'code': 'CHF', 'name': '瑞士法郎', 'symbol': 'Fr', 'rate': 8.2, 'flag': '🇨🇭'},
    {'code': 'THB', 'name': '泰铢', 'symbol': '฿', 'rate': 0.2, 'flag': '🇹🇭'},
  ];

  String _fromCurrency = 'CNY';
  String _toCurrency = 'USD';
  String _inputAmount = '100';
  double _result = 0;
  DateTime _lastUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final fromRate = _currencies.firstWhere((c) => c['code'] == _fromCurrency)['rate'];
    final toRate = _currencies.firstWhere((c) => c['code'] == _toCurrency)['rate'];
    final amount = double.tryParse(_inputAmount) ?? 0;
    
    // 换算：先转为CNY，再转为目标货币
    setState(() {
      _result = amount * fromRate / toRate;
    });
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
      _calculate();
    });
  }

  void _showCurrencyPicker(bool isFrom) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isFrom ? '选择原货币' : '选择目标货币',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _currencies.length,
                itemBuilder: (context, index) {
                  final currency = _currencies[index];
                  final isSelected = isFrom 
                      ? currency['code'] == _fromCurrency
                      : currency['code'] == _toCurrency;
                  
                  return ListTile(
                    leading: Text(currency['flag'], style: const TextStyle(fontSize: 24)),
                    title: Text(currency['name']),
                    subtitle: Text('${currency['code']} - ${currency['symbol']}'),
                    trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      setState(() {
                        if (isFrom) {
                          _fromCurrency = currency['code'];
                        } else {
                          _toCurrency = currency['code'];
                        }
                        _calculate();
                      });
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fromCurrency = _currencies.firstWhere((c) => c['code'] == _fromCurrency);
    final toCurrency = _currencies.firstWhere((c) => c['code'] == _toCurrency);

    return Scaffold(
      appBar: AppBar(
        title: const Text('汇率换算'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 更新时间提示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '汇率仅供参考，交易请以银行实际牌价为准\n更新于 ${_lastUpdate.hour}:${_lastUpdate.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 输入金额
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('输入金额', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: TextEditingController(text: _inputAmount),
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            fromCurrency['symbol'],
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        _inputAmount = value;
                        _calculate();
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 货币选择
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // 原货币
                    ListTile(
                      leading: Text(fromCurrency['flag'], style: const TextStyle(fontSize: 32)),
                      title: Text(fromCurrency['name']),
                      subtitle: Text(fromCurrency['code']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showCurrencyPicker(true),
                    ),
                    
                    // 交换按钮
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.swap_vert),
                        onPressed: _swapCurrencies,
                      ),
                    ),
                    
                    // 目标货币
                    ListTile(
                      leading: Text(toCurrency['flag'], style: const TextStyle(fontSize: 32)),
                      title: Text(toCurrency['name']),
                      subtitle: Text(toCurrency['code']),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showCurrencyPicker(false),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 结果
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('换算结果', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          toCurrency['symbol'],
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _result.toStringAsFixed(2),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1 ${fromCurrency['code']} ≈ ${(fromCurrency['rate'] / toCurrency['rate']).toStringAsFixed(4)} ${toCurrency['code']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 常用汇率表
            const Text('常用汇率参考', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 5,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final currency = _currencies[index + 1];
                  return ListTile(
                    dense: true,
                    leading: Text(currency['flag'], style: const TextStyle(fontSize: 20)),
                    title: Text(currency['name']),
                    trailing: Text(
                      '100 ${currency['code']} = ${(100 * currency['rate']).toStringAsFixed(2)} CNY',
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
