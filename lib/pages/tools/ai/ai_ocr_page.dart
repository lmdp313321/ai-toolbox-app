import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class AiOcrPage extends StatefulWidget {
  const AiOcrPage({super.key});
  @override
  State<AiOcrPage> createState() => _AiOcrPageState();
}

class _AiOcrPageState extends State<AiOcrPage> {
  File? _image;
  String _result = '';
  bool _isLoading = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _result = '';
      });
      _recognize();
    }
  }

  Future<void> _recognize() async {
    if (_image == null) return;
    setState(() => _isLoading = true);
    
    try {
      // TODO: 对接腾讯云OCR API（已配置密钥）
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _result = 'OCR识别结果将在这里显示（百度OCR+腾讯云OCR双引擎）');
    } catch (e) {
      setState(() => _result = '识别失败: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('文字识别')),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _image == null
                  ? const Icon(Icons.document_scanner, size: 100, color: Colors.grey)
                  : Image.file(_image!, fit: BoxFit.contain),
            ),
          ),
          if (_result.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: SelectableText(_result),
            ),
          if (_isLoading) const LinearProgressIndicator(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('拍照'),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.photo_library),
                      label: const Text('相册'),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
