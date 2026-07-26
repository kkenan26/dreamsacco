import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  bool _isLoading = true;
  String _groupName = '';
  String _goalDescription = '';
  double _targetAmount = 0;
  double _currentAmount = 0;
  double _monthlyTarget = 0;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    QuerySnapshot memberGroups = await FirebaseFirestore.instance
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    String groupId = memberGroups.docs.first.reference.parent.parent!.id;
    DocumentSnapshot groupDoc = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .get();

    if (groupDoc.exists) {
      Map<String, dynamic> data = groupDoc.data() as Map<String, dynamic>;
      setState(() {
        _groupName = data['name'] ?? 'Your Group';
        _goalDescription = data['goalDescription'] ?? 'Savings Goal';
        _targetAmount = (data['goalAmount'] ?? 0).toDouble();
        _currentAmount = (data['totalBalance'] ?? 0).toDouble();
        _monthlyTarget = (data['contribution'] ?? 0).toDouble();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  double get progress =>
      _targetAmount <= 0 ? 0 : (_currentAmount / _targetAmount).clamp(0, 1);

  double get remainingAmount =>
      (_targetAmount - _currentAmount).clamp(0, double.infinity);

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
        title: const Text("Savings Goals", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _targetAmount == 0
          ? const Center(child: Text("No group goal set yet."))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_groupName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(_goalDescription, style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation(secondaryColor),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${(progress * 100).toStringAsFixed(0)}% Complete",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor, fontSize: 13)),
                    Text("${_formatCurrency(_currentAmount)} / ${_formatCurrency(_targetAmount)}",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Remaining", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(_formatCurrency(remainingAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Monthly Contribution", style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                          Text(_formatCurrency(_monthlyTarget), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}