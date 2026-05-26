import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../models/chat_models.dart';

/// 聊天记录数据库管理
class ChatDatabase {
  static final ChatDatabase _instance = ChatDatabase._internal();
  factory ChatDatabase() => _instance;
  ChatDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_toolbox_chat.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 创建会话表
        await db.execute('''
          CREATE TABLE chat_sessions(
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            aiSource TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');

        // 创建消息表
        await db.execute('''
          CREATE TABLE chat_messages(
            id TEXT PRIMARY KEY,
            sessionId TEXT NOT NULL,
            role TEXT NOT NULL,
            content TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            isError INTEGER NOT NULL DEFAULT 0,
            model TEXT,
            FOREIGN KEY (sessionId) REFERENCES chat_sessions(id) ON DELETE CASCADE
          )
        ''');

        // 创建索引
        await db.execute('CREATE INDEX idx_messages_session ON chat_messages(sessionId)');
        await db.execute('CREATE INDEX idx_messages_timestamp ON chat_messages(timestamp)');
      },
    );
  }

  /// 创建新会话
  Future<String> createSession(String title, String aiSource) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    await db.insert('chat_sessions', {
      'id': id,
      'title': title,
      'aiSource': aiSource,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    });

    return id;
  }

  /// 获取所有会话（按更新时间倒序）
  Future<List<ChatSession>> getAllSessions() async {
    final db = await database;
    final maps = await db.query(
      'chat_sessions',
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => ChatSession.fromMap(map)).toList();
  }

  /// 获取单个会话
  Future<ChatSession?> getSession(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    if (maps.isEmpty) return null;

    final messages = await getMessages(sessionId);
    return ChatSession.fromMap(maps.first, messages: messages);
  }

  /// 更新会话标题
  Future<void> updateSessionTitle(String sessionId, String title) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {
        'title': title,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 更新会话时间
  Future<void> updateSessionTime(String sessionId) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 删除会话
  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  /// 添加消息
  Future<void> addMessage(ChatMessage message) async {
    final db = await database;
    await db.insert('chat_messages', message.toMap());
    await updateSessionTime(message.sessionId);
  }

  /// 获取会话的所有消息
  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  /// 删除消息
  Future<void> deleteMessage(String messageId) async {
    final db = await database;
    await db.delete(
      'chat_messages',
      where: 'id = ?',
      whereArgs: [messageId],
    );
  }

  /// 搜索会话
  Future<List<ChatSession>> searchSessions(String keyword) async {
    final db = await database;
    final maps = await db.query(
      'chat_sessions',
      where: 'title LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'updatedAt DESC',
    );

    return maps.map((map) => ChatSession.fromMap(map)).toList();
  }

  /// 搜索消息内容
  Future<List<ChatMessage>> searchMessages(String keyword) async {
    final db = await database;
    final maps = await db.query(
      'chat_messages',
      where: 'content LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => ChatMessage.fromMap(map)).toList();
  }

  /// 清空所有数据
  Future<void> clearAll() async {
    final db = await database;
    await db.delete('chat_messages');
    await db.delete('chat_sessions');
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
