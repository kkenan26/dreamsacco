import 'package:flutter/material.dart';

class SavingsGoal {
  String title;
  double targetAmount;
  double currentAmount;
  double monthlyTarget;
  DateTime createdAt;

  SavingsGoal({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.monthlyTarget,
    required this.createdAt,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0, 1);

  double get remainingAmount =>
      (targetAmount - currentAmount).clamp(0, double.infinity);

  DateTime? get estimatedCompletionDate {
    if (monthlyTarget <= 0 || remainingAmount <= 0) return null;
    final monthsNeeded = (remainingAmount / monthlyTarget).ceil();
    return DateTime(
      createdAt.year,
      createdAt.month + monthsNeeded,
      createdAt.day,
    );
  }
}

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  final List<SavingsGoal> goals = [
    SavingsGoal(
      title: "Emergency Fund",
      targetAmount: 2000000,
      currentAmount: 1360000,
      monthlyTarget: 150000,
      createdAt: DateTime(2026, 1, 1),
    ),
    SavingsGoal(
      title: "New Motorbike",
      targetAmount: 4500000,
      currentAmount: 900000,
      monthlyTarget: 200000,
      createdAt: DateTime(2026, 3, 1),
    ),
  ];

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

  String _formatDate(DateTime date) {
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return "${months[date.month - 1]} ${date.year}";
  }

  void _openGoalDialog({SavingsGoal? existingGoal, int? index}) {
    final titleController = TextEditingController(
      text: existingGoal?.title ?? "",
    );
    final targetController = TextEditingController(
      text: existingGoal != null
          ? existingGoal.targetAmount.toStringAsFixed(0)
          : "",
    );
    final currentController = TextEditingController(
      text: existingGoal != null
          ? existingGoal.currentAmount.toStringAsFixed(0)
          : "",
    );
    final monthlyController = TextEditingController(
      text: existingGoal != null
          ? existingGoal.monthlyTarget.toStringAsFixed(0)
          : "",
    );

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(existingGoal == null ? "Set New Goal" : "Edit Goal"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Goal Title"),
                ),
                TextField(
                  controller: targetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Target Amount (UGX)",
                  ),
                ),
                TextField(
                  controller: currentController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Current Savings (UGX)",
                  ),
                ),
                TextField(
                  controller: monthlyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Monthly Target (UGX)",
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final title = titleController.text.trim();
                final target =
                    double.tryParse(targetController.text.trim()) ?? 0;
                final current =
                    double.tryParse(currentController.text.trim()) ?? 0;
                final monthly =
                    double.tryParse(monthlyController.text.trim()) ?? 0;

                if (title.isEmpty || target <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        "Please provide a valid title and target amount",
                      ),
                    ),
                  );
                  return;
                }

                setState(() {
                  if (existingGoal != null && index != null) {
                    goals[index] = SavingsGoal(
                      title: title,
                      targetAmount: target,
                      currentAmount: current,
                      monthlyTarget: monthly,
                      createdAt: existingGoal.createdAt,
                    );
                  } else {
                    goals.add(
                      SavingsGoal(
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        monthlyTarget: monthly,
                        createdAt: DateTime.now(),
                      ),
                    );
                  }
                });
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _deleteGoal(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Delete Goal"),
          content: const Text(
            "Are you sure you want to delete this savings goal?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                setState(() => goals.removeAt(index));
                Navigator.pop(context);
              },
              child: const Text("Delete"),
            ),
          ],
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
          "Savings Goals",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        onPressed: () => _openGoalDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: goals.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) =>
                  _buildGoalCard(goals[index], index),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            "No savings goals yet",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            "Tap + to set your first goal",
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(SavingsGoal goal, int index) {
    final progressPercent = (goal.progress * 100).toStringAsFixed(0);
    final completionDate = goal.estimatedCompletionDate;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.grey),
                onSelected: (value) {
                  if (value == "edit") {
                    _openGoalDialog(existingGoal: goal, index: index);
                  } else if (value == "delete") {
                    _deleteGoal(index);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: "edit", child: Text("Edit")),
                  const PopupMenuItem(value: "delete", child: Text("Delete")),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goal.progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation(secondaryColor),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$progressPercent% Complete",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                  fontSize: 13,
                ),
              ),
              Text(
                "${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _infoTile(
                  icon: Icons.savings_outlined,
                  label: "Remaining",
                  value: _formatCurrency(goal.remainingAmount),
                ),
              ),
              Expanded(
                child: _infoTile(
                  icon: Icons.calendar_today_outlined,
                  label: "Monthly Target",
                  value: _formatCurrency(goal.monthlyTarget),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoTile(
            icon: Icons.flag_circle_outlined,
            label: "Estimated Completion",
            value: completionDate != null
                ? _formatDate(completionDate)
                : "Set a monthly target",
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: secondaryColor),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
