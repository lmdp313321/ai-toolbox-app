import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// 图片工具页面 - 压缩/裁剪/格式转换
class ImageToolPage extends StatefulWidget {
  const ImageToolPage({super.key});

  @override
  State<ImageToolPage> createState() => _ImageToolPageState();
}

class _ImageToolPageState extends State<ImageToolPage> {
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  Future<void> _compressImage() async {
    if (_selectedImage == null) return;
    setState(() => _isProcessing = true);
    
    // 模拟压缩处理
    await Future.delayed(const Duration(seconds: 1));
    
    setState(() => _isProcessing = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('图片压缩完成（模拟）')),
    );
  }

  Future<void> _convertFormat() async {
    if (_selectedImage == null) return;
    
    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('选择目标格式'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'jpg'),
            child: const Text('JPG'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'png'),
            child: const Text('PNG'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'webp'),
            child: const Text('WebP'),
          ),
        ],
      ),
    );
    
    if (format != null) {
      setState(() => _isProcessing = true);
      await Future.delayed(const Duration(seconds: 1));
      setState(() => _isProcessing = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已转换为 $format 格式（模拟）')),
      );
    }
  }

  Future<void> _shareImage() async {
    if (_selectedImage == null) return;
    
    try {
      await Share.shareXFiles([XFile(_selectedImage!.path)]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分享失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片工具'),
      ),
      body: Column(
        children: [
          // 图片选择区域
          Expanded(
            flex: 2,
            child: _selectedImage != null
                ? Image.file(_selectedImage!, fit: BoxFit.contain)
                : _buildEmptyImageArea(),
          ),
          
          // 操作按钮
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 选择图片按钮
                  if (_selectedImage == null) ...[
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('相册选择'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('拍照'),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // 图片信息
                    if (_selectedImage != null)
                      FutureBuilder<FileStat>(
                        future: _selectedImage!.stat(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final size = snapshot.data!.size;
                            final sizeStr = size > 1024 * 1024
                                ? '${(size / 1024 / 1024).toStringAsFixed(2)} MB'
                                : '${(size / 1024).toStringAsFixed(1)} KB';
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                '文件大小: $sizeStr',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    
                    // 功能按钮
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildActionButton(
                          icon: Icons.compress,
                          label: '压缩',
                          onTap: _compressImage,
                        ),
                        _buildActionButton(
                          icon: Icons.transform,
                          label: '格式转换',
                          onTap: _convertFormat,
                        ),
                        _buildActionButton(
                          icon: Icons.crop,
                          label: '裁剪',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('裁剪功能开发中...')),
                            );
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.share,
                          label: '分享',
                          onTap: _shareImage,
                        ),
                        _buildActionButton(
                          icon: Icons.delete,
                          label: '清除',
                          color: Colors.red,
                          onTap: () => setState(() => _selectedImage = null),
                        ),
                      ],
                    ),
                  ],
                  
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyImageArea() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '选择图片进行处理',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '支持压缩、格式转换、裁剪等功能',
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 70,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color ?? Theme.of(context).primaryColor),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: color ?? Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }
}
