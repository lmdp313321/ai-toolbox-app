import 'package:flutter/material.dart';
import 'dart:math';

class PasswordGenPage extends StatefulWidget {
  const PasswordGenPage({super.key});
  @override
  State<PasswordGenPage> createState() => _PasswordGenPageState();
}

class _PasswordGenPageState extends State<PasswordGenPage> {
  String _password = '';
  int _length = 16;
  bool _uppercase = true;
  bool _lowercase = true;
  bool _numbers = true;
  bool _symbols = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('密码生成')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 生成的密码
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _password.isEmpty ? '点击生成按钮生成密码' : _password,
                style: const TextStyle(fontSize: 18, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 24),
            
            // 长度滑块
            Row(
              children: [
                const Text('长度: '),
                Expanded(
                  child: Slider(
                    value: _length.toDouble(),
                    min: 8,
                    max: 64,
                    divisions: 56,
                    label: _length.toString(),
                    onChanged: (v) => setState(() => _length = v.round()),
                  ),
                ),
                Text('$_length'),
              ],
            ),
            
            // 选项
            SwitchListTile(title: const Text('大写字母'), value: _uppercase, onChanged: (v) => setState(() => _uppercase = v)),
            SwitchListTile(title: const Text('小写字母'), value: _lowercase, onChanged: (v) => setState(() => _lowercase = v)),
            SwitchListTile(title: const Text('数字'), value: _numbers, onChanged: (v) => setState(() => _numbers = v)),
            SwitchListTile(title: const Text('特殊符号'), value: _symbols, onChanged: (v) => setState(() => _symbols = v)),
            
            const Spacer(),
            
            // 生成按钮
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _generatePassword,
                icon: const Icon(Icons.refresh),
                label: const Text('生成密码'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _generatePassword() {
    String chars = '';
    if (_uppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (_lowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (_numbers) chars += '0123456789';
    if (_symbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';
    
    if (chars.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一种字符类型')),
      );
      return;
    }

    final random = Random();
    setState(() {
      _password = List.generate(_length, (_) => chars[random.nextInt(chars.length)]).join();
    });
  }
}
