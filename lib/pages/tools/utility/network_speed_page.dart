import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// 网速测试页面 - 下载/上传速度测试
class NetworkSpeedPage extends StatefulWidget {
  const NetworkSpeedPage({super.key});

  @override
  State<NetworkSpeedPage> createState() => _NetworkSpeedPageState();
}

class _NetworkSpeedPageState extends State<NetworkSpeedPage>
    with SingleTickerProviderStateMixin {
  bool _isTesting = false;
  double _downloadSpeed = 0; // Mbps
  double _uploadSpeed = 0; // Mbps
  double _ping = 0; // ms
  int _progress = 0;
  
  String _testPhase = '';
  AnimationController? _animationController;
  Timer? _testTimer;
  
  final List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _animationController?.dispose();
    _testTimer?.cancel();
    super.dispose();
  }

  Future<void> _startTest() async {
    if (_isTesting) return;

    setState(() {
      _isTesting = true;
      _downloadSpeed = 0;
      _uploadSpeed = 0;
      _ping = 0;
      _progress = 0;
      _testPhase = '准备测试...';
    });

    _animationController?.repeat();

    // 模拟测试过程
    // 1. Ping测试
    await _testPing();
    
    // 2. 下载速度测试
    await _testDownload();
    
    // 3. 上传速度测试
    await _testUpload();

    // 测试完成
    setState(() {
      _isTesting = false;
      _testPhase = '测试完成';
      _progress = 100;
      
      _history.insert(0, {
        'time': DateTime.now(),
        'download': _downloadSpeed,
        'upload': _uploadSpeed,
        'ping': _ping,
      });
      if (_history.length > 10) _history.removeLast();
    });

    _animationController?.stop();
  }

  Future<void> _testPing() async {
    setState(() => _testPhase = '正在测试延迟...');
    
    // 模拟ping测试
    for (int i = 0; i < 5; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      setState(() {
        _ping = 10 + Random().nextInt(50).toDouble();
      });
    }
    
    setState(() => _progress = 10);
  }

  Future<void> _testDownload() async {
    setState(() => _testPhase = '正在测试下载速度...');
    
    final random = Random();
    final baseSpeed = 50 + random.nextInt(200).toDouble(); // 基础速度 50-250 Mbps
    
    for (int i = 0; i <= 40; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        // 模拟波动
        final fluctuation = random.nextDouble() * 20 - 10;
        _downloadSpeed = baseSpeed + fluctuation + i * 2;
        if (_downloadSpeed < 0) _downloadSpeed = 0;
        _progress = 10 + i;
      });
    }
    
    // 最终确定速度
    setState(() {
      _downloadSpeed = baseSpeed + random.nextDouble() * 20;
      _progress = 50;
    });
  }

  Future<void> _testUpload() async {
    setState(() => _testPhase = '正在测试上传速度...');
    
    final random = Random();
    // 上传速度通常是下载的 20-50%
    final baseSpeed = _downloadSpeed * (0.2 + random.nextDouble() * 0.3);
    
    for (int i = 0; i <= 40; i++) {
      await Future.delayed(const Duration(milliseconds: 50));
      setState(() {
        final fluctuation = random.nextDouble() * 10 - 5;
        _uploadSpeed = baseSpeed + fluctuation + i * 0.5;
        if (_uploadSpeed < 0) _uploadSpeed = 0;
        _progress = 50 + i;
      });
    }
    
    setState(() {
      _uploadSpeed = baseSpeed;
      _progress = 90;
    });
  }

  String _getSpeedGrade(double speed) {
    if (speed < 10) return '较慢';
    if (speed < 50) return '一般';
    if (speed < 100) return '良好';
    if (speed < 300) return '优秀';
    return '极速';
  }

  Color _getSpeedColor(double speed) {
    if (speed < 10) return Colors.red;
    if (speed < 50) return Colors.orange;
    if (speed < 100) return Colors.blue;
    if (speed < 300) return Colors.green;
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网速测试'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _showHistory,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 主速度显示
              Stack(
                alignment: Alignment.center,
                children: [
                  // 背景圆环
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: CircularProgressIndicator(
                      value: _isTesting ? null : (_progress / 100),
                      strokeWidth: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        _getSpeedColor(_downloadSpeed),
                      ),
                    ),
                  ),
                  
                  // 中心内容
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isTesting) ...[
                        RotationTransition(
                          turns: _animationController!,
                          child: Icon(
                            Icons.network_check,
                            size: 48,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _testPhase,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ] else ...[
                        Text(
                          _downloadSpeed > 0 
                            ? _downloadSpeed.toStringAsFixed(1)
                            : '0.0',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: _downloadSpeed > 0 
                                ? _getSpeedColor(_downloadSpeed)
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          'Mbps',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // 详细数据
              if (!_isTesting && _downloadSpeed > 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSpeedInfo('下载', _downloadSpeed, Icons.download),
                    _buildSpeedInfo('上传', _uploadSpeed, Icons.upload),
                    _buildPingInfo(),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // 网络评级
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: _getSpeedColor(_downloadSpeed).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    '网络质量: ${_getSpeedGrade(_downloadSpeed)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _getSpeedColor(_downloadSpeed),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // 测试按钮
              SizedBox(
                width: 200,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isTesting 
                        ? Colors.grey 
                        : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: _isTesting ? null : _startTest,
                  child: Text(
                    _isTesting ? '测试中...' : '开始测试',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // 提示
              Text(
                _isTesting 
                    ? '请保持网络连接稳定...'
                    : '测试结果仅供参考，实际速度可能有所不同',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
              
              // 参考说明
              if (!_isTesting && _downloadSpeed == 0) ...[
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                const Text('参考标准', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildReferenceItem('10 Mbps以下', '较慢', Colors.red),
                _buildReferenceItem('10-50 Mbps', '一般', Colors.orange),
                _buildReferenceItem('50-100 Mbps', '良好', Colors.blue),
                _buildReferenceItem('100-300 Mbps', '优秀', Colors.green),
                _buildReferenceItem('300 Mbps以上', '极速', Colors.purple),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedInfo(String label, double speed, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        const SizedBox(height: 4),
        Text(
          '${speed.toStringAsFixed(1)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text('Mbps', style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildPingInfo() {
    return Column(
      children: [
        Icon(Icons.timer, color: Colors.grey[600]),
        const SizedBox(height: 4),
        const Text('延迟', style: TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          '${_ping.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Text('ms', style: TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildReferenceItem(String speed, String grade, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(speed)),
          Text(grade, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ],
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
                Text('测试历史', style: Theme.of(context).textTheme.titleMedium),
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
                child: Text('暂无测试记录', style: TextStyle(color: Colors.grey)),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    final item = _history[index];
                    final time = item['time'] as DateTime;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getSpeedColor(item['download']).withOpacity(0.2),
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(color: _getSpeedColor(item['download'])),
                        ),
                      ),
                      title: Text('${item['download'].toStringAsFixed(1)} Mbps'),
                      subtitle: Text(
                        '${time.hour}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}',
                      ),
                      trailing: Text(_getSpeedGrade(item['download'])),
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
