import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/feedback_service.dart';
import '../../core/theme/premium_theme.dart';
import 'feedback_questions.dart';

/// Tap-to-answer feedback: fixed questions (no typing) plus 1-5 star ratings
/// for each theme. Every question is optional; one answer or rating is
/// enough to send.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FeedbackService _feedbackService = FeedbackService();

  /// Question id -> picked option ids, in the order they were picked.
  final Map<String, List<String>> _picks = {};

  /// Theme id -> stars (1-5). A missing key means "not rated".
  final Map<String, int> _ratings = {};

  bool _sending = false;
  bool _sent = false;

  bool get _hasAnything => _picks.isNotEmpty || _ratings.isNotEmpty;

  void _togglePick(FeedbackQuestion question, FeedbackOption option) {
    HapticFeedback.selectionClick();
    setState(() {
      final current = List<String>.of(_picks[question.id] ?? const []);

      if (current.contains(option.id)) {
        current.remove(option.id);
      } else if (!question.isMultiChoice || option.exclusive) {
        current
          ..clear()
          ..add(option.id);
      } else {
        // Picking a normal option clears an exclusive one.
        final exclusiveIds = question.options
            .where((o) => o.exclusive)
            .map((o) => o.id)
            .toSet();
        current.removeWhere(exclusiveIds.contains);
        // At the limit, the oldest pick makes way for the new one.
        if (current.length >= question.maxPicks) current.removeAt(0);
        current.add(option.id);
      }

      if (current.isEmpty) {
        _picks.remove(question.id);
      } else {
        _picks[question.id] = current;
      }
    });
  }

  void _rate(FeedbackTheme theme, int stars) {
    HapticFeedback.selectionClick();
    setState(() {
      // Tapping the current rating again clears it.
      if (_ratings[theme.id] == stars) {
        _ratings.remove(theme.id);
      } else {
        _ratings[theme.id] = stars;
      }
    });
  }

  Future<void> _send() async {
    if (_sending || !_hasAnything) return;
    setState(() => _sending = true);

    final answers = <String, Object>{
      for (final question in feedbackQuestions)
        if (_picks[question.id] != null)
          question.id: question.isMultiChoice
              ? _picks[question.id]!
              : _picks[question.id]!.first,
    };

    final result = await _feedbackService.submit(
      answers: answers,
      themeRatings: Map.of(_ratings),
    );
    if (!mounted) return;

    switch (result) {
      case FeedbackSubmitResult.sent:
        HapticFeedback.mediumImpact();
        setState(() {
          _sending = false;
          _sent = true;
        });
      case FeedbackSubmitResult.rateLimited:
        setState(() => _sending = false);
        _showSnack("You've already sent feedback today. Thank you!");
      case FeedbackSubmitResult.failed:
        setState(() => _sending = false);
        _showSnack("Couldn't send right now. Check your connection and try again.");
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          icon: Icon(Icons.arrow_back, color: PremiumTheme.primaryTextColor),
        ),
        title: Text(
          'Share Feedback',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: PremiumTheme.primaryTextColor,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: PremiumTheme.mediumDuration,
          child: _sent ? _buildThanks() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            children: [
              Text(
                'Just tap your answers, no typing needed. Skip anything you like.',
                style: TextStyle(
                  fontSize: 14,
                  color: PremiumTheme.secondaryTextColor,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              for (final question in feedbackQuestions) _buildQuestion(question),
              _buildThemeRatings(),
            ],
          ),
        ),
        _buildSendBar(),
      ],
    );
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

  Widget _cardTitle(String text, {String? hint}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PremiumTheme.primaryTextColor,
              height: 1.3,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(
              hint,
              style: TextStyle(fontSize: 12, color: PremiumTheme.tertiaryTextColor),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion(FeedbackQuestion question) {
    final picked = _picks[question.id] ?? const <String>[];

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            question.prompt,
            hint: question.isMultiChoice ? 'Pick up to ${question.maxPicks}' : null,
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in question.options)
                _OptionChip(
                  label: option.label,
                  selected: picked.contains(option.id),
                  onTap: () => _togglePick(question, option),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeRatings() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle(
            'Rate the themes',
            hint: 'Tap the stars for any theme you have tried',
          ),
          for (final theme in feedbackThemes)
            _ThemeRatingRow(
              theme: theme,
              stars: _ratings[theme.id] ?? 0,
              isCurrent: PremiumTheme.currentMode == theme.id,
              onRate: (stars) => _rate(theme, stars),
            ),
        ],
      ),
    );
  }

  Widget _buildSendBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: PremiumTheme.backgroundColor,
        border: Border(top: BorderSide(color: PremiumTheme.dividerColor)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: _hasAnything && !_sending ? _send : null,
          style: FilledButton.styleFrom(
            backgroundColor: PremiumTheme.accentColor,
            foregroundColor: PremiumTheme.backgroundColor,
            disabledBackgroundColor: PremiumTheme.dividerColor,
            disabledForegroundColor: PremiumTheme.tertiaryTextColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _sending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: PremiumTheme.backgroundColor,
                  ),
                )
              : Text(
                  _hasAnything ? 'Send Feedback' : 'Tap an answer to start',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
        ),
      ),
    );
  }

  Widget _buildThanks() {
    return Center(
      key: const ValueKey('thanks'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_rounded, size: 56, color: PremiumTheme.accentColor),
            const SizedBox(height: 16),
            Text(
              'Thank you!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: PremiumTheme.primaryTextColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us decide what to build next.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: PremiumTheme.secondaryTextColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = PremiumTheme.accentColor;

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: PremiumTheme.fastDuration,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.16) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? accent : PremiumTheme.dividerColor,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(Icons.check_rounded, size: 16, color: accent),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: PremiumTheme.primaryTextColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeRatingRow extends StatelessWidget {
  const _ThemeRatingRow({
    required this.theme,
    required this.stars,
    required this.isCurrent,
    required this.onRate,
  });

  final FeedbackTheme theme;
  final int stars;
  final bool isCurrent;
  final ValueChanged<int> onRate;

  static const Color _starColor = Color(0xFFFFC233);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Theme swatch: background with an accent dot.
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: theme.background,
              shape: BoxShape.circle,
              border: Border.all(color: PremiumTheme.dividerColor),
            ),
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: theme.accent, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  theme.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: PremiumTheme.primaryTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrent)
                  Text(
                    'Your theme',
                    style: TextStyle(fontSize: 11, color: PremiumTheme.tertiaryTextColor),
                  ),
              ],
            ),
          ),
          for (var i = 1; i <= 5; i++)
            Semantics(
              button: true,
              label: '$i star${i == 1 ? '' : 's'} for ${theme.name}',
              selected: stars == i,
              child: InkResponse(
                onTap: () => onRate(i),
                radius: 20,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 24,
                    color: i <= stars ? _starColor : PremiumTheme.tertiaryTextColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
