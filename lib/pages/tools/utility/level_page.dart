import 'dart:math';
import 'package:flutter/material.dart';

class LevelPage extends StatefulWidget {
  const LevelPage({super.key});
  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  // 模拟水平仪数据（实际使用需要传感器插件）
  double _x = 0;
  double _y = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    )..repeat();
    
    // 模拟小幅摆动
    _animController.addListener(() {
      setState(() {
        _x = sin(_animController.value * pi * 2) * 0.5;
        _y = cos(_animController.value * pi * 2) * 0.3;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('水平仪')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 280, height: 280,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 外圈
                  Container(
                    width: 280, height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                    ),
                  ),
                  // 内圈
                  Container(
                    width: 200, height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                  ),
                  // 气泡
                  Transform.translate(
                    offset: Offset(_x * 80, _y * 80),
                    child: Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Colors.blue.shade300, Colors.blue.shade600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('X: ${_x.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'monospace')),
            Text('Y: ${_y.toStringAsFixed(2)}', style: const TextStyle(fontFamily: 'monospace')),
            const SizedBox(height: 16),
            const Text('提示：完整功能需要传感器支持', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
