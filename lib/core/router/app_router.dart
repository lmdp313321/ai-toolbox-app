import 'package:flutter/material.dart';
import '../../pages/home/home_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/settings/api_config_page.dart';
import '../../pages/settings/tool_manage_page.dart';
import '../../pages/settings/model_manage_page.dart';

// ========== AI智能 (12) ==========
import '../../pages/tools/ai/ai_chat_page_v2.dart';
import '../../pages/tools/ai/ai_writing_page.dart';
import '../../pages/tools/ai/ai_ocr_page.dart';
import '../../pages/tools/ai/ai_image_page.dart';
import '../../pages/tools/ai/ai_paint_page.dart';
import '../../pages/tools/ai/prompt_library_page.dart';
import '../../pages/tools/ai/ai_voice_page.dart';
import '../../pages/tools/ai/ai_code_page.dart';
import '../../pages/tools/ai/ai_excel_page.dart';
import '../../pages/tools/ai/ai_document_page.dart';
import '../../pages/tools/ai/ai_learn_page.dart';
import '../../pages/tools/ai/ai_translate_page.dart';

// ========== 日常助手 (18) ==========
import '../../pages/tools/daily/accounting_page.dart';
import '../../pages/tools/daily/schedule_page.dart';
import '../../pages/tools/daily/notes_page.dart';
import '../../pages/tools/daily/quick_note_page.dart';
import '../../pages/tools/daily/todo_list_page.dart';
import '../../pages/tools/daily/habit_tracker_page.dart';
import '../../pages/tools/daily/health_record_page.dart';
import '../../pages/tools/daily/drink_reminder_page.dart';
import '../../pages/tools/daily/password_gen_page.dart';
import '../../pages/tools/daily/reading_notes_page.dart';
import '../../pages/tools/daily/shopping_list_page.dart';
import '../../pages/tools/daily/countdown_page.dart';
import '../../pages/tools/daily/wallpaper_mgr_page.dart';
import '../../pages/tools/daily/trip_planning_page.dart';
import '../../pages/tools/daily/express_query_page.dart';
import '../../pages/tools/daily/data_backup_page.dart';
import '../../pages/tools/daily/memo_page.dart';
import '../../pages/tools/daily/mood_diary_page.dart';

// ========== 开发工具 (13) ==========
import '../../pages/tools/dev/json_tool_page.dart';
import '../../pages/tools/dev/text_diff_page.dart';
import '../../pages/tools/dev/encoding_tool_page.dart';
import '../../pages/tools/dev/regex_tool_page.dart';
import '../../pages/tools/dev/time_tool_page.dart';
import '../../pages/tools/dev/uuid_gen_page.dart';
import '../../pages/tools/dev/qrcode_gen_page.dart';
import '../../pages/tools/dev/qrcode_scan_page.dart';
import '../../pages/tools/dev/http_test_page.dart';
import '../../pages/tools/dev/network_tool_page.dart';
import '../../pages/tools/dev/ip_query_page.dart';
import '../../pages/tools/dev/port_scan_page.dart';
import '../../pages/tools/dev/ascii_table_page.dart';

// ========== 实用工具 (15) ==========
import '../../pages/tools/utility/calculator_page.dart';
import '../../pages/tools/utility/unit_convert_page.dart';
import '../../pages/tools/utility/timer_page.dart';
import '../../pages/tools/utility/calendar_page.dart';
import '../../pages/tools/utility/weather_page.dart';
import '../../pages/tools/utility/flashlight_page.dart';
import '../../pages/tools/utility/phone_info_page.dart';
import '../../pages/tools/utility/image_tool_page.dart';
import '../../pages/tools/utility/level_page.dart';
import '../../pages/tools/utility/mirror_page.dart';
import '../../pages/tools/utility/vibration_test_page.dart';
import '../../pages/tools/utility/compass_page.dart';

// 旧的页面仍然保留（作为fallback）
import '../../pages/tools/dev/code_diff_page.dart' as old_diff;
import '../../pages/tools/dev/qr_code_page.dart' as old_qr;


class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case '/settings/api':
        return MaterialPageRoute(builder: (_) => const ApiConfigPage());
      case '/settings/tools':
        return MaterialPageRoute(builder: (_) => const ToolManagePage());
      case '/settings/models':
        return MaterialPageRoute(builder: (_) => const ModelManagePage());
      
      // ========== AI智能 ==========
      case '/tool/ai_chat':
        return MaterialPageRoute(builder: (_) => const AiChatPage());
      case '/tool/ai_writing':
        return MaterialPageRoute(builder: (_) => const AiWritingPage());
      case '/tool/ai_ocr':
        return MaterialPageRoute(builder: (_) => const AiOcrPage());
      case '/tool/ai_image':
        return MaterialPageRoute(builder: (_) => const AiImagePage());
      case '/tool/ai_paint':
        return MaterialPageRoute(builder: (_) => const AiPaintPage());
      case '/tool/prompt_library':
        return MaterialPageRoute(builder: (_) => const PromptLibraryPage());
      case '/tool/ai_voice':
        return MaterialPageRoute(builder: (_) => const AiVoicePage());
      case '/tool/ai_code':
        return MaterialPageRoute(builder: (_) => const AiCodePage());
      case '/tool/ai_excel':
        return MaterialPageRoute(builder: (_) => const AiExcelPage());
      case '/tool/ai_document':
        return MaterialPageRoute(builder: (_) => const AiDocumentPage());
      case '/tool/ai_learn':
        return MaterialPageRoute(builder: (_) => const AiLearnPage());
      case '/tool/ai_translate':
        return MaterialPageRoute(builder: (_) => const AiTranslatePage());
      
      // ========== 日常助手 ==========
      case '/tool/accounting':
        return MaterialPageRoute(builder: (_) => const AccountingPage());
      case '/tool/schedule':
        return MaterialPageRoute(builder: (_) => const SchedulePage());
      case '/tool/notes':
        return MaterialPageRoute(builder: (_) => const NotesPage());
      case '/tool/quick_note':
        return MaterialPageRoute(builder: (_) => const QuickNotePage());
      case '/tool/todo_list':
        return MaterialPageRoute(builder: (_) => const TodoListPage());
      case '/tool/habit_tracker':
        return MaterialPageRoute(builder: (_) => const HabitTrackerPage());
      case '/tool/health_record':
        return MaterialPageRoute(builder: (_) => const HealthRecordPage());
      case '/tool/drink_reminder':
        return MaterialPageRoute(builder: (_) => const DrinkReminderPage());
      case '/tool/password_gen':
        return MaterialPageRoute(builder: (_) => const PasswordGenPage());
      case '/tool/reading_notes':
        return MaterialPageRoute(builder: (_) => const ReadingNotesPage());
      case '/tool/shopping_list':
        return MaterialPageRoute(builder: (_) => const ShoppingListPage());
      case '/tool/countdown_day':
        return MaterialPageRoute(builder: (_) => const CountdownDayPage());
      case '/tool/wallpaper_mgr':
        return MaterialPageRoute(builder: (_) => const WallpaperMgrPage());
      case '/tool/travel_plan':
        return MaterialPageRoute(builder: (_) => const TripPlanningPage());
      case '/tool/express_query':
        return MaterialPageRoute(builder: (_) => const ExpressQueryPage());
      case '/tool/data_backup':
        return MaterialPageRoute(builder: (_) => const DataBackupPage());
      case '/tool/memo':
        return MaterialPageRoute(builder: (_) => const MemoPage());
      case '/tool/mood_diary':
        return MaterialPageRoute(builder: (_) => const MoodDiaryPage());
      
      // ========== 开发工具 ==========
      case '/tool/json_tool':
        return MaterialPageRoute(builder: (_) => const JsonToolPage());
      case '/tool/text_diff':
        return MaterialPageRoute(builder: (_) => const TextDiffPage());
      case '/tool/encoding_tool':
        return MaterialPageRoute(builder: (_) => const EncodingToolPage());
      case '/tool/regex_tool':
        return MaterialPageRoute(builder: (_) => const RegexToolPage());
      case '/tool/time_tool':
        return MaterialPageRoute(builder: (_) => const TimeToolPage());
      case '/tool/uuid_gen':
        return MaterialPageRoute(builder: (_) => const UuidGenPage());
      case '/tool/qrcode_gen':
        return MaterialPageRoute(builder: (_) => const QrcodeGenPage());
      case '/tool/qrcode_scan':
        return MaterialPageRoute(builder: (_) => const QrcodeScanPage());
      case '/tool/http_tool':
        return MaterialPageRoute(builder: (_) => const HttpTestPage());
      case '/tool/network_tool':
        return MaterialPageRoute(builder: (_) => const NetworkToolPage());
      case '/tool/ip_query':
        return MaterialPageRoute(builder: (_) => const IpQueryPage());
      case '/tool/port_scan':
        return MaterialPageRoute(builder: (_) => const PortScanPage());
      case '/tool/ascii_table':
        return MaterialPageRoute(builder: (_) => const AsciiTablePage());
      
      // ========== 实用工具 ==========
      case '/tool/calculator':
        return MaterialPageRoute(builder: (_) => const CalculatorPage());
      case '/tool/unit_convert':
        return MaterialPageRoute(builder: (_) => const UnitConvertPage());
      case '/tool/timer_alarm':
        return MaterialPageRoute(builder: (_) => const TimerPage());
      case '/tool/calendar':
        return MaterialPageRoute(builder: (_) => const CalendarPage());
      case '/tool/weather':
        return MaterialPageRoute(builder: (_) => const WeatherPage());
      case '/tool/flashlight':
        return MaterialPageRoute(builder: (_) => const FlashlightPage());
      case '/tool/phone_info':
        return MaterialPageRoute(builder: (_) => const PhoneInfoPage());
      case '/tool/image_tool':
        return MaterialPageRoute(builder: (_) => const ImageToolPage());
      case '/tool/level':
        return MaterialPageRoute(builder: (_) => const LevelPage());
      case '/tool/mirror':
        return MaterialPageRoute(builder: (_) => const MirrorPage());
      case '/tool/vibration_test':
        return MaterialPageRoute(builder: (_) => const VibrationTestPage());
      case '/tool/compass':
        return MaterialPageRoute(builder: (_) => const CompassPage());
      
      // ========== 兼容旧路由 ==========
      case '/tool/json':
        return MaterialPageRoute(builder: (_) => const JsonToolPage());
      case '/tool/encoding':
        return MaterialPageRoute(builder: (_) => const EncodingToolPage());
      case '/tool/regex':
        return MaterialPageRoute(builder: (_) => const RegexToolPage());
      case '/tool/time':
        return MaterialPageRoute(builder: (_) => const TimeToolPage());
      case '/tool/unit':
        return MaterialPageRoute(builder: (_) => const UnitConvertPage());
      case '/tool/network':
        return MaterialPageRoute(builder: (_) => const NetworkToolPage());
      case '/tool/http_test':
        return MaterialPageRoute(builder: (_) => const HttpTestPage());
      case '/tool/countdown':
        return MaterialPageRoute(builder: (_) => const CountdownDayPage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('页面不存在')),
            body: const Center(child: Text('404 - 该工具还在开发中')),
          ),
        );
    }
  }
}
