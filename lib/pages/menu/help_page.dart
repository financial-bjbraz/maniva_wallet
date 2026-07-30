import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../util/app_theme.dart';
import '../../util/util.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  _HelpPageState createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() {
          _appVersion = 'v${info.version}';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final faqs = [
      (t.faq1Q, t.faq1A),
      (t.faq2Q, t.faq2A),
      (t.faq3Q, t.faq3A),
      (t.faq4Q, t.faq4A),
      (t.faq5Q, t.faq5A),
    ];
    return Scaffold(
      backgroundColor: rootstockBlack,
      appBar: AppBar(
        backgroundColor: rootstockBlack,
        iconTheme: const IconThemeData(color: rootstockCream),
        title: Text(t.help, style: const TextStyle(color: rootstockCream)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final faq in faqs)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                iconColor: rootstockCream,
                collapsedIconColor: rootstockCream,
                title: Text(
                  faq.$1,
                  style: const TextStyle(color: rootstockCream, fontWeight: FontWeight.bold),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      faq.$2,
                      style: mutedCaptionText,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          if (_appVersion.isNotEmpty)
            Center(
              child: Text(_appVersion, style: mutedCaptionText),
            ),
        ],
      ),
    );
  }
}
