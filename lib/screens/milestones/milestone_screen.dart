import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/group_picker.dart';

class Milestone {
  final int percent;
  final String title;
  final String description;
  final IconData icon;

  Milestone({required this.percent, required this.title, required this.description, required this.icon});
}

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen({super.key});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  String? _selectedGroupId;
  double targetGoal = 0;
  double currentSavings = 0;
  bool _isLoading = false;

  late AnimationController _progressController;

  final List<Milestone> milestones = [
    Milestone(percent: 25, title: "Getting Started", description: "You've saved a quarter of your goal", icon: Icons.emoji_events_outlined),
    Milestone(percent: 50, title: "Halfway There", description: "You've reached the halfway mark", icon: Icons.military_tech_outlined),
    Milestone(percent: 75, title: "Almost There", description: "Three quarters of your goal achieved", icon: Icons.workspace_premium_outlined),
    Milestone(percent: 100, title: "Goal Achieved", description: "You've reached your full savings goal!", icon: Icons.emoji_events),
  ];

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _onGroupSelected(String? groupId) async {
    if (groupId == null || groupId == _selectedGroupId) return;
    setState(() {
      _selectedGroupId = groupId;
      _isLoading = true;
    });

    DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
    if (groupDoc.exists && mounted) {
      Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
      setState(() {
        targetGoal = (data['goalAmount'] ?? 0).toDouble();
        currentSavings = (data['totalBalance'] ?? 0).toDouble();
        _isLoading = false;
      });
      _progressController.forward(from: 0);
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  double get progressPercent => targetGoal == 0 ? 0 : (currentSavings / targetGoal * 100).clamp(0, 100);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Milestones", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupPicker(selectedGroupId: _selectedGroupId, onChanged: _onGroupSelected),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedGroupId != null) ...[
            _buildProgressCard(),
            const SizedBox(height: 24),
            const Text("Achievements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...milestones.map((m) => _buildMilestoneCard(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryColor, secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Goal Progress", style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text("${progressPercent.toStringAsFixed(0)}%", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _progressController,
            builder: (context, child) {
              final animatedValue = (progressPercent / 100) * _progressController.value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: animatedValue, minHeight: 14, backgroundColor: Colors.white24, valueColor: const AlwaysStoppedAnimation(Colors.white)),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatCurrency(currentSavings), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Text(_formatCurrency(targetGoal), style: const TextStyle(color: Colors.white70, fontSize: 13)),
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: achieved ? const LinearGradient(colors: [Colors.amber, Colors.orange]) : LinearGradient(colors: [Colors.grey.shade300, Colors.grey.shade300]),
            ),
            child: Icon(achieved ? milestone.icon : Icons.lock_outline, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text("${milestone.percent}%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: achieved ? primaryColor : Colors.grey.shade500)),
                    const SizedBox(width: 8),
                    Text(milestone.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: achieved ? Colors.black87 : Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(milestone.description, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
          Icon(achieved ? Icons.check_circle : Icons.radio_button_unchecked, color: achieved ? Colors.green : Colors.grey.shade300, size: 20),
        ],
      ),
    );
  }
}