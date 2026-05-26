import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../providers/api_provider.dart';
import '../../../services/ai_service.dart';

/// AI语音页面 - TTS文字转语音
class AiVoicePage extends StatefulWidget {
  const AiVoicePage({super.key});

  @override
  State<AiVoicePage> createState() => _AiVoicePageState();
}

class _AiVoicePageState extends State<AiVoicePage> with SingleTickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final Dio _dio = Dio();
  
  late TabController _tabController;
  
  bool _isGenerating = false;
  bool _isRecording = false;
  String? _audioUrl;
  String? _errorMessage;
  String _recognizedText = '';
  
  // TTS参数
  String _selectedVoice = 'zh-CN-XiaoxiaoNeural';
  double _speed = 1.0;
  
  final List<Map<String, String>> _voices = [
    {'id': 'zh-CN-XiaoxiaoNeural', 'name': '晓晓 (女声)'},
    {'id': 'zh-CN-YunyangNeural', 'name': '云扬 (男声)'},
    {'id': 'zh-CN-YunxiNeural', 'name': '云希 (男声)'},
    {'id': 'zh-CN-XiaoyiNeural', 'name': '晓伊 (女声)'},
    {'id': 'zh-CN-YunjianNeural', 'name': '云健 (男声)'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _textController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  /// 生成语音 (TTS)
  Future<void> _generateSpeech() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入要转换的文字')),
      );
      return;
    }

    final apiConfig = context.read<ApiProvider>().activeConfig;
    if (apiConfig == null || apiConfig.apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先配置API Key')),
      );
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _audioUrl = null;
    });

    try {
      // 使用硅基流动的TTS API
      final response = await _dio.post(
        '${apiConfig!.baseUrl}/audio/speech',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${apiConfig.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.bytes,
        ),
        data: jsonEncode({
          'model': 'FunAudioLLM/CosyVoice2-0.5B',
          'input': text,
          'voice': _selectedVoice,
          'speed': _speed,
          'response_format': 'mp3',
        }),
      );

      if (response.statusCode == 200) {
        // 将音频数据保存为base64用于播放
        final base64Audio = base64Encode(response.data);
        setState(() {
          _audioUrl = 'data:audio/mp3;base64,$base64Audio';
          _isGenerating = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('语音生成成功')),
        );
      } else {
        throw Exception('生成失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      setState(() {
        _errorMessage = 'API错误: ${e.message}';
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '生成失败: $e';
        _isGenerating = false;
      });
    }
  }

  /// 开始语音识别
  Future<void> _startRecording() async {
    setState(() {
      _isRecording = true;
      _recognizedText = '';
    });
    
    // 模拟语音识别
    await Future.delayed(const Duration(seconds: 3));
    
    setState(() {
      _isRecording = false;
      _recognizedText = '（语音识别功能需要接入讯飞或百度语音API）';
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('语音识别功能开发中，请使用文字输入')),
    );
  }

  /// 停止录音
  void _stopRecording() {
    setState(() {
      _isRecording = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI语音'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.record_voice_over), text: '文字转语音'),
            Tab(icon: Icon(Icons.mic), text: '语音转文字'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTTSTab(),
          _buildSTTTab(),
        ],
      ),
    );
  }

  /// 文字转语音界面
  Widget _buildTTSTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 文字输入
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: '输入文字',
              hintText: '请输入要转换为语音的文字...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.text_fields),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 8),
          
          // 快捷操作
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {
                  _textController.clear();
                },
                icon: const Icon(Icons.clear),
                label: const Text('清空'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final data = await Clipboard.getData('text/plain');
                  if (data?.text != null) {
                    _textController.text = data!.text!;
                  }
                },
                icon: const Icon(Icons.paste),
                label: const Text('粘贴'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // 语音选择
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('选择声音', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedVoice,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.record_voice_over),
                    ),
                    items: _voices.map((voice) {
                      return DropdownMenuItem(
                        value: voice['id'],
                        child: Text(voice['name']!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedVoice = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('语速', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('慢'),
                      Expanded(
                        child: Slider(
                          value: _speed,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          label: '${_speed.toStringAsFixed(1)}x',
                          onChanged: (value) {
                            setState(() => _speed = value);
                          },
                        ),
                      ),
                      const Text('快'),
                    ],
                  ),
                  Center(
                    child: Text('${_speed.toStringAsFixed(1)}x', 
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // 生成按钮
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateSpeech,
            icon: _isGenerating 
              ? const SizedBox(
                  width: 20, 
                  height: 20, 
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.volume_up),
            label: Text(_isGenerating ? '生成中...' : '生成语音'),
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            ),
          ],
          
          // 音频播放器占位
          if (_audioUrl != null) ...[
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.audio_file, size: 48, color: Colors.blue),
                    const SizedBox(height: 8),
                    const Text('语音已生成', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '（音频播放功能需要添加音频播放器依赖）',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FilledButton.icon(
                          onPressed: () {
                            // TODO: 播放音频
                          },
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('播放'),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            // TODO: 保存音频
                          },
                          icon: const Icon(Icons.download),
                          label: const Text('保存'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          
          // 说明
          const SizedBox(height: 24),
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
                  '• TTS功能使用硅基流动API\n'
                  '• 支持多种中文语音\n'
                  '• 可调节语速\n'
                  '• 需要配置有效的API Key',
                  style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 语音转文字界面
  Widget _buildSTTTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 录音按钮
            GestureDetector(
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
              onTapCancel: () => _stopRecording(),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? Colors.red : Colors.blue).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  size: 48,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isRecording ? '录音中...' : '按住说话',
              style: TextStyle(
                fontSize: 18,
                color: _isRecording ? Colors.red : Colors.grey[600],
              ),
            ),
            
            if (_recognizedText.isNotEmpty) ...[
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('识别结果:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_recognizedText),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: _recognizedText));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('已复制到剪贴板')),
                            );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('复制'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
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
                      '语音识别功能需要接入讯飞或百度语音识别API，当前为演示模式',
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
}
