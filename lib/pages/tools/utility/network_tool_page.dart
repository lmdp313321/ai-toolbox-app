import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// 网络工具页面 - Ping/IP查询/端口扫描
class NetworkToolPage extends StatefulWidget {
  const NetworkToolPage({super.key});

  @override
  State<NetworkToolPage> createState() => _NetworkToolPageState();
}

class _NetworkToolPageState extends State<NetworkToolPage> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  // Ping 相关
  final TextEditingController _pingHostController = TextEditingController(text: 'www.baidu.com');
  bool _isPinging = false;
  List<String> _pingResults = [];
  
  // IP查询相关
  final TextEditingController _ipController = TextEditingController();
  Map<String, dynamic>? _ipInfo;
  bool _isQueryingIP = false;
  
  // 端口扫描相关
  final TextEditingController _portHostController = TextEditingController(text: '127.0.0.1');
  final TextEditingController _portStartController = TextEditingController(text: '80');
  final TextEditingController _portEndController = TextEditingController(text: '100');
  bool _isScanning = false;
  List<Map<String, dynamic>> _scanResults = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pingHostController.dispose();
    _ipController.dispose();
    _portHostController.dispose();
    _portStartController.dispose();
    _portEndController.dispose();
    super.dispose();
  }

  Future<void> _startPing() async {
    final host = _pingHostController.text.trim();
    if (host.isEmpty) return;

    setState(() {
      _isPinging = true;
      _pingResults = [];
    });

    // 模拟Ping结果
    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 500));
      final ms = 20 + (i * 5);
      setState(() {
        _pingResults.add('来自 $host 的回复: 字节=32 时间=${ms}ms TTL=55');
      });
    }

    setState(() {
      _pingResults.add('');
      _pingResults.add('Ping 统计:');
      _pingResults.add('    发送 = 4，接收 = 4，丢失 = 0 (0% 丢失)');
      _isPinging = false;
    });
  }

  Future<void> _queryIP() async {
    final ip = _ipController.text.trim();
    if (ip.isEmpty) {
      // 获取本机IP
      setState(() => _isQueryingIP = true);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() {
        _ipInfo = {
          'ip': '192.168.1.100',
          'type': 'IPv4',
          'location': '局域网',
          'isp': '本地网络',
        };
        _isQueryingIP = false;
      });
      return;
    }

    setState(() => _isQueryingIP = true);
    
    // 模拟IP查询
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() {
      _ipInfo = {
        'ip': ip,
        'type': 'IPv4',
        'location': '中国 北京',
        'isp': '中国电信',
        'lat': '39.9042',
        'lon': '116.4074',
      };
      _isQueryingIP = false;
    });
  }

  Future<void> _scanPorts() async {
    final host = _portHostController.text.trim();
    final startPort = int.tryParse(_portStartController.text) ?? 80;
    final endPort = int.tryParse(_portEndController.text) ?? 100;

    if (host.isEmpty || startPort > endPort) return;

    setState(() {
      _isScanning = true;
      _scanResults = [];
    });

    // 模拟端口扫描
    for (int port = startPort; port <= endPort && port < startPort + 20; port++) {
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 模拟开放端口
      final commonPorts = {80, 443, 22, 21, 3306, 8080};
      final isOpen = commonPorts.contains(port) || port % 17 == 0;
      
      if (isOpen) {
        setState(() {
          _scanResults.add({
            'port': port,
            'status': '开放',
            'service': _getServiceName(port),
          });
        });
      }
    }

    setState(() => _isScanning = false);
  }

  String _getServiceName(int port) {
    final services = {
      21: 'FTP',
      22: 'SSH',
      80: 'HTTP',
      443: 'HTTPS',
      3306: 'MySQL',
      8080: 'HTTP Proxy',
    };
    return services[port] ?? '未知服务';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('网络工具'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.network_ping), text: 'Ping'),
            Tab(icon: Icon(Icons.location_on), text: 'IP查询'),
            Tab(icon: Icon(Icons.scanner), text: '端口扫描'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPingTab(),
          _buildIPQueryTab(),
          _buildPortScanTab(),
        ],
      ),
    );
  }

  Widget _buildPingTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pingHostController,
                  decoration: const InputDecoration(
                    labelText: '目标主机',
                    hintText: '例如: www.baidu.com',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isPinging ? null : _startPing,
                icon: _isPinging 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_isPinging ? '测试中...' : '开始'),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 结果区域
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: _pingResults.isEmpty
                  ? Center(
                      child: Text(
                        '点击开始按钮进行Ping测试',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _pingResults.length,
                      itemBuilder: (context, index) => Text(
                        _pingResults[index],
                        style: const TextStyle(
                          color: Colors.green,
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIPQueryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 输入框
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ipController,
                  decoration: const InputDecoration(
                    labelText: 'IP地址（留空查询本机）',
                    hintText: '例如: 8.8.8.8',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _isQueryingIP ? null : _queryIP,
                icon: _isQueryingIP
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2)
                      )
                    : const Icon(Icons.search),
                label: const Text('查询'),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 查询结果
          if (_ipInfo != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.computer),
                      title: const Text('IP地址'),
                      trailing: Text(
                        _ipInfo!['ip'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.category),
                      title: const Text('类型'),
                      trailing: Text(_ipInfo!['type'] ?? '-'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.location_on),
                      title: const Text('地理位置'),
                      trailing: Text(_ipInfo!['location'] ?? '-'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.business),
                      title: const Text('运营商'),
                      trailing: Text(_ipInfo!['isp'] ?? '-'),
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // 快捷查询按钮
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.computer, size: 16),
                label: const Text('本机IP'),
                onPressed: () {
                  _ipController.clear();
                  _queryIP();
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.cloud, size: 16),
                label: const Text('8.8.8.8'),
                onPressed: () {
                  _ipController.text = '8.8.8.8';
                  _queryIP();
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.cloud, size: 16),
                label: const Text('114.114.114.114'),
                onPressed: () {
                  _ipController.text = '114.114.114.114';
                  _queryIP();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPortScanTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 主机输入
          TextField(
            controller: _portHostController,
            decoration: const InputDecoration(
              labelText: '目标主机',
              hintText: '例如: 127.0.0.1',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          
          // 端口范围
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _portStartController,
                  decoration: const InputDecoration(
                    labelText: '起始端口',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('到'),
              ),
              Expanded(
                child: TextField(
                  controller: _portEndController,
                  decoration: const InputDecoration(
                    labelText: '结束端口',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 扫描按钮
          FilledButton.icon(
            onPressed: _isScanning ? null : _scanPorts,
            icon: _isScanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)
                  )
                : const Icon(Icons.scanner),
            label: Text(_isScanning ? '扫描中...' : '开始扫描'),
          ),
          
          const SizedBox(height: 24),
          
          // 扫描结果
          if (_scanResults.isNotEmpty) ...[
            const Text(
              '开放端口',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ..._scanResults.map((result) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: Colors.green[50],
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${result['port']}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(result['service']),
                trailing: Chip(
                  label: Text(result['status']),
                  backgroundColor: Colors.green[100],
                ),
              ),
            )),
          ] else if (!_isScanning) ...[
            Center(
              child: Text(
                '扫描结果将显示在这里',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
