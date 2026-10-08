import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../theme/premium_theme.dart';

enum FeedbackSubmitResult { sent, rateLimited, failed }

/// Sends in-app feedback through the submit_app_feedback RPC
/// (supabase/migrations/20261008_create_app_feedback.sql). The table itself
/// is closed to clients; the RPC stamps the caller's own auth.uid().
class FeedbackService {
  Future<FeedbackSubmitResult> submit({
    required Map<String, Object> answers,
    required Map<String, int> themeRatings,
    Map<String, String> comments = const {},
  }) async {
    try {
      await Supabase.instance.client.rpc('submit_app_feedback', params: {
        'p_answers': answers,
        'p_theme_ratings': themeRatings,
        'p_current_theme': PremiumTheme.currentMode,
        'p_platform': _platform(),
        'p_comments': comments,
      });
      if (kDebugMode) {
        debugPrint('💬 Feedback sent: ${answers.length} answers, '
            '${themeRatings.length} theme ratings, ${comments.length} comments');
      }
      return FeedbackSubmitResult.sent;
    } on PostgrestException catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send feedback: ${e.message}');
      }
      return e.message.contains('rate_limited')
          ? FeedbackSubmitResult.rateLimited
          : FeedbackSubmitResult.failed;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Failed to send feedback: $e');
      }
      return FeedbackSubmitResult.failed;
    }
  }

  String? _platform() {
    if (kIsWeb) return null;
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return null;
  }
}
