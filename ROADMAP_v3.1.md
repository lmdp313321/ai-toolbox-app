# AI工具箱 - 第四版开发路线图 (v3.1)

## 版本信息
- **版本号**: v3.1
- **开发时间**: 2026-04-06 至 2026-04-10
- **开发者**: QQ 40305583
- **目标**: 增加生活助手功能

---

## 新增功能规划

### 1. 阅读笔记 📚
**功能描述**: 书籍管理和阅读进度追踪

**核心功能**:
- [ ] 书籍信息录入（书名/作者/封面）
- [ ] 阅读进度百分比
- [ ] 章节笔记标注
- [ ] 书籍分类标签
- [ ] 阅读时长统计
- [ ] 书架视图（网格/列表）

**数据库表**:
```sql
CREATE TABLE books(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  author TEXT,
  coverPath TEXT,
  totalPages INTEGER,
  currentPage INTEGER DEFAULT 0,
  status TEXT DEFAULT 'reading', -- reading/finished/wishlist
  rating INTEGER,
  startDate TEXT,
  finishDate TEXT,
  createdAt TEXT NOT NULL
);

CREATE TABLE book_notes(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  bookId INTEGER NOT NULL,
  page INTEGER,
  content TEXT NOT NULL,
  type TEXT DEFAULT 'note', -- note/quote/thought
  createdAt TEXT NOT NULL,
  FOREIGN KEY (bookId) REFERENCES books(id) ON DELETE CASCADE
);
```

---

### 2. 心情日记 😊
**功能描述**: 每日心情记录和趋势分析

**核心功能**:
- [ ] 心情选择器（5级表情）
- [ ] 日记文字记录
- [ ] 心情趋势图表（周/月/年）
- [ ] 标签系统（工作/生活/健康等）
- [ ] 日记回顾（随机历史日记）
- [ ] 数据统计（平均心情值）

**数据库表**:
```sql
CREATE TABLE mood_records(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  date TEXT NOT NULL UNIQUE,
  moodLevel INTEGER NOT NULL, -- 1-5
  content TEXT,
  tags TEXT, -- JSON数组
  weather TEXT,
  location TEXT,
  createdAt TEXT NOT NULL
);
```

---

### 3. 购物清单 🛒
**功能描述**: 智能购物清单管理

**核心功能**:
- [ ] 商品分类（生鲜/日用品/食品等）
- [ ] 购买状态勾选
- [ ] 预算管理
- [ ] 价格记录
- [ ] 常用商品库
- [ ] 清单模板（快速创建）

**数据库表**:
```sql
CREATE TABLE shopping_lists(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  budget REAL,
  totalCost REAL DEFAULT 0,
  isCompleted INTEGER DEFAULT 0,
  createdAt TEXT NOT NULL
);

CREATE TABLE shopping_items(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  listId INTEGER NOT NULL,
  name TEXT NOT NULL,
  category TEXT,
  quantity TEXT,
  price REAL,
  isPurchased INTEGER DEFAULT 0,
  note TEXT,
  FOREIGN KEY (listId) REFERENCES shopping_lists(id) ON DELETE CASCADE
);
```

---

### 4. 旅行计划 ✈️
**功能描述**: 旅行行程规划和景点管理

**核心功能**:
- [ ] 旅程基本信息（目的地/时间/预算）
- [ ] 日程安排（每天活动）
- [ ] 景点信息（名称/地址/门票）
- [ ] 交通信息记录
- [ ] 住宿信息
- [ ] 行李清单
- [ ] 费用统计

**数据库表**:
```sql
CREATE TABLE trips(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL,
  destination TEXT,
  startDate TEXT,
  endDate TEXT,
  budget REAL,
  actualCost REAL DEFAULT 0,
  status TEXT DEFAULT 'planning', -- planning/ongoing/finished
  coverImage TEXT,
  createdAt TEXT NOT NULL
);

CREATE TABLE trip_itineraries(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  tripId INTEGER NOT NULL,
  day INTEGER NOT NULL,
  date TEXT,
  title TEXT,
  notes TEXT,
  FOREIGN KEY (tripId) REFERENCES trips(id) ON DELETE CASCADE
);

CREATE TABLE trip_activities(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  itineraryId INTEGER NOT NULL,
  time TEXT,
  title TEXT NOT NULL,
  type TEXT, -- sight/food/transport/accommodation
  location TEXT,
  cost REAL,
  note TEXT,
  FOREIGN KEY (itineraryId) REFERENCES trip_itineraries(id) ON DELETE CASCADE
);
```

---

## 技术优化

### 状态管理升级
- [ ] 评估 Riverpod 替换 Provider
- [ ] 统一状态管理方案

### 代码质量
- [ ] 添加单元测试（数据库操作）
- [ ] 代码格式化检查
- [ ] 减少重复代码

### UI 优化
- [ ] 统一主题颜色配置
- [ ] 添加空状态插图
- [ ] 优化加载动画

---

## 开发计划时间表

| 日期 | 任务 | 负责人 |
|------|------|--------|
| 04-06 | 阅读笔记功能开发 | 小宝 |
| 04-07 | 心情日记功能开发 | 小宝 |
| 04-08 | 购物清单功能开发 | 小宝 |
| 04-09 | 旅行计划功能开发 | 小宝 |
| 04-10 | 测试修复、打包发布 | 小宝 |

---

## 注意事项

### 开发原则
1. **稳定性优先**: 新功能必须编译通过才能提交
2. **依赖精简**: 优先使用 Flutter 内置组件
3. **数据库先行**: 先设计表结构，再写页面
4. **测试验证**: 每个功能完成后立即测试

### 必查清单
- [ ] pubspec.yaml 版本号更新为 3.1.0
- [ ] 数据库版本升级逻辑（如有表变更）
- [ ] 新增页面路由配置
- [ ] 页面添加到工具列表

---

## 版本发布

### v3.1 发布标准
- [ ] 4个新功能全部可用
- [ ] 编译无警告无错误
- [ ] 代码已提交 Git
- [ ] 已打标签 v3.1
- [ ] 知识库已更新

---

**开始时间**: 2026-04-06
**预计完成**: 2026-04-10
**开发者QQ**: 40305583
