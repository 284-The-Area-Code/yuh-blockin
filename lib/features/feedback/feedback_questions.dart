import 'package:flutter/material.dart';

import '../../core/theme/premium_theme.dart';

/// The fixed, tap-to-answer questions shown on the feedback screen.
///
/// Question and option ids are what gets stored server-side
/// (supabase/migrations/20261008_create_app_feedback.sql), so keep them
/// stable: change the label freely, but give a reworded question or option a
/// new id if its meaning changes, or old and new answers get counted together.
/// Ids must match ^[a-z0-9_]{1,40}$ - the server rejects anything else.
class FeedbackQuestion {
  const FeedbackQuestion({
    required this.id,
    required this.prompt,
    required this.options,
    this.maxPicks = 1,
  });

  final String id;
  final String prompt;
  final List<FeedbackOption> options;

  /// 1 = single choice. More than 1 = pick up to this many.
  final int maxPicks;

  bool get isMultiChoice => maxPicks > 1;
}

class FeedbackOption {
  const FeedbackOption(this.id, this.label, {this.exclusive = false});

  final String id;
  final String label;

  /// Picking this clears every other pick for the question, and picking any
  /// other option clears this one (e.g. "Nothing, it's great").
  final bool exclusive;
}

const List<FeedbackQuestion> feedbackQuestions = [
  FeedbackQuestion(
    id: 'overall',
    prompt: 'How do you like Yuh Blockin so far?',
    options: [
      FeedbackOption('love_it', 'Love it'),
      FeedbackOption('like_it', "It's good"),
      FeedbackOption('okay', "It's OK"),
      FeedbackOption('not_for_me', 'Not for me'),
    ],
  ),
  FeedbackQuestion(
    id: 'liked_most',
    prompt: 'What do you like most?',
    maxPicks: 3,
    options: [
      FeedbackOption('quick_alerts', 'Quick alerts'),
      FeedbackOption('no_numbers', 'No phone numbers shared'),
      FeedbackOption('easy_to_use', 'Easy to use'),
      FeedbackOption('themes', 'The themes'),
      FeedbackOption('sounds', 'Alert sounds'),
      FeedbackOption('local', 'Made for the islands'),
    ],
  ),
  FeedbackQuestion(
    id: 'response_speed',
    prompt: 'When you sent an alert, how fast did the driver move?',
    options: [
      FeedbackOption('very_fast', 'Very fast'),
      FeedbackOption('fast_enough', 'Fast enough'),
      FeedbackOption('slow', 'Slow'),
      FeedbackOption('no_response', 'No response'),
      FeedbackOption('not_sent_yet', "Haven't sent one yet"),
    ],
  ),
  FeedbackQuestion(
    id: 'improve_next',
    prompt: 'What should we work on next?',
    maxPicks: 3,
    options: [
      FeedbackOption('faster_responses', 'Faster responses'),
      FeedbackOption('notifications', 'More reliable notifications'),
      FeedbackOption('more_themes', 'More themes'),
      FeedbackOption('more_sounds', 'More sounds'),
      FeedbackOption('easier_setup', 'Easier setup'),
      FeedbackOption('nothing', "Nothing, it's great", exclusive: true),
    ],
  ),
  FeedbackQuestion(
    id: 'recommend',
    prompt: 'Would you recommend Yuh Blockin to a friend?',
    options: [
      FeedbackOption('definitely', 'Definitely'),
      FeedbackOption('maybe', 'Maybe'),
      FeedbackOption('probably_not', 'Probably not'),
    ],
  ),
];

/// A theme people can rate. [id] is the PremiumTheme mode string, so ratings
/// line up with the theme each user actually has selected.
class FeedbackTheme {
  const FeedbackTheme({
    required this.id,
    required this.name,
    required this.background,
    required this.accent,
  });

  final String id;
  final String name;
  final Color background;
  final Color accent;
}

/// Same names and preview colors as the Theme settings screen.
const List<FeedbackTheme> feedbackThemes = [
  FeedbackTheme(
    id: PremiumTheme.lightMode,
    name: 'Light Mode',
    background: Color(0xFFFCFCFC),
    accent: Color(0xFF0A84FF),
  ),
  FeedbackTheme(
    id: PremiumTheme.darkMode,
    name: 'Dark Mode',
    background: Color(0xFF000000),
    accent: Color(0xFF0A84FF),
  ),
  FeedbackTheme(
    id: PremiumTheme.sunsetMode,
    name: 'Caribbean Sunset',
    background: Color(0xFF2D1B14),
    accent: Color(0xFFFF8C42),
  ),
  FeedbackTheme(
    id: PremiumTheme.pinkMode,
    name: 'Premium Pink',
    background: Color(0xFF1A1218),
    accent: Color(0xFFFF6B9D),
  ),
  FeedbackTheme(
    id: PremiumTheme.cyberpunkMode,
    name: 'Cyberpunk',
    background: Color(0xFF0A0A12),
    accent: Color(0xFF00F5FF),
  ),
  FeedbackTheme(
    id: PremiumTheme.islandGoldMode,
    name: 'Island Gold',
    background: Color(0xFF0A1628),
    accent: Color(0xFFF7C700),
  ),
  FeedbackTheme(
    id: PremiumTheme.bviPrideMode,
    name: 'BVI Pride',
    background: PremiumTheme.bviPrideResolutionBlue,
    accent: PremiumTheme.bviPrideAccentColor,
  ),
];
