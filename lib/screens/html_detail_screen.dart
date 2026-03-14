import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/html_localizer.dart';
import 'home_screen.dart';

class HtmlDetailScreen extends StatefulWidget {
  final String title;
  final String htmlContent;

  const HtmlDetailScreen({
    Key? key,
    required this.title,
    required this.htmlContent,
  }) : super(key: key);

  @override
  State<HtmlDetailScreen> createState() => _HtmlDetailScreenState();
}

class _HtmlDetailScreenState extends State<HtmlDetailScreen> {
  String? _localizedHtml;

  @override
  void initState() {
    super.initState();
    _localize();
  }

  Future<void> _localize() async {
    final localized = await HtmlLocalizer.localizeHtml(widget.htmlContent);
    if (mounted) setState(() { _localizedHtml = localized; });
  }

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
        appBar: AppBar(title: Text(widget.title)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            isDark: isDark,
            child: Html(
              data: _localizedHtml ?? widget.htmlContent,
              onLinkTap: (url, attributes, element) async {
                if (url != null) {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) await launchUrl(uri);
                }
              },
              style: {
                "body": Style(fontSize: FontSize(16.0), color: isDark ? Colors.white : Colors.black87),
                "img": Style(width: Width(100, Unit.percent)),
              },
            ),
          ),
        ),
      ),
    );
  }
}
