import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 颜色选择器工具
class ColorPickerPage extends StatefulWidget {
  const ColorPickerPage({super.key});

  @override
  State<ColorPickerPage> createState() => _ColorPickerPageState();
}

class _ColorPickerPageState extends State<ColorPickerPage> {
  double _red = 100;
  double _green = 150;
  double _blue = 200;
  double _alpha = 255;
  
  final TextEditingController _hexController = TextEditingController();
  final TextEditingController _rgbController = TextEditingController();

  Color get _currentColor => Color.fromARGB(
    _alpha.toInt(),
    _red.toInt(),
    _green.toInt(),
    _blue.toInt(),
  );

  @override
  void initState() {
    super.initState();
    _updateTextValues();
  }

  void _updateTextValues() {
    final color = _currentColor;
    _hexController.text = '#${color.value.toRadixString(16).padLeft(8, '0').toUpperCase()}';
    _rgbController.text = 'rgba(${_red.toInt()}, ${_green.toInt()}, ${_blue.toInt()}, ${(_alpha / 255).toStringAsFixed(2)})';
  }

  void _onColorChanged() {
    setState(() {
      _updateTextValues();
    });
  }

  void _parseHex(String hex) {
    hex = hex.trim().replaceAll('#', '');
    if (hex.length == 6) {
      hex = 'FF$hex';
    }
    if (hex.length == 8) {
      try {
        final value = int.parse(hex, radix: 16);
        final color = Color(value);
        setState(() {
          _alpha = color.alpha.toDouble();
          _red = color.red.toDouble();
          _green = color.green.toDouble();
          _blue = color.blue.toDouble();
          _updateTextValues();
        });
      } catch (e) {
        // 解析失败，忽略
      }
    }
  }

  void _copyHex() {
    Clipboard.setData(ClipboardData(text: _hexController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: ${_hexController.text}')),
    );
  }

  void _copyRgb() {
    Clipboard.setData(ClipboardData(text: _rgbController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: ${_rgbController.text}')),
    );
  }

  void _copyFlutterColor() {
    final code = 'Color(0x${_hexController.text.replaceAll('#', '')})';
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制: $code')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('🎨 颜色选择器')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 颜色预览
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: _currentColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _hexController.text,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // RGB滑块
            _buildSlider(
              label: '红色 (R)',
              value: _red,
              color: Colors.red,
              onChanged: (v) {
                setState(() => _red = v);
                _onColorChanged();
              },
            ),
            _buildSlider(
              label: '绿色 (G)',
              value: _green,
              color: Colors.green,
              onChanged: (v) {
                setState(() => _green = v);
                _onColorChanged();
              },
            ),
            _buildSlider(
              label: '蓝色 (B)',
              value: _blue,
              color: Colors.blue,
              onChanged: (v) {
                setState(() => _blue = v);
                _onColorChanged();
              },
            ),
            _buildSlider(
              label: '透明度 (A)',
              value: _alpha,
              color: Colors.grey,
              onChanged: (v) {
                setState(() => _alpha = v);
                _onColorChanged();
              },
            ),
            
            const SizedBox(height: 24),
            
            // 颜色值显示
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  // HEX
                  _buildColorValueRow(
                    label: 'HEX:',
                    controller: _hexController,
                    onCopy: _copyHex,
                    onChanged: _parseHex,
                  ),
                  const SizedBox(height: 12),
                  // RGB
                  _buildColorValueRow(
                    label: 'RGB:',
                    controller: _rgbController,
                    onCopy: _copyRgb,
                    readOnly: true,
                  ),
                  const SizedBox(height: 12),
                  // Flutter Color
                  Row(
                    children: [
                      const SizedBox(
                        width: 60,
                        child: Text('Flutter:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Text(
                            'Color(0x${_hexController.text.replaceAll('#', '')})',
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyFlutterColor,
                        tooltip: '复制Flutter代码',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 预设颜色
            const Text('预设颜色', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _presetColors.map((color) => _buildColorPreset(color)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required double value,
    required MaterialColor color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: Slider(
                value: value,
                min: 0,
                max: 255,
                divisions: 255,
                activeColor: color,
                onChanged: onChanged,
              ),
            ),
            SizedBox(
              width: 50,
              child: Text(
                value.toInt().toString(),
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildColorValueRow({
    required String label,
    required TextEditingController controller,
    required VoidCallback onCopy,
    ValueChanged<String>? onChanged,
    bool readOnly = false,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            readOnly: readOnly,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.copy),
          onPressed: onCopy,
          tooltip: '复制',
        ),
      ],
    );
  }

  Widget _buildColorPreset(Color color) {
    final isSelected = _currentColor.value == color.value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _red = color.red.toDouble();
          _green = color.green.toDouble();
          _blue = color.blue.toDouble();
          _alpha = color.alpha.toDouble();
          _updateTextValues();
        });
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
      ),
    );
  }

  final List<Color> _presetColors = [
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
    Colors.black,
    Colors.white,
  ];

  @override
  void dispose() {
    _hexController.dispose();
    _rgbController.dispose();
    super.dispose();
  }
}