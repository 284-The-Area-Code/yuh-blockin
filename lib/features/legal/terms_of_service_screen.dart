import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/theme/premium_theme.dart';

/// Renders the bundled Terms of Service (assets/legal/terms_of_service.md)
/// as plain formatted text, with no surrounding Scaffold/AppBar - embeddable
/// directly inside another screen (see OnboardingFlow's agreement gate).
///
/// Deliberately reads the local bundled copy rather than fetching
/// PaymentConfig.termsOfServiceUrl - this is the text a user actually agrees
/// to, so it must not depend on network access or an external site staying
/// in sync with what shipped in this build. No markdown package is used -
/// the source file only needs headers, bullets, and body text, which a
/// small line-based formatter handles without a new dependency.
class TermsOfServiceContent extends StatefulWidget {
  const TermsOfServiceContent({super.key});

  @override
  State<TermsOfServiceContent> createState() => _TermsOfServiceContentState();
}

class _TermsOfServiceContentState extends State<TermsOfServiceContent> {
  String? _content;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final text = await rootBundle.loadString('assets/legal/terms_of_service.md');
      if (mounted) setState(() => _content = text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  List<Widget> _formatted(String text) {
    final widgets = <Widget>[];
    for (final rawLine in text.split('\n')) {
      final line = rawLine.trimRight();
      if (line.isEmpty || line == '---') {
        widgets.add(const SizedBox(height: 12));
      } else if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 6),
          child: Text(
            line.substring(3),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
        ));
      } else if (line.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            line.substring(2),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
        ));
      } else if (line.startsWith('- ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('•  ', style: TextStyle(color: PremiumTheme.secondaryTextColor)),
              Expanded(
                child: Text(
                  line.substring(2),
                  style: TextStyle(fontSize: 14, color: PremiumTheme.secondaryTextColor, height: 1.4),
                ),
              ),
            ],
          ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**') && line.length > 4) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line.substring(2, line.length - 2),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            style: TextStyle(fontSize: 14, color: PremiumTheme.secondaryTextColor, height: 1.4),
          ),
        ));
      }
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            'Could not load the Terms of Service.\n$_error',
            textAlign: TextAlign.center,
            style: TextStyle(color: PremiumTheme.secondaryTextColor),
          ),
        ),
      );
    }
    if (_content == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _formatted(_content!),
      ),
    );
  }
}

/// Full-page Terms of Service viewer, reached from the hamburger menu /
/// Contact & Support. Just [TermsOfServiceContent] wrapped in a standard
/// Scaffold + AppBar.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PremiumTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: PremiumTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.arrow_back, color: PremiumTheme.primaryTextColor),
        ),
        title: Text(
          'Terms of Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
      ),
      body: const SafeArea(child: TermsOfServiceContent()),
    );
  }
}
