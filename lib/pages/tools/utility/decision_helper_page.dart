import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';

/// 决策助手 - 随机选择、转盘、抽签模式
class DecisionHelperPage extends StatefulWidget {
  const DecisionHelperPage({super.key});

  @override
  State<DecisionHelperPage> createState() => _DecisionHelperPageState();
}

class _DecisionHelperPageState extends State<DecisionHelperPage> with SingleTickerProviderStateMixin {
  final TextEditingController _optionController = TextEditingController();
  final List<String> _options = [];
  final Random _random = Random();
  
  String? _selectedOption;
  bool _isSpinning = false;
  late AnimationController _animationController;
  
  // 预设模板
  final List<Map<String, dynamic>> _templates = [
    {'name': '今天吃什么', 'options': ['火锅', '烧烤', '麻辣烫', '汉堡', '寿司', ' pizza', '面条']},
    {'name': '周末去哪', 'options': ['公园', '商场', '电影院', '图书馆', '爬山', '在家']},
    {'name': '谁请客', 'options': ['我请', '你请', 'AA制', '石头剪刀布']},
    {'name': '是否做', 'options': ['做', '不做', '再想想']},
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _optionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _addOption() {
    final text = _optionController.text.trim();
    if (text.isEmpty) return;
    if (_options.contains(text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('该选项已存在')),
      );
      return;
    }
    setState(() {
      _options.add(text);
      _optionController.clear();
    });
  }

  void _removeOption(int index) {
    setState(() => _options.removeAt(index));
  }

  void _loadTemplate(List<String> options) {
    setState(() {
      _options.clear();
      _options.addAll(options);
      _selectedOption = null;
    });
  }

  Future<void> _startDecision() async {
    if (_options.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少添加2个选项')),
      );
      return;
    }

    setState(() => _isSpinning = true);
    
    // 模拟滚动效果
    for (int i = 0; i < 20; i++) {
      setState(() {
        _selectedOption = _options[_random.nextInt(_options.length)];
      });
      await Future.delayed(Duration(milliseconds: 50 + i * 10));
    }

    // 最终结果
    final result = _options[_random.nextInt(_options.length)];
    setState(() {
      _selectedOption = result;
      _isSpinning = false;
    });

    // 显示结果
    _showResultDialog(result);
  }

  void _showResultDialog(String result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Center(child: Text('🎉 决策结果')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.celebration,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '命运已经做出了选择！',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _startDecision();
            },
            child: const Text('再来一次'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('决策助手'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快速模板
            const Text('快速模板', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _templates.map((t) => ActionChip(
                avatar: const Icon(Icons.auto_awesome, size: 18),
                label: Text(t['name']),
                onPressed: () => _loadTemplate(List<String>.from(t['options'])),
              )).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // 添加选项
            const Text('添加选项', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optionController,
                    decoration: const InputDecoration(
                      hintText: '输入选项，例如：吃火锅',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _addOption(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _addOption,
                  child: const Icon(Icons.add),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 选项列表
            if (_options.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('共 ${_options.length} 个选项', style: TextStyle(color: Colors.grey[600])),
                  TextButton(
                    onPressed: () => setState(() => _options.clear()),
                    child: const Text('清空'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _options.asMap().entries.map((entry) {
                  final isSelected = _selectedOption == entry.value;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: Chip(
                      label: Text(
                        entry.value,
                        style: TextStyle(
                          color: isSelected ? Colors.white : null,
                          fontWeight: isSelected ? FontWeight.bold : null,
                        ),
                      ),
                      backgroundColor: isSelected ? Theme.of(context).colorScheme.primary : null,
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () => _removeOption(entry.key),
                    ),
                  );
                }).toList(),
              ),
            ],
            
            const SizedBox(height: 32),
            
            // 决策按钮
            if (_options.length >= 2)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                  onPressed: _isSpinning ? null : _startDecision,
                  child: _isSpinning
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _selectedOption ?? '决策中...',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ],
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.casino, size: 28),
                            SizedBox(width: 12),
                            Text(
                              '开始决策',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            
            // 备选方式：掷骰子
            if (_options.length >= 2 && _options.length <= 6) ...[
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  '或者试试掷骰子？',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              _buildDiceRoller(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiceRoller() {
    return Center(
      child: GestureDetector(
        onTap: () {
          final result = _random.nextInt(_options.length);
          _showResultDialog(_options[result]);
        },
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Icon(
            Icons.casino,
            size: 40,
            color: Colors.red,
          ),
        ),
      ),
    );
  }
}
