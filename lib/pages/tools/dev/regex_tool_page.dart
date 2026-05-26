import 'package:flutter/material.dart';

class RegexToolPage extends StatefulWidget {
  const RegexToolPage({super.key});
  @override
  State<RegexToolPage> createState() => _RegexToolPageState();
}

class _RegexToolPageState extends State<RegexToolPage> {
  final TextEditingController _patternController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  List<Match> _matches = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('正则测试')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _patternController,
              decoration: const InputDecoration(
                labelText: '正则表达式',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '测试文本',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _test, child: const Text('测试匹配')),
            const SizedBox(height: 16),
            Text('匹配结果: ${_matches.length} 个'),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _matches.length,
                itemBuilder: (context, index) {
                  final m = _matches[index];
                  return ListTile(
                    title: Text(m.group(0) ?? ''),
                    subtitle: Text('位置: ${m.start}-${m.end}'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _test() {
    try {
      final pattern = RegExp(_patternController.text);
      setState(() {
        _matches = pattern.allMatches(_textController.text).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正则表达式错误: $e')),
      );
    }
  }
}
