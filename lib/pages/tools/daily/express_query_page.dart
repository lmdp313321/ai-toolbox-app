import 'package:flutter/material.dart';

class ExpressQueryPage extends StatefulWidget {
  const ExpressQueryPage({super.key});
  @override
  State<ExpressQueryPage> createState() => _ExpressQueryPageState();
}

class _ExpressQueryPageState extends State<ExpressQueryPage> {
  final TextEditingController _controller = TextEditingController();
  String? _result;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('快递查询')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '输入快递单号',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.local_shipping),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    setState(() => _result = '查询中...');
                    Future.delayed(const Duration(seconds: 1), () {
                      setState(() => _result = '快递单号: ${_controller.text}\n\n物流信息查询功能开发中，\n后续将对接快递100/快递鸟API');
                    });
                  },
                ),
              ),
            ),
            if (_result != null)
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SelectableText(_result!),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
