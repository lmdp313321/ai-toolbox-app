# AI工具箱

一款自用的多功能AI工具集合，包含40个实用工具。

## 功能模块

### 🤖 AI智能（10个工具）
- AI对话、AI写作、AI识图、AI绘画、Prompt库
- AI语音、AI代码、AI表格、AI文档、AI学习

### 📅 日常助手（12个工具）
- 记账本、日程管理、备忘录、密码生成、习惯打卡
- 健康记录、读书笔记、心情日记、购物清单、旅行规划
- **数据备份**、**Markdown笔记**

### 💻 开发工具（14个工具）
- JSON工具、编码转换、加密解密、正则测试、时间工具
- 代码对比、颜色选择器、URL解析、二维码生成、JWT解码
- HTML转义、**HTTP测试**、**Git命令**、**代码格式化**、**网络工具**

### 🔧 实用工具（15个工具）
- **二维码**、**图片工具**、文字处理、单位换算、颜色工具
- **天气查询**、**手机号归属地**、汇率换算、**世界时钟**、**网络工具**
- 计算器、倒计时、随机数、决策助手、日历查询
- BMI计算、房贷计算、网速测试

---

## 环境准备

### 1. 安装Flutter SDK

**Windows:**
1. 下载Flutter SDK: https://docs.flutter.dev/get-started/install/windows
2. 解压到 `C:\flutter`
3. 添加 `C:\flutter\bin` 到系统环境变量 PATH
4. 打开命令行运行: `flutter doctor`

**macOS:**
```bash
# 使用Homebrew安装
brew install flutter

# 或手动下载
# https://docs.flutter.dev/get-started/install/macos
```

**Linux:**
```bash
# 使用Snap安装
sudo snap install flutter --classic

# 或手动下载
# https://docs.flutter.dev/get-started/install/linux
```

### 2. 安装开发工具

**Android编译需要:**
- Android Studio: https://developer.android.com/studio
- 安装Android SDK
- 配置Android模拟器或连接真机

**iOS编译需要（仅macOS）:**
- Xcode: 从App Store安装
- Xcode Command Line Tools: `xcode-select --install`

### 3. 验证环境

```bash
# 检查Flutter环境
flutter doctor

# 预期输出应该包含:
# [✓] Flutter (Channel stable, x.x.x)
# [✓] Android toolchain
# [✓] Chrome (如果要在Web调试)
# [✓] Android Studio
# [✓] Xcode (仅macOS)
```

---

## 项目编译

### 1. 获取项目代码

```bash
# 方式1: 从压缩包解压
unzip ai_toolbox.zip
cd ai_toolbox

# 方式2: 从Git克隆（如果使用Git）
git clone <your-repo-url>
cd ai_toolbox
```

### 2. 安装依赖

```bash
# 进入项目目录
cd ai_toolbox

# 安装依赖包
flutter pub get
```

### 3. 编译APK（Android）

```bash
# 调试版本（快速编译，用于测试）
flutter build apk --debug

# 发布版本（优化体积和性能）
flutter build apk --release

# 分架构编译（体积更小）
flutter build apk --split-per-abi --release
```

**编译输出位置:**
```
build/app/outputs/flutter-apk/app-release.apk
```

### 4. 编译iOS（仅macOS）

```bash
# 需要先在Xcode中配置签名
cd ios
pod install
cd ..

# 编译
flutter build ios --release

# 或生成IPA
flutter build ipa --release
```

**编译输出位置:**
```
build/ios/iphoneos/Runner.app
build/ios/ipa/ Runner.ipa
```

---

## 安装到手机

### Android

**方式1: USB连接**
```bash
# 连接手机，开启USB调试
flutter install
```

**方式2: 直接传输APK**
1. 将 `app-release.apk` 传到手机
2. 在手机上打开安装（需开启"允许未知来源"）

### iOS

需要通过Xcode安装，或上传到TestFlight:
```bash
# 打开Xcode
open ios/Runner.xcworkspace

# 在Xcode中选择设备，点击运行
```

---

## API配置

首次使用需要配置AI服务的API Key:

1. 打开APP
2. 进入 设置 → API配置
3. 点击要使用的API服务
4. 输入API Key和Base URL
5. 点击"测试连接"验证
6. 点击"设为当前"激活

### 支持的API服务

| 服务 | Base URL | 说明 |
|------|----------|------|
| 硅基流动 | https://api.siliconflow.cn/v1 | 推荐，国内稳定 |
| 英伟达NIM | https://integrate.api.nvidia.com/v1 | 推荐 |
| DeepSeek | https://api.deepseek.com/v1 | 便宜 |
| OpenAI | https://api.openai.com/v1 | 备用 |
| Claude | https://api.anthropic.com/v1 | 备用 |

---

## 项目结构

```
ai_toolbox/
├── lib/
│   ├── main.dart              # 入口文件
│   ├── app.dart               # App配置
│   ├── core/                  # 核心模块
│   │   ├── config/            # 配置文件
│   │   └── router/            # 路由
│   ├── models/                # 数据模型
│   ├── providers/             # 状态管理
│   ├── services/              # 服务层
│   ├── widgets/               # 公共组件
│   └── pages/                 # 页面
│       ├── home/              # 首页
│       ├── settings/          # 设置
│       └── tools/             # 工具页面
│           ├── ai/            # AI智能
│           ├── daily/         # 日常助手
│           ├── dev/           # 开发工具
│           └── utility/       # 实用工具
├── assets/                    # 资源文件
├── pubspec.yaml               # 依赖配置
└── README.md                  # 本文件
```

---

## 添加新工具

### 方式1: 修改配置文件

1. 编辑 `lib/core/config/tool_config.dart`
2. 在 `tools` 列表添加新工具配置
3. 创建对应的页面文件
4. 在 `lib/core/router/app_router.dart` 添加路由

### 方式2: 新增板块

1. 编辑 `lib/core/config/tool_config.dart`
2. 在 `categories` 列表添加新分类
3. 创建对应的工具页面文件夹

---

## 常见问题

### Q: 编译报错 "Could not resolve all files"
```bash
# 清理并重新获取依赖
flutter clean
flutter pub get
```

### Q: Android编译报错 "SDK location not found"
创建 `android/local.properties`:
```
sdk.dir=C:\\Users\\你的用户名\\AppData\\Local\\Android\\Sdk
# macOS/Linux
sdk.dir=/Users/你的用户名/Library/Android/sdk
```

### Q: iOS编译报错 "CocoaPods not installed"
```bash
sudo gem install cocoapods
cd ios
pod install
```

### Q: API调用失败
1. 检查API Key是否正确
2. 检查网络连接
3. 确认API服务的Base URL正确

---

## 更新日志

### v1.0.0 (2026-04-04)
- 初始版本
- 包含40个工具的基础框架
- 支持多API配置和切换
- 支持深色/浅色主题切换

---

## 技术栈

- **框架**: Flutter 3.x
- **语言**: Dart
- **状态管理**: Provider
- **本地存储**: SharedPreferences + SQLite
- **网络请求**: Dio
- **加密**: crypto
- **UUID**: uuid

---

## License

本项目仅供个人学习使用。

> 2026-05-26: 编译模式切换为release(arm64/arm32/x86_64)
