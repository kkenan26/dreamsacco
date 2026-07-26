// lib/screens/whatif/what_if_calculator_screen.dart
import 'package:flutter/material.dart';

class WhatIfCalculatorScreen extends StatefulWidget {
  const WhatIfCalculatorScreen({super.key});

  @override
  State<WhatIfCalculatorScreen> createState() => _WhatIfCalculatorScreenState();
}

class _WhatIfCalculatorScreenState extends State<WhatIfCalculatorScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  final _formKey = GlobalKey<FormState>();

  final TextEditingController currentSavingsController = TextEditingController(
    text: "850000",
  );
  final TextEditingController monthlyContributionController =
      TextEditingController(text: "95000");
  final TextEditingController monthsController = TextEditingController(
    text: "12",
  );
  final TextEditingController goalTargetController = TextEditingController(
    text: "2000000",
  );

  bool hasResult = false;
  double projectedSavings = 0;
  double totalGrowth = 0;
  double goalProgress = 0;

  late AnimationController _resultAnimController;

  @override
  void initState() {
    super.initState();
    _resultAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    currentSavingsController.dispose();
    monthlyContributionController.dispose();
    monthsController.dispose();
    goalTargetController.dispose();
    _resultAnimController.dispose();
    super.dispose();
  }

  String _formatCurrency(double value) {
    final isNegative = value < 0;
    final str = value.abs().toStringAsFixed(0);
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      final posFromRight = str.length - i;
      buffer.write(str[i]);
      if (posFromRight > 1 && posFromRight % 3 == 1) buffer.write(',');
    }
    return "${isNegative ? '-' : ''}UGX ${buffer.toString()}";
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    final currentSavings = double.parse(currentSavingsController.text.trim());
    final monthlyContribution = double.parse(
      monthlyContributionController.text.trim(),
    );
    final months = int.parse(monthsController.text.trim());
    final goalTarget = double.tryParse(goalTargetController.text.trim()) ?? 0;

    final projected = currentSavings + (monthlyContribution * months);
    final growth = projected - currentSavings;
    final progress = goalTarget > 0
        ? (projected / goalTarget).clamp(0, 1).toDouble()
        : 0.0;

    setState(() {
      projectedSavings = projected;
      totalGrowth = growth;
      goalProgress = progress;
      hasResult = true;
    });

    _resultAnimController.forward(from: 0);
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
          "What-if Calculator",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntroCard(),
            const SizedBox(height: 20),
            _buildFormCard(),
            const SizedBox(height: 20),
            if (hasResult) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.white24,
            child: Icon(Icons.calculate, color: Colors.white),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              "See how your savings could grow by adjusting your monthly contribution",
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
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
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildInputField(
              controller: currentSavingsController,
              label: "Current Savings (UGX)",
              icon: Icons.account_balance_wallet_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: monthlyContributionController,
              label: "Monthly Contribution (UGX)",
              icon: Icons.payments_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: monthsController,
              label: "Number of Months",
              icon: Icons.calendar_month_outlined,
            ),
            const SizedBox(height: 14),
            _buildInputField(
              controller: goalTargetController,
              label: "Savings Goal Target (UGX) — optional",
              icon: Icons.flag_outlined,
              required: false,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Calculate Projection",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: secondaryColor),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      validator: (value) {
        if (!required) return null;
        if (value == null || value.trim().isEmpty) return "Required";
        if (double.tryParse(value.trim()) == null)
          // ignore: curly_braces_in_flow_control_structures
          return "Enter a valid number";
        return null;
      },
    );
  }

  Widget _buildResultSection() {
    return FadeTransition(
      opacity: _resultAnimController,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
              CurvedAnimation(
                parent: _resultAnimController,
                curve: Curves.easeOutCubic,
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Projection Results",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _resultCard(
              icon: Icons.trending_up,
              color: Colors.green,
              label: "Projected Savings",
              value: _formatCurrency(projectedSavings),
            ),
            const SizedBox(height: 12),
            _resultCard(
              icon: Icons.show_chart,
              color: secondaryColor,
              label: "Total Growth",
              value: _formatCurrency(totalGrowth),
            ),
            const SizedBox(height: 12),
            _buildGoalProgressCard(),
          ],
        ),
      ),
    );
  }

  Widget _resultCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    final goalTarget = double.tryParse(goalTargetController.text.trim()) ?? 0;
    if (goalTarget <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Goal Progress",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Text(
                "${(goalProgress * 100).toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: goalProgress),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(
                    goalProgress >= 1 ? Colors.green : secondaryColor,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
