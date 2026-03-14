import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/database.dart';
import '../widgets/file_list_item.dart';
import 'html_detail_screen.dart';
import 'assignment_detail_screen.dart';
import 'home_screen.dart';

class CourseDetailScreen extends StatefulWidget {
  final Course course;
  final bool isDarkMode;
  const CourseDetailScreen({Key? key, required this.course, required this.isDarkMode}) : super(key: key);
  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> with SingleTickerProviderStateMixin {
  final LocalDatabase _db = LocalDatabase();
  late TabController _tabController;
  List<CourseFile> _files = [];
  List<Assignment> _assignments = [];
  bool _isLoading = false;
  String? _backgroundPath;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBackground();
    _loadData();
  }

  Future<void> _loadBackground() async {
    final bgPath = await _db.getBackgroundPath();
    if (mounted) setState(() { _backgroundPath = bgPath; });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _db.getCourseFiles(widget.course.id),
        _db.getCourseAssignments(widget.course.id),
        _db.getCoursePages(widget.course.id),
      ]);
      
      final List<CourseFile> files = results[0] as List<CourseFile>;
      final List<CoursePage> pages = results[2] as List<CoursePage>;
      
      // 将大纲和重要页面混入文件列表
      final List<CourseFile> virtualFiles = [];
      for (var p in pages) {
        if (p.title.contains('大纲') || p.title.contains('讨论')) {
          virtualFiles.add(CourseFile(
            id: p.id,
            courseId: widget.course.id,
            filename: '📄 ${p.title}',
            source: '资料',
            url: 'page://${p.id}', // 虚拟协议标记
          ));
        }
      }

      setState(() {
        _files = [...files, ...virtualFiles];
        _assignments = results[1] as List<Assignment>;
      });
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    return Container(
      decoration: BoxDecoration(
        color: _backgroundPath != null ? (isDark ? Colors.black : Colors.white) : null,
        image: _backgroundPath != null && File(_backgroundPath!).existsSync()
            ? DecorationImage(
                image: FileImage(File(_backgroundPath!)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(isDark ? 0.6 : 0.2), // Darken background slightly
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: _backgroundPath == null 
            ? LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0D1224), const Color(0xFF1E1333)] 
                  : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)],
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(widget.course.name, style: TextStyle(fontWeight: FontWeight.w800, color: isDark || _backgroundPath != null ? Colors.white : Colors.black87)),
          iconTheme: IconThemeData(color: isDark || _backgroundPath != null ? Colors.white : Colors.black87),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: GlassCard(
                isDark: isDark,
                padding: EdgeInsets.zero,
                child: TabBar(
                  controller: _tabController,
                  dividerColor: Colors.transparent,
                  indicatorColor: Colors.blueAccent,
                  labelColor: isDark || _backgroundPath != null ? Colors.white : const Color(0xFF0775C9),
                  unselectedLabelColor: isDark || _backgroundPath != null ? Colors.white54 : Colors.blueGrey,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  tabs: const [Tab(text: '课件与资料'), Tab(text: '作业任务')],
                ),
              ),
            ),
          ),
        ),
        body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : TabBarView(
              controller: _tabController,
              children: [
                _buildFilesTab(),
                _buildAssignmentsTab(),
              ],
            ),
      ),
    );
  }

  Widget _buildFilesTab() {
    if (_files.isEmpty) return const Center(child: Text('暂无资料'));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _files.length,
      itemBuilder: (c, i) => FileListItem(file: _files[i]),
    );
  }

  Widget _buildAssignmentsTab() {
    if (_assignments.isEmpty) return Center(child: Text('暂无作业', style: TextStyle(color: widget.isDarkMode || _backgroundPath != null ? Colors.white : Colors.black)));
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _assignments.length,
      itemBuilder: (c, i) {
        final a = _assignments[i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            isDark: widget.isDarkMode,
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.assignment_rounded, color: Colors.orangeAccent, size: 28),
              title: Text(a.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: widget.isDarkMode || _backgroundPath != null ? Colors.white : Colors.black87)),
              subtitle: a.dueAt != null ? Text('截止: ${DateFormat('MM-dd HH:mm').format(a.dueAt!)}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: widget.isDarkMode || _backgroundPath != null ? Colors.white70 : Colors.blueGrey)) : null,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => AssignmentDetailScreen(assignment: a))),
            ),
          ),
        );
      },
    );
  }
}