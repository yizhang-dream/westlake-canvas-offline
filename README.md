# Canvas Offline - Flutter 版本

使用 Flutter 开发的跨平台 Canvas 客户端，支持 Android 和 iOS。

## 📋 功能特点

- ✅ **完整功能** - 所有 Node.js 版本的功能
- ✅ **原生性能** - 直接编译成原生代码
- ✅ **离线使用** - 数据存储在本地
- ✅ **美观 UI** - Material Design 设计
- ✅ **无需服务器** - 直接调用 Canvas API
- ✅ **文件下载** - 支持下载课程文件
- ✅ **作业提交** - 支持提交作业

## 🔧 环境要求

### 开发环境

1. **Flutter SDK** (3.0+)
   - 下载地址：https://docs.flutter.dev/get-started/install
   
2. **Android Studio** (用于 Android 开发)
   - 下载地址：https://developer.android.com/studio

3. **Xcode** (用于 iOS 开发，仅 macOS)
   - 在 Mac App Store 下载

### 验证安装

```bash
# 检查 Flutter 安装
flutter doctor

# 检查 Android 设备
flutter devices
```

## 📱 运行应用

### 1. 安装依赖

```bash
cd canvas-offline-flutter
flutter pub get
```

### 2. 运行应用

**Android 模拟器/真机：**
```bash
flutter run
```

**iOS 模拟器（仅 macOS）：**
```bash
flutter run -d ios
```

## 📦 构建 APK

### Debug APK（测试用）

```bash
flutter build apk --debug
```

输出位置：`build/app/outputs/flutter-apk/app-debug.apk`

### Release APK（发布用）

**1. 配置签名（可选）**

编辑 `android/app/build.gradle`：

```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias 'your-key-alias'
            keyPassword 'your-key-password'
            storeFile file('your-keystore.jks')
            storePassword 'your-store-password'
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**2. 构建 Release APK**

```bash
flutter build apk --release
```

输出位置：`build/app/outputs/flutter-apk/app-release.apk`

### 构建 AAB（Google Play 发布）

```bash
flutter build appbundle --release
```

输出位置：`build/app/outputs/bundle/release/app-release.aab`

## 📲 安装到手机

### 方法 1：USB 连接

1. 手机开启开发者模式和 USB 调试
2. 连接电脑
3. 运行：`flutter run`

### 方法 2：直接安装 APK

1. 将 APK 传输到手机
2. 在手机上允许"未知来源"安装
3. 点击 APK 安装

## 🗄️ 数据存储

应用使用 SQLite 数据库存储：

- **位置**：`/data/data/com.canvas.offline/databases/canvas_offline.db`
- **内容**：
  - 课程信息
  - 文件列表
  - 作业列表
  - 页面内容
  - 公告
  - API Token

### 清除数据

**方法 1：应用内**
- 设置 → 清除数据

**方法 2：系统设置**
- 设置 → 应用 → Canvas Offline → 存储 → 清除数据

## 🎨 项目结构

```
canvas-offline-flutter/
├── lib/
│   ├── main.dart              # 应用入口
│   ├── models/
│   │   └── models.dart        # 数据模型
│   ├── services/
│   │   ├── canvas_api.dart    # Canvas API 客户端
│   │   └── database.dart      # 本地数据库
│   └── screens/
│       ├── home_screen.dart           # 主屏幕
│       ├── login_screen.dart          # 登录屏幕
│       └── course_detail_screen.dart  # 课程详情
├── android/                   # Android 项目
├── ios/                       # iOS 项目
└── pubspec.yaml              # 项目配置
```

## 🔑 获取 Canvas API Token

1. 登录 https://canvas.westlake.edu.cn
2. 点击 **Account** → **Settings**
3. 滚动到 **"Approved Integrations"**
4. 点击 **"+ New Access Token"**
5. 输入描述（如：Offline Client）
6. 选择过期时间（建议 60 天或更长）
7. 点击生成并**立即复制**Token

## ⚠️ 注意事项

### Android 权限

应用需要以下权限：
- **网络** - 访问 Canvas API
- **存储** - 下载课程文件

### 网络配置

在 `android/app/src/main/AndroidManifest.xml` 中已配置：
```xml
android:usesCleartextTraffic="true"
```

允许 HTTP 连接（如果 Canvas 使用 HTTP）。

### iOS 配置

在 `ios/Runner/Info.plist` 中添加：
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

## 🐛 常见问题

### Q: Flutter 下载太慢？
A: 使用国内镜像：
```bash
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn
```

### Q: 构建失败？
A: 检查：
1. Flutter 版本 >= 3.0
2. 运行 `flutter pub get`
3. 运行 `flutter clean` 然后重新构建

### Q: Token 过期了怎么办？
A: 在设置中清除 Token，重新输入新 Token。

### Q: 数据会丢失吗？
A: 只要不清除应用数据或卸载，数据会一直保存。

## 📄 License

MIT

## 🙏 致谢

- Canvas LMS API
- Flutter & Dart
- Material Design
