import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/storage/app_database.dart';

/// 倒计时页面 - 多个倒计时，支持暂停/继续
class CountdownPage extends StatefulWidget {
  const CountdownPage({super.key});

  @override
  State<CountdownPage> createState() => _CountdownPageState();
}

class _CountdownPageState extends State<CountdownPage> {
  final AppDatabase _db = AppDatabase();
  final List<Map<String, dynamic>> _timers = [];
  Timer? _tickTimer;
  
  @override
  void initState() {
    super.initState();
    _loadTimers();
    // 每秒刷新一次
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }

  void _tick() {
    setState(() {
      for (var timer in _timers) {
        if (timer['isRunning'] && timer['remainingSeconds'] > 0) {
          timer['remainingSeconds']--;
          if (timer['remainingSeconds'] == 0) {
            timer['isRunning'] = false;
            _showTimerComplete(timer);
          }
        }
      }
    });
  }

  Future<void> _loadTimers() async {
    final timers = await _db.getCountdowns();
    setState(() {
      _timers.clear();
      _timers.addAll(timers.map((t) => {
        ...t,
        'remainingSeconds': t['duration'],
        'isRunning': false,
      }));
    });
  }

  void _showTimerComplete(Map<String, dynamic> timer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⏰ 时间到！'),
        content: Text('"${timer['name']}" 倒计时结束'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTimer(timer);
            },
            child: const Text('重新开始'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _restartTimer(Map<String, dynamic> timer) {
    setState(() {
      timer['remainingSeconds'] = timer['duration'];
      timer['isRunning'] = true;
    });
  }

  void _toggleTimer(Map<String, dynamic> timer) {
    setState(() {
      timer['isRunning'] = !timer['isRunning'];
    });
  }

  void _resetTimer(Map<String, dynamic> timer) {
    setState(() {
      timer['remainingSeconds'] = timer['duration'];
      timer['isRunning'] = false;
    });
  }

  Future<void> _deleteTimer(int id) async {
    await _db.deleteCountdown(id);
    _loadTimers();
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('倒计时'),
      ),
      body: _timers.isEmpty ? _buildEmptyState() : _buildTimerList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTimerDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.timer, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('暂无倒计时', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('点击右下角添加', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildTimerList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _timers.length,
      itemBuilder: (context, index) => _buildTimerCard(_timers[index]),
    );
  }

  Widget _buildTimerCard(Map<String, dynamic> timer) {
    final progress = timer['remainingSeconds'] / timer['duration'];
    final isRunning = timer['isRunning'] as bool;
    
    return Dismissible(
      key: Key(timer['id'].toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteTimer(timer['id']),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      timer['name'] ?? '倒计时',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 20),
                    onPressed: () => _resetTimer(timer),
                  ),
                  IconButton(
                    icon: Icon(
                      isRunning ? Icons.pause : Icons.play_arrow,
                      size: 28,
                    ),
                    color: Theme.of(context).colorScheme.primary,
                    onPressed: () => _toggleTimer(timer),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 进度条
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation(
                    progress < 0.2 ? Colors.red : 
                    progress < 0.5 ? Colors.orange : Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  _formatDuration(timer['remainingSeconds']),
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: isRunning ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAddTimerDialog() async {
    final nameController = TextEditingController();
    int hours = 0;
    int minutes = 5;
    int seconds = 0;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('添加倒计时', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                  hintText: '例如：煮蛋、休息...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              
              const Text('时长设置', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // 时间选择器
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTimePicker('时', hours, 0, 23, (v) => setModalState(() => hours = v)),
                  const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  _buildTimePicker('分', minutes, 0, 59, (v) => setModalState(() => minutes = v)),
                  const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  _buildTimePicker('秒', seconds, 0, 59, (v) => setModalState(() => seconds = v)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 快捷预设
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ActionChip(
                    label: const Text('煮蛋'),
                    onPressed: () => setModalState(() { hours = 0; minutes = 8; seconds = 0; }),
                  ),
                  ActionChip(
                    label: const Text('泡面'),
                    onPressed: () => setModalState(() { hours = 0; minutes = 3; seconds = 0; }),
                  ),
                  ActionChip(
                    label: const Text('番茄钟'),
                    onPressed: () => setModalState(() { hours = 0; minutes = 25; seconds = 0; }),
                  ),
                  ActionChip(
                    label: const Text('休息'),
                    onPressed: () => setModalState(() { hours = 0; minutes = 5; seconds = 0; }),
                  ),
                  ActionChip(
                    label: const Text('1小时'),
                    onPressed: () => setModalState(() { hours = 1; minutes = 0; seconds = 0; }),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    if (nameController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('请输入名称')),
                      );
                      return;
                    }
                    
                    final totalSeconds = hours * 3600 + minutes * 60 + seconds;
                    if (totalSeconds == 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('时长不能为0')),
                      );
                      return;
                    }
                    
                    await _db.addCountdown({
                      'name': nameController.text.trim(),
                      'duration': totalSeconds,
                    });
                    
                    Navigator.pop(context);
                    _loadTimers();
                  },
                  child: const Text('添加'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, int value, int min, int max, ValueChanged<int> onChanged) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            Container(
              width: 40,
              alignment: Alignment.center,
              child: Text(
                value.toString().padLeft(2, '0'),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
