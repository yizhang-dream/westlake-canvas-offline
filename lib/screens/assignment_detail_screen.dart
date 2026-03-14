import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/models.dart';
import 'home_screen.dart';

class AssignmentDetailScreen extends StatelessWidget {
  final Assignment assignment;
  const AssignmentDetailScreen({Key? key, required this.assignment}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)] 
            : [const Color(0xFFE2E8F0), const Color(0xFFBFDBFE)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: const Text('作业详情')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            isDark: isDark,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(assignment.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (assignment.pointsPossible != null)
                  Text('总分: ${assignment.pointsPossible}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                const Divider(height: 32),
                Html(
                  data: assignment.description ?? '<p>无详细说明</p>',
                  onLinkTap: (url, attributes, element) async {
                    if (url != null) {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    }
                  },
                  style: {
                    "body": Style(fontSize: FontSize(16.0), color: isDark ? Colors.white : Colors.black87),
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}