# AI工具箱编译问题知识库

## 版本编译记录

### v3.0 日常助手版 (2026-04-05)
**Flutter版本**: 3.19.5+  
**Gradle版本**: 8.0  
**编译结果**: ✅ 成功（经过5次修复）

#### v3.0 出现的问题清单

| # | 问题 | 原因 | 解决方案 | 预防 |
|---|------|------|----------|------|
| 1 | 缺少 `android/` 目录 | 打包时只复制了 lib/ 代码 | 重新创建完整 android 目录结构 | **以后所有版本必须包含完整项目结构** |
| 2 | Gradle下载超时 | 国外镜像连接失败 | 改用阿里云/华为云镜像 | 默认配置国内镜像 |
| 3 | `selectedLanguage` 未定义错误 | ai_code_page.dart 第96行变量名错误 | 改为 `$_selectedLanguage` | 写代码时注意变量名一致性 |
| 4 | AndroidX未启用 | 缺少 gradle.properties 配置 | 添加 `android.useAndroidX=true` 和 `android.enableJetifier=true` | 新项目必须包含此配置 |
| 5 | 应用图标缺失 | mipmap 目录为空 | 创建 mipmap-anydpi-v26/ic_launcher.xml | 创建项目时一并创建图标资源 |
| 6 | adaptive-icon 放错目录 | 放到了 mipmap-mdpi 等目录 | 只保留在 mipmap-anydpi-v26 | 了解 Android 资源目录规则 |
| 7 | Kotlin 版本不兼容 | settings.gradle 配置 Kotlin 1.7.10 | 改为 Kotlin 1.9.0 | **Java 21 需要 Kotlin 1.9.0+** |
| 8 | 依赖版本冲突 | `intl: ^0.18.1` 与 `flutter_quill: ^8.6.4` 不兼容 | `intl` 升级到 `^0.19.0` | 注意依赖版本兼容性 |
| 9 | 数据库方法重复定义 | AppDatabase 中方法写了两遍 | 删除重复的方法块 | 编辑时检查是否已存在 |
| 10 | 类缺少右大括号 | AppDatabase 类未正确闭合 | 添加 `}` 闭合类 | 注意代码结构完整性 |
| 11 | 方法未定义 | `updateHabit` 方法缺失 | 添加 `updateHabit` 实现 | 页面调用前确认方法存在 |
| 12 | DateTime 可空类型错误 | `endTime` 为 `DateTime?` 但直接传给非空参数 | 使用 `endTime!` 断言或判空后处理 | 注意可空类型转换 |
| 13 | 富文本组件冲突 | `flutter_quill` 导致编译失败 | 移除 `flutter_quill`，改用标准 TextField | 复杂组件优先考虑稳定性 |
| 14 | 动画组件冲突 | `confetti` 依赖问题 | 移除 `confetti`，使用标准动画或文字提示 | 核心功能优先，动画可选 |

---

## ⚠️ 关键文件位置（必记）

### Kotlin 版本配置位置
**文件**: `android/settings.gradle`
**行号**: 第19行左右
```gradle
// 错误配置（Java 21 不兼容）
id "org.jetbrains.kotlin.android" version "1.7.10" apply false

// 正确配置（Java 21 兼容）
id "org.jetbrains.kotlin.android" version "1.9.0" apply false
```

### 其他关键配置文件
| 配置项 | 文件 | 说明 |
|-------|------|------|
| Kotlin 版本 | `android/settings.gradle` | Java 21 必须用 Kotlin 1.9.0+ |
| Gradle 版本 | `android/gradle/wrapper/gradle-wrapper.properties` | 推荐 7.6.3 |
| AndroidX | `android/gradle.properties` | 必须启用 |
| 国内镜像 | `android/settings.gradle` + `android/build.gradle` | 阿里云/华为云 |
| 应用图标 | `android/app/src/main/res/mipmap-anydpi-v26/` | adaptive-icon 只放这里 |

---

## 标准项目结构检查清单

打包前必须确认以下文件存在：

```
android/
├── .gitignore
├── build.gradle
├── settings.gradle
├── gradle.properties          # 必须包含 AndroidX 配置
├── gradle/wrapper/gradle-wrapper.properties  # 国内镜像
└── app/
    ├── build.gradle
    ├── src/debug/AndroidManifest.xml
    ├── src/profile/AndroidManifest.xml
    └── src/main/
        ├── AndroidManifest.xml
        ├── java/com/example/ai_toolbox/MainActivity.kt
        └── res/
            ├── drawable/launch_background.xml
            ├── drawable/ic_launcher_background.xml
            ├── drawable/ic_launcher_foreground.xml
            ├── mipmap-anydpi-v26/ic_launcher.xml
            ├── mipmap-mdpi/ (空目录)
            ├── mipmap-hdpi/ (空目录)
            ├── mipmap-xhdpi/ (空目录)
            ├── mipmap-xxhdpi/ (空目录)
            ├── mipmap-xxxhdpi/ (空目录)
            └── values/styles.xml
```

---

## 国内镜像配置

### gradle-wrapper.properties
```properties
distributionUrl=https\://mirrors.aliyun.com/gradle/distributions/v8.0.0/gradle-8.0-all.zip
```

### settings.gradle
```gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/public' }
    maven { url 'https://maven.aliyun.com/repository/google' }
    google()
    mavenCentral()
}
```

---

## 编译前自检流程

1. **项目完整性检查**
   - [ ] android/ 目录存在
   - [ ] ios/ 目录存在（可选）
   - [ ] lib/ 目录存在
   - [ ] pubspec.yaml 存在

2. **Android 配置检查**
   - [ ] gradle.properties 包含 AndroidX 配置
   - [ ] 镜像配置为国内源
   - [ ] 图标资源已创建

3. **代码检查**
   - [ ] 无未定义变量错误
   - [ ] 所有导入路径正确

4. **版本号更新**
   - [ ] pubspec.yaml 版本号已更新
   - [ ] 设置页版本号已更新

---

## 编译卡住的处理

如果编译超过 10 分钟无响应：

1. 检查是否有进程在运行
2. 使用 `--verbose` 查看详细日志
3. 清理缓存后重试：
   ```bash
   flutter clean
   flutter build apk --debug
   ```

---

## 双电脑环境记录

### 1号电脑（ASUS - 主力开发机）
- Flutter: 3.22.3
- Java: 17
- SDK: 34
- 状态: ✅ 编译正常

### 2号电脑（Administrator - 备用）
- Flutter: 3.19.5
- Java: 21
- SDK: 33
- 状态: ⚠️ 需检查Gradle版本兼容性

---

## 依赖管理最佳实践

### 稳定依赖清单（已验证）
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  provider: ^6.1.1
  
  # 本地存储
  shared_preferences: ^2.2.2
  sqflite: ^2.3.0
  path: ^1.8.3
  
  # 网络请求
  dio: ^5.4.0
  http: ^1.1.0
  
  # WebView
  webview_flutter: ^4.8.0
  
  # 文件选择
  file_picker: ^8.0.0+1
  image_picker: ^1.0.7
  
  # UI组件 - 只用稳定版本
  flutter_slidable: ^3.0.1
  fl_chart: ^0.66.0
  table_calendar: ^3.0.9
  
  # 工具类
  uuid: ^4.2.1
  url_launcher: ^6.2.2
  share_plus: ^7.2.1
  permission_handler: ^11.1.0
  intl: ^0.19.0
  
  # Markdown渲染
  flutter_markdown: ^0.6.18+3
```

### 避免使用的依赖（已出现问题）
| 依赖 | 问题 | 替代方案 |
|------|------|----------|
| `flutter_quill` | 版本冲突、编译失败 | 使用标准 `TextField` + `maxLines` |
| `confetti` | 额外依赖负担 | 使用 `SnackBar` 或简单动画 |

---

## 版本发布检查清单

### 发布前必须确认
- [ ] `pubspec.yaml` 版本号更新（如 `3.0.0+1`）
- [ ] `lib/core/constants/app_constants.dart` 版本号更新
- [ ] 所有页面功能测试通过
- [ ] 编译无警告无错误
- [ ] APK 能正常安装运行
- [ ] 代码已提交 Git 并打标签

### Git 标签命令
```bash
git add .
git commit -m "v3.0: 日常助手功能完成"
git tag v3.0 -m "第三版：日常助手"
git push origin v3.0
```

---

**下次开发前必须先检查此知识库！**

**开发者QQ**: 40305583
