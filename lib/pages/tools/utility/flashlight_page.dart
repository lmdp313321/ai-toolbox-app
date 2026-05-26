import 'package:flutter/material.dart';

class FlashlightPage extends StatefulWidget {
  const FlashlightPage({super.key});
  @override
  State<FlashlightPage> createState() => _FlashlightPageState();
}

class _FlashlightPageState extends State<FlashlightPage> {
  bool _isOn = false;

  void _toggle() {
    setState(() => _isOn = !_isOn);
    // TODO: 调用原生闪光灯（需要 permission_handler + 原生插件）
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手电筒')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200, height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isOn ? Colors.yellow.shade600 : Colors.grey.shade300,
                  boxShadow: _isOn
                      ? [BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 50, spreadRadius: 20)]
                      : [],
                ),
                child: Icon(
                  _isOn ? Icons.flash_on : Icons.flash_off,
                  size: 80,
                  color: _isOn ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              _isOn ? '点击关闭' : '点击开启',
              style: TextStyle(fontSize: 18, color: _isOn ? Colors.yellow.shade700 : Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('完整功能需要闪光灯权限', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
