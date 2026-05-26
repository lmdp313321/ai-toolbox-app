import 'package:flutter/material.dart';

class ColorToolPage extends StatefulWidget {
  const ColorToolPage({super.key});
  @override
  State<ColorToolPage> createState() => _ColorToolPageState();
}

class _ColorToolPageState extends State<ColorToolPage> {
  Color _color = Colors.blue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('颜色工具')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: _color,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(height: 16),
            Text('HEX: #${_color.value.toRadixString(16).substring(2).toUpperCase()}'),
            Text('RGB: ${_color.red}, ${_color.green}, ${_color.blue}'),
          ],
        ),
      ),
    );
  }
}
