import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class Milestone {
  final int percent;
  final String title;
  final String description;
  final IconData icon;

  Milestone({
    required this.percent,
    required this.title,
    required this.description,
    required this.icon,
  });
}

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen({super.key});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  double targetGoal = 0;
  double currentSavings = 0;
  bool _isLoading = true;

  late AnimationController _progressController;

  final List<Milestone> milestones = [
    Milestone(
      percent: 25,
      title: "Getting Started",
      description: "You've saved a quarter of your goal",
      icon: Icons.emoji_events_outlined,
    ),
    Milestone(
      percent: 50,
      title: "Halfway There",
      description: "You've reached the halfway mark",
      icon: Icons.military_tech_outlined,
    ),
    Milestone(
      percent: 75,
      title: "Almost There",
      description: "Three quarters of your goal achieved",
      icon: Icons.workspace_premium_outlined,
    ),
    Milestone(
      percent: 100,
      title: "Goal Achieved",
      description: "You've reached your full savings goal!",
      icon: Icons.emoji_events,
    ),
  ];

  Set<int> celebratedMilestones = {25};

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loadMilestoneData();
  }

  Future<void> _loadMilestoneData() async {
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
      DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();

      if (groupDoc.exists) {
        Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            targetGoal = (data['goalAmount'] ?? 0).toDouble();
            currentSavings = (data['totalBalance'] ?? 0).toDouble();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }

      _progressController.forward();
    } catch (e) {
      debugPrint('Milestone load error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  double get progressPercent =>
      (currentSavings / targetGoal * 100).clamp(0, 100);

  String _formatCurrency(double value) {
    final str = value.toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromRight = str.length - i;
      buffer.write(str[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(',');
    }
    return "UGX ${buffer.toString()}";
  }

  void _simulateContribution() {
    final increment = targetGoal * 0.1;
    final newSavings = (currentSavings + increment).clamp(0, targetGoal);
    final oldPercent = progressPercent;

    setState(() => currentSavings = newSavings.toDouble());

    final newPercent = progressPercent;

    for (final milestone in milestones) {
      if (oldPercent < milestone.percent &&
          newPercent >= milestone.percent &&
          !celebratedMilestones.contains(milestone.percent)) {
        celebratedMilestones.add(milestone.percent);
        _showCelebrationDialog(milestone);
        break;
      }
    }

    _progressController.forward(from: 0);
  }

  void _showCelebrationDialog(Milestone milestone) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.amber, Colors.orange],
                          ),
                        ),
                        child: Icon(
                          milestone.icon,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "${milestone.percent}% Milestone!",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        milestone.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        milestone.description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            "Awesome!",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "Milestones",
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
            _buildProgressCard(),
            const SizedBox(height: 24),
            const Text(
              "Achievements",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...milestones.map((m) => _buildMilestoneCard(m)),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Goal Progress",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            "${progressPercent.toStringAsFixed(0)}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final animatedValue =
                  (progressPercent / 100) * _progressController.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: animatedValue,
                  minHeight: 14,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatCurrency(currentSavings),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                _formatCurrency(targetGoal),
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(Milestone milestone) {
    final achieved = progressPercent >= milestone.percent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: achieved ? Border.all(color: Colors.amber, width: 1.5) : null,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: achieved
                  ? const LinearGradient(colors: [Colors.amber, Colors.orange])
                  : LinearGradient(
                      colors: [Colors.grey.shade300, Colors.grey.shade300],
                    ),
            ),
            child: Icon(
              achieved ? milestone.icon : Icons.lock_outline,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "${milestone.percent}%",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: achieved ? primaryColor : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      milestone.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: achieved ? Colors.black87 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  milestone.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (achieved)
            const Icon(Icons.check_circle, color: Colors.green, size: 20)
          else
            Icon(
              Icons.radio_button_unchecked,
              color: Colors.grey.shade300,
              size: 20,
            ),
        ],
      ),
    );
  }
}
