import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/download_service.dart';
import '../screens/home_screen.dart';

class FileListItem extends StatefulWidget {
  final CourseFile file;
  const FileListItem({Key? key, required this.file}) : super(key: key);

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  final DownloadService _downloadService = DownloadService();
  bool _isDownloaded = false;
  bool _isDownloading = false;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final downloaded = await _downloadService.isFileDownloaded(widget.file);
    if (mounted) setState(() { _isDownloaded = downloaded; });
  }

  Future<void> _handleTap() async {
    if (_isDownloaded) {
      try { await _downloadService.openLocalFile(widget.file); } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('无法打开文件: $e')));
      }
    } else {
      if (_isDownloading) return;
      setState(() { _isDownloading = true; _progress = 0.0; });
      try {
        await _downloadService.downloadFile(widget.file, onReceiveProgress: (count, total) {
          if (total != -1 && mounted) setState(() { _progress = count / total; });
        });
        if (mounted) setState(() { _isDownloaded = true; _isDownloading = false; });
      } catch (e) {
        if (mounted) { 
          setState(() => _isDownloading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下载失败: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        isDark: isDark,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.insert_drive_file_rounded, color: Colors.blue, size: 22),
          title: Text(widget.file.filename, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.file.source != null && widget.file.source != '课程目录')
                Text('来源: ${widget.file.source}', style: const TextStyle(fontSize: 10, color: Colors.blueGrey)),
              if (_isDownloading) 
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: LinearProgressIndicator(value: _progress, minHeight: 2),
                )
              else if (widget.file.size != null) 
                Text('${(widget.file.size! / 1024 / 1024).toStringAsFixed(1)} MB', style: const TextStyle(fontSize: 10)),
            ],
          ),
          trailing: Icon(
            _isDownloaded ? Icons.folder_open_rounded : Icons.download_rounded,
            size: 18,
            color: _isDownloaded ? Colors.green : Colors.blueGrey,
          ),
          onTap: _handleTap,
        ),
      ),
    );
  }
}