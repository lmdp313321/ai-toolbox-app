import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

/// 应用数据库 - 管理所有本地数据（第三版功能）
class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ai_toolbox_app.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createV2Tables(db);
        }
        if (oldVersion < 3) {
          await _createV3Tables(db);
        }
      },
    );
  }

  /// 创建所有表（v1 + v2）
  Future<void> _createTables(Database db) async {
    await _createV1Tables(db);
    await _createV2Tables(db);
  }

  /// 创建v1表
  Future<void> _createV1Tables(Database db) async {
        // ========== 记账本表 ==========
        await db.execute('''
          CREATE TABLE account_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            amount REAL NOT NULL,
            type TEXT NOT NULL,
            category TEXT NOT NULL,
            remark TEXT,
            date TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_account_date ON account_records(date)');
        await db.execute('CREATE INDEX idx_account_type ON account_records(type)');

        // ========== 日程/待办表 ==========
        await db.execute('''
          CREATE TABLE schedules(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            startTime TEXT NOT NULL,
            endTime TEXT,
            isAllDay INTEGER NOT NULL DEFAULT 0,
            isRepeat INTEGER NOT NULL DEFAULT 0,
            repeatType TEXT,
            remindTime TEXT,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_schedule_time ON schedules(startTime)');
        await db.execute('CREATE INDEX idx_schedule_completed ON schedules(isCompleted)');

        // ========== 备忘录表 ==========
        await db.execute('''
          CREATE TABLE memos(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            content TEXT NOT NULL,
            tags TEXT,
            isPinned INTEGER NOT NULL DEFAULT 0,
            createdAt TEXT NOT NULL,
            updatedAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_memo_pinned ON memos(isPinned)');
        await db.execute('CREATE INDEX idx_memo_updated ON memos(updatedAt)');

        // ========== 习惯打卡表 ==========
        await db.execute('''
          CREATE TABLE habits(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            icon TEXT,
            color TEXT,
            description TEXT,
            targetDays INTEGER NOT NULL DEFAULT 21,
            remindTime TEXT,
            createdAt TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE habit_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            habitId INTEGER NOT NULL,
            date TEXT NOT NULL,
            isCompleted INTEGER NOT NULL DEFAULT 0,
            note TEXT,
            FOREIGN KEY (habitId) REFERENCES habits(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('CREATE INDEX idx_habit_record ON habit_records(habitId, date)');

        // ========== 健康记录表 ==========
        await db.execute('''
          CREATE TABLE health_records(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            value REAL NOT NULL,
            unit TEXT,
            note TEXT,
            date TEXT NOT NULL,
            createdAt TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX idx_health_type_date ON health_records(type, date)');
      }

  /// 创建v2表（新增表）
  Future<void> _createV2Tables(Database db) async {
    // ========== 书籍表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS books(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        author TEXT,
        coverPath TEXT,
        totalPages INTEGER NOT NULL DEFAULT 0,
        currentPage INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'reading',
        createdAt TEXT NOT NULL
      )
    ''');

    // ========== 读书笔记表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS book_notes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bookId INTEGER NOT NULL,
        content TEXT NOT NULL,
        page INTEGER,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
      )
    ''');

    // ========== 心情记录表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mood_entries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        mood TEXT NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_mood_date ON mood_entries(date)');

    // ========== 购物清单表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS shopping_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity TEXT,
        price REAL,
        category TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // ========== 旅行表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        destination TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        budget REAL,
        actualCost REAL DEFAULT 0,
        status TEXT DEFAULT 'planning',
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // ========== 旅行行程表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trip_itineraries(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        tripId INTEGER NOT NULL,
        day INTEGER NOT NULL,
        date TEXT,
        title TEXT,
        notes TEXT,
        FOREIGN KEY (tripId) REFERENCES trips(id) ON DELETE CASCADE
      )
    ''');

    // ========== 旅行活动表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trip_activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        itineraryId INTEGER NOT NULL,
        time TEXT,
        title TEXT NOT NULL,
        type TEXT,
        location TEXT,
        cost REAL,
        note TEXT,
        FOREIGN KEY (itineraryId) REFERENCES trip_itineraries(id) ON DELETE CASCADE
      )
    ''');

    // ========== 打包清单表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS packing_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT,
        isPacked INTEGER NOT NULL DEFAULT 0,
        createdAt TEXT NOT NULL
      )
    ''');

    // ========== 倒计时表 ==========
    await db.execute('''
      CREATE TABLE IF NOT EXISTS countdowns(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        duration INTEGER NOT NULL,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  /// 创建v3表（数据库升级）
  Future<void> _createV3Tables(Database db) async {
    // 为books表添加coverPath字段（如果不存在）
    try {
      await db.execute('ALTER TABLE books ADD COLUMN coverPath TEXT');
    } catch (_) {
      // 字段已存在，忽略
    }
  }

  // ========== 记账本方法 ==========
  
  /// 添加记账记录
  Future<int> addAccountRecord(Map<String, dynamic> record) async {
    final db = await database;
    record['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('account_records', record);
  }

  /// 获取记账记录（按日期范围）
  Future<List<Map<String, dynamic>>> getAccountRecords({String? startDate, String? endDate, String? type}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'date BETWEEN ? AND ?';
      whereArgs = [startDate, endDate];
    }
    if (type != null) {
      whereClause = whereClause.isEmpty ? 'type = ?' : '$whereClause AND type = ?';
      whereArgs.add(type);
    }

    return await db.query(
      'account_records',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC, createdAt DESC',
    );
  }

  /// 获取月度统计
  Future<Map<String, double>> getMonthlyStats(String yearMonth) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT type, SUM(amount) as total 
      FROM account_records 
      WHERE date LIKE ? 
      GROUP BY type
    ''', ['$yearMonth%']);

    return {
      'income': result.firstWhere((r) => r['type'] == 'income', orElse: () => {'total': 0})['total'] as double? ?? 0,
      'expense': result.firstWhere((r) => r['type'] == 'expense', orElse: () => {'total': 0})['total'] as double? ?? 0,
    };
  }

  /// 删除记账记录
  Future<int> deleteAccountRecord(int id) async {
    final db = await database;
    return await db.delete('account_records', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 日程方法 ==========

  /// 添加日程
  Future<int> addSchedule(Map<String, dynamic> schedule) async {
    final db = await database;
    schedule['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('schedules', schedule);
  }

  /// 获取日程（按日期范围）
  Future<List<Map<String, dynamic>>> getSchedules({String? startDate, String? endDate, bool? isCompleted}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (startDate != null && endDate != null) {
      whereClause = 'startTime BETWEEN ? AND ?';
      whereArgs = [startDate, endDate];
    }
    if (isCompleted != null) {
      whereClause = whereClause.isEmpty ? 'isCompleted = ?' : '$whereClause AND isCompleted = ?';
      whereArgs.add(isCompleted ? 1 : 0);
    }

    return await db.query(
      'schedules',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'startTime ASC',
    );
  }

  /// 更新日程
  Future<int> updateSchedule(int id, Map<String, dynamic> schedule) async {
    final db = await database;
    return await db.update('schedules', schedule, where: 'id = ?', whereArgs: [id]);
  }

  /// 更新日程完成状态
  Future<int> completeSchedule(int id, bool completed) async {
    final db = await database;
    return await db.update(
      'schedules',
      {'isCompleted': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 删除日程
  Future<int> deleteSchedule(int id) async {
    final db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 备忘录方法 ==========

  /// 添加备忘录
  Future<int> addMemo(Map<String, dynamic> memo) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    memo['createdAt'] = now;
    memo['updatedAt'] = now;
    return await db.insert('memos', memo);
  }

  /// 获取备忘录列表
  Future<List<Map<String, dynamic>>> getMemos({String? search}) async {
    final db = await database;
    if (search != null && search.isNotEmpty) {
      return await db.query(
        'memos',
        where: 'title LIKE ? OR content LIKE ?',
        whereArgs: ['%$search%', '%$search%'],
        orderBy: 'isPinned DESC, updatedAt DESC',
      );
    }
    return await db.query('memos', orderBy: 'isPinned DESC, updatedAt DESC');
  }

  /// 更新备忘录
  Future<int> updateMemo(int id, Map<String, dynamic> memo) async {
    final db = await database;
    memo['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('memos', memo, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除备忘录
  Future<int> deleteMemo(int id) async {
    final db = await database;
    return await db.delete('memos', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 习惯打卡方法 ==========

  /// 添加习惯
  Future<int> addHabit(Map<String, dynamic> habit) async {
    final db = await database;
    habit['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('habits', habit);
  }

  /// 获取习惯列表
  Future<List<Map<String, dynamic>>> getHabits() async {
    final db = await database;
    return await db.query('habits', orderBy: 'createdAt DESC');
  }

  /// 获取所有习惯（别名）
  Future<List<Map<String, dynamic>>> getAllHabits() async => getHabits();

  /// 打卡
  Future<int> checkInHabit(int habitId, String date, {bool completed = true, String? note}) async {
    final db = await database;
    
    // 检查是否已存在记录
    final existing = await db.query(
      'habit_records',
      where: 'habitId = ? AND date = ?',
      whereArgs: [habitId, date],
    );

    if (existing.isNotEmpty) {
      // 更新
      return await db.update(
        'habit_records',
        {'isCompleted': completed ? 1 : 0, 'note': note},
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
    } else {
      // 新增
      return await db.insert('habit_records', {
        'habitId': habitId,
        'date': date,
        'isCompleted': completed ? 1 : 0,
        'note': note,
      });
    }
  }

  /// 获取习惯打卡记录
  Future<List<Map<String, dynamic>>> getHabitRecords(int habitId, {String? startDate, String? endDate}) async {
    final db = await database;
    String whereClause = 'habitId = ?';
    List<dynamic> whereArgs = [habitId];

    if (startDate != null && endDate != null) {
      whereClause += ' AND date BETWEEN ? AND ?';
      whereArgs.addAll([startDate, endDate]);
    }

    return await db.query(
      'habit_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
    );
  }

  /// 获取连续打卡天数
  Future<int> getStreakDays(int habitId) async {
    final db = await database;
    final records = await db.query(
      'habit_records',
      where: 'habitId = ? AND isCompleted = 1',
      whereArgs: [habitId],
      orderBy: 'date DESC',
    );

    if (records.isEmpty) return 0;

    int streak = 0;
    DateTime today = DateTime.now();
    today = DateTime(today.year, today.month, today.day);

    for (var record in records) {
      final date = DateTime.parse(record['date'] as String);
      final expectedDate = today.subtract(Duration(days: streak));
      
      if (date.year == expectedDate.year && 
          date.month == expectedDate.month && 
          date.day == expectedDate.day) {
        streak++;
      } else if (streak == 0 && date.isBefore(today)) {
        // 今天还没打卡，检查昨天
        final yesterday = today.subtract(const Duration(days: 1));
        if (date.year == yesterday.year && 
            date.month == yesterday.month && 
            date.day == yesterday.day) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  /// 删除习惯
  Future<int> deleteHabit(int id) async {
    final db = await database;
    // 关联记录会自动删除（外键约束）
    return await db.delete('habits', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 健康记录方法 ==========

  /// 添加健康记录
  Future<int> addHealthRecord(Map<String, dynamic> record) async {
    final db = await database;
    record['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('health_records', record);
  }

  /// 获取健康记录
  Future<List<Map<String, dynamic>>> getHealthRecords(String type, {String? startDate, String? endDate, int? limit}) async {
    final db = await database;
    String whereClause = 'type = ?';
    List<dynamic> whereArgs = [type];

    if (startDate != null && endDate != null) {
      whereClause += ' AND date BETWEEN ? AND ?';
      whereArgs.addAll([startDate, endDate]);
    }

    return await db.query(
      'health_records',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'date DESC',
      limit: limit,
    );
  }

  /// 删除健康记录
  Future<int> deleteHealthRecord(int id) async {
    final db = await database;
    return await db.delete('health_records', where: 'id = ?', whereArgs: [id]);
  }

  /// 更新习惯
  Future<int> updateHabit(int id, Map<String, dynamic> habit) async {
    final db = await database;
    habit['updatedAt'] = DateTime.now().toIso8601String();
    return await db.update('habits', habit, where: 'id = ?', whereArgs: [id]);
  }

  // ========== 读书笔记方法 ==========

  /// 添加书籍
  Future<int> addBook(Map<String, dynamic> book) async {
    final db = await database;
    book['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('books', book);
  }

  /// 获取书籍列表
  Future<List<Map<String, dynamic>>> getBooks({String? status}) async {
    final db = await database;
    if (status != null && status != 'all') {
      return await db.query('books', where: 'status = ?', whereArgs: [status], orderBy: 'createdAt DESC');
    }
    return await db.query('books', orderBy: 'createdAt DESC');
  }

  /// 更新书籍
  Future<int> updateBook(int id, Map<String, dynamic> book) async {
    final db = await database;
    return await db.update('books', book, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除书籍
  Future<int> deleteBook(int id) async {
    final db = await database;
    return await db.delete('books', where: 'id = ?', whereArgs: [id]);
  }

  /// 添加读书笔记
  Future<int> addBookNote(Map<String, dynamic> note) async {
    final db = await database;
    note['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('book_notes', note);
  }

  /// 获取读书笔记
  Future<List<Map<String, dynamic>>> getBookNotes(int bookId) async {
    final db = await database;
    return await db.query('book_notes', where: 'bookId = ?', whereArgs: [bookId], orderBy: 'date DESC');
  }

  /// 删除读书笔记
  Future<int> deleteBookNote(int id) async {
    final db = await database;
    return await db.delete('book_notes', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 心情日记方法 ==========

  /// 添加心情记录
  Future<int> addMoodEntry(Map<String, dynamic> entry) async {
    final db = await database;
    entry['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('mood_entries', entry);
  }

  /// 获取心情记录
  Future<List<Map<String, dynamic>>> getMoodEntries({String? startDate, String? endDate}) async {
    final db = await database;
    String whereClause = '';
    List<dynamic> whereArgs = [];
    
    if (startDate != null && endDate != null) {
      whereClause = 'date BETWEEN ? AND ?';
      whereArgs = [startDate, endDate];
    }
    
    return await db.query(
      'mood_entries',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'date DESC',
    );
  }

  /// 删除心情记录
  Future<int> deleteMoodEntry(int id) async {
    final db = await database;
    return await db.delete('mood_entries', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 购物清单方法 ==========

  /// 添加购物项
  Future<int> addShoppingItem(Map<String, dynamic> item) async {
    final db = await database;
    item['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('shopping_items', item);
  }

  /// 获取购物清单
  Future<List<Map<String, dynamic>>> getShoppingItems({bool? completed}) async {
    final db = await database;
    if (completed != null) {
      return await db.query('shopping_items', where: 'isCompleted = ?', whereArgs: [completed ? 1 : 0], orderBy: 'createdAt DESC');
    }
    return await db.query('shopping_items', orderBy: 'createdAt DESC');
  }

  /// 更新购物项
  Future<int> updateShoppingItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update('shopping_items', item, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除购物项
  Future<int> deleteShoppingItem(int id) async {
    final db = await database;
    return await db.delete('shopping_items', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 旅行规划方法 ==========

  /// 添加行程
  Future<int> addTrip(Map<String, dynamic> trip) async {
    final db = await database;
    trip['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('trips', trip);
  }

  /// 获取行程列表
  Future<List<Map<String, dynamic>>> getTrips() async {
    final db = await database;
    return await db.query('trips', orderBy: 'startDate DESC');
  }

  /// 更新行程
  Future<int> updateTrip(int id, Map<String, dynamic> trip) async {
    final db = await database;
    return await db.update('trips', trip, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除行程
  Future<int> deleteTrip(int id) async {
    final db = await database;
    return await db.delete('trips', where: 'id = ?', whereArgs: [id]);
  }

  /// 添加打包物品
  Future<int> addPackingItem(Map<String, dynamic> item) async {
    final db = await database;
    item['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('packing_items', item);
  }

  /// 获取打包清单
  Future<List<Map<String, dynamic>>> getPackingItems() async {
    final db = await database;
    return await db.query('packing_items', orderBy: 'createdAt DESC');
  }

  /// 更新打包物品
  Future<int> updatePackingItem(int id, Map<String, dynamic> item) async {
    final db = await database;
    return await db.update('packing_items', item, where: 'id = ?', whereArgs: [id]);
  }

  /// 删除打包物品
  Future<int> deletePackingItem(int id) async {
    final db = await database;
    return await db.delete('packing_items', where: 'id = ?', whereArgs: [id]);
  }

  // ========== 旅行行程详情方法 ==========

  /// 获取行程的日程安排
  Future<List<Map<String, dynamic>>> getTripItineraries(int tripId) async {
    final db = await database;
    return await db.query(
      'trip_itineraries',
      where: 'tripId = ?',
      whereArgs: [tripId],
      orderBy: 'day ASC',
    );
  }

  /// 添加行程日程
  Future<int> insertTripItinerary(int tripId, int day, String title, String? date) async {
    final db = await database;
    return await db.insert('trip_itineraries', {
      'tripId': tripId,
      'day': day,
      'title': title,
      'date': date,
    });
  }

  /// 获取日程活动
  Future<List<Map<String, dynamic>>> getTripActivities(int itineraryId) async {
    final db = await database;
    return await db.query(
      'trip_activities',
      where: 'itineraryId = ?',
      whereArgs: [itineraryId],
      orderBy: 'time ASC',
    );
  }

  /// 添加活动
  Future<int> insertTripActivity(int itineraryId, String title, String type, String? location, double? cost, String? time) async {
    final db = await database;
    return await db.insert('trip_activities', {
      'itineraryId': itineraryId,
      'title': title,
      'type': type,
      'location': location,
      'cost': cost,
      'time': time,
    });
  }

  /// 获取旅行费用统计
  Future<Map<String, dynamic>> getTripExpenseStats(int tripId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(cost) as totalCost 
      FROM trip_activities a
      JOIN trip_itineraries i ON a.itineraryId = i.id
      WHERE i.tripId = ?
    ''', [tripId]);
    return {'totalCost': (result.first['totalCost'] as num?)?.toDouble() ?? 0.0};
  }

  /// 获取旅行费用分类统计
  Future<List<Map<String, dynamic>>> getTripExpensesByCategory(int tripId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT a.type as category, SUM(a.cost) as total
      FROM trip_activities a
      JOIN trip_itineraries i ON a.itineraryId = i.id
      WHERE i.tripId = ? AND a.cost IS NOT NULL
      GROUP BY a.type
      ORDER BY total DESC
    ''', [tripId]);
  }

  // ========== 倒计时方法 ==========

  /// 添加倒计时
  Future<int> addCountdown(Map<String, dynamic> countdown) async {
    final db = await database;
    countdown['createdAt'] = DateTime.now().toIso8601String();
    return await db.insert('countdowns', countdown);
  }

  /// 获取倒计时列表
  Future<List<Map<String, dynamic>>> getCountdowns() async {
    final db = await database;
    return await db.query('countdowns', orderBy: 'createdAt DESC');
  }

  /// 删除倒计时
  Future<int> deleteCountdown(int id) async {
    final db = await database;
    return await db.delete('countdowns', where: 'id = ?', whereArgs: [id]);
  }

  /// 关闭数据库
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}



