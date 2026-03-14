/// 课程模型
class Course {
  final int id;
  final String name;
  final String? courseCode;
  final String? term;
  final DateTime? createdAt;

  Course({
    required this.id,
    required this.name,
    this.courseCode,
    this.term,
    this.createdAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    try {
      // 1. 尝试从各种可能的 term 字段提取原始文本
      String? rawTerm;
      final termData = json['term'];
      if (termData is Map) {
        rawTerm = termData['name']?.toString() ?? termData['label']?.toString();
      } else if (termData is String) {
        rawTerm = termData;
      }

      // 2. 智能识别逻辑 (Westlake & Standard)
      String? termName;
      final courseName = json['name']?.toString() ?? '';
      
      // A. 如果 API 给了 rawTerm，优先解析它
      if (rawTerm != null && rawTerm.isNotEmpty && rawTerm.toLowerCase() != 'default term') {
        termName = _formatTerm(rawTerm);
      }
      
      // B. 如果 rawTerm 无效，尝试从课程名字里“抠”
      if (termName == null) {
        // 匹配 2024-2025-1 或 2024秋季 或 2024 Fall 等
        final match = RegExp(r'(20\d{2})').firstMatch(courseName);
        if (match != null) {
          String year = match.group(1)!;
          String n = courseName.toLowerCase();
          if (n.contains('秋') || n.contains('fall') || n.contains('-1')) {
            termName = '$year Fall';
          } else if (n.contains('春') || n.contains('spring') || n.contains('-2')) {
            termName = '$year Spring';
          }
        }
      }

      // 最终兜底：如果还是没拿到，给一个明确的标识
      termName ??= '2024 Fall'; 

      return Course(
        id: json['id'] ?? 0,
        name: json['name'] ?? '未命名课程',
        courseCode: json['course_code'],
        term: termName,
        createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      );
    } catch (e) {
      return Course(id: json['id'] ?? 0, name: json['name'] ?? '解析失败');
    }
  }

  /// 规范化学期格式: "2026 SPRING" -> "2026 Spring"
  static String? _formatTerm(String raw) {
    final match = RegExp(r'(20\d{2})\s*(FALL|SPRING|SUMMER|秋|春|夏)', caseSensitive: false).firstMatch(raw);
    if (match != null) {
      String year = match.group(1)!;
      String season = match.group(2)!.toLowerCase();
      if (season.contains('fall') || season.contains('秋')) return '$year Fall';
      if (season.contains('spring') || season.contains('春')) return '$year Spring';
      if (season.contains('summer') || season.contains('夏')) return '$year Summer';
    }
    return raw; // 无法规范化则原样返回
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'course_code': courseCode,
      'term': term,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

/// 文件模型
class CourseFile {
  final int id;
  final int courseId;
  final String filename;
  final int? size;
  final String? contentType;
  final String? url;
  final DateTime? createdAt;
  final String? source;

  CourseFile({
    required this.id,
    required this.courseId,
    required this.filename,
    this.size,
    this.contentType,
    this.url,
    this.createdAt,
    this.source,
  });

  factory CourseFile.fromJson(Map<String, dynamic> json) {
    return CourseFile(
      id: json['id'] ?? 0,
      courseId: json['course_id'] ?? 0,
      filename: json['filename'] ?? '',
      size: json['size'],
      contentType: json['content_type'],
      url: json['url'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      source: json['source'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'filename': filename,
      'size': size,
      'content_type': contentType,
      'url': url,
      'created_at': createdAt?.toIso8601String(),
      'source': source,
    };
  }
}

/// 作业模型
class Assignment {
  final int id;
  final int courseId;
  final String name;
  final String? description;
  final DateTime? dueAt;
  final double? pointsPossible;
  final bool hasSubmission;
  final bool graded;
  final double? score;
  final DateTime? submittedAt;

  Assignment({
    required this.id,
    required this.courseId,
    required this.name,
    this.description,
    this.dueAt,
    this.pointsPossible,
    this.hasSubmission = false,
    this.graded = false,
    this.score,
    this.submittedAt,
  });

  factory Assignment.fromJson(Map<String, dynamic> json, {int courseId = 0}) {
    final submission = json['submission'] as Map<String, dynamic>? ?? {};
    return Assignment(
      id: json['id'] ?? 0,
      courseId: courseId,
      name: json['name'] ?? '',
      description: json['description'],
      dueAt: json['due_at'] != null ? DateTime.tryParse(json['due_at']) : null,
      pointsPossible: json['points_possible']?.toDouble(),
      hasSubmission: submission['submitted_at'] != null,
      graded: submission['graded'] ?? false,
      score: submission['score']?.toDouble(),
      submittedAt: submission['submitted_at'] != null 
          ? DateTime.tryParse(submission['submitted_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'name': name,
      'description': description,
      'due_at': dueAt?.toIso8601String(),
      'points_possible': pointsPossible,
      'has_submission': hasSubmission,
      'graded': graded,
      'score': score,
      'submitted_at': submittedAt?.toIso8601String(),
    };
  }
}

/// 课程页面模型
class CoursePage {
  final int id;
  final int courseId;
  final String title;
  final String? body;
  final DateTime? updatedAt;
  final String? pageUrl; // 新增 URL 标识符

  CoursePage({
    required this.id,
    required this.courseId,
    required this.title,
    this.body,
    this.updatedAt,
    this.pageUrl,
  });

  factory CoursePage.fromJson(Map<String, dynamic> json, {int courseId = 0}) {
    return CoursePage(
      id: json['id'] ?? (json['page_id'] ?? 0),
      courseId: courseId,
      title: json['title'] ?? '',
      body: json['body'],
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
      pageUrl: json['url'], // API 中的 'url' 字段其实是标识符
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'body': body,
      'updated_at': updatedAt?.toIso8601String(),
      'url': pageUrl,
    };
  }
}

/// 公告模型
class Announcement {
  final int id;
  final int courseId;
  final String title;
  final String? message;
  final DateTime? createdAt;

  Announcement({
    required this.id,
    required this.courseId,
    required this.title,
    this.message,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json, {int courseId = 0}) {
    return Announcement(
      id: json['id'] ?? 0,
      courseId: courseId,
      title: json['title'] ?? '',
      message: json['message'],
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'course_id': courseId,
      'title': title,
      'message': message,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
