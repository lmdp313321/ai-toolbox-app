/// 工具配置文件 v3.3
/// 58个工具，4大分类
class ToolConfig {
  static const categories = [
    {'id': 'ai', 'name': 'AI智能', 'icon': '🤖', 'sort': 0, 'enabled': true},
    {'id': 'daily', 'name': '日常助手', 'icon': '📅', 'sort': 1, 'enabled': true},
    {'id': 'dev', 'name': '开发工具', 'icon': '💻', 'sort': 2, 'enabled': true},
    {'id': 'utility', 'name': '实用工具', 'icon': '🔧', 'sort': 3, 'enabled': true},
  ];

  static const tools = [
    // ========== AI智能 (12个) ==========
    {'id': 'ai_chat', 'categoryId': 'ai', 'name': 'AI对话', 'icon': '💬', 'description': '多模型AI对话/网页版DeepSeek', 'route': '/tool/ai_chat', 'enabled': true, 'sort': 0},
    {'id': 'ai_writing', 'categoryId': 'ai', 'name': 'AI写作', 'icon': '✍️', 'description': '翻译/摘要/改写/扩写/文案', 'route': '/tool/ai_writing', 'enabled': true, 'sort': 1},
    {'id': 'ai_ocr', 'categoryId': 'ai', 'name': '文字识别', 'icon': '🔍', 'description': '百度+腾讯云OCR拍照提取文字', 'route': '/tool/ai_ocr', 'enabled': true, 'sort': 2},
    {'id': 'ai_image', 'categoryId': 'ai', 'name': 'AI识图', 'icon': '👁️', 'description': '图片描述/分析', 'route': '/tool/ai_image', 'enabled': true, 'sort': 3},
    {'id': 'ai_paint', 'categoryId': 'ai', 'name': 'AI绘画', 'icon': '🎨', 'description': 'AI生成图片', 'route': '/tool/ai_paint', 'enabled': true, 'sort': 4},
    {'id': 'prompt_library', 'categoryId': 'ai', 'name': 'Prompt库', 'icon': '📝', 'description': '提示词模板管理', 'route': '/tool/prompt_library', 'enabled': true, 'sort': 5},
    {'id': 'ai_voice', 'categoryId': 'ai', 'name': 'AI语音', 'icon': '🎙️', 'description': '语音转文字/文字转语音', 'route': '/tool/ai_voice', 'enabled': true, 'sort': 6},
    {'id': 'ai_code', 'categoryId': 'ai', 'name': 'AI代码', 'icon': '👨‍💻', 'description': '代码生成/解释/优化', 'route': '/tool/ai_code', 'enabled': true, 'sort': 7},
    {'id': 'ai_excel', 'categoryId': 'ai', 'name': 'AI表格', 'icon': '📊', 'description': 'Excel公式/数据分析', 'route': '/tool/ai_excel', 'enabled': true, 'sort': 8},
    {'id': 'ai_document', 'categoryId': 'ai', 'name': 'AI文档', 'icon': '📄', 'description': 'PDF对话/文档摘要', 'route': '/tool/ai_document', 'enabled': true, 'sort': 9},
    {'id': 'ai_learn', 'categoryId': 'ai', 'name': 'AI学习', 'icon': '📚', 'description': 'AI辅助学习工具', 'route': '/tool/ai_learn', 'enabled': true, 'sort': 10},
    {'id': 'ai_translate', 'categoryId': 'ai', 'name': 'AI翻译', 'icon': '🌐', 'description': '多引擎智能翻译', 'route': '/tool/ai_translate', 'enabled': true, 'sort': 11},

    // ========== 日常助手 (18个) ==========
    {'id': 'accounting', 'categoryId': 'daily', 'name': '记账本', 'icon': '💰', 'description': '收支记录/分类统计/图表', 'route': '/tool/accounting', 'enabled': true, 'sort': 0},
    {'id': 'schedule', 'categoryId': 'daily', 'name': '日程管理', 'icon': '📅', 'description': '日程安排/提醒', 'route': '/tool/schedule', 'enabled': true, 'sort': 1},
    {'id': 'notes', 'categoryId': 'daily', 'name': '笔记', 'icon': '📝', 'description': '随手记/分类笔记', 'route': '/tool/notes', 'enabled': true, 'sort': 2},
    {'id': 'quick_note', 'categoryId': 'daily', 'name': '速记', 'icon': '⚡', 'description': '打开即写/语音转文字', 'route': '/tool/quick_note', 'enabled': true, 'sort': 3},
    {'id': 'todo_list', 'categoryId': 'daily', 'name': '待办清单', 'icon': '✅', 'description': '任务列表/优先级', 'route': '/tool/todo_list', 'enabled': true, 'sort': 4},
    {'id': 'habit_tracker', 'categoryId': 'daily', 'name': '习惯打卡', 'icon': '🎯', 'description': '每日习惯打卡追踪', 'route': '/tool/habit_tracker', 'enabled': true, 'sort': 5},
    {'id': 'health_record', 'categoryId': 'daily', 'name': '健康记录', 'icon': '❤️', 'description': '体重/饮水/睡眠记录', 'route': '/tool/health_record', 'enabled': true, 'sort': 6},
    {'id': 'drink_reminder', 'categoryId': 'daily', 'name': '喝水提醒', 'icon': '💧', 'description': '定时喝水提醒', 'route': '/tool/drink_reminder', 'enabled': true, 'sort': 7},
    {'id': 'password_gen', 'categoryId': 'daily', 'name': '密码生成', 'icon': '🔐', 'description': '强密码/随机密码', 'route': '/tool/password_gen', 'enabled': true, 'sort': 8},
    {'id': 'reading_notes', 'categoryId': 'daily', 'name': '读书笔记', 'icon': '📖', 'description': '读书摘录/读后感', 'route': '/tool/reading_notes', 'enabled': true, 'sort': 9},
    {'id': 'shopping_list', 'categoryId': 'daily', 'name': '购物清单', 'icon': '🛒', 'description': '购物清单/分类', 'route': '/tool/shopping_list', 'enabled': true, 'sort': 10},
    {'id': 'countdown', 'categoryId': 'daily', 'name': '倒数日', 'icon': '⏰', 'description': '纪念日/考试倒计时', 'route': '/tool/countdown_day', 'enabled': true, 'sort': 11},
    {'id': 'wallpaper_mgr', 'categoryId': 'daily', 'name': '壁纸管理', 'icon': '🖼️', 'description': '壁纸/表情包分类管理', 'route': '/tool/wallpaper_mgr', 'enabled': true, 'sort': 12},
    {'id': 'travel_plan', 'categoryId': 'daily', 'name': '旅行计划', 'icon': '✈️', 'description': '行程/预算/清单', 'route': '/tool/travel_plan', 'enabled': true, 'sort': 13},
    {'id': 'express_query', 'categoryId': 'daily', 'name': '快递查询', 'icon': '📦', 'description': '快递单号/物流跟踪', 'route': '/tool/express_query', 'enabled': true, 'sort': 14},
    {'id': 'data_backup', 'categoryId': 'daily', 'name': '数据备份', 'icon': '💾', 'description': '本地数据导出备份', 'route': '/tool/data_backup', 'enabled': true, 'sort': 15},
    {'id': 'memo', 'categoryId': 'daily', 'name': '备忘', 'icon': '📌', 'description': '速记/提醒/标签', 'route': '/tool/memo', 'enabled': true, 'sort': 16},
    {'id': 'mood_diary', 'categoryId': 'daily', 'name': '心情日记', 'icon': '😊', 'description': '每日心情记录', 'route': '/tool/mood_diary', 'enabled': true, 'sort': 17},

    // ========== 开发工具 (13个) ==========
    {'id': 'json_tool', 'categoryId': 'dev', 'name': 'JSON工具', 'icon': '🔧', 'description': '格式化/校验/压缩/转换', 'route': '/tool/json_tool', 'enabled': true, 'sort': 0},
    {'id': 'text_diff', 'categoryId': 'dev', 'name': '文本对比', 'icon': '📊', 'description': '代码/文本差异对比', 'route': '/tool/text_diff', 'enabled': true, 'sort': 1},
    {'id': 'encoding_tool', 'categoryId': 'dev', 'name': '编码解码', 'icon': '🔤', 'description': 'Base64/URL/HTML/Unicode', 'route': '/tool/encoding_tool', 'enabled': true, 'sort': 2},
    {'id': 'regex_tool', 'categoryId': 'dev', 'name': '正则测试', 'icon': '🔍', 'description': '正则表达式测试/调试', 'route': '/tool/regex_tool', 'enabled': true, 'sort': 3},
    {'id': 'time_tool', 'categoryId': 'dev', 'name': '时间戳', 'icon': '⏱️', 'description': '时间戳/日期格式转换', 'route': '/tool/time_tool', 'enabled': true, 'sort': 4},
    {'id': 'uuid_gen', 'categoryId': 'dev', 'name': 'UUID生成', 'icon': '🆔', 'description': 'UUID/GUID一键生成', 'route': '/tool/uuid_gen', 'enabled': true, 'sort': 5},
    {'id': 'qrcode_gen', 'categoryId': 'dev', 'name': '二维码生成', 'icon': '📱', 'description': '文本/链接生成二维码', 'route': '/tool/qrcode_gen', 'enabled': true, 'sort': 6},
    {'id': 'qrcode_scan', 'categoryId': 'dev', 'name': '扫码', 'icon': '📷', 'description': '扫描二维码/条形码', 'route': '/tool/qrcode_scan', 'enabled': true, 'sort': 7},
    {'id': 'http_tool', 'categoryId': 'dev', 'name': 'HTTP测试', 'icon': '🌐', 'description': 'API调试/请求测试', 'route': '/tool/http_tool', 'enabled': true, 'sort': 8},
    {'id': 'network_tool', 'categoryId': 'dev', 'name': '网络工具', 'icon': '📡', 'description': 'Ping/IP/端口/网络信息', 'route': '/tool/network_tool', 'enabled': true, 'sort': 9},
    {'id': 'ip_query', 'categoryId': 'dev', 'name': 'IP查询', 'icon': '🌍', 'description': '本机IP/公网IP/归属地', 'route': '/tool/ip_query', 'enabled': true, 'sort': 10},
    {'id': 'port_scan', 'categoryId': 'dev', 'name': '端口扫描', 'icon': '🔌', 'description': '局域网端口/设备扫描', 'route': '/tool/port_scan', 'enabled': true, 'sort': 11},
    {'id': 'ascii_table', 'categoryId': 'dev', 'name': '进制转换', 'icon': '🔢', 'description': '进制/ASCII/Unicode互转', 'route': '/tool/ascii_table', 'enabled': true, 'sort': 12},

    // ========== 实用工具 (15个) ==========
    {'id': 'calculator', 'categoryId': 'utility', 'name': '计算器', 'icon': '🧮', 'description': '科学计算器', 'route': '/tool/calculator', 'enabled': true, 'sort': 0},
    {'id': 'unit_convert', 'categoryId': 'utility', 'name': '单位换算', 'icon': '📏', 'description': '长度/重量/温度/面积等', 'route': '/tool/unit_convert', 'enabled': true, 'sort': 1},
    {'id': 'timer_alarm', 'categoryId': 'utility', 'name': '闹钟计时', 'icon': '⏲️', 'description': '倒计时/番茄钟/秒表', 'route': '/tool/timer_alarm', 'enabled': true, 'sort': 2},
    {'id': 'calendar', 'categoryId': 'utility', 'name': '日历', 'icon': '📆', 'description': '公历/农历/黄历/节假日', 'route': '/tool/calendar', 'enabled': true, 'sort': 3},
    {'id': 'weather', 'categoryId': 'utility', 'name': '天气', 'icon': '🌤️', 'description': '实时天气/一周预报', 'route': '/tool/weather', 'enabled': true, 'sort': 4},
    {'id': 'flashlight', 'categoryId': 'utility', 'name': '手电筒', 'icon': '🔦', 'description': '一键开闪光灯', 'route': '/tool/flashlight', 'enabled': true, 'sort': 5},
    {'id': 'phone_info', 'categoryId': 'utility', 'name': '手机信息', 'icon': '📱', 'description': '硬件/系统/存储信息', 'route': '/tool/phone_info', 'enabled': true, 'sort': 6},
    {'id': 'image_tool', 'categoryId': 'utility', 'name': '图片工具', 'icon': '🖼️', 'description': '裁剪/压缩/格式转换', 'route': '/tool/image_tool', 'enabled': true, 'sort': 7},
    {'id': 'level', 'categoryId': 'utility', 'name': '水平仪', 'icon': '📐', 'description': '手机水平/倾斜测量', 'route': '/tool/level', 'enabled': true, 'sort': 8},
    {'id': 'mirror', 'categoryId': 'utility', 'name': '镜子', 'icon': '🪞', 'description': '前置摄像头当镜子', 'route': '/tool/mirror', 'enabled': true, 'sort': 9},
    {'id': 'vibration_test', 'categoryId': 'utility', 'name': '震动测试', 'icon': '📳', 'description': '扬声器/振动马达测试', 'route': '/tool/vibration_test', 'enabled': true, 'sort': 10},
    {'id': 'compass', 'categoryId': 'utility', 'name': '指南针', 'icon': '🧭', 'description': '方向/角度/水平仪', 'route': '/tool/compass', 'enabled': true, 'sort': 11},
  ];
}
