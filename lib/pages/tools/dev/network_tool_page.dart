import 'package:flutter/material.dart';
import 'dart:io';

/// 网络工具 - Ping/端口检测
class NetworkToolPage extends StatefulWidget {
  const NetworkToolPage({super.key});

  @override
  State<NetworkToolPage> createState() => _NetworkToolPageState();
}

class _NetworkToolPageState extends State<NetworkToolPage> {
  final _hostCtrl = TextEditingController(text: 'baidu.com');
  final _portCtrl = TextEditingController(text: '80');
  String _result = '';
  bool _loading = false;

  Future<void> _ping() async {
    setState(() { _loading = true; _result = 'Pinging ${_hostCtrl.text}...'; });
    try {
      final result = await Process.run('ping', ['-c', '4', '-W', '3', _hostCtrl.text]);
      setState(() { _result = result.stdout.toString(); });
    } catch (e) {
      setState(() { _result = 'Ping failed: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _checkPort() async {
    final host = _hostCtrl.text;
    final port = int.tryParse(_portCtrl.text) ?? 80;
    setState(() { _loading = true; _result = 'Checking $host:$port...'; });
    try {
      final socket = await Socket.connect(host, port, timeout: const Duration(seconds: 5));
      socket.destroy();
      setState(() { _result = '✓ Port $port is OPEN on $host'; });
    } catch (e) {
      setState(() { _result = '✗ Port $port is CLOSED on $host ($e)'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('网络工具')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _hostCtrl,
              decoration: const InputDecoration(
                labelText: '主机地址',
                hintText: 'baidu.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _portCtrl,
              decoration: const InputDecoration(
                labelText: '端口号',
                hintText: '80',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _ping,
                    icon: const Icon(Icons.wifi_tethering),
                    label: const Text('Ping'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _checkPort,
                    icon: const Icon(Icons.sensors),
                    label: const Text('端口检测'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _result.isEmpty ? '输入主机地址，点击 Ping 或 端口检测' : _result,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
