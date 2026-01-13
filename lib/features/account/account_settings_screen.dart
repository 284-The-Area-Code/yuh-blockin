import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/premium_theme.dart';
import '../../core/services/simple_alert_service.dart';
import '../onboarding/onboarding_flow.dart';

/// Account Settings Screen
/// Allows users to view account info and delete their account
/// Required by App Store Review Guidelines 5.1.1(v)
class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  String? _userId;
  DateTime? _createdAt;
  bool _isLoading = true;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadAccountInfo();
  }

  Future<void> _loadAccountInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        // Get user creation date from database
        final supabase = Supabase.instance.client;
        final result = await supabase
            .from('users')
            .select('created_at')
            .eq('id', userId)
            .maybeSingle();

        setState(() {
          _userId = userId;
          if (result != null && result['created_at'] != null) {
            _createdAt = DateTime.tryParse(result['created_at']);
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _maskUserId(String userId) {
    if (userId.length <= 10) return userId;
    return '${userId.substring(0, 10)}...${userId.substring(userId.length - 4)}';
  }

  Future<void> _showDeleteConfirmation() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DeleteAccountDialog(),
    );

    if (result == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    if (_userId == null) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete user account from database
      final success = await SimpleAlertService().deleteUserAccount(_userId!);

      if (success) {
        // Clear local data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // Sign out from Supabase
        try {
          await Supabase.instance.client.auth.signOut();
        } catch (_) {
          // Ignore sign out errors
        }

        if (mounted) {
          // Navigate to onboarding and clear navigation stack
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const OnboardingFlow(),
            ),
            (route) => false,
          );
        }
      } else {
        if (mounted) {
          _showErrorSnackbar('Failed to delete account. Please try again.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('An error occurred. Please try again later.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
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
          icon: Icon(
            Icons.arrow_back,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
        title: Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxHeight < 700;

        return SingleChildScrollView(
          padding: EdgeInsets.all(isCompact ? 16.0 : 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Info Section
              _buildSectionHeader('Account Information', isCompact),
              const SizedBox(height: 16),
              _buildInfoCard(isCompact),

              SizedBox(height: isCompact ? 32 : 48),

              // Danger Zone Section
              _buildSectionHeader('Danger Zone', isCompact, isDestructive: true),
              const SizedBox(height: 16),
              _buildDeleteSection(isCompact),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isCompact, {bool isDestructive = false}) {
    return Text(
      title,
      style: TextStyle(
        fontSize: isCompact ? 14 : 16,
        fontWeight: FontWeight.w600,
        color: isDestructive ? Colors.red.shade400 : PremiumTheme.secondaryTextColor,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildInfoCard(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: PremiumTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PremiumTheme.dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            'Account ID',
            _userId != null ? _maskUserId(_userId!) : 'Unknown',
            Icons.person_outline,
            isCompact,
          ),
          const Divider(height: 24),
          _buildInfoRow(
            'Created',
            _createdAt != null ? _formatDate(_createdAt!) : 'Unknown',
            Icons.calendar_today_outlined,
            isCompact,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool isCompact) {
    return Row(
      children: [
        Icon(
          icon,
          size: isCompact ? 18 : 20,
          color: PremiumTheme.accentColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isCompact ? 12 : 13,
                  color: PremiumTheme.secondaryTextColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isCompact ? 14 : 16,
                  fontWeight: FontWeight.w500,
                  color: PremiumTheme.primaryTextColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteSection(bool isCompact) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.red.shade50.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.shade200.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete Account',
            style: TextStyle(
              fontSize: isCompact ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Permanently delete your account and all associated data. This action cannot be undone.',
            style: TextStyle(
              fontSize: isCompact ? 13 : 14,
              color: PremiumTheme.secondaryTextColor,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isDeleting ? null : _showDeleteConfirmation,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isDeleting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Delete My Account',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Delete Account Confirmation Dialog
class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: PremiumTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.red.shade400,
            size: 28,
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              'Delete Account?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: PremiumTheme.primaryTextColor,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This will permanently delete:',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: PremiumTheme.primaryTextColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDeleteItem('All your registered vehicles'),
          _buildDeleteItem('All sent and received alerts'),
          _buildDeleteItem('Your subscription and payment history'),
          _buildDeleteItem('All account data'),
          const SizedBox(height: 16),
          Text(
            'This action cannot be undone.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red.shade400,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _confirmed,
                  onChanged: (value) {
                    setState(() {
                      _confirmed = value ?? false;
                    });
                    HapticFeedback.selectionClick();
                  },
                  activeColor: Colors.red.shade400,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'I understand this is permanent',
                  style: TextStyle(
                    fontSize: 14,
                    color: PremiumTheme.primaryTextColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: PremiumTheme.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _confirmed ? () => Navigator.of(context).pop(true) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 0,
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.remove_circle_outline,
            size: 16,
            color: Colors.red.shade300,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: PremiumTheme.secondaryTextColor,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
