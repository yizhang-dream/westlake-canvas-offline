# Canvas Offline Flutter - 快速开始指南

## 📥 第一步：安装 Flutter

### 方法 1：使用 Scoop 安装（推荐，最简单）

1. **安装 Scoop（如果还没有）**
   
   打开 PowerShell，运行：
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression
   ```

2. **安装 Flutter**
   ```powershell
   scoop install flutter
   ```

3. **验证安装**
   ```powershell
   flutter --version
   ```

### 方法 2：手动下载安装

1. **下载 Flutter SDK**
   
   访问：https://docs.flutter.dev/get-started/install/windows
   
   下载最新版本的 Flutter SDK（约 900MB）

2. **解压到合适位置**
   
   建议解压到：`C:\src\flutter` 或 `C:\home\zyz\flutter`
   
   ⚠️ 不要解压到包含空格的目录（如 Program Files）

3. **添加 Flutter 到 PATH**
   
   - 右键"此电脑" → 属性 → 高级系统设置
   - 点击"环境变量"
   - 在"系统变量"中找到 `Path`
   - 点击"编辑" → "新建"
   - 添加：`C:\src\flutter\bin`（根据你的实际路径）
   - 点击"确定"保存

4. **验证安装**
   
   打开新的命令提示符，运行：
   ```cmd
   flutter --version
   ```

## 📱 第二步：安装 Android Studio

### 1. 下载并安装

下载地址：https://developer.android.com/studio

### 2. 安装 Android SDK

打开 Android Studio：
1. 点击 "More Actions" → "SDK Manager"
2. 在 "SDK Platforms" 标签页：
   - 勾选 "Android 13.0 (API 33)" 或更高版本
3. 在 "SDK Tools" 标签页：
   - 勾选 "Android SDK Build-Tools"
   - 勾选 "Android Emulator"
   - 勾选 "Android SDK Platform-Tools"
4. 点击 "Apply" 安装

### 3. 创建 Android 模拟器

1. 点击 "More Actions" → "Virtual Device Manager"
2. 点击 "Create Device"
3. 选择设备（如 Pixel 6）
4. 选择系统镜像（推荐 API 33）
5. 点击 "Finish"

## 🔧 第三步：配置 Flutter

### 1. 接受 Android 许可证

```bash
flutter doctor --android-licenses
```

输入 `y` 接受所有许可证

### 2. 检查开发环境

```bash
flutter doctor
```

应该看到类似输出：
```
[✓] Flutter (Channel stable, 3.x.x, on Windows)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] Connected device
```

## 🚀 第四步：运行应用

### 1. 进入项目目录

```bash
cd C:\home\zyz\.npm-global\canvas-offline-flutter
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 连接设备或启动模拟器

**启动 Android 模拟器：**
```bash
emulator -list-avds  # 查看可用模拟器
emulator -avd <模拟器名称>  # 启动模拟器
```

**或使用 USB 连接真机：**
- 手机开启"开发者选项"
- 开启"USB 调试"
- 用 USB 连接电脑

### 4. 运行应用

```bash
flutter run
```

## 📦 第五步：构建 APK

### 构建 Debug APK

```bash
flutter build apk --debug
```

输出位置：`build\app\outputs\flutter-apk\app-debug.apk`

### 构建 Release APK

```bash
flutter build apk --release
```

输出位置：`build\app\outputs\flutter-apk\app-release.apk`

## ⚡ 快速命令参考

```bash
# 查看 Flutter 版本
flutter --version

# 检查开发环境
flutter doctor

# 安装依赖
flutter pub get

# 运行应用
flutter run

# 构建 Debug APK
flutter build apk --debug

# 构建 Release APK
flutter build apk --release

# 清理构建缓存
flutter clean

# 查看连接的设备
flutter devices
```

## 🐛 常见问题

### Q: flutter doctor 显示 Android license status unknown

**解决：**
```bash
flutter doctor --android-licenses
```

### Q: 构建失败，提示 SDK 未找到

**解决：**
1. 打开 Android Studio
2. File → Settings → Appearance & Behavior → System Settings → Android SDK
3. 记下 Android SDK Location
4. 运行：`flutter config --android-sdk <SDK 路径>`

### Q: 下载依赖太慢

**解决：** 使用国内镜像

Windows PowerShell：
```powershell
$env:PUB_HOSTED_URL="https://pub.flutter-io.cn"
$env:FLUTTER_STORAGE_BASE_URL="https://storage.flutter-io.cn"
flutter pub get
```

或在环境变量中添加：
- `PUB_HOSTED_URL` = `https://pub.flutter-io.cn`
- `FLUTTER_STORAGE_BASE_URL` = `https://storage.flutter-io.cn`

### Q: 构建的 APK 太大

**解决：**
```bash
# 使用 App Bundle（更小）
flutter build appbundle --release

# 或构建分架构 APK
flutter build apk --split-per-abi
```

## 📱 安装 APK 到手机

### 方法 1：USB 连接

```bash
flutter install
```

### 方法 2：ADB 命令

```bash
adb install build\app\outputs\flutter-apk\app-release.apk
```

### 方法 3：手动安装

1. 将 APK 复制到手机
2. 在手机上打开文件管理器
3. 点击 APK 文件安装

## 🎯 下一步

应用运行后：

1. **首次使用需要输入 Token**
   - 按照屏幕提示获取 Canvas API Token
   - 输入并保存

2. **同步课程数据**
   - 点击右上角同步按钮
   - 等待同步完成

3. **浏览课程**
   - 查看课程列表
   - 点击课程查看详情
   - 浏览文件、作业、页面、公告

## 📞 需要帮助？

运行以下命令获取帮助：
```bash
flutter -h
flutter run -h
flutter build apk -h
```

或访问：https://flutter.dev/docs
