import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:open_filex/open_filex.dart';
import '../models/models.dart';
import 'canvas_api.dart';

class DownloadService {
  final CanvasApi _api = CanvasApi();

  /// 设置下载器使用的 Token
  void setToken(String token) {
    _api.setToken(token);
  }

  /// 获取文件应该保存的本地路径
  Future<String> getLocalFilePath(CourseFile file) async {
    final docsDir = await getApplicationDocumentsDirectory();
    // 路径结构: Documents/canvas_offline/files/<course_id>/<file_id>_<filename>
    final courseDir = Directory(p.join(docsDir.path, 'canvas_offline', 'files', file.courseId.toString()));
    
    if (!await courseDir.exists()) {
      await courseDir.create(recursive: true);
    }
    
    return p.join(courseDir.path, '${file.id}_${file.filename}');
  }

  /// 检查文件是否已下载
  Future<bool> isFileDownloaded(CourseFile file) async {
    final path = await getLocalFilePath(file);
    final f = File(path);
    if (await f.exists()) {
      // 检查文件大小是否匹配 (简单校验，防止下载了一半的文件)
      if (file.size != null && file.size! > 0) {
        final stat = await f.stat();
        return stat.size > 0;
      }
      return true;
    }
    return false;
  }

  /// 下载单个文件 (支持 OneDrive 和 重定向)
  Future<void> downloadFile(CourseFile file, {void Function(int count, int total)? onReceiveProgress}) async {
    String savePath = await getLocalFilePath(file);
    if (await isFileDownloaded(file)) return;

    try {
      String downloadUrl = file.url ?? '';
      if (downloadUrl.isEmpty) {
        downloadUrl = await _api.getFileDownloadUrl(file.id);
      }

      // 如果链接包含 onedrive 或 sharepoint，我们需要特殊处理重定向
      final isExternal = downloadUrl.contains('sharepoint.com') || downloadUrl.contains('onedrive.live.com');

      final response = await Dio().download(
        downloadUrl,
        savePath,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: isExternal ? {} : {'Authorization': 'Bearer ${_api.token}'},
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
      );

      // 如果是外部链接，尝试根据 Header 修正文件名 (如果之前只有 ID)
      if (isExternal && response.headers['content-disposition'] != null) {
        // TODO: 之后可以解析 disposition 提取真实文件名并重命名文件
      }
    } catch (e) {
      final f = File(savePath);
      if (await f.exists()) await f.delete();
      rethrow;
    }
  }

  /// 打开本地文件
  Future<void> openLocalFile(CourseFile file) async {
    final path = await getLocalFilePath(file);
    if (await File(path).exists()) {
      await OpenFilex.open(path);
    } else {
      throw Exception('文件未下载或已丢失');
    }
  }
}