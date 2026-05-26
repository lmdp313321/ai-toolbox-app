import 'package:flutter/material.dart';
import '../../pages/home/home_page.dart';
import '../../pages/settings/settings_page.dart';
import '../../pages/settings/api_config_page.dart';
import '../../pages/settings/tool_manage_page.dart';
import '../../pages/settings/model_manage_page.dart';

// AI智能工具页面
import '../../pages/tools/ai/ai_chat_page_v2.dart';
import '../../pages/tools/ai/ai_writing_page.dart';
import '../../pages/tools/ai/ai_image_page.dart';
import '../../pages/tools/ai/ai_paint_page.dart';
import '../../pages/tools/ai/prompt_library_page.dart';
import '../../pages/tools/ai/ai_voice_page.dart';
import '../../pages/tools/ai/ai_code_page.dart';
import '../../pages/tools/ai/ai_excel_page.dart';
import '../../pages/tools/ai/ai_document_page.dart';
import '../../pages/tools/ai/ai_learn_page.dart';

// 日常助手工具页面
import '../../pages/tools/daily/accounting_page.dart';
import '../../pages/tools/daily/schedule_page.dart';
import '../../pages/tools/daily/memo_page.dart';
import '../../pages/tools/daily/password_gen_page.dart';
import '../../pages/tools/daily/habit_tracker_page.dart';
import '../../pages/tools/daily/health_record_page.dart';
import '../../pages/tools/daily/reading_notes_page.dart';
import '../../pages/tools/daily/mood_diary_page.dart';
import '../../pages/tools/daily/shopping_list_page.dart';
import '../../pages/tools/daily/trip_planning_page.dart';
import '../../pages/tools/daily/data_backup_page.dart';
import '../../pages/tools/daily/notes_page.dart';

// 开发工具页面
import '../../pages/tools/dev/json_tool_page.dart';
import '../../pages/tools/dev/encoding_tool_page.dart';
import '../../pages/tools/dev/encrypt_tool_page.dart';
import '../../pages/tools/dev/regex_tool_page.dart';
import '../../pages/tools/dev/time_tool_page.dart';
import '../../pages/tools/dev/code_diff_page.dart';
import '../../pages/tools/dev/color_picker_page.dart';
import '../../pages/tools/dev/url_parser_page.dart';
import '../../pages/tools/dev/qr_code_page.dart';
import '../../pages/tools/dev/jwt_decoder_page.dart';
import '../../pages/tools/dev/html_escape_page.dart';
import '../../pages/tools/dev/http_test_page.dart';
import '../../pages/tools/dev/git_command_page.dart';
import '../../pages/tools/dev/code_format_page.dart';

// AI智能工具补充
import '../../pages/tools/ai/ai_translate_page.dart';

// 实用工具页面
import '../../pages/tools/utility/qrcode_page.dart';
import '../../pages/tools/utility/image_tool_page.dart';
import '../../pages/tools/utility/text_tool_page.dart';
import '../../pages/tools/utility/unit_convert_page.dart';
import '../../pages/tools/utility/color_tool_page.dart';
import '../../pages/tools/utility/weather_page.dart';
import '../../pages/tools/utility/phone_lookup_page.dart';
import '../../pages/tools/utility/exchange_rate_page.dart';
import '../../pages/tools/utility/world_clock_page.dart';
import '../../pages/tools/utility/network_tool_page.dart';

// v3.2.0 新增实用工具
import '../../pages/tools/utility/calculator_page.dart';
import '../../pages/tools/utility/countdown_page.dart';
import '../../pages/tools/utility/random_number_page.dart';
import '../../pages/tools/utility/decision_helper_page.dart';
import '../../pages/tools/utility/calendar_page.dart';
import '../../pages/tools/utility/bmi_calculator_page.dart';
import '../../pages/tools/utility/mortgage_calculator_page.dart';
import '../../pages/tools/utility/network_speed_page.dart';

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
      
      // AI智能工具
      case '/tool/ai_chat':
        return MaterialPageRoute(builder: (_) => const AiChatPage());
      case '/tool/ai_writing':
        return MaterialPageRoute(builder: (_) => const AiWritingPage());
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
      
      // 日常助手工具
      case '/tool/accounting':
        return MaterialPageRoute(builder: (_) => const AccountingPage());
      case '/tool/schedule':
        return MaterialPageRoute(builder: (_) => const SchedulePage());
      case '/tool/notes':
        return MaterialPageRoute(builder: (_) => const MemoPage());
      case '/tool/password_gen':
        return MaterialPageRoute(builder: (_) => const PasswordGenPage());
      case '/tool/habit_tracker':
        return MaterialPageRoute(builder: (_) => const HabitTrackerPage());
      case '/tool/health_record':
        return MaterialPageRoute(builder: (_) => const HealthRecordPage());
      case '/tool/reading_notes':
        return MaterialPageRoute(builder: (_) => const ReadingNotesPage());
      case '/tool/mood_diary':
        return MaterialPageRoute(builder: (_) => const MoodDiaryPage());
      case '/tool/shopping_list':
        return MaterialPageRoute(builder: (_) => const ShoppingListPage());
      case '/tool/travel_plan':
        return MaterialPageRoute(builder: (_) => const TripPlanningPage());
      
      // 开发工具
      case '/tool/json':
        return MaterialPageRoute(builder: (_) => const JsonToolPage());
      case '/tool/code_diff':
      case '/tool/text_diff':
        return MaterialPageRoute(builder: (_) => const CodeDiffPage());
      case '/tool/encoding':
        return MaterialPageRoute(builder: (_) => const EncodingToolPage());
      case '/tool/regex':
        return MaterialPageRoute(builder: (_) => const RegexToolPage());
      case '/tool/time':
        return MaterialPageRoute(builder: (_) => const TimeToolPage());
      case '/tool/color_picker':
        return MaterialPageRoute(builder: (_) => const ColorPickerPage());
      case '/tool/url_parser':
        return MaterialPageRoute(builder: (_) => const UrlParserPage());
      case '/tool/qrcode':
        return MaterialPageRoute(builder: (_) => const QrCodePage());
      case '/tool/jwt':
        return MaterialPageRoute(builder: (_) => const JwtDecoderPage());
      case '/tool/html_escape':
        return MaterialPageRoute(builder: (_) => const HtmlEscapePage());
      case '/tool/encrypt':
        return MaterialPageRoute(builder: (_) => const EncryptToolPage());
      
      // AI工具补充
      case '/tool/ai_translate':
        return MaterialPageRoute(builder: (_) => const AiTranslatePage());
      
      // 实用工具
      case '/tool/qrcode':
        return MaterialPageRoute(builder: (_) => const QrcodePage());
      case '/tool/image':
        return MaterialPageRoute(builder: (_) => const ImageToolPage());
      case '/tool/text':
        return MaterialPageRoute(builder: (_) => const TextToolPage());
      case '/tool/unit':
        return MaterialPageRoute(builder: (_) => const UnitConvertPage());
      case '/tool/color':
        return MaterialPageRoute(builder: (_) => const ColorToolPage());
      case '/tool/weather':
        return MaterialPageRoute(builder: (_) => const WeatherPage());
      case '/tool/phone_lookup':
        return MaterialPageRoute(builder: (_) => const PhoneLookupPage());
      case '/tool/exchange_rate':
        return MaterialPageRoute(builder: (_) => const ExchangeRatePage());
      case '/tool/world_clock':
        return MaterialPageRoute(builder: (_) => const WorldClockPage());
      case '/tool/network':
        return MaterialPageRoute(builder: (_) => const NetworkToolPage());
      
      // v3.2.0 新增实用工具路由
      case '/tool/calculator':
        return MaterialPageRoute(builder: (_) => const CalculatorPage());
      case '/tool/countdown':
        return MaterialPageRoute(builder: (_) => const CountdownPage());
      case '/tool/random_number':
        return MaterialPageRoute(builder: (_) => const RandomNumberPage());
      case '/tool/decision':
        return MaterialPageRoute(builder: (_) => const DecisionHelperPage());
      case '/tool/calendar':
        return MaterialPageRoute(builder: (_) => const CalendarPage());
      case '/tool/bmi':
        return MaterialPageRoute(builder: (_) => const BmiCalculatorPage());
      case '/tool/mortgage':
        return MaterialPageRoute(builder: (_) => const MortgageCalculatorPage());
      case '/tool/network_speed':
        return MaterialPageRoute(builder: (_) => const NetworkSpeedPage());
      
      // v3.2.1 新增扩展工具路由
      case '/tool/weather':
        return MaterialPageRoute(builder: (_) => const WeatherPage());
      case '/tool/phone_lookup':
        return MaterialPageRoute(builder: (_) => const PhoneLookupPage());
      case '/tool/world_clock':
        return MaterialPageRoute(builder: (_) => const WorldClockPage());
      case '/tool/http_test':
        return MaterialPageRoute(builder: (_) => const HttpTestPage());
      case '/tool/git_command':
        return MaterialPageRoute(builder: (_) => const GitCommandPage());
      case '/tool/code_format':
        return MaterialPageRoute(builder: (_) => const CodeFormatPage());
      case '/tool/data_backup':
        return MaterialPageRoute(builder: (_) => const DataBackupPage());
      case '/tool/notes':
        return MaterialPageRoute(builder: (_) => const NotesPage());
      
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('页面不存在')),
            body: const Center(child: Text('404 - Page not found')),
          ),
        );
    }
  }
}
