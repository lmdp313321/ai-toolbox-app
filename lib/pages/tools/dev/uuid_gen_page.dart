import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';

class UuidGenPage extends StatefulWidget {
  const UuidGenPage({super.key});
  @override
  State<UuidGenPage> createState() => _UuidGenPageState();
}

class _UuidGenPageState extends State<UuidGenPage> {
  final _uuid = const Uuid();
  String _current = '';

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() {
    setState(() {
      _current = _uuid.v4();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UUID生成')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText(
                    _current,
                    style: const TextStyle(fontSize: 18, fontFamily: 'monospace', letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('生成新UUID'),
                    onPressed: _generate,
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.copy),
                    label: const Text('复制'),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _current));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已复制到剪贴板')));
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
