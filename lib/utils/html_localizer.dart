import 'dart:io';
import '../models/models.dart';
import '../services/database.dart';
import '../services/download_service.dart';

class HtmlLocalizer {
  static final LocalDatabase _db = LocalDatabase();
  static final DownloadService _downloadService = DownloadService();

  /// 将 HTML 中的远程 Canvas 链接替换为本地文件路径
  static Future<String> localizeHtml(String html) async {
    // 匹配 Canvas 文件链接的正则表达式: /files/(\d+)
    final RegExp regExp = RegExp(r'(?:https?://[^/]+)?/files/(\d+)(?:/[^"''\s>]+)?');
    
    // 我们需要通过这些 ID 找到对应的本地路径
    final matches = regExp.allMatches(html);
    if (matches.isEmpty) return html;

    String localizedHtml = html;
    
    // 收集所有唯一的 ID
    Set<int> fileIds = {};
    for (var match in matches) {
      final idStr = match.group(1);
      if (idStr != null) {
        final id = int.tryParse(idStr);
        if (id != null) fileIds.add(id);
      }
    }

    // 针对每个 ID 尝试寻找本地映射
    for (int fileId in fileIds) {
      final CourseFile? file = await _db.getFileById(fileId);
      if (file != null) {
        if (await _downloadService.isFileDownloaded(file)) {
          final String localPath = await _downloadService.getLocalFilePath(file);
          // 转换为 file:// URL，并在 Windows 上处理路径斜杠
          final String fileUrl = 'file:///${localPath.replaceAll('\\', '/')}';
          
          // 替换所有引用此 ID 的 URL (不管是带域名还是不带域名的)
          // 这里的正则需要小心，防止误伤其他类似 ID
          final String pattern = r'(?:https?://[^/]+)?/files/' + fileId.toString() + r'(?:/[^"''\s>]+)?';
          localizedHtml = localizedHtml.replaceAll(RegExp(pattern), fileUrl);
        }
      }
    }
    
    return localizedHtml;
  }
}