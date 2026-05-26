import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

class QrcodeGenPage extends StatefulWidget {
  const QrcodeGenPage({super.key});
  @override
  State<QrcodeGenPage> createState() => _QrcodeGenPageState();
}

class _QrcodeGenPageState extends State<QrcodeGenPage> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('二维码生成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入文本/链接生成二维码',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _controller.text));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制')));
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_controller.text.isNotEmpty)
              QrImageView(
                data: _controller.text,
                version: QrVersions.auto,
                size: 250,
                backgroundColor: Colors.white,
              ),
          ],
        ),
      ),
    );
  }
}
