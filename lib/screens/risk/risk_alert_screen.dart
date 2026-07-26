import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum RiskLevel { low, medium, high }

class MonthlyContribution {
  final String month;
  final double amount;
  final bool paid;

  MonthlyContribution({
    required this.month,
    required this.amount,
    required this.paid,
  });
}

class RiskAlertScreen extends StatefulWidget {
  const RiskAlertScreen({super.key});

  @override
  State<RiskAlertScreen> createState() => _RiskAlertScreenState();
}

class _RiskAlertScreenState extends State<RiskAlertScreen> {
  static const Color primaryColor = Color(0xFF0D47A1);

  List<MonthlyContribution> history = [];
  bool _isLoading = true;

  RiskLevel riskLevel = RiskLevel.low;
  List<String> triggeredFactors = [];
  List<String> recommendations = [];

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      QuerySnapshot memberGroups = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (memberGroups.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String groupId = memberGroups.docs.first.reference.parent.parent!.id;

      QuerySnapshot contributions = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('contributions')
          .where('userId', isEqualTo: uid)
          .orderBy('paidAt', descending: false)
          .limit(6)
          .get();

      List<MonthlyContribution> loaded = contributions.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return MonthlyContribution(
          month: data['month'] ?? '',
          amount: (data['amount'] ?? 0).toDouble(),
          paid: data['status'] == 'paid',
        );
      }).toList();

      if (mounted) {
        setState(() {
          history = loaded;
          _isLoading = false;
        });
      }

      _assessRisk();
    } catch (e) {
      debugPrint('Risk alert load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }



  int get missedContributions => history.where((h) => !h.paid).length;

  int get consecutiveMissedMonths {
    int maxStreak = 0;
    int current = 0;
    for (final record in history) {
      if (!record.paid) {
        current += 1;
        if (current > maxStreak) maxStreak = current;
      } else {
        current = 0;
      }
    }
    return maxStreak;
  }

  bool get hasDecliningPattern {
    final paidAmounts = history
        .where((h) => h.paid)
        .map((h) => h.amount)
        .toList();
    if (paidAmounts.length < 3) return false;
    int decliningSteps = 0;
    for (int i = 1; i < paidAmounts.length; i++) {
      if (paidAmounts[i] < paidAmounts[i - 1]) decliningSteps++;
    }
    return decliningSteps >= (paidAmounts.length - 1) * 0.6;
  }

  bool get hasLowSavingsTrend {
    final recentPaid = history.length >= 3
        ? history
              .sublist(history.length - 3)
              .where((h) => h.paid)
              .map((h) => h.amount)
        : <double>[];
    if (recentPaid.isEmpty) return true;
    final avg = recentPaid.reduce((a, b) => a + b) / recentPaid.length;
    return avg < 50000;
  }

  void _assessRisk() {
    final factors = <String>[];

    if (missedContributions >= 1) {
      factors.add(
        "$missedContributions missed contribution${missedContributions > 1 ? 's' : ''} in the last ${history.length} months",
      );
    }
    if (consecutiveMissedMonths >= 2) {
      factors.add("$consecutiveMissedMonths consecutive months missed");
    }
    if (hasDecliningPattern) {
      factors.add("Declining contribution pattern detected");
    }
    if (hasLowSavingsTrend) {
      factors.add("Low savings trend in recent months");
    }

    RiskLevel level;
    if (consecutiveMissedMonths >= 2 || missedContributions >= 3) {
      level = RiskLevel.high;
    } else if (missedContributions >= 1 ||
        hasDecliningPattern ||
        hasLowSavingsTrend) {
      level = RiskLevel.medium;
    } else {
      level = RiskLevel.low;
    }

    final recs = <String>[];
    switch (level) {
      case RiskLevel.high:
        recs.addAll([
          "Contact your SACCO support officer to discuss a revised contribution plan",
          "Set up automatic reminders before your contribution due date",
          "Consider lowering your monthly target temporarily to stay consistent",
        ]);
        break;
      case RiskLevel.medium:
        recs.addAll([
          "Try to catch up on missed contributions this month",
          "Review your budget to keep contributions consistent",
          "Set a savings reminder a few days before the due date",
        ]);
        break;
      case RiskLevel.low:
        recs.addAll([
          "Great job staying consistent — keep up the momentum",
          "Consider increasing your monthly contribution to reach goals faster",
        ]);
        break;
    }

    setState(() {
      riskLevel = level;
      triggeredFactors = factors;
      recommendations = recs;
    });
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.red;
    }
  }

  String _riskLabel(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return "Low Risk";
      case RiskLevel.medium:
        return "Medium Risk";
      case RiskLevel.high:
        return "High Risk";
    }
  }

  IconData _riskIcon(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return Icons.verified_outlined;
      case RiskLevel.medium:
        return Icons.warning_amber_outlined;
      case RiskLevel.high:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _riskColor(riskLevel);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Risk Alerts",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRiskBadge(color),
            const SizedBox(height: 24),
            if (triggeredFactors.isNotEmpty) ...[
              const Text(
                "Detected Factors",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...triggeredFactors.map((f) => _factorTile(f)),
              const SizedBox(height: 24),
            ],
            const Text(
              "Contribution Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            history.isEmpty
                ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                "No contributions yet.",
                style: TextStyle(color: Colors.grey.shade600),
              ),
            )
                : _buildTrendChart(),
            const SizedBox(height: 24),
            const Text(
              "Recommendations",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            recommendations.isEmpty
                ? Text("No recommendations yet.", style: TextStyle(color: Colors.grey.shade600))
                : Column(children: recommendations.map((r) => _recommendationTile(r)).toList()),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(Color color) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.9), color],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(_riskIcon(riskLevel), color: Colors.white, size: 42),
                const SizedBox(height: 10),
                Text(
                  _riskLabel(riskLevel),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Based on your recent contribution activity",
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _factorTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.orange, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildTrendChart() {
    final maxVal = history
        .map((h) => h.amount)
        .fold<double>(0, (p, c) => c > p ? c : p);
    final safeMax = maxVal == 0 ? 1 : maxVal;

    return Container(
      height: 150,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: history.map((record) {
          final heightFactor = record.amount / safeMax;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: heightFactor <= 0 ? 0.04 : heightFactor,
                    ),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return Container(
                        height: 90 * value,
                        decoration: BoxDecoration(
                          color: record.paid
                              ? const Color(0xFF1976D2)
                              : Colors.red.shade300,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    record.month.split(' ').first,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _recommendationTile(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: primaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
