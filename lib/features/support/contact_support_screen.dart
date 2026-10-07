import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/services/simple_alert_service.dart';
import '../../core/services/user_alias_service.dart';
import '../../core/theme/premium_theme.dart';
import '../legal/terms_of_service_screen.dart';

const String _supportEmail = 'dev@dezetingz.ai';

/// In-app contact/support entry point (Apple Guideline 1.2 remediation) plus
/// a "Blocked Users" management list - without this, blocking someone would
/// have no way to be undone.
class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final SimpleAlertService _alertService = SimpleAlertService();
  final UserAliasService _aliasService = UserAliasService();

  String? _userId;
  List<String> _blockedUserIds = [];
  bool _loadingBlocked = true;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    await _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    if (_userId == null) {
      setState(() => _loadingBlocked = false);
      return;
    }
    final ids = await _alertService.getBlockedUserIds(_userId!);
    if (mounted) {
      setState(() {
        _blockedUserIds = ids;
        _loadingBlocked = false;
      });
    }
  }

  Future<void> _unblock(String blockedId) async {
    if (_userId == null) return;
    final success = await _alertService.unblockUser(
      blockerId: _userId!,
      blockedUserId: blockedId,
    );
    if (success && mounted) {
      setState(() => _blockedUserIds.remove(blockedId));
    }
  }

  Future<void> _emailSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: _supportEmail,
      queryParameters: {'subject': "Yuh Blockin' Support"},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email us directly at $_supportEmail')),
      );
    }
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: PremiumTheme.dividerColor),
      ),
      child: child,
    );
  }

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
          'Contact & Support',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.mail_outline_rounded, color: PremiumTheme.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Contact Us',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Questions, feedback, or anything else - reach us at $_supportEmail.',
                    style: TextStyle(fontSize: 13, color: PremiumTheme.secondaryTextColor, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _emailSupport,
                      icon: const Icon(Icons.email_outlined, size: 18),
                      label: const Text('Email Support'),
                    ),
                  ),
                ],
              ),
            ),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.shield_outlined, color: PremiumTheme.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Reporting a Safety Concern',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuh Blockin\' has zero tolerance for objectionable content or abusive users. '
                    'You can report any alert directly from your Activity feed, or block a sender to '
                    'stop them from reaching you entirely. We review every report within 24 hours '
                    'and remove content and accounts that violate our policy.',
                    style: TextStyle(fontSize: 13, color: PremiumTheme.secondaryTextColor, height: 1.4),
                  ),
                ],
              ),
            ),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.gavel_rounded, color: PremiumTheme.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Terms of Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                        );
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('View Terms of Service'),
                    ),
                  ),
                ],
              ),
            ),
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.block_rounded, color: PremiumTheme.accentColor),
                      const SizedBox(width: 10),
                      Text(
                        'Blocked Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: PremiumTheme.primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_loadingBlocked)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_blockedUserIds.isEmpty)
                    Text(
                      'You haven\'t blocked anyone.',
                      style: TextStyle(fontSize: 13, color: PremiumTheme.secondaryTextColor),
                    )
                  else
                    ..._blockedUserIds.map((id) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: FutureBuilder<String>(
                                  future: _aliasService.getAliasForUser(id),
                                  builder: (context, snapshot) {
                                    final alias = snapshot.hasData
                                        ? _aliasService.formatAliasForDisplay(snapshot.data!)
                                        : 'Loading…';
                                    return Text(
                                      alias,
                                      style: TextStyle(fontSize: 14, color: PremiumTheme.primaryTextColor),
                                    );
                                  },
                                ),
                              ),
                              TextButton(
                                onPressed: () => _unblock(id),
                                child: const Text('Unblock'),
                              ),
                            ],
                          ),
                        )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
