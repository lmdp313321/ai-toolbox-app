# AI工具箱 - 关键文件速查表

## 🚨 编译问题必查文件

### 1. Kotlin 版本（Java 21 必改！）
**文件**: `android/settings.gradle`
**行号**: 第19行
```gradle
// ❌ 错误（Java 21 不兼容）
id "org.jetbrains.kotlin.android" version "1.7.10" apply false

// ✅ 正确（Java 21 兼容）
id "org.jetbrains.kotlin.android" version "1.9.0" apply false
```

---

### 2. Gradle 版本
**文件**: `android/gradle/wrapper/gradle-wrapper.properties`
```properties
# 推荐版本（稳定）
distributionUrl=https\://mirrors.aliyun.com/gradle/distributions/v7.6.3/gradle-7.6.3-all.zip
```

---

### 3. AndroidX 配置
**文件**: `android/gradle.properties`
```properties
android.useAndroidX=true
android.enableJetifier=true
```

---

### 4. 国内镜像
**文件**: `android/settings.gradle` 和 `android/build.gradle`
```gradle
repositories {
    maven { url 'https://maven.aliyun.com/repository/public' }
    maven { url 'https://maven.aliyun.com/repository/google' }
    google()
    mavenCentral()
}
```

---

### 5. 应用图标
**目录**: `android/app/src/main/res/mipmap-anydpi-v26/`
**文件**: `ic_launcher.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
```

---

## 📋 编译前检查清单

- [ ] `android/settings.gradle` - Kotlin 版本 1.9.0
- [ ] `android/gradle.properties` - AndroidX 已启用
- [ ] `android/gradle/wrapper/gradle-wrapper.properties` - 国内镜像
- [ ] `android/app/src/main/res/mipmap-anydpi-v26/` - 图标存在

---

## 🔧 环境要求

| 组件 | 版本要求 | 你的版本 |
|-----|---------|---------|
| Java | 17 或 21 | ✅ |
| Flutter | 3.19+ | ✅ |
| Kotlin | 1.9.0+ (Java 21) | ⚠️ 必查 |
| Gradle | 7.6.3 | ✅ |

---

**下次开发前必须先检查此文件！**
