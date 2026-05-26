import 'dart:convert';
import 'package:dio/dio.dart';
import '../providers/api_provider.dart';

/// AI服务 - 调用各种AI API
class AiService {
  static final Dio _dio = Dio();
  
  /// 发送聊天请求
  static Future<String> chat({
    required List<Map<String, dynamic>> messages,
    required ApiConfig config,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async {
    if (config.apiKey.isEmpty) {
      throw Exception('API Key未配置');
    }
    
    try {
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': config.model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('API错误: ${e.response?.data['error']['message'] ?? e.message}');
      } else {
        throw Exception('网络错误: ${e.message}');
      }
    }
  }
  
  /// 发送流式聊天请求
  static Stream<String> chatStream({
    required List<Map<String, dynamic>> messages,
    required ApiConfig config,
    double temperature = 0.7,
    int maxTokens = 4096,
  }) async* {
    if (config.apiKey.isEmpty) {
      throw Exception('API Key未配置');
    }
    
    try {
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
          responseType: ResponseType.stream,
        ),
        data: jsonEncode({
          'model': config.model,
          'messages': messages,
          'temperature': temperature,
          'max_tokens': maxTokens,
          'stream': true,
        }),
      );
      
      await for (final chunk in response.data.stream) {
        final lines = utf8.decode(chunk).split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ') && !line.contains('[DONE]')) {
            try {
              final json = jsonDecode(line.substring(6));
              final content = json['choices']?[0]?['delta']?['content'];
              if (content != null) {
                yield content;
              }
            } catch (_) {}
          }
        }
      }
    } catch (e) {
      throw Exception('流式请求失败: $e');
    }
  }
  
  /// 图片识别
  static Future<String> analyzeImage({
    required String imageUrl,
    required String prompt,
    required ApiConfig config,
  }) async {
    if (config.apiKey.isEmpty) {
      throw Exception('API Key未配置');
    }
    
    try {
      final response = await _dio.post(
        '${config.baseUrl}/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': config.model,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': prompt},
                {'type': 'image_url', 'image_url': {'url': imageUrl}},
              ],
            }
          ],
        }),
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('图片识别失败: $e');
    }
  }
  
  /// 语音转文字
  static Future<String> transcribe({
    required String audioPath,
    required ApiConfig config,
  }) async {
    if (config.apiKey.isEmpty) {
      throw Exception('API Key未配置');
    }
    
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(audioPath),
        'model': 'whisper-1',
      });
      
      final response = await _dio.post(
        '${config.baseUrl}/audio/transcriptions',
        options: Options(
          headers: {
            'Authorization': 'Bearer ${config.apiKey}',
          },
        ),
        data: formData,
      );
      
      if (response.statusCode == 200) {
        return response.data['text'];
      } else {
        throw Exception('请求失败: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('语音识别失败: $e');
    }
  }
}
