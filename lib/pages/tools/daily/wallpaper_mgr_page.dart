import 'package:flutter/material.dart';

class WallpaperMgrPage extends StatefulWidget {
  const WallpaperMgrPage({super.key});
  @override
  State<WallpaperMgrPage> createState() => _WallpaperMgrPageState();
}

class _WallpaperMgrPageState extends State<WallpaperMgrPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('壁纸管理')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wallpaper, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('壁纸/表情包管理'),
            const SizedBox(height: 8),
            const Text('功能开发中...', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
