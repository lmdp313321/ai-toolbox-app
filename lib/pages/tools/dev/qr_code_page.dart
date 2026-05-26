import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// 二维码生成工具
class QrCodePage extends StatefulWidget {
  const QrCodePage({super.key});

  @override
  State<QrCodePage> createState() => _QrCodePageState();
}

class _QrCodePageState extends State<QrCodePage> {
  final TextEditingController _textController = TextEditingController();
  String _qrData = '';
  double _qrSize = 250;
  Color _qrColor = Colors.black;
  Color _backgroundColor = Colors.white;
  int _errorCorrectionLevel = QrErrorCorrectLevel.M;

  void _generateQr() {
    setState(() {
      _qrData = _textController.text.trim();
    });
  }

  void _clear() {
    _textController.clear();
    setState(() {
      _qrData = '';
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _textController.text = data!.text!;
      _generateQr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📱 二维码生成'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.clear_all),
            tooltip: '清空',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 输入区
            TextField(
              controller: _textController,
              decoration: InputDecoration(
                labelText: '输入内容',
                hintText: '输入文本、URL、联系方式等...',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.paste),
                      onPressed: _pasteFromClipboard,
                      tooltip: '粘贴',
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _textController.clear(),
                      tooltip: '清空',
                    ),
                  ],
                ),
              ),
              maxLines: 5,
              minLines: 3,
              onChanged: (_) => _generateQr(),
            ),
            
            const SizedBox(height: 16),
            
            // 快捷输入
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickInput('WiFi', Icons.wifi, _buildWifiDialog),
                _buildQuickInput('网址', Icons.link, () => _textController.text = 'https://'),
                _buildQuickInput('邮箱', Icons.email, () => _textController.text = 'mailto:'),
                _buildQuickInput('电话', Icons.phone, () => _textController.text = 'tel:'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 二维码预览
            if (_qrData.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _qrData,
                      size: _qrSize,
                      backgroundColor: _backgroundColor,
                      foregroundColor: _qrColor,
                      errorCorrectionLevel: _errorCorrectionLevel,
                      errorStateBuilder: (context, error) {
                        return Container(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '生成失败: 内容过长或包含不支持字符',
                            style: TextStyle(color: Colors.red[700]),
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '内容长度: ${_qrData.length} 字符',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('输入内容生成二维码', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            
            const SizedBox(height: 24),
            
            // 设置选项
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('设置', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  
                  // 大小调节
                  Row(
                    children: [
                      const Text('尺寸:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Slider(
                          value: _qrSize,
                          min: 150,
                          max: 350,
                          divisions: 4,
                          label: '${_qrSize.toInt()}',
                          onChanged: (v) => setState(() => _qrSize = v),
                        ),
                      ),
                      Text('${_qrSize.toInt()}px'),
                    ],
                  ),
                  
                  // 纠错级别
                  Row(
                    children: [
                      const Text('纠错级别:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: QrErrorCorrectLevel.L, label: Text('低')),
                            ButtonSegment(value: QrErrorCorrectLevel.M, label: Text('中')),
                            ButtonSegment(value: QrErrorCorrectLevel.Q, label: Text('高')),
                            ButtonSegment(value: QrErrorCorrectLevel.H, label: Text('最高')),
                          ],
                          selected: {_errorCorrectionLevel},
                          onSelectionChanged: (v) => setState(() => _errorCorrectionLevel = v.first),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // 颜色选择
                  Row(
                    children: [
                      const Text('前景色:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _pickColor(isForeground: true),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _qrColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Text('背景色:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _pickColor(isForeground: false),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInput(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 18),
      label: Text(label),
      onPressed: onTap,
    );
  }

  void _buildWifiDialog() {
    final ssidController = TextEditingController();
    final passwordController = TextEditingController();
    String securityType = 'WPA';

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
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: securityType,
              decoration: const InputDecoration(
                labelText: '加密方式',
                border: OutlineInputBorder(),
              ),
              items: ['WPA', 'WEP', 'nopass'].map((s) => 
                DropdownMenuItem(value: s, child: Text(s))
              ).toList(),
              onChanged: (v) => securityType = v!,
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
              final wifiString = 'WIFI:T:$securityType;S:${ssidController.text};P:${passwordController.text};;';
              _textController.text = wifiString;
              _generateQr();
              Navigator.pop(context);
            },
            child: const Text('生成'),
          ),
        ],
      ),
    );
  }

  void _pickColor({required bool isForeground}) {
    final colors = [
      Colors.black,
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
      Colors.white,
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择颜色'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) => GestureDetector(
            onTap: () {
              setState(() {
                if (isForeground) {
                  _qrColor = color;
                } else {
                  _backgroundColor = color;
                }
              });
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
            ),
          )).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}