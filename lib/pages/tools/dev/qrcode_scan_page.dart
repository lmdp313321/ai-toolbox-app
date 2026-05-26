import 'package:flutter/material.dart';

class QrcodeScanPage extends StatefulWidget {
  const QrcodeScanPage({super.key});
  @override
  State<QrcodeScanPage> createState() => _QrcodeScanPageState();
}

class _QrcodeScanPageState extends State<QrcodeScanPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('扫码')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.qr_code_scanner, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('扫码功能需要摄像头权限'),
            const SizedBox(height: 8),
            const Text('后续集成 qr_code_scanner 插件实现', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
