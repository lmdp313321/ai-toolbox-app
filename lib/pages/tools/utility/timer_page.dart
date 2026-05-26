import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});
  @override
  State<TimerPage> createState() => _TimerPageState();
}

class _TimerPageState extends State<TimerPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // 计时器
  int _seconds = 0;
  Timer? _stopwatchTimer;
  bool _isRunning = false;
  
  // 倒计时
  int _countdownSeconds = 0;
  int _countdownRemaining = 0;
  Timer? _countdownTimer;
  bool _countdownRunning = false;
  final TextEditingController _countdownController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _startStopwatch() {
    setState(() => _isRunning = true);
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _seconds++);
    });
  }

  void _stopStopwatch() {
    _stopwatchTimer?.cancel();
    setState(() => _isRunning = false);
  }

  void _resetStopwatch() {
    _stopStopwatch();
    setState(() => _seconds = 0);
  }

  void _startCountdown() {
    final total = int.tryParse(_countdownController.text);
    if (total == null || total <= 0) return;
    setState(() {
      _countdownSeconds = total;
      _countdownRemaining = total;
      _countdownRunning = true;
    });
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_countdownRemaining > 0) {
        setState(() => _countdownRemaining--);
      } else {
        _countdownTimer?.cancel();
        setState(() => _countdownRunning = false);
        HapticFeedback.heavyImpact();
      }
    });
  }

  void _stopCountdown() {
    _countdownTimer?.cancel();
    setState(() => _countdownRunning = false);
  }

  String _formatTime(int s) {
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _countdownTimer?.cancel();
    _tabController.dispose();
    _countdownController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('定时器'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '计时器'), Tab(text: '倒计时')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStopwatch(),
          _buildCountdown(),
        ],
      ),
    );
  }

  Widget _buildStopwatch() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_formatTime(_seconds), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_isRunning)
                FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始'),
                  onPressed: _startStopwatch,
                )
              else
                FilledButton.icon(
                  icon: const Icon(Icons.pause),
                  label: const Text('暂停'),
                  onPressed: _stopStopwatch,
                ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
                onPressed: _resetStopwatch,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountdown() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (!_countdownRunning)
            Padding(
              padding: const EdgeInsets.all(32),
              child: TextField(
                controller: _countdownController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '秒数',
                  border: OutlineInputBorder(),
                  hintText: '输入倒计时秒数',
                ),
              ),
            ),
          Text(_formatTime(_countdownRemaining), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w200, fontFamily: 'monospace')),
          const SizedBox(height: 32),
          if (!_countdownRunning && _countdownRemaining == 0)
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('开始'),
              onPressed: _startCountdown,
            )
          else if (_countdownRunning)
            FilledButton.icon(
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
              onPressed: _stopCountdown,
            ),
        ],
      ),
    );
  }
}
