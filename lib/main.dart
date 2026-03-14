import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const CanvasOfflineApp());
}

class CanvasOfflineApp extends StatefulWidget {
  const CanvasOfflineApp({Key? key}) : super(key: key);

  @override
  State<CanvasOfflineApp> createState() => _CanvasOfflineAppState();
}

class _CanvasOfflineAppState extends State<CanvasOfflineApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Canvas Offline',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        fontFamily: 'Microsoft YaHei', // 首选微软雅黑
        fontFamilyFallback: const ['Times New Roman', 'SimSun'], // 备选 Roman 和 宋体
        colorSchemeSeed: const Color(0xFF0775C9),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Microsoft YaHei',
        fontFamilyFallback: const ['Times New Roman', 'SimSun'],
        colorSchemeSeed: const Color(0xFF0775C9),
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
        ),
      ),
      home: HomeScreen(onThemeToggle: _toggleTheme, isDarkMode: _themeMode == ThemeMode.dark),
    );
  }
}
