import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:async';

class PhoneInfoPage extends StatefulWidget {
  const PhoneInfoPage({super.key});
  @override
  State<PhoneInfoPage> createState() => _PhoneInfoPageState();
}

class _PhoneInfoPageState extends State<PhoneInfoPage> {
  Map<String, String> _info = {};

  @override
  void initState() {
    super.initState();
    _getInfo();
  }

  void _getInfo() {
    setState(() {
      _info = {
        '系统': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        '架构': Platform.version,
        '主机': Platform.localHostname,
        'Dart版本': Platform.version.split(' ').first,
        '路径分隔符': Platform.pathSeparator,
        '换行符': Platform.lineTerminator == '\n' ? 'LF (\\n)' : 'CRLF',
        '处理器数': '${Platform.numberOfProcessors}',
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('手机信息')),
      body: RefreshIndicator(
        onRefresh: () async {
          _getInfo();
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.phone_android, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    Text('设备信息', style: Theme.of(context).textTheme.titleMedium),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._info.entries.map((e) => Card(
              child: ListTile(
                title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(e.value),
              ),
            )),
          ],
        ),
      ),
    );
  }
}
