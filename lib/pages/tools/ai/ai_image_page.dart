import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// AI识图页面 - 腾讯云OCR
/// 支持通用文字识别、身份证识别、银行卡识别等
class AiImagePage extends StatefulWidget {
  const AiImagePage({super.key});

  @override
  State<AiImagePage> createState() => _AiImagePageState();
}

class _AiImagePageState extends State<AiImagePage> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final Dio _dio = Dio();
  
  late TabController _tabController;
  
  File? _selectedImage;
  Uint8List? _imageBytes;
  bool _isProcessing = false;
  String _result = '';
  String _ocrType = 'general'; // general, idcard, bankcard, license
  
  // 腾讯云配置 - 请到设置页面配置你的密钥
  static const String _secretId = 'YOUR_TENCENT_SECRET_ID';
  static const String _secretKey = 'YOUR_TENCENT_SECRET_KEY';
  static const String _region = 'ap-guangzhou';
  static const String _service = 'ocr';
  static const String _host = 'ocr.tencentcloudapi.com';
  
  final Map<String, Map<String, String>> _ocrTypes = {
    'general': {
      'name': '通用文字识别',
      'action': 'GeneralBasicOCR',
      'version': '2018-11-19',
      'desc': '识别图片中的文字',
    },
    'accurate': {
      'name': '高精度版',
      'action': 'GeneralAccurateOCR',
      'version': '2018-11-19',
      'desc': '更高精度的文字识别',
    },
    'handwriting': {
      'name': '手写识别',
      'action': 'GeneralHandwritingOCR',
      'version': '2018-11-19',
      'desc': '识别手写文字',
    },
    'idcard': {
      'name': '身份证识别',
      'action': 'IDCardOCR',
      'version': '2018-11-19',
      'desc': '识别身份证信息',
    },
    'bankcard': {
      'name': '银行卡识别',
      'action': 'BankCardOCR',
      'version': '2018-11-19',
      'desc': '识别银行卡信息',
    },
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 选择图片
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (picked != null) {
        final file = File(picked.path);
        final bytes = await file.readAsBytes();
        
        setState(() {
          _selectedImage = file;
          _imageBytes = bytes;
          _result = '';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('选择图片失败: $e')),
      );
    }
  }

  /// 生成腾讯云API签名
  Map<String, String> _generateSignature(String action, String version, String payload) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final date = _formatDate(DateTime.now());
    
    // 1. 创建规范请求
    final httpRequestMethod = 'POST';
    final canonicalUri = '/';
    final canonicalQueryString = '';
    final canonicalHeaders = 'content-type:application/json\nhost:$_host\n';
    final signedHeaders = 'content-type;host';
    final hashedRequestPayload = sha256.convert(utf8.encode(payload)).toString().toLowerCase();
    final canonicalRequest = '$httpRequestMethod\n$canonicalUri\n$canonicalQueryString\n$canonicalHeaders\n$signedHeaders\n$hashedRequestPayload';
    
    // 2. 创建待签名字符串
    final algorithm = 'TC3-HMAC-SHA256';
    final credentialScope = '$date/$_service/tc3_request';
    final hashedCanonicalRequest = sha256.convert(utf8.encode(canonicalRequest)).toString().toLowerCase();
    final stringToSign = '$algorithm\n$timestamp\n$credentialScope\n$hashedCanonicalRequest';
    
    // 3. 计算签名
    final secretDate = _hmacSha256(utf8.encode('TC3$_secretKey'), utf8.encode(date));
    final secretService = _hmacSha256(secretDate, utf8.encode(_service));
    final secretSigning = _hmacSha256(secretService, utf8.encode('tc3_request'));
    final signature = _hmacSha256(secretSigning, utf8.encode(stringToSign));
    final signatureHex = signature.map((b) => b.toRadixString(16).padLeft(2, '0')).join('').toLowerCase();
    
    // 4. 构建Authorization
    final authorization = '$algorithm Credential=$_secretId/$credentialScope, SignedHeaders=$signedHeaders, Signature=$signatureHex';
    
    return {
      'Authorization': authorization,
      'Content-Type': 'application/json',
      'Host': _host,
      'X-TC-Action': action,
      'X-TC-Version': version,
      'X-TC-Timestamp': timestamp.toString(),
      'X-TC-Region': _region,
    };
  }

  /// HMAC-SHA256
  List<int> _hmacSha256(List<int> key, List<int> message) {
    final hmac = Hmac(sha256, key);
    return hmac.convert(message).bytes;
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return '${date.year}${_twoDigits(date.month)}${_twoDigits(date.day)}';
  }

  String _twoDigits(int n) {
    return n >= 10 ? '$n' : '0$n';
  }

  /// 执行OCR识别
  Future<void> _performOCR() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择图片')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _result = '';
    });

    try {
      // Base64编码图片
      final base64Image = base64Encode(_imageBytes!);
      
      // 获取OCR类型配置
      final ocrConfig = _ocrTypes[_ocrType]!;
      final action = ocrConfig['action']!;
      final version = ocrConfig['version']!;
      
      // 构建请求体
      final payload = jsonEncode({
        'ImageBase64': base64Image,
      });
      
      // 生成签名
      final headers = _generateSignature(action, version, payload);
      
      // 发送请求
      final response = await _dio.post(
        'https://$_host',
        options: Options(
          headers: headers,
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
        data: payload,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        if (data['Response']?['Error'] != null) {
          final error = data['Response']['Error'];
          setState(() {
            _result = '❌ 识别失败\n\n错误码: ${error['Code']}\n错误信息: ${error['Message']}';
          });
        } else {
          // 格式化结果
          setState(() {
            _result = _formatResult(data['Response']);
          });
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() {
        _result = '❌ 请求失败\n\n${e.message}\n\n请检查网络连接和API配置';
      });
    } catch (e) {
      setState(() {
        _result = '❌ 识别失败\n\n$e\n\n可能是图片格式不支持或API配置错误';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// 格式化识别结果
  String _formatResult(Map<String, dynamic> response) {
    final buffer = StringBuffer();
    buffer.writeln('✅ 识别成功');
    buffer.writeln('');
    
    // 通用文字识别
    if (response['TextDetections'] != null) {
      buffer.writeln('📄 识别内容:');
      buffer.writeln('');
      final detections = response['TextDetections'] as List;
      for (var i = 0; i < detections.length; i++) {
        final detection = detections[i];
        buffer.writeln('${i + 1}. ${detection['DetectedText']}');
        if (detection['Confidence'] != null) {
          buffer.writeln('   置信度: ${detection['Confidence']}%');
        }
      }
      
      // 所有文字
      if (response['Text'] != null) {
        buffer.writeln('');
        buffer.writeln('📝 完整文本:');
        buffer.writeln(response['Text']);
      }
    }
    
    // 身份证识别
    if (response['Name'] != null) {
      buffer.writeln('🆔 身份证信息:');
      buffer.writeln('姓名: ${response['Name']}');
      buffer.writeln('性别: ${response['Sex']}');
      buffer.writeln('民族: ${response['Nation']}');
      buffer.writeln('出生: ${response['Birth']}');
      buffer.writeln('地址: ${response['Address']}');
      buffer.writeln('身份证号: ${response['IdNum']}');
    }
    
    // 银行卡识别
    if (response['CardNo'] != null) {
      buffer.writeln('💳 银行卡信息:');
      buffer.writeln('卡号: ${response['CardNo']}');
      buffer.writeln('银行: ${response['BankInfo']}');
      buffer.writeln('类型: ${response['CardType']}');
      buffer.writeln('有效期: ${response['ValidDate']}');
    }
    
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI识图'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.camera_alt), text: 'OCR识别'),
            Tab(icon: Icon(Icons.image_search), text: '图片描述'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOCRTab(),
          _buildImageDescTab(),
        ],
      ),
    );
  }

  /// OCR识别界面
  Widget _buildOCRTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // OCR类型选择
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('识别类型', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _ocrTypes.entries.map((entry) {
                      final isSelected = _ocrType == entry.key;
                      return ChoiceChip(
                        label: Text(entry.value['name']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _ocrType = entry.key;
                            });
                          }
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ocrTypes[_ocrType]!['desc']!,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 图片选择区域
          Card(
            child: InkWell(
              onTap: () => _showImageSourceDialog(),
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        _imageBytes!,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text('点击选择图片', style: TextStyle(color: Colors.grey[600])),
                        const SizedBox(height: 4),
                        Text('支持拍照或从相册选择', 
                          style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      ],
                    ),
              ),
            ),
          ),
          
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _imageBytes = null;
                  _result = '';
                });
              },
              icon: const Icon(Icons.delete, color: Colors.red),
              label: const Text('移除图片', style: TextStyle(color: Colors.red)),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // 识别按钮
          FilledButton.icon(
            onPressed: _isProcessing ? null : _performOCR,
            icon: _isProcessing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.document_scanner),
            label: Text(_isProcessing ? '识别中...' : '开始识别'),
          ),
          
          const SizedBox(height: 16),
          
          // 识别结果
          if (_result.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('识别结果', style: TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.copy, size: 20),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _result));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制到剪贴板')),
                            );
                          },
                          tooltip: '复制',
                        ),
                      ],
                    ),
                    const Divider(),
                    SelectableText(_result),
                  ],
                ),
              ),
            ),
          ],
          
          // 使用说明
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Text('使用说明', style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    )),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '• 使用腾讯云OCR服务\n'
                  '• 支持通用文字、身份证、银行卡识别\n'
                  '• 识别结果自动复制到剪贴板\n'
                  '• 每日有免费额度限制',
                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 图片描述界面（使用AI模型）
  Widget _buildImageDescTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_search, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              '图片描述功能',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '上传图片，AI会生成详细描述',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '此功能需要使用支持视觉的多模态模型\n如 GPT-4V、Qwen-VL 等',
                      style: TextStyle(fontSize: 13, color: Colors.orange[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 显示图片来源选择对话框
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('拍照'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('从相册选择'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }
}
