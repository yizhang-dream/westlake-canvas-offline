import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/models.dart';

class LocalDatabase {
  static final LocalDatabase _instance = LocalDatabase._internal();
  factory LocalDatabase() => _instance;
  LocalDatabase._internal();

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'canvas_offline.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE config (
            key TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE courses (
            id INTEGER PRIMARY KEY,
            name TEXT NOT NULL,
            course_code TEXT,
            term TEXT,
            created_at TEXT,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE files (
            id INTEGER PRIMARY KEY,
            course_id INTEGER,
            filename TEXT NOT NULL,
            size INTEGER,
            content_type TEXT,
            url TEXT,
            created_at TEXT,
            source TEXT,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE assignments (
            id INTEGER PRIMARY KEY,
            course_id INTEGER,
            name TEXT NOT NULL,
            description TEXT,
            due_at TEXT,
            points_possible REAL,
            has_submission INTEGER,
            graded INTEGER,
            score REAL,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE pages (
            id INTEGER PRIMARY KEY,
            course_id INTEGER,
            title TEXT NOT NULL,
            body TEXT,
            updated_at TEXT,
            data TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE announcements (
            id INTEGER PRIMARY KEY,
            course_id INTEGER,
            title TEXT NOT NULL,
            message TEXT,
            created_at TEXT,
            data TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try { await db.execute('ALTER TABLE files ADD COLUMN source TEXT'); } catch(e) {}
        }
      },
    );
  }

  // ==================== Token 管理 ====================

  Future<void> saveToken(String token) async {
    final db = await database;
    await db.insert('config', {'key': 'canvas_token', 'value': token}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getToken() async {
    final db = await database;
    final result = await db.query('config', where: 'key = ?', whereArgs: ['canvas_token']);
    if (result.isEmpty) return null;
    return result.first['value'] as String;
  }

  Future<void> clearToken() async {
    final db = await database;
    await db.delete('config', where: 'key = ?', whereArgs: ['canvas_token']);
  }

  // ==================== 背景图管理 ====================

  Future<void> saveBackgroundPath(String path) async {
    final db = await database;
    await db.insert('config', {'key': 'custom_background_path', 'value': path}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<String?> getBackgroundPath() async {
    final db = await database;
    final result = await db.query('config', where: 'key = ?', whereArgs: ['custom_background_path']);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> clearBackgroundPath() async {
    final db = await database;
    await db.delete('config', where: 'key = ?', whereArgs: ['custom_background_path']);
  }

  Future<void> clearAllData() async {
    final db = await database;
    final batch = db.batch();
    batch.delete('courses');
    batch.delete('files');
    batch.delete('assignments');
    batch.delete('pages');
    batch.delete('announcements');
    await batch.commit(noResult: true);
  }

  // ==================== 课程管理 ====================

  Future<void> saveCourses(List<Course> courses) async {
    final db = await database;
    final batch = db.batch();
    for (final course in courses) {
      batch.insert('courses', {
        'id': course.id,
        'name': course.name,
        'course_code': course.courseCode,
        'term': course.term,
        'created_at': course.createdAt?.toIso8601String(),
        'data': jsonEncode(course.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Course>> getCourses() async {
    final db = await database;
    final result = await db.query('courses', orderBy: 'name');
    return result.map((item) => Course.fromJson(jsonDecode(item['data'] as String))).toList();
  }

  Future<List<Course>> getNonEmptyCourses() async {
    final db = await database;
    final nonEmptyIds = await db.rawQuery('SELECT DISTINCT id FROM courses WHERE id IN (SELECT DISTINCT course_id FROM files) OR id IN (SELECT DISTINCT course_id FROM assignments) OR id IN (SELECT DISTINCT course_id FROM announcements)');
    final Set<int> ids = nonEmptyIds.map((e) => e['id'] as int).toSet();
    final allCourses = await getCourses();
    return allCourses.where((c) => ids.contains(c.id)).toList();
  }

  // ==================== 文件管理 ====================

  Future<void> saveCourseFiles(List<CourseFile> files) async {
    final db = await database;
    final batch = db.batch();
    for (final file in files) {
      batch.insert('files', {
        'id': file.id,
        'course_id': file.courseId,
        'filename': file.filename,
        'size': file.size,
        'content_type': file.contentType,
        'url': file.url,
        'created_at': file.createdAt?.toIso8601String(),
        'source': file.source,
        'data': jsonEncode(file.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CourseFile>> getCourseFiles(int courseId) async {
    final db = await database;
    final result = await db.query('files', where: courseId > 0 ? 'course_id = ?' : null, whereArgs: courseId > 0 ? [courseId] : null, orderBy: 'filename');
    return result.map((item) => CourseFile.fromJson(jsonDecode(item['data'] as String))).toList();
  }

  Future<CourseFile?> getFileById(int fileId) async {
    final db = await database;
    final result = await db.query('files', where: 'id = ?', whereArgs: [fileId], limit: 1);
    if (result.isEmpty) return null;
    return CourseFile.fromJson(jsonDecode(result.first['data'] as String));
  }

  // ==================== 作业管理 ====================

  Future<void> saveAssignments(List<Assignment> assignments) async {
    final db = await database;
    final batch = db.batch();
    for (final assignment in assignments) {
      batch.insert('assignments', {
        'id': assignment.id,
        'course_id': assignment.courseId,
        'name': assignment.name,
        'description': assignment.description,
        'due_at': assignment.dueAt?.toIso8601String(),
        'points_possible': assignment.pointsPossible,
        'has_submission': assignment.hasSubmission ? 1 : 0,
        'graded': assignment.graded ? 1 : 0,
        'score': assignment.score,
        'data': jsonEncode(assignment.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Assignment>> getCourseAssignments(int courseId) async {
    final db = await database;
    final result = await db.query('assignments', where: 'course_id = ?', whereArgs: [courseId], orderBy: 'due_at');
    return result.map((item) => Assignment.fromJson(jsonDecode(item['data'] as String))).toList();
  }

  // ==================== 页面管理 ====================

  Future<void> savePages(List<CoursePage> pages) async {
    final db = await database;
    final batch = db.batch();
    for (final page in pages) {
      batch.insert('pages', {
        'id': page.id,
        'course_id': page.courseId,
        'title': page.title,
        'body': page.body,
        'updated_at': page.updatedAt?.toIso8601String(),
        'data': jsonEncode(page.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<CoursePage>> getCoursePages(int courseId) async {
    final db = await database;
    final result = await db.query('pages', where: 'course_id = ?', whereArgs: [courseId]);
    return result.map((item) => CoursePage.fromJson(jsonDecode(item['data'] as String))).toList();
  }

  // ==================== 公告管理 ====================

  Future<void> saveAnnouncements(List<Announcement> announcements) async {
    final db = await database;
    final batch = db.batch();
    for (final announcement in announcements) {
      batch.insert('announcements', {
        'id': announcement.id,
        'course_id': announcement.courseId,
        'title': announcement.title,
        'message': announcement.message,
        'created_at': announcement.createdAt?.toIso8601String(),
        'data': jsonEncode(announcement.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Announcement>> getCourseAnnouncements(int courseId) async {
    final db = await database;
    final result = await db.query('announcements', where: 'course_id = ?', whereArgs: [courseId], orderBy: 'created_at DESC');
    return result.map((item) => Announcement.fromJson(jsonDecode(item['data'] as String))).toList();
  }

  // ==================== 统计功能 ====================

  Future<Map<String, int>> getStats() async {
    final db = await database;
    final courses = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    final files = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM files')) ?? 0;
    final assignments = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM assignments')) ?? 0;
    final announcements = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM announcements')) ?? 0;
    return {'courses': courses, 'files': files, 'assignments': assignments, 'announcements': announcements};
  }

  // ==================== 搜索功能 ====================

  Future<Map<String, List<dynamic>>> search(String query) async {
    final db = await database;
    final keyword = '%$query%';
    final courses = await db.query('courses', where: 'name LIKE ?', whereArgs: [keyword]);
    final files = await db.query('files', where: 'filename LIKE ?', whereArgs: [keyword]);
    final assignments = await db.query('assignments', where: 'name LIKE ?', whereArgs: [keyword]);
    final pages = await db.query('pages', where: 'title LIKE ?', whereArgs: [keyword]);
    return {
      'courses': courses.map((i) => Course.fromJson(jsonDecode(i['data'] as String))).toList(),
      'files': files.map((i) => CourseFile.fromJson(jsonDecode(i['data'] as String))).toList(),
      'assignments': assignments.map((i) => Assignment.fromJson(jsonDecode(i['data'] as String))).toList(),
      'pages': pages.map((i) => CoursePage.fromJson(jsonDecode(i['data'] as String))).toList(),
    };
  }

  Future<void> close() async { if (_database != null) { await _database!.close(); _database = null; } }
}