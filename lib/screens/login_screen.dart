import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/database.dart';
import '../services/canvas_api.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final LocalDatabase _db = LocalDatabase();
  final CanvasApi _api = CanvasApi();
  final _tokenController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      _api.setToken(token);
      if (await _api.testConnection()) {
        await _db.saveToken(token);
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomeScreen(
            onThemeToggle: () {}, // 临时占位，重启后由 main 接管
            isDarkMode: false,
          )));
        }
      } else { throw Exception('无效 Token'); }
    } catch (e) { 
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('登录失败: $e'))); 
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFBFDBFE)]),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: GlassCard(
              isDark: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.school_rounded, size: 72, color: Color(0xFF0775C9)),
                  const SizedBox(height: 16),
                  const Text('Canvas Offline', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  const SizedBox(height: 40),
                  TextField(
                    controller: _tokenController,
                    decoration: InputDecoration(
                      labelText: 'API Token',
                      prefixIcon: const Icon(Icons.vpn_key_rounded),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.3),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0775C9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('开启离线之旅', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}