import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../models/models.dart';

/// Canvas API 客户端
class CanvasApi {
  final String baseUrl;
  final String apiVersion;
  String? _token;
  late Dio _dio;

  CanvasApi({
    this.baseUrl = 'https://canvas.westlake.edu.cn',
    this.apiVersion = '/api/v1',
    String? token,
  }) {
    _token = token;
    
    // Web 版本使用本地代理服务器解决 CORS 问题
    final effectiveBaseUrl = kIsWeb 
        ? 'http://localhost:3000/api' 
        : baseUrl + apiVersion;
    
    _dio = Dio(BaseOptions(
      baseUrl: effectiveBaseUrl,
      headers: {
        'Authorization': 'Bearer $_token',
        'Content-Type': 'application/json',
      },
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
    ));
  }

  String? get token => _token;

  /// 设置 Token
  void setToken(String token) {
    _token = token;
    _dio.options.headers['Authorization'] = 'Bearer $_token';
  }

  /// 获取当前用户
  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/users/self');
    return response.data as Map<String, dynamic>;
  }

  /// 获取课程列表
  Future<List<Course>> getCourses({int perPage = 100}) async {
    final response = await _dio.get(
      '/courses',
      queryParameters: {
        'per_page': perPage,
        'include[]': 'term', // 确保包含学期
        'enrollment_state': 'active,invited,completed', // 抓取所有状态的课程
      },
    );
    
    final List<dynamic> data = response.data as List;
    // 过滤掉没有名字的垃圾课程（有时 API 会返回这些）
    return data
      .where((item) => item['name'] != null)
      .map((item) => Course.fromJson(item))
      .toList();
  }

  /// 获取课程文件
  Future<List<CourseFile>> getCourseFiles(int courseId, {int perPage = 100}) async {
    final response = await _dio.get(
      '/courses/$courseId/files',
      queryParameters: {'per_page': perPage},
    );
    
    final List<dynamic> data = response.data as List;
    return data.map((item) => CourseFile.fromJson({...item, 'course_id': courseId})).toList();
  }

  /// 获取个人文件 (My Files)
  Future<List<CourseFile>> getUserFiles({int perPage = 100}) async {
    final response = await _dio.get(
      '/users/self/files',
      queryParameters: {'per_page': perPage},
    );
    final List<dynamic> data = response.data as List;
    // 个人文件在数据库中统一归类到课程 ID 为 0
    return data.map((item) => CourseFile.fromJson({...item, 'course_id': 0, 'source': '我的文件'})).toList();
  }

  /// 获取作业列表
  Future<List<Assignment>> getAssignments(int courseId, {int perPage = 100}) async {
    final response = await _dio.get(
      '/courses/$courseId/assignments',
      queryParameters: {
        'per_page': perPage,
        'include[]': 'submission',
      },
    );
    
    final List<dynamic> data = response.data as List;
    return data.map((item) => Assignment.fromJson(item, courseId: courseId)).toList();
  }

  /// 获取课程页面
  Future<List<CoursePage>> getPages(int courseId, {int perPage = 100}) async {
    final response = await _dio.get(
      '/courses/$courseId/pages',
      queryParameters: {'per_page': perPage},
    );

    final List<dynamic> data = response.data as List;
    return data.map((item) => CoursePage.fromJson(item, courseId: courseId)).toList();
  }

  /// 根据 URL 获取单个页面详情 (含 Body)
  Future<CoursePage> getPageDetail(int courseId, String pageUrl) async {
    final response = await _dio.get('/courses/$courseId/pages/$pageUrl');
    return CoursePage.fromJson(response.data, courseId: courseId);
  }

  /// 获取课程公告 (西湖大学兼容版)
  Future<List<Announcement>> getAnnouncements(int courseId, {int perPage = 50}) async {
    // 强制使用全局公告接口，带上课程编码
    final response = await _dio.get(
      '/announcements',
      queryParameters: {
        'per_page': perPage,
        'context_codes[]': 'course_$courseId', 
      },
    );

    final List<dynamic> data = response.data as List;
    return data.map((item) => Announcement.fromJson({...item, 'course_id': courseId})).toList();
  }

  /// 获取课程导航栏 (Tabs)
  Future<List<dynamic>> getCourseTabs(int courseId) async {
    final response = await _dio.get('/courses/$courseId/tabs');
    return response.data as List;
  }

  /// 获取课程讨论区 (Discussions)
  Future<List<dynamic>> getDiscussions(int courseId) async {
    final response = await _dio.get('/courses/$courseId/discussion_topics');
    return response.data as List;
  }

  /// 获取课程大纲 (Syllabus) 文字内容
  Future<String?> getCourseSyllabus(int courseId) async {
    final response = await _dio.get('/courses/$courseId', queryParameters: {'include[]': 'syllabus_body'});
    return response.data['syllabus_body'] as String?;
  }

  /// 获取课程首页 (Front Page)
  Future<Map<String, dynamic>?> getCourseFrontPage(int courseId) async {
    try {
      final response = await _dio.get('/courses/$courseId/front_page');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// 获取单个页面内容
  Future<CoursePage> getPage(int courseId, int pageId) async {
    final response = await _dio.get('/courses/$courseId/pages/$pageId');
    return CoursePage.fromJson(response.data, courseId: courseId);
  }

  /// 获取课程模块 (Modules)
  Future<List<dynamic>> getModules(int courseId) async {
    final response = await _dio.get(
      '/courses/$courseId/modules',
      queryParameters: {'include[]': 'items', 'per_page': 50},
    );
    return response.data as List;
  }

  /// 获取作业详情
  Future<Assignment> getAssignment(int courseId, int assignmentId) async {
    final response = await _dio.get(
      '/courses/$courseId/assignments/$assignmentId',
      queryParameters: {'include[]': 'submission'},
    );
    return Assignment.fromJson(response.data, courseId: courseId);
  }

  /// 提交作业（文本）
  Future<Map<String, dynamic>> submitAssignmentText(
    int courseId,
    int assignmentId,
    String text,
  ) async {
    final response = await _dio.post(
      '/courses/$courseId/assignments/$assignmentId/submissions',
      data: {
        'submission[submission_type]': 'online_text_entry',
        'submission[body]': text,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 提交作业（文件 - 简单实现版，针对允许直接上传的接口）
  /// 注意: Canvas 标准文件上传分三步，此为简化直接提交（如果接口支持）
  Future<Map<String, dynamic>> submitAssignmentFile(
    int courseId,
    int assignmentId,
    int fileId,
  ) async {
    final response = await _dio.post(
      '/courses/$courseId/assignments/$assignmentId/submissions',
      data: {
        'submission[submission_type]': 'online_upload',
        'submission[file_ids][]': fileId,
      },
    );
    return response.data as Map<String, dynamic>;
  }

  /// 获取文件下载 URL
  Future<String> getFileDownloadUrl(int fileId) async {
    final response = await _dio.get('/files/$fileId');
    return response.data['url'] as String;
  }

  /// 获取单个文件的详细信息
  Future<CourseFile> getFileDetails(int fileId) async {
    final response = await _dio.get('/files/$fileId');
    final data = response.data;
    // 如果没有 course_id，我们尝试从 context_id 提取或设为 0
    int courseId = 0;
    if (data['context_type'] == 'Course') {
      courseId = data['context_id'] ?? 0;
    }
    return CourseFile.fromJson({...data, 'course_id': courseId});
  }

  /// 测试连接
  Future<bool> testConnection() async {
    try {
      await getCurrentUser();
      return true;
    } catch (e) {
      return false;
    }
  }
}
