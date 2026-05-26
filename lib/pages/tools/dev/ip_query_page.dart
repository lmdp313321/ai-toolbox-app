import 'dart:convert';
import 'package:flutter/material.dart';
import 'dart:io';

class IpQueryPage extends StatefulWidget {
  const IpQueryPage({super.key});
  @override
  State<IpQueryPage> createState() => _IpQueryPageState();
}

class _IpQueryPageState extends State<IpQueryPage> {
  String _localIp = '获取中...';
  String _publicIp = '获取中...';

  @override
  void initState() {
    super.initState();
    _getIps();
  }

  Future<void> _getIps() async {
    try {
      for (var iface in await NetworkInterface.list()) {
        for (var addr in iface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            setState(() => _localIp = addr.address);
            break;
          }
        }
      }
    } catch (e) {
      setState(() => _localIp = '获取失败');
    }
    
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse('https://api.ipify.org'));
      final response = await request.close();
      if (response.statusCode == 200) {
        final ip = await response.transform(utf8.decoder).join();
        setState(() => _publicIp = ip.trim());
      }
      client.close();
    } catch (e) {
      setState(() => _publicIp = '网络不可用');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('IP查询')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.wifi, color: Colors.blue),
                title: const Text('本机IP'),
                subtitle: Text(_localIp, style: const TextStyle(fontSize: 18, fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.public, color: Colors.green),
                title: const Text('公网IP'),
                subtitle: Text(_publicIp, style: const TextStyle(fontSize: 18, fontFamily: 'monospace')),
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('刷新'),
              onPressed: _getIps,
            ),
          ],
        ),
      ),
    );
  }
}
