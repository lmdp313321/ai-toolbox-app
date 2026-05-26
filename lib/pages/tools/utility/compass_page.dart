import 'dart:math';
import 'package:flutter/material.dart';

class CompassPage extends StatefulWidget {
  const CompassPage({super.key});
  @override
  State<CompassPage> createState() => _CompassPageState();
}

class _CompassPageState extends State<CompassPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  double _angle = 0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    
    // 模拟旋转（真实使用需要传感器）
    _animController.addListener(() {
      setState(() {
        _angle = _animController.value * 360;
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
      appBar: AppBar(title: const Text('指南针')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // 指南针盘
            SizedBox(
              width: 280, height: 280,
              child: Transform.rotate(
                angle: _angle * pi / 180,
                child: CustomPaint(
                  painter: _CompassPainter(),
                  size: const Size(280, 280),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              '${_angle.toStringAsFixed(1)}°',
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w200),
            ),
            Text(
              _getDirection(_angle),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('提示：完整功能需要磁力传感器支持', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _getDirection(double angle) {
    if (angle < 22.5 || angle >= 337.5) return '北 N';
    if (angle < 67.5) return '东北 NE';
    if (angle < 112.5) return '东 E';
    if (angle < 157.5) return '东南 SE';
    if (angle < 202.5) return '南 S';
    if (angle < 247.5) return '西南 SW';
    if (angle < 292.5) return '西 W';
    return '西北 NW';
  }
}

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // 外圈
    canvas.drawCircle(center, radius, paint);
    canvas.drawCircle(center, radius - 20, paint);

    // 刻度
    for (int i = 0; i < 360; i += 30) {
      final angle = i * (pi / 180);
      final start = center + Offset(cos(angle - pi / 2), sin(angle - pi / 2)) * (radius - 15);
      final end = center + Offset(cos(angle - pi / 2), sin(angle - pi / 2)) * (radius - 5);
      canvas.drawLine(start, end, paint);
    }

    // 方向标记
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    const directions = {'N': 0, 'E': 90, 'S': 180, 'W': 270};
    for (final entry in directions.entries) {
      final angle = entry.value * (pi / 180);
      final pos = center + Offset(cos(angle - pi / 2), sin(angle - pi / 2)) * (radius - 30);
      textPainter.text = TextSpan(
        text: entry.key,
        style: TextStyle(color: entry.key == 'N' ? Colors.red : Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
    }

    // 指针
    final pointerPaint = Paint()..color = Colors.red..strokeWidth = 3;
    final top = center + Offset(0, -radius + 40);
    canvas.drawLine(center, top, pointerPaint);
    
    final bottomPaint = Paint()..color = Colors.grey..strokeWidth = 3;
    final bottom = center + Offset(0, radius - 40);
    canvas.drawLine(center, bottom, bottomPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
