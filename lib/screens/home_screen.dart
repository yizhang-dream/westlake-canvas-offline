import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/models.dart';
import '../services/database.dart';
import '../services/canvas_api.dart';
import '../services/download_service.dart';
import 'course_detail_screen.dart';
import 'login_screen.dart';
import 'search_screen.dart';

enum SortOption { name, term }

class HomeScreen extends StatefulWidget {
  final VoidCallback onThemeToggle;
  final bool isDarkMode;
  const HomeScreen({Key? key, required this.onThemeToggle, required this.isDarkMode}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocalDatabase _db = LocalDatabase();
  final CanvasApi _api = CanvasApi();
  final DownloadService _downloadService = DownloadService();
  
  List<Course> _courses = [];
  Map<String, int> _stats = {};
  bool _isLoading = false;
  String? _userName;
  String _syncStatus = '';
  SortOption _sortOption = SortOption.term;
  bool _sortAscending = false;
  String? _backgroundPath;

  @override
  void initState() {
    super.initState();
    _checkToken();
  }

  Future<void> _checkToken() async {
    final token = await _db.getToken();
    if (token == null) {
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }
    _api.setToken(token);
    _downloadService.setToken(token);
    
    final bgPath = await _db.getBackgroundPath();
    if (mounted) setState(() { _backgroundPath = bgPath; });
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _courses = await _db.getCourses();
      _applySort();
      _stats = await _db.getStats();
      final user = await _api.getCurrentUser();
      if (mounted) setState(() { _userName = user['name'] as String?; });
    } catch (e) {}
    setState(() => _isLoading = false);
  }

  void _applySort() {
    setState(() {
      _courses.sort((a, b) {
        if (_sortOption == SortOption.term) {
          final wA = _getTermWeight(a.term);
          final wB = _getTermWeight(b.term);
          int cmp = wB.compareTo(wA);
          if (cmp == 0) return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return cmp;
        } else {
          int cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          return _sortAscending ? cmp : -cmp;
        }
      });
    });
  }

  int _getTermWeight(String? term) {
    if (term == null || term.isEmpty) return 0;
    final yearMatch = RegExp(r'\d{4}').firstMatch(term);
    int year = yearMatch != null ? int.parse(yearMatch.group(0)!) : 0;
    int weight = 0;
    String t = term.toLowerCase();
    if (t.contains('fall')) weight = 2;
    else if (t.contains('summer')) weight = 1;
    else if (t.contains('spring')) weight = 0;
    return year * 10 + weight;
  }

  void _setSort(SortOption option) {
    setState(() {
      if (_sortOption == option) {
        _sortAscending = !_sortAscending;
      } else {
        _sortOption = option;
        _sortAscending = option == SortOption.name;
      }
      _applySort();
    });
  }

  Future<void> _syncAll() async {
    setState(() { _isLoading = true; _syncStatus = '同步中...'; });
    try {
      final token = await _db.getToken();
      if (token == null) return;
      
      // 1. 个人文件
      final myFiles = await _api.getUserFiles();
      await _db.saveCourseFiles(myFiles);

      // 2. 课程列表
      final courses = await _api.getCourses();
      await _db.saveCourses(courses);
      
      List<CourseFile> allFiles = [...myFiles];
      Map<int, String> fileIdToSource = {};
      
      for (var course in courses) {
        setState(() { _syncStatus = '正在同步: ${course.name}'; });
        try {
          final files = await _api.getCourseFiles(course.id);
          final filesWithSource = files.map((f) => CourseFile.fromJson({...f.toJson(), 'source': '课程目录'})).toList();
          await _db.saveCourseFiles(filesWithSource);
          allFiles.addAll(filesWithSource);
          
          await _db.saveAssignments(await _api.getAssignments(course.id));
          
          // 抓取大纲
          final syllabus = await _api.getCourseSyllabus(course.id);
          if (syllabus != null) {
            await _db.savePages([CoursePage(id: course.id + 99000, courseId: course.id, title: '课程大纲', body: syllabus)]);
            _extract(syllabus, fileIdToSource, '课程大纲');
          }

          // 抓取页面
          final pages = await _api.getPages(course.id);
          for (var p in pages) {
            if (p.pageUrl != null) {
              final full = await _api.getPageDetail(course.id, p.pageUrl!);
              await _db.savePages([full]);
              if (full.body != null) _extract(full.body!, fileIdToSource, '页面: ${full.title}');
            }
          }
        } catch (e) {}
      }

      // 3. 处理关联文件
      for (var entry in fileIdToSource.entries) {
        try {
          final detail = await _api.getFileDetails(entry.key);
          final f = CourseFile.fromJson({...detail.toJson(), 'source': entry.value});
          await _db.saveCourseFiles([f]);
          allFiles.add(f);
        } catch (e) {}
      }
      
      // 4. 下载
      for (int i = 0; i < allFiles.length; i++) {
        final f = allFiles[i];
        setState(() { _syncStatus = '下载资料 (${i+1}/${allFiles.length})'; });
        try { if (!await _downloadService.isFileDownloaded(f)) await _downloadService.downloadFile(f); } catch (e) {}
      }
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ 同步完成'))); _loadData(); }
    } catch (e) {} finally { if (mounted) setState(() { _isLoading = false; _syncStatus = ''; }); }
  }

  void _extract(String h, Map<int, String> r, String s) {
    RegExp(r'/files/(\d+)').allMatches(h).forEach((m) {
      final id = int.tryParse(m.group(1)!);
      if (id != null) r[id] = s;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要清除所有本地数据吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('确定', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await _db.clearToken();
      await _db.clearAllData();
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Future<void> _pickBackground() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.single.path != null) {
        String path = result.files.single.path!;
        await _db.saveBackgroundPath(path);
        setState(() { _backgroundPath = path; });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('选择图片失败: $e')));
    }
  }

  Future<void> _clearBackground() async {
    await _db.clearBackgroundPath();
    setState(() { _backgroundPath = null; });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final Map<String, List<Course>> grouped = {};
    for (var c in _courses) {
      final t = c.term ?? '其他';
      if (!grouped.containsKey(t)) grouped[t] = [];
      grouped[t]!.add(c);
    }
    final terms = grouped.keys.toList()..sort((a, b) => _getTermWeight(b).compareTo(_getTermWeight(a)));

    return Container(
      decoration: BoxDecoration(
        color: _backgroundPath != null ? (isDark ? Colors.black : Colors.white) : null,
        image: _backgroundPath != null && File(_backgroundPath!).existsSync()
            ? DecorationImage(
                image: FileImage(File(_backgroundPath!)),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(isDark ? 0.6 : 0.2), // Darken background slightly to ensure text legibility
                  BlendMode.darken,
                ),
              )
            : null,
        gradient: _backgroundPath == null 
            ? LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: isDark 
                  ? [const Color(0xFF0D1224), const Color(0xFF1E1333)] // Deep space / dark purple vibe
                  : [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)], // Light blue/purple fresh vibe
              )
            : null,
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text('Canvas Offline', style: TextStyle(fontWeight: FontWeight.w800, color: isDark || _backgroundPath != null ? Colors.white : Colors.black87)),
          actions: [
            if (_backgroundPath != null)
              IconButton(icon: const Icon(Icons.hide_image_rounded), onPressed: _clearBackground, tooltip: '清除背景'),
            IconButton(icon: const Icon(Icons.wallpaper_rounded), onPressed: _pickBackground, tooltip: '设置背景'),
            IconButton(icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round), onPressed: widget.onThemeToggle),
            IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _isLoading ? null : _syncAll),
            IconButton(icon: const Icon(Icons.logout_rounded, color: Colors.redAccent), onPressed: _logout),
            const SizedBox(width: 8),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStats(),
              if (_isLoading && _syncStatus.isNotEmpty) ...[const SizedBox(height: 16), _buildSync()],
              const SizedBox(height: 24),
              _buildSearch(),
              const SizedBox(height: 32),
              _buildSectionTitle('个人空间', isDark),
              const SizedBox(height: 8),
              _buildMyFilesCard(),
              const SizedBox(height: 32),
              if (_isLoading && _courses.isEmpty) const Center(child: CircularProgressIndicator())
              else ...terms.map((t) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(t, isDark),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 280, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.25),
                    itemCount: grouped[t]!.length,
                    itemBuilder: (c, i) => _buildCourseCard(grouped[t]![i]),
                  ),
                  const SizedBox(height: 24),
                ],
              )).toList(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 4, height: 20, decoration: BoxDecoration(color: Colors.blueAccent, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: isDark || _backgroundPath != null ? Colors.white.withOpacity(0.95) : const Color(0xFF1E293B))),
        ]),
        const SizedBox(height: 4),
        Divider(color: isDark || _backgroundPath != null ? Colors.white.withOpacity(0.1) : Colors.black12),
      ],
    );
  }

  Widget _buildMyFilesCard() {
    return SizedBox(
      width: double.infinity, height: 60,
      child: GlassCard(
        isDark: widget.isDarkMode, padding: EdgeInsets.zero, color: Colors.blue.withOpacity(0.1),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CourseDetailScreen(course: Course(id: 0, name: '我的个人文件'), isDarkMode: widget.isDarkMode))),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cloud_queue_rounded, color: Colors.blue, size: 24),
              SizedBox(width: 12),
              Text('我的云端个人文件', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(children: [
      _buildStat('课程', _stats['courses'] ?? 0, Colors.blue),
      const SizedBox(width: 12),
      _buildStat('资料', _stats['files'] ?? 0, Colors.orange),
      const SizedBox(width: 12),
      _buildStat('作业', _stats['assignments'] ?? 0, Colors.green),
    ]);
  }

  Widget _buildStat(String l, int v, Color c) {
    return Expanded(child: GlassCard(isDark: widget.isDarkMode, child: Column(children: [
      Text('$v', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: c.withOpacity(0.9))),
      Text(l, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: widget.isDarkMode ? Colors.white38 : Colors.grey.shade600)),
    ])));
  }

  Widget _buildSync() {
    final isDark = widget.isDarkMode;
    return GlassCard(isDark: widget.isDarkMode, color: Colors.blue.withOpacity(0.05), child: Row(children: [
      const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
      const SizedBox(width: 12),
      Expanded(child: Text(_syncStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark || _backgroundPath != null ? Colors.blue[200] : Colors.blue[800]), overflow: TextOverflow.ellipsis)),
    ]));
  }

  Widget _buildSearch() {
    final isDark = widget.isDarkMode;
    return GlassCard(isDark: widget.isDarkMode, padding: EdgeInsets.zero, child: TextField(
      style: TextStyle(color: isDark || _backgroundPath != null ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(hintText: '搜课件、搜作业...', hintStyle: TextStyle(color: isDark || _backgroundPath != null ? Colors.white54 : Colors.black38), prefixIcon: Icon(Icons.search_rounded, color: isDark || _backgroundPath != null ? Colors.white70 : Colors.black54), border: InputBorder.none),
      onSubmitted: (v) { if (v.isNotEmpty) Navigator.push(context, MaterialPageRoute(builder: (c) => SearchScreen(initialQuery: v))); },
    ));
  }

  Widget _buildCourseCard(Course course) {
    final subjectColor = _getCourseColor(course);
    final isDark = widget.isDarkMode;
    return GlassCard(
      isDark: isDark, padding: EdgeInsets.zero, color: subjectColor.withOpacity(isDark || _backgroundPath != null ? 0.25 : 0.15),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => CourseDetailScreen(course: course, isDarkMode: widget.isDarkMode))),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.book_rounded, color: isDark || _backgroundPath != null ? subjectColor.withOpacity(0.9) : subjectColor, size: 22),
                const SizedBox(width: 8),
                if (course.courseCode != null) Expanded(child: Text(course.courseCode!, textAlign: TextAlign.right, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: (isDark || _backgroundPath != null ? Colors.white : subjectColor).withOpacity(0.7)))),
              ]),
              const Spacer(),
              Text(course.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: isDark || _backgroundPath != null ? Colors.white : Colors.black87, height: 1.25)),
              const SizedBox(height: 6),
              if (course.term != null) Text(course.term!, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark || _backgroundPath != null ? Colors.white70 : Colors.blueGrey[600])),
            ],
          ),
        ),
      ),
    );
  }

  Color _getCourseColor(Course course) {
    final name = course.name.toLowerCase();
    // Vibrant colors mapping
    if (RegExp(r'算法|导论|数据|计算|数|物|化|理|程序|algorithm|computer|data|phys|chem|math|programming').hasMatch(name)) return const Color(0xFF3B82F6); // Bright Blue
    if (RegExp(r'史|政|社|经|法|全球|哲|人文|history|politic|soc|econ|global|law|philo').hasMatch(name)) return const Color(0xFFF97316); // Bright Orange
    if (RegExp(r'英|写|艺|美|音|语|english|write|art|music|lang').hasMatch(name)) return const Color(0xFFD946EF); // Fuchsia/Purple
    return const Color(0xFF0EA5E9); // Light Blue default
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? color;
  final bool isDark;
  const GlassCard({Key? key, required this.child, this.padding, this.color, required this.isDark}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return ClipRRect(borderRadius: BorderRadius.circular(20), child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Increased blur for better readability with backgrounds
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? (isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.4), width: 1.5),
        ),
        child: child,
      ),
    ));
  }
}