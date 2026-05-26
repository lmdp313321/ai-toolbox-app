import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

/// HTTP测试页面 - API接口调试
class HttpTestPage extends StatefulWidget {
  const HttpTestPage({super.key});

  @override
  State<HttpTestPage> createState() => _HttpTestPageState();
}

class _HttpTestPageState extends State<HttpTestPage> {
  String _selectedMethod = 'GET';
  final TextEditingController _urlController = TextEditingController(
    text: 'https://api.github.com/users/github',
  );
  final TextEditingController _headersController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  
  bool _isLoading = false;
  Response? _response;
  String? _error;
  
  final Dio _dio = Dio();
  final List<String> _methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'HEAD'];

  Future<void> _sendRequest() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _response = null;
      _error = null;
    });

    try {
      // 解析headers
      final headers = <String, dynamic>{};
      if (_headersController.text.isNotEmpty) {
        try {
          final headerMap = json.decode(_headersController.text);
          headers.addAll(headerMap.cast<String, dynamic>());
        } catch (e) {
          // 简单的header解析
          for (final line in _headersController.text.split('\n')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              headers[parts[0].trim()] = parts.sublist(1).join(':').trim();
            }
          }
        }
      }

      Response response;
      final options = Options(
        headers: headers,
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      );

      switch (_selectedMethod) {
        case 'GET':
          response = await _dio.get(url, options: options);
          break;
        case 'POST':
          response = await _dio.post(
            url,
            data: _bodyController.text.isNotEmpty ? _bodyController.text : null,
            options: options,
          );
          break;
        case 'PUT':
          response = await _dio.put(
            url,
            data: _bodyController.text.isNotEmpty ? _bodyController.text : null,
            options: options,
          );
          break;
        case 'DELETE':
          response = await _dio.delete(url, options: options);
          break;
        case 'PATCH':
          response = await _dio.patch(
            url,
            data: _bodyController.text.isNotEmpty ? _bodyController.text : null,
            options: options,
          );
          break;
        case 'HEAD':
          response = await _dio.head(url, options: options);
          break;
        default:
          response = await _dio.get(url, options: options);
      }

      setState(() => _response = response);
    } on DioException catch (e) {
      setState(() => _error = '请求失败: ${e.message}\n${e.response?.statusMessage ?? ""}');
      if (e.response != null) {
        setState(() => _response = e.response);
      }
    } catch (e) {
      setState(() => _error = '错误: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HTTP测试'),
      ),
      body: Column(
        children: [
          // 请求区域
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                // 方法和URL
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[400]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMethod,
                          items: _methods.map((m) => DropdownMenuItem(
                            value: m,
                            child: Text(m, style: const TextStyle(fontWeight: FontWeight.bold)),
                          )).toList(),
                          onChanged: (v) => setState(() => _selectedMethod = v!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          hintText: '输入URL',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _isLoading ? null : _sendRequest,
                      child: _isLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('发送'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 选项卡
          Expanded(
            child: DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: '请求'),
                      Tab(text: '响应'),
                      Tab(text: '历史'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildRequestTab(),
                        _buildResponseTab(),
                        _buildHistoryTab(),
                      ],
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

  Widget _buildRequestTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headers
          const Text('请求头 (Headers)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _headersController,
            decoration: const InputDecoration(
              hintText: '{"Content-Type": "application/json"}',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          
          const SizedBox(height: 16),
          
          // Body
          if (_selectedMethod != 'GET' && _selectedMethod != 'HEAD') ...[
            const Text('请求体 (Body)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _bodyController,
              decoration: const InputDecoration(
                hintText: '{"key": "value"}',
                border: OutlineInputBorder(),
              ),
              maxLines: 8,
            ),
          ],
          
          // 快捷设置
          const SizedBox(height: 16),
          const Text('快捷设置', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                label: const Text('JSON Headers'),
                onPressed: () {
                  _headersController.text = '''{
  "Content-Type": "application/json",
  "Accept": "application/json"
}''';
                },
              ),
              ActionChip(
                label: const Text('清空Body'),
                onPressed: () => _bodyController.clear(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResponseTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_error != null && _response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ),
      );
    }
    
    if (_response == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.http, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('点击发送按钮测试API', style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      );
    }

    String formattedBody;
    try {
      final jsonData = json.decode(_response!.data.toString());
      formattedBody = const JsonEncoder.withIndent('  ').convert(jsonData);
    } catch (e) {
      formattedBody = _response!.data.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 状态码
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: (_response!.statusCode ?? 0) >= 200 && (_response!.statusCode ?? 0) < 300
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_response!.statusCode} ${_response!.statusMessage ?? ""}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text('耗时: ${_response!.headers.value('x-response-time') ?? "未知"}'),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // 响应头
          const Text('响应头', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _response!.headers.map.map(
                (k, v) => MapEntry(k, '$k: ${v.join(", ")}'),
              ).values.join('\n'),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // 响应体
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('响应体', style: TextStyle(fontWeight: FontWeight.bold)),
              TextButton.icon(
                onPressed: () {
                  // 复制响应
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('复制'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(4),
            ),
            child: SelectableText(
              formattedBody,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('请求历史功能开发中...'),
        ],
      ),
    );
  }
}
