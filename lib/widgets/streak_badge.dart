import 'package:flutter/material.dart';

/// A small "🔥 N" badge showing a member's consecutive payment streak.
/// Color intensifies at the same thresholds used for loan-limit upgrades,
/// so members visually understand why their loan limit just increased.
class StreakBadge extends StatelessWidget {
  final int streak;

  const StreakBadge({super.key, required this.streak});

  Color _colorForStreak() {
    if (streak >= 12) return Colors.purple;
    if (streak >= 6) return Colors.blue;
    if (streak >= 3) return Colors.green;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _colorForStreak().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _colorForStreak()),
      ),
      child: Text(
        '🔥 $streak',
        style: TextStyle(
          color: _colorForStreak(),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
