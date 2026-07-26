// lib/screens/shares/shares_screen.dart
import 'package:flutter/material.dart';

class ShareTransaction {
  final String date;
  final int units;
  final double amount;
  final String type; // "Purchase" or "Transfer"

  ShareTransaction({
    required this.date,
    required this.units,
    required this.amount,
    required this.type,
  });
}

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  final String memberId = "SAC001";
  final double sharePrice = 5000;
  int totalUnits = 48;
  final int minimumUnits = 20;

  late AnimationController _animController;

  final List<ShareTransaction> transactions = [
    ShareTransaction(
      date: "Jul 2026",
      units: 8,
      amount: 40000,
      type: "Purchase",
    ),
    ShareTransaction(
      date: "Apr 2026",
      units: 10,
      amount: 50000,
      type: "Purchase",
    ),
    ShareTransaction(
      date: "Jan 2026",
      units: 15,
      amount: 75000,
      type: "Purchase",
    ),
    ShareTransaction(
      date: "Sep 2025",
      units: 15,
      amount: 75000,
      type: "Purchase",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double get totalShareValue => totalUnits * sharePrice;

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

  void _openBuySharesDialog() {
    final unitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text("Buy Shares"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Share Price: ${_formatCurrency(sharePrice)} per unit",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: unitsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Number of Units"),
              ),
            ],
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
                final units = int.tryParse(unitsController.text.trim()) ?? 0;
                if (units <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Enter a valid number of units"),
                    ),
                  );
                  return;
                }
                setState(() {
                  totalUnits += units;
                  transactions.insert(
                    0,
                    ShareTransaction(
                      date: "Jul 2026",
                      units: units,
                      amount: units * sharePrice,
                      type: "Purchase",
                    ),
                  );
                });
                Navigator.pop(context);
                _animController.forward(from: 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      "Purchased $units share unit${units > 1 ? 's' : ''} successfully",
                    ),
                  ),
                );
              },
              child: const Text("Confirm"),
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
          "My Shares",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryColor,
        onPressed: _openBuySharesDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Buy Shares", style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 24),
            _sectionTitle("Share Certificate"),
            const SizedBox(height: 12),
            _buildCertificateCard(),
            const SizedBox(height: 24),
            _sectionTitle("Purchase History"),
            const SizedBox(height: 12),
            _buildTransactionList(),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Total Share Value",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final displayValue =
                  totalShareValue *
                  Curves.easeOutCubic.transform(_animController.value);
              return Text(
                _formatCurrency(displayValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Units Owned",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$totalUnits units",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 32, color: Colors.white30),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Price per Unit",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(sharePrice),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateCard() {
    final meetsMinimum = totalUnits >= minimumUnits;

    return Container(
      padding: const EdgeInsets.all(18),
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
            radius: 22,
            backgroundColor: secondaryColor.withValues(alpha: 0.12),
            child: const Icon(Icons.badge_outlined, color: secondaryColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Member ID: $memberId",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meetsMinimum
                      ? "Minimum share requirement met ($minimumUnits units)"
                      : "Minimum requirement: $minimumUnits units (${minimumUnits - totalUnits} more needed)",
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          Icon(
            meetsMinimum ? Icons.verified : Icons.info_outline,
            color: meetsMinimum ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList() {
    if (transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text(
            "No share purchases yet",
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      );
    }

    return Column(
      children: transactions.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: secondaryColor.withValues(alpha: 0.12),
                child: const Icon(
                  Icons.pie_chart,
                  color: secondaryColor,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${tx.type} • ${tx.units} units",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx.date,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(tx.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
