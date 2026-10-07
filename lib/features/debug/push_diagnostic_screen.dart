import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/push_notification_service.dart';
import '../../core/models/push_diagnostic_model.dart';
import '../../core/theme/premium_theme.dart';

class PushDiagnosticScreen extends StatelessWidget {
  const PushDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('iOS Push Diagnostics'),
        backgroundColor: PremiumTheme.surfaceColor,
      ),
      body: ValueListenableBuilder<PushRegistrationReport>(
        valueListenable: PushNotificationService().diagnosticReport,
        builder: (context, report, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDiagnosticCard(report),
                const SizedBox(height: 32),
                _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDiagnosticCard(PushRegistrationReport report) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildStatusRow('Permission', report.permission),
            const Divider(),
            _buildStatusRow('APNs Registration', report.apnsRegistration),
            const Divider(),
            _buildStatusRow('APNs Token', report.apnsToken),
            const Divider(),
            _buildStatusRow('FCM Token', report.fcmToken),
            const Divider(),
            _buildStatusRow('User ID', report.userId),
            const Divider(),
            _buildStatusRow('Supabase Sync', report.supabaseSync),
            const Divider(),
            _buildInfoRow('Last Error', report.lastError ?? 'NONE'),
            const Divider(),
            _buildInfoRow(
              'Last Attempt',
              report.lastAttempt != null
                  ? DateFormat('HH:mm:ss').format(report.lastAttempt!)
                  : 'NEVER',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, PushDiagnosticState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          _buildStateBadge(state),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: value == 'NONE' ? Colors.grey : Colors.red,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateBadge(PushDiagnosticState state) {
    Color color;
    String text;

    switch (state) {
      case PushDiagnosticState.unknown:
        color = Colors.grey;
        text = 'UNKNOWN';
        break;
      case PushDiagnosticState.pending:
        color = Colors.orange;
        text = 'PENDING';
        break;
      case PushDiagnosticState.available:
        color = Colors.blue;
        text = 'AVAILABLE';
        break;
      case PushDiagnosticState.missing:
        color = Colors.red;
        text = 'MISSING';
        break;
      case PushDiagnosticState.success:
        color = Colors.green;
        text = 'SUCCESS';
        break;
      case PushDiagnosticState.failed:
        color = Colors.red;
        text = 'FAILED';
        break;
      case PushDiagnosticState.notAttempted:
        color = Colors.grey;
        text = 'NOT ATTEMPTED';
        break;
      case PushDiagnosticState.timeout:
        color = Colors.purple;
        text = 'TIMEOUT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => PushNotificationService().retryRegistration(),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTheme.accentColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Retry Registration',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Note: Retrying will request permissions and attempt a fresh APNs -> FCM -> Supabase handshake.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
