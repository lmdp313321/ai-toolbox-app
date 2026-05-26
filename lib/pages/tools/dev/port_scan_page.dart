import 'package:flutter/material.dart';
import 'dart:io';

class PortScanPage extends StatefulWidget {
  const PortScanPage({super.key});
  @override
  State<PortScanPage> createState() => _PortScanPageState();
}

class _PortScanPageState extends State<PortScanPage> {
  final TextEditingController _ipController = TextEditingController();
  List<int> _openPorts = [];
  bool _isScanning = false;

  Future<void> _scan() async {
    final target = _ipController.text.trim();
    if (target.isEmpty) return;
    
    setState(() {
      _isScanning = true;
      _openPorts = [];
    });

    const commonPorts = [21, 22, 23, 80, 443, 3389, 8080, 8443, 9090, 9095, 9096, 9097, 9098, 9099];
    final results = <int>[];
    
    for (final port in commonPorts) {
      try {
        final socket = await Socket.connect(target, port, timeout: const Duration(seconds: 2));
        results.add(port);
        socket.destroy();
      } catch (_) {}
    }
    
    setState(() {
      _openPorts = results;
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('端口扫描')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      hintText: 'IP地址（如 192.168.1.1）',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.computer),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _isScanning ? null : _scan,
                  child: _isScanning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('扫描'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_openPorts.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: _openPorts.length,
                  itemBuilder: (ctx, i) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.green),
                    title: Text('端口 ${_openPorts[i]}', style: const TextStyle(fontFamily: 'monospace')),
                    subtitle: Text(_getServiceName(_openPorts[i])),
                  ),
                ),
              )
            else if (!_isScanning)
              const Expanded(
                child: Center(child: Text('输入IP地址点击扫描')),
              ),
          ],
        ),
      ),
    );
  }

  String _getServiceName(int port) {
    const services = {21: 'FTP', 22: 'SSH', 23: 'Telnet', 80: 'HTTP', 443: 'HTTPS', 3389: 'RDP', 8080: 'HTTP代理', 8443: 'HTTPS备用'};
    return services[port] ?? '自定义';
  }
}
