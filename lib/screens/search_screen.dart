import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/database.dart';
import '../widgets/file_list_item.dart';
import 'course_detail_screen.dart';
import 'assignment_detail_screen.dart';
import 'html_detail_screen.dart';
import 'home_screen.dart';

class SearchScreen extends StatefulWidget {
  final String initialQuery;
  const SearchScreen({Key? key, required this.initialQuery}) : super(key: key);
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final LocalDatabase _db = LocalDatabase();
  final TextEditingController _ctl = TextEditingController();
  bool _loading = false;
  Map<String, List<dynamic>> _res = {'courses': [], 'files': [], 'assignments': [], 'pages': []};
  String? _backgroundPath;

  @override
  void initState() {
    super.initState();
    _ctl.text = widget.initialQuery;
    _loadBackground();
    _search(widget.initialQuery);
  }

  Future<void> _loadBackground() async {
    final bgPath = await _db.getBackgroundPath();
    if (mounted) setState(() { _backgroundPath = bgPath; });
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final r = await _db.search(q.trim());
      setState(() { _res = r; });
    } catch (e) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: _backgroundPath != null ? (isDark ? Colors.black : Colors.white) : null,
        image: _backgroundPath != null && File(_backgroundPath!).existsSync()
            ? DecorationImage(
                image: FileImage(File(_backgroundPath!)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: _backgroundPath == null 
            ? LinearGradient(
                colors: isDark 
                  ? [const Color(0xFF0D1224), const Color(0xFF1E1333)] 
                  : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)]
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: TextField(
            controller: _ctl,
            style: TextStyle(color: isDark || _backgroundPath != null ? Colors.white : Colors.black87, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '搜索课件、作业...', 
              hintStyle: TextStyle(color: isDark || _backgroundPath != null ? Colors.white54 : Colors.black38), 
              border: InputBorder.none
            ),
            onSubmitted: _search,
          ),
          iconTheme: IconThemeData(color: isDark || _backgroundPath != null ? Colors.white : Colors.black87),
        ),
        body: _loading 
          ? const Center(child: CircularProgressIndicator()) 
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSec('课件资料', _res['files']!, Icons.insert_drive_file_rounded, isDark),
                _buildSec('作业任务', _res['assignments']!, Icons.assignment_rounded, isDark),
                _buildSec('课程', _res['courses']!, Icons.book_rounded, isDark),
                _buildSec('页面内容', _res['pages']!, Icons.article_rounded, isDark),
              ],
            ),
      ),
    );
  }

  Widget _buildSec(String t, List<dynamic> items, IconData icon, bool isDark) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(t, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: isDark || _backgroundPath != null ? Colors.white70 : Colors.black54)),
        ),
        ...items.map((item) {
          if (item is CourseFile) return FileListItem(file: item);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              isDark: isDark,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(icon, color: Colors.blueAccent, size: 24),
                title: Text(_getTitle(item), style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark || _backgroundPath != null ? Colors.white : Colors.black87)),
                onTap: () => _handleTap(item, isDark),
              ),
            ),
          );
        }).toList(),
        const SizedBox(height: 12),
      ],
    );
  }

  String _getTitle(dynamic i) {
    if (i is Course) return i.name;
    if (i is Assignment) return i.name;
    if (i is CoursePage) return i.title;
    return '';
  }

  void _handleTap(dynamic i, bool isDark) {
    if (i is Course) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => CourseDetailScreen(course: i, isDarkMode: isDark)));
    } else if (i is Assignment) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => AssignmentDetailScreen(assignment: i)));
    } else if (i is CoursePage) {
      Navigator.push(context, MaterialPageRoute(builder: (c) => HtmlDetailScreen(title: i.title, htmlContent: i.body ?? '')));
    }
  }
}