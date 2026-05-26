/// 聊天会话模型
class ChatSession {
  final String id;
  final String title;
  final String aiSource; // deepseek_web, doubao_web, silicon_api, nvidia_api
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.aiSource,
    required this.createdAt,
    required this.updatedAt,
    this.messages = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'aiSource': aiSource,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ChatSession.fromMap(Map<String, dynamic> map, {List<ChatMessage> messages = const []}) {
    return ChatSession(
      id: map['id'],
      title: map['title'],
      aiSource: map['aiSource'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      messages: messages,
    );
  }

  ChatSession copyWith({
    String? id,
    String? title,
    String? aiSource,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      aiSource: aiSource ?? this.aiSource,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? this.messages,
    );
  }
}

/// 聊天消息模型
class ChatMessage {
  final String id;
  final String sessionId;
  final String role; // user, assistant, system
  final String content;
  final DateTime timestamp;
  final bool isError;
  final String? model; // 使用的模型（API模式）

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isError = false,
    this.model,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sessionId': sessionId,
      'role': role,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'isError': isError ? 1 : 0,
      'model': model,
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'],
      sessionId: map['sessionId'],
      role: map['role'],
      content: map['content'],
      timestamp: DateTime.parse(map['timestamp']),
      isError: map['isError'] == 1,
      model: map['model'],
    );
  }
}

/// AI源类型枚举
enum AISourceType {
  deepseekWeb('deepseek_web', 'DeepSeek', '网页版', true),
  doubaoWeb('doubao_web', '豆包', '网页版', true),
  siliconApi('silicon_api', '硅基流动', 'API', false),
  nvidiaApi('nvidia_api', '英伟达', 'API', false);

  final String code;
  final String name;
  final String type;
  final bool isWebView;

  const AISourceType(this.code, this.name, this.type, this.isWebView);

  static AISourceType fromCode(String code) {
    return AISourceType.values.firstWhere(
      (e) => e.code == code,
      orElse: () => AISourceType.siliconApi,
    );
  }
}
