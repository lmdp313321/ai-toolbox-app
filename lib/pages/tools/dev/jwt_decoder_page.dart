import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// JWT解码工具
/// 支持解码JWT Token的Header和Payload
/// 版本: v3.1.0
/// 开发者: 40305583
class JwtDecoderPage extends StatefulWidget {
  const JwtDecoderPage({super.key});

  @override
  State<JwtDecoderPage> createState() => _JwtDecoderPageState();
}

class _JwtDecoderPageState extends State<JwtDecoderPage> {
  final TextEditingController _jwtController = TextEditingController();
  Map<String, dynamic>? _header;
  Map<String, dynamic>? _payload;
  String? _signature;
  String? _errorMessage;
  bool _isValid = false;

  /// 解码JWT
  void _decodeJwt() {
    final token = _jwtController.text.trim();
    
    if (token.isEmpty) {
      setState(() {
        _errorMessage = '请输入JWT Token';
        _clearDecodedData();
      });
      return;
    }

    try {
      // JWT格式: header.payload.signature
      final parts = token.split('.');
      if (parts.length != 3) {
        throw FormatException('JWT格式错误，应包含3个部分');
      }

      // 解码Header
      final headerJson = _decodeBase64(parts[0]);
      final header = jsonDecode(headerJson) as Map<String, dynamic>;

      // 解码Payload
      final payloadJson = _decodeBase64(parts[1]);
      final payload = jsonDecode(payloadJson) as Map<String, dynamic>;

      // Signature保持原样（是加密的，无法解码）
      final signature = parts[2];

      setState(() {
        _header = header;
        _payload = payload;
        _signature = signature;
        _isValid = true;
        _errorMessage = null;
      });

    } catch (e) {
      setState(() {
        _errorMessage = '解码失败: $e';
        _clearDecodedData();
      });
    }
  }

  /// Base64解码（处理URL安全字符）
  String _decodeBase64(String input) {
    // 替换URL安全字符为标准Base64字符
    String normalized = input.replaceAll('-', '+').replaceAll('_', '/');
    
    // 补齐Padding
    final padding = 4 - (normalized.length % 4);
    if (padding != 4) {
      normalized += '=' * padding;
    }
    
    // 解码
    final bytes = base64Decode(normalized);
    return utf8.decode(bytes);
  }

  /// 清空解码数据
  void _clearDecodedData() {
    _header = null;
    _payload = null;
    _signature = null;
    _isValid = false;
  }

  /// 清空输入
  void _clear() {
    _jwtController.clear();
    setState(() {
      _clearDecodedData();
      _errorMessage = null;
    });
  }

  /// 粘贴剪贴板内容
  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData('text/plain');
      if (data?.text != null) {
        _jwtController.text = data!.text!;
        _decodeJwt();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('粘贴失败: $e')),
      );
    }
  }

  /// 复制内容到剪贴板
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label已复制')),
    );
  }

  /// 格式化JSON显示
  String _formatJson(Map<String, dynamic>? data) {
    if (data == null) return '';
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  /// 格式化时间戳
  String _formatTimestamp(int? timestamp) {
    if (timestamp == null) return '无';
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${dateTime.toLocal()} (${_getTimeAgo(timestamp)})';
  }

  /// 获取相对时间
  String _getTimeAgo(int timestamp) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diff = timestamp - now;
    
    if (diff < 0) {
      return '已过期 ${_formatDuration(-diff)}';
    } else {
      return '还有 ${_formatDuration(diff)}';
    }
  }

  /// 格式化时长
  String _formatDuration(int seconds) {
    if (seconds < 60) return '$seconds秒';
    if (seconds < 3600) return '${seconds ~/ 60}分钟';
    if (seconds < 86400) return '${seconds ~/ 3600}小时';
    return '${seconds ~/ 86400}天';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔐 JWT解码'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clear,
            tooltip: '清空',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // JWT输入区
            _buildInputSection(),
            const SizedBox(height: 16),
            
            // 操作按钮
            _buildActionButtons(),
            const SizedBox(height: 16),
            
            // 错误提示
            if (_errorMessage != null) _buildErrorCard(),
            
            // 解码结果
            if (_isValid) ...[
              // 验证状态
              _buildValidationCard(),
              const SizedBox(height: 16),
              
              // Header
              _buildHeaderCard(),
              const SizedBox(height: 16),
              
              // Payload
              _buildPayloadCard(),
              const SizedBox(height: 16),
              
              // Signature
              _buildSignatureCard(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建输入区域
  Widget _buildInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'JWT Token',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _jwtController,
          decoration: InputDecoration(
            hintText: 'eyJhbGciOiJIUzI1NiIs...',
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.vpn_key),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: _pasteFromClipboard,
                  tooltip: '粘贴',
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _jwtController.clear(),
                  tooltip: '清空',
                ),
              ],
            ),
          ),
          maxLines: 5,
          minLines: 2,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ],
    );
  }

  /// 构建操作按钮
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _decodeJwt,
            icon: const Icon(Icons.lock_open),
            label: const Text('解码Token'),
          ),
        ),
      ],
    );
  }

  /// 构建错误卡片
  Widget _buildErrorCard() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建验证状态卡片
  Widget _buildValidationCard() {
    final exp = _payload?['exp'] as int?;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final isExpired = exp != null && exp < now;
    
    return Card(
      color: isExpired ? Colors.orange[50] : Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isExpired ? Icons.warning : Icons.check_circle,
                  color: isExpired ? Colors.orange[700] : Colors.green[700],
                ),
                const SizedBox(width: 8),
                Text(
                  isExpired ? 'Token已过期' : 'Token有效',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isExpired ? Colors.orange[700] : Colors.green[700],
                  ),
                ),
              ],
            ),
            if (exp != null) ...[
              const SizedBox(height: 8),
              Text('过期时间: ${_formatTimestamp(exp)}'),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建Header卡片
  Widget _buildHeaderCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.title, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Header (头部)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(
                    _formatJson(_header),
                    'Header',
                  ),
                  tooltip: '复制',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('算法 (alg)', _header?['alg']?.toString() ?? '无'),
                _buildInfoRow('类型 (typ)', _header?['typ']?.toString() ?? '无'),
                const Divider(),
                Text(
                  _formatJson(_header),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Payload卡片
  Widget _buildPayloadCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Payload (负载)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(
                    _formatJson(_payload),
                    'Payload',
                  ),
                  tooltip: '复制',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('签发者 (iss)', _payload?['iss']?.toString()),
                _buildInfoRow('主题 (sub)', _payload?['sub']?.toString()),
                _buildInfoRow('受众 (aud)', _payload?['aud']?.toString()),
                _buildInfoRow(
                  '签发时间 (iat)',
                  _formatTimestamp(_payload?['iat'] as int?),
                ),
                _buildInfoRow(
                  '过期时间 (exp)',
                  _formatTimestamp(_payload?['exp'] as int?),
                ),
                _buildInfoRow(
                  '生效时间 (nbf)',
                  _formatTimestamp(_payload?['nbf'] as int?),
                ),
                const Divider(),
                Text(
                  _formatJson(_payload),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建Signature卡片
  Widget _buildSignatureCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.security, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Signature (签名)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20),
                  onPressed: () => _copyToClipboard(
                    _signature ?? '',
                    'Signature',
                  ),
                  tooltip: '复制',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '签名是加密的，无法直接解码。用于验证Token的完整性和真实性。',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _signature ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 构建信息行
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '无',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _jwtController.dispose();
    super.dispose();
  }
}