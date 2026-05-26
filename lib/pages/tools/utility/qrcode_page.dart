import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 二维码工具 - 生成/扫描
class QrcodePage extends StatefulWidget {
  const QrcodePage({super.key});

  @override
  State<QrcodePage> createState() => _QrcodePageState();
}

class _QrcodePageState extends State<QrcodePage> {
  final TextEditingController _inputController = TextEditingController();
  String _qrData = '';
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  double _qrSize = 200;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _generateQR() {
    setState(() {
      _qrData = _inputController.text.trim();
    });
  }

  Future<void> _shareQR() async {
    if (_qrData.isEmpty) return;
    
    try {
      final qrPainter = QrPainter(
        data: _qrData,
        version: QrVersions.auto,
        color: _qrColor,
        emptyColor: _backgroundColor,
        gapless: true,
      );
      
      final picData = await qrPainter.toImageData(_qrSize * 2);
      if (picData != null) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/qr_code.png');
        await file.writeAsBytes(picData.buffer.asUint8List());
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: '二维码: $_qrData',
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  void _copyResult() {
    if (_qrData.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _qrData));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制到剪贴板')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('二维码工具'),
        bottom: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.qr_code), text: '生成'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: '扫描'),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          _buildGeneratorTab(),
          _buildScannerTab(),
        ],
      ),
    );
  }

  Widget _buildGeneratorTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 输入区域
          TextField(
            controller: _inputController,
            decoration: InputDecoration(
              labelText: '输入内容',
              hintText: '网址、文本、联系方式...',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _inputController.clear();
                  setState(() => _qrData = '');
                },
              ),
            ),
            maxLines: 3,
            onChanged: (_) => _generateQR(),
          ),
          
          const SizedBox(height: 16),
          
          // 快捷输入
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.wifi, size: 16),
                label: const Text('WiFi'),
                onPressed: () => _showWiFiDialog(),
              ),
              ActionChip(
                avatar: const Icon(Icons.contact_phone, size: 16),
                label: const Text('联系人'),
                onPressed: () => _showContactDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 样式设置
          const Text('样式设置', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _qrColor,
                  ),
                  title: const Text('二维码颜色'),
                  onTap: () => _pickColor(true),
                ),
              ),
              Expanded(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 24,
                    height: 24,
                    color: _backgroundColor,
                  ),
                  title: const Text('背景颜色'),
                  onTap: () => _pickColor(false),
                ),
              ),
            ],
          ),
          
          // 大小调节
          Row(
            children: [
              const Text('大小:'),
              Expanded(
                child: Slider(
                  value: _qrSize,
                  min: 100,
                  max: 300,
                  divisions: 4,
                  label: '${_qrSize.toInt()}',
                  onChanged: (v) => setState(() => _qrSize = v),
                ),
              ),
              Text('${_qrSize.toInt()}'),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // 二维码预览
          if (_qrData.isNotEmpty)
            Center(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: _qrSize,
                        backgroundColor: _backgroundColor,
                        foregroundColor: _qrColor,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _qrData.length > 30 
                            ? '${_qrData.substring(0, 30)}...'
                            : _qrData,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyResult,
                            tooltip: '复制内容',
                          ),
                          IconButton(
                            icon: const Icon(Icons.share),
                            onPressed: _shareQR,
                            tooltip: '分享',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Center(
              child: Column(
                children: [
                  Icon(Icons.qr_code, size: 100, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('输入内容生成二维码', style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScannerTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text('相机扫描功能', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            '由于Flutter WebView限制，\n建议使用系统相机扫描',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('请使用系统相机扫描二维码')),
              );
            },
            icon: const Icon(Icons.open_in_new),
            label: const Text('打开相机'),
          ),
        ],
      ),
    );
  }

  void _pickColor(bool isQRColor) {
    final colors = [
      Colors.black,
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.purple,
      Colors.orange,
    ];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isQRColor ? '选择二维码颜色' : '选择背景颜色'),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: colors.map((color) => GestureDetector(
                onTap: () {
                  setState(() {
                    if (isQRColor) {
                      _qrColor = color;
                    } else {
                      _backgroundColor = color;
                    }
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _showWiFiDialog() {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成WiFi二维码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: ssidController,
              decoration: const InputDecoration(
                labelText: 'WiFi名称 (SSID)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              decoration: const InputDecoration(
                labelText: '密码',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final wifiString = 
                  'WIFI:S:${ssidController.text};T:WPA;P:${passwordController.text};;';
              _inputController.text = wifiString;
              _generateQR();
              Navigator.pop(context);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('生成联系人二维码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '姓名',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: '电话',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              final vcard = '''BEGIN:VCARD
VERSION:3.0
FN:${nameController.text}
TEL:${phoneController.text}
END:VCARD''';
              _inputController.text = vcard;
              _generateQR();
              Navigator.pop(context);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }
}
