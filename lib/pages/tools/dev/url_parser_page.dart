import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// URL参数解析工具
class UrlParserPage extends StatefulWidget {
  const UrlParserPage({super.key});

  @override
  State<UrlParserPage> createState() => _UrlParserPageState();
}

class _UrlParserPageState extends State<UrlParserPage> {
  final TextEditingController _urlController = TextEditingController();
  Uri? _parsedUri;
  Map<String, String> _params = {};
  String _error = '';

  void _parseUrl() {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() {
        _error = '请输入URL';
        _parsedUri = null;
        _params = {};
      });
      return;
    }

    try {
      String urlToParse = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlToParse = 'https://$url';
      }
      
      final uri = Uri.parse(urlToParse);
      setState(() {
        _parsedUri = uri;
        _params = uri.queryParameters;
        _error = '';
      });
    } catch (e) {
      setState(() {
        _error = 'URL解析失败: $e';
        _parsedUri = null;
        _params = {};
      });
    }
  }

  void _clear() {
    _urlController.clear();
    setState(() {
      _parsedUri = null;
      _params = {};
      _error = '';
    });
  }

  void _copyParam(String key) {
    final value = _params[key] ?? '';
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制参数值: $key')),
    );
  }

  void _copyAllParams() {
    final buffer = StringBuffer();
    for (final entry in _params.entries) {
      buffer.writeln('${entry.key}: ${entry.value}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('已复制所有参数')),
    );
  }

  void _buildUrlFromParams() {
    final scheme = _parsedUri?.scheme ?? 'https';
    final host = _parsedUri?.host ?? '';
    final path = _parsedUri?.path ?? '';
    
    final queryString = _params.entries
        .map((e) => '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
    
    final newUrl = queryString.isNotEmpty
        ? '$scheme://$host$path?$queryString'
        : '$scheme://$host$path';
    
    Clipboard.setData(ClipboardData(text: newUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已复制重构URL: $newUrl')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔗 URL参数解析'),
        actions: [
          IconButton(
            onPressed: _clear,
            icon: const Icon(Icons.clear_all),
            tooltip: '清空',
          ),
        ],
      ),
      body: Column(
        children: [
          // URL输入区
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: '输入URL',
                    hintText: 'https://example.com?name=value&key=test',
                    border: const OutlineInputBorder(),
                    suffixIcon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.paste),
                          onPressed: () async {
                            final data = await Clipboard.getData('text/plain');
                            if (data?.text != null) {
                              _urlController.text = data!.text!;
                            }
                          },
                          tooltip: '粘贴',
                        ),
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => _urlController.clear(),
                          tooltip: '清空',
                        ),
                      ],
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _parseUrl,
                        icon: const Icon(Icons.link),
                        label: const Text('解析URL'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // 错误提示
          if (_error.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.red[50],
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_error, style: TextStyle(color: Colors.red[700])),
                  ),
                ],
              ),
            ),
          
          // 解析结果
          if (_parsedUri != null)
            Expanded(
              child: Column(
                children: [
                  // URL基本信息
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('URL信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 12),
                        _buildInfoRow('协议 (Scheme):', _parsedUri!.scheme),
                        _buildInfoRow('主机 (Host):', _parsedUri!.host),
                        _buildInfoRow('端口 (Port):', _parsedUri!.port.toString()),
                        _buildInfoRow('路径 (Path):', _parsedUri!.path),
                        if (_parsedUri!.fragment.isNotEmpty)
                          _buildInfoRow('锚点 (Fragment):', _parsedUri!.fragment),
                      ],
                    ),
                  ),
                  
                  // 参数列表
                  if (_params.isNotEmpty) ...[
                    const Divider(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Query参数',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _copyAllParams,
                            icon: const Icon(Icons.copy, size: 18),
                            label: const Text('复制全部'),
                          ),
                          TextButton.icon(
                            onPressed: _buildUrlFromParams,
                            icon: const Icon(Icons.build, size: 18),
                            label: const Text('重构URL'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _params.length,
                        itemBuilder: (context, index) {
                          final entry = _params.entries.elementAt(index);
                          return _buildParamItem(entry.key, entry.value);
                        },
                      ),
                    ),
                  ] else if (_parsedUri != null)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text('该URL没有Query参数', style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                ],
              ),
            ),
          
          // 空状态
          if (_parsedUri == null && _error.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_off, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('输入URL后点击解析', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                value.isEmpty ? '(空)' : value,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParamItem(String key, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        title: Text(
          key,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        subtitle: Container(
          margin: const EdgeInsets.only(top: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            value.isEmpty ? '(空值)' : value,
            style: TextStyle(
              fontFamily: 'monospace',
              color: value.isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () => _copyParam(key),
          tooltip: '复制值',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}