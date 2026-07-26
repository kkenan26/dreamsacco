//lib/screens/loan_request_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanRequestScreen extends StatefulWidget {
  const LoanRequestScreen({super.key});

  @override
  State<LoanRequestScreen> createState() => _LoanRequestScreenState();
}

class _LoanRequestScreenState extends State<LoanRequestScreen> {
  final TextEditingController _amountController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _selectedMonths = 6;
  List<Map<String, dynamic>> _repaymentSchedule = [];
  bool _isSubmitting = false;
  String? _groupId;
  int _userCreditScore = 0;
  int _loanLimit = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String uid = _auth.currentUser?.uid ?? '';

    // Get user credit score and loan limit
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists) {
      setState(() {
        _userCreditScore = (userDoc['creditScore'] as num?)?.toInt() ?? 0;
        _loanLimit = (userDoc['loanLimit'] as num?)?.toInt() ?? 0;
      });
    }

    // Find user's group
    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isNotEmpty) {
      setState(() {
        _groupId = memberGroups.docs.first.reference.parent.parent!.id;
      });
    }
  }

  double _getInterestRate() {
    if (_userCreditScore >= 80) return 0.05;
    if (_userCreditScore >= 60) return 0.08;
    if (_userCreditScore >= 40) return 0.12;
    return 0.15;
  }

  void _generateSchedule() {
    double requestedAmount = double.tryParse(_amountController.text) ?? 0.0;

    if (requestedAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid loan amount")),
      );
      return;
    }

    if (requestedAmount > _loanLimit) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                "Amount exceeds your loan limit of UGX $_loanLimit")),
      );
      return;
    }

    double interestRate = _getInterestRate();
    double totalInterest = requestedAmount * interestRate;
    double totalRepayment = requestedAmount + totalInterest;
    double monthlyInstallment = totalRepayment / _selectedMonths;

    List<Map<String, dynamic>> schedule = [];
    DateTime currentDate = DateTime.now();

    for (int i = 1; i <= _selectedMonths; i++) {
      currentDate =
          DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      schedule.add({
        "month": "Month $i",
        "dueDate":
        "${currentDate.day}/${currentDate.month}/${currentDate.year}",
        "amount": "UGX ${monthlyInstallment.toStringAsFixed(0)}",
        "dueDateRaw": currentDate.toIso8601String(),
        "amountRaw": monthlyInstallment,
        "status": "pending",
      });
    }

    setState(() => _repaymentSchedule = schedule);
  }

  void _submitLoan() async {
    if (_repaymentSchedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please generate a repayment schedule first")),
      );
      return;
    }

    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be in a group to request a loan")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String uid = _auth.currentUser?.uid ?? '';
      double amount = double.tryParse(_amountController.text) ?? 0;

      await _db
          .collection('groups')
          .doc(_groupId)
          .collection('loans')
          .add({
        'requesterId': uid,
        'amount': amount,
        'creditScoreAtRequest': _userCreditScore,
        'interestRate': _getInterestRate(),
        'status': 'pending',
        'repaymentSchedule': _repaymentSchedule
            .map((e) => {
          'dueDate': e['dueDateRaw'],
          'amount': e['amountRaw'],
          'status': 'pending',
        })
            .toList(),
        'requestedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Loan request submitted successfully"),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }

    setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Loan Request & Schedule"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Credit score info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Your Credit Score",
                          style: TextStyle(
                              color: Color(0xFF0D47A1),
                              fontWeight: FontWeight.bold)),
                      Text("$_userCreditScore / 100",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1))),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text("Loan Limit",
                          style: TextStyle(color: Color(0xFF0D47A1))),
                      Text("UGX $_loanLimit",
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            const Text("Requested Amount (UGX)",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "e.g. 500000",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Repayment Duration",
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedMonths,
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(value: 3, child: Text("3 Months")),
                    DropdownMenuItem(value: 6, child: Text("6 Months")),
                    DropdownMenuItem(value: 12, child: Text("12 Months")),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedMonths = value!),
                ),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _generateSchedule,
                child: const Text("Generate Repayment Schedule",
                    style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 24),

            if (_repaymentSchedule.isNotEmpty) ...[
              const Text(
                "Auto-Generated Repayment Schedule",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _repaymentSchedule.length,
                itemBuilder: (context, index) {
                  final item = _repaymentSchedule[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor:
                        const Color(0xFF0D47A1).withValues(alpha: 0.1),
                        child: Text("${index + 1}",
                            style: const TextStyle(
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.bold)),
                      ),
                      title: Text(item["month"],
                          style:
                          const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Due: ${item["dueDate"]}"),
                      trailing: Text(item["amount"],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _isSubmitting
                  ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFF0D47A1)))
                  : SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitLoan,
                  child: const Text("Submit Loan Request",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}