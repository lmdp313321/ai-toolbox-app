import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 随机数生成器 - 支持范围设置、批量生成、多种类型
class RandomNumberPage extends StatefulWidget {
  const RandomNumberPage({super.key});

  @override
  State<RandomNumberPage> createState() => _RandomNumberPageState();
}

class _RandomNumberPageState extends State<RandomNumberPage> {
  final Random _random = Random();
  
  // 设置参数
  final TextEditingController _minController = TextEditingController(text: '1');
  final TextEditingController _maxController = TextEditingController(text: '100');
  final TextEditingController _countController = TextEditingController(text: '1');
  
  // 结果
  List<int> _results = [];
  List<String> _history = [];
  
  // 选项
  bool _allowRepeat = true;
  bool _sortResults = false;
  bool _isGenerating = false;

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _generate() {
    final min = int.tryParse(_minController.text) ?? 1;
    final max = int.tryParse(_maxController.text) ?? 100;
    final count = int.tryParse(_countController.text) ?? 1;

    if (min >= max) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('最小值必须小于最大值')),
      );
      return;
    }

    if (!_allowRepeat && count > (max - min + 1)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('不重复模式下，生成数量不能大于数值范围')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    // 模拟生成动画
    Future.delayed(const Duration(milliseconds: 300), () {
      final List<int> numbers = [];
      final Set<int> used = {};

      for (int i = 0; i < count; i++) {
        int number;
        if (_allowRepeat) {
          number = min + _random.nextInt(max - min + 1);
        } else {
          do {
            number = min + _random.nextInt(max - min + 1);
          } while (used.contains(number));
          used.add(number);
        }
        numbers.add(number);
      }

      if (_sortResults) {
        numbers.sort();
      }

      setState(() {
        _results = numbers;
        _isGenerating = false;
        
        final resultStr = numbers.join(', ');
        _history.insert(0, '$min-$max: $resultStr');
        if (_history.length > 20) _history.removeLast();
      });
    });
  }

  void _copyResults() {
    if (_results.isEmpty) return;
    final text = _results.join(', ');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  void _quickPreset(int min, int max) {
    setState(() {
      _minController.text = min.toString();
      _maxController.text = max.toString();
      _countController.text = '1';
    });
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('随机数'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 快捷预设
            const Text('快捷预设', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip('掷骰子', 1, 6),
                _buildPresetChip('硬币', 0, 1),
                _buildPresetChip('1-10', 1, 10),
                _buildPresetChip('1-100', 1, 100),
                _buildPresetChip('双色球', 1, 33),
                _buildPresetChip('大乐透', 1, 35),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 设置区域
            const Text('参数设置', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    decoration: const InputDecoration(
                      labelText: '最小值',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text('~', style: TextStyle(fontSize: 24)),
                ),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    decoration: const InputDecoration(
                      labelText: '最大值',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            TextField(
              controller: _countController,
              decoration: const InputDecoration(
                labelText: '生成数量',
                border: OutlineInputBorder(),
                helperText: '一次生成多少个随机数',
              ),
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // 选项
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('允许重复', style: TextStyle(fontSize: 14)),
                    value: _allowRepeat,
                    onChanged: (v) => setState(() => _allowRepeat = v!),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('自动排序', style: TextStyle(fontSize: 14)),
                    value: _sortResults,
                    onChanged: (v) => setState(() => _sortResults = v!),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton(
                onPressed: _isGenerating ? null : _generate,
                child: _isGenerating
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('生成随机数', style: TextStyle(fontSize: 18)),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // 结果显示
            if (_results.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('生成结果', style: TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: _copyResults,
                    tooltip: '复制结果',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: _results.map((n) => _buildResultNumber(n)).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int min, int max) {
    return ActionChip(
      avatar: const Icon(Icons.casino, size: 18),
      label: Text(label),
      onPressed: () => _quickPreset(min, max),
    );
  }

  Widget _buildResultNumber(int number) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        number.toString(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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
                Text('历史记录', style: Theme.of(context).textTheme.titleMedium),
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
                    leading: CircleAvatar(
                      child: Text('${index + 1}'),
                    ),
                    title: Text(_history[index]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
