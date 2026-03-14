@echo off
chcp 65001 >nul
echo ========================================
echo   Canvas Offline Flutter - 构建脚本
echo ========================================
echo.

REM 检查 Flutter 是否安装
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ❌ 未检测到 Flutter
    echo.
    echo 请先安装 Flutter：
    echo 1. 访问 https://docs.flutter.dev/get-started/install/windows
    echo 2. 下载并解压 Flutter SDK
    echo 3. 将 Flutter 添加到 PATH 环境变量
    echo.
    echo 或者使用 Scoop 安装（推荐）：
    echo    scoop install flutter
    echo.
    pause
    exit /b 1
)

echo ✅ 检测到 Flutter
flutter --version
echo.

REM 进入项目目录
cd /d "%~dp0"
echo 📁 项目目录：%CD%
echo.

REM 检查依赖
echo 📦 检查依赖...
flutter pub get
if %errorlevel% neq 0 (
    echo ❌ 依赖安装失败
    pause
    exit /b 1
)
echo ✅ 依赖安装完成
echo.

REM 选择构建类型
echo 请选择构建类型：
echo 1. Debug APK (测试用，较大)
echo 2. Release APK (发布用，优化)
echo 3. 直接运行到设备
echo.
set /p choice="请输入选项 (1/2/3): "

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
if "%choice%"=="3" goto run_device

echo 无效选项
pause
exit /b 1

:build_debug
echo.
echo 📦 开始构建 Debug APK...
echo.
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ❌ 构建失败
    pause
    exit /b 1
)
echo.
echo ✅ Debug APK 构建完成！
echo 位置：build\app\outputs\flutter-apk\app-debug.apk
echo.
goto install_prompt

:build_release
echo.
echo 📦 开始构建 Release APK...
echo.
flutter build apk --release
if %errorlevel% neq 0 (
    echo ❌ 构建失败
    pause
    exit /b 1
)
echo.
echo ✅ Release APK 构建完成！
echo 位置：build\app\outputs\flutter-apk\app-release.apk
echo.
goto install_prompt

:run_device
echo.
echo 📱 检查设备...
flutter devices
echo.
echo 开始运行应用...
flutter run
goto end

:install_prompt
echo 是否安装到连接的设备？
set /p install="输入 Y 安装，或直接回车跳过： "
if /i "%install%"=="Y" (
    echo 📲 安装中...
    flutter install
)

:end
echo.
echo ========================================
echo   完成！
echo ========================================
echo.
pause
