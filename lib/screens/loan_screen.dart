import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group.dart';
import '../../services/adapter.dart';

class LoanScreen extends StatefulWidget {
  const LoanScreen({super.key});

  @override
  State<LoanScreen> createState() => _LoanScreenState();
}

class _LoanScreenState extends State<LoanScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text("Loans"),
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Request Loan"),
              Tab(text: "My Loans"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LoanRequestTab(),
            _LoanStatusTab(),
          ],
        ),
      ),
    );
  }
}

class _LoanRequestTab extends StatefulWidget {
  const _LoanRequestTab();

  @override
  State<_LoanRequestTab> createState() => _LoanRequestTabState();
}

class _LoanRequestTabState extends State<_LoanRequestTab> {
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

    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && mounted) {
      setState(() {
        _userCreditScore = (userDoc['creditScore'] as num?)?.toInt() ?? 0;
        _loanLimit = (userDoc['loanLimit'] as num?)?.toInt() ?? 0;
      });
    }

    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isNotEmpty && mounted) {
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
        SnackBar(content: Text("Amount exceeds your loan limit of UGX $_loanLimit")),
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
      currentDate = DateTime(currentDate.year, currentDate.month + 1, currentDate.day);
      schedule.add({
        "month": "Month $i",
        "dueDate": "${currentDate.day}/${currentDate.month}/${currentDate.year}",
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
        const SnackBar(content: Text("Please generate a repayment schedule first")),
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

      await _db.collection('groups').doc(_groupId).collection('loans').add({
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
        const SnackBar(content: Text("Loan request submitted successfully"), backgroundColor: Colors.green),
      );
      setState(() {
        _repaymentSchedule = [];
        _amountController.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    const Text("Your Credit Score", style: TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                    Text("$_userCreditScore / 100", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text("Loan Limit", style: TextStyle(color: Color(0xFF0D47A1))),
                    Text("UGX $_loanLimit", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text("Requested Amount (UGX)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: "e.g. 500000",
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 20),
          const Text("Repayment Duration", style: TextStyle(fontWeight: FontWeight.bold)),
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
                onChanged: (value) => setState(() => _selectedMonths = value!),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _generateSchedule,
              child: const Text("Generate Repayment Schedule", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 24),
          if (_repaymentSchedule.isNotEmpty) ...[
            const Text("Auto-Generated Repayment Schedule", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0D47A1).withValues(alpha: 0.1),
                      child: Text("${index + 1}", style: const TextStyle(color: Color(0xFF0D47A1), fontWeight: FontWeight.bold)),
                    ),
                    title: Text(item["month"], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("Due: ${item["dueDate"]}"),
                    trailing: Text(item["amount"], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14)),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF0D47A1)))
                : SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _submitLoan,
                child: const Text("Submit Loan Request", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LoanStatusTab extends StatefulWidget {
  const _LoanStatusTab();

  @override
  State<_LoanStatusTab> createState() => _LoanStatusTabState();
}

class _LoanStatusTabState extends State<_LoanStatusTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _repayLoan(String loanId, double monthlyAmount) async {
    final groupService = GroupService(creditScoreService: RealCreditScoreAdapter());
    String uid = _auth.currentUser!.uid;

    // Find the groupId (you already have this logic in _loadLoans)
    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where('userId', isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isEmpty) return;
    String groupId = memberGroups.docs.first.reference.parent.parent!.id;

    try {
      await groupService.recordLoanRepayment(
        groupId: groupId,
        loanId: loanId,
        userId: uid,
        amountPaid: monthlyAmount,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Repayment recorded!'), backgroundColor: Colors.green),
      );
      _loadLoans(); // refresh the list
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _loadLoans() async {
    try {
      String uid = _auth.currentUser?.uid ?? '';

      QuerySnapshot memberGroups = await _db
          .collectionGroup('members')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (memberGroups.docs.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      String groupId = memberGroups.docs.first.reference.parent.parent!.id;

      QuerySnapshot loans = await _db
          .collection('groups')
          .doc(groupId)
          .collection('loans')
          .where('requesterId', isEqualTo: uid)
          .orderBy('creditScoreAtRequest', descending: true)
          .get();

      if (mounted) {
        setState(() {
          _loans = loans.docs.map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'amount': data['amount'] ?? 0,
              'status': data['status'] ?? 'pending',
              'creditScore': data['creditScoreAtRequest'] ?? 0,
              'interestRate': data['interestRate'] ?? 0.15,
              'requestedAt': data['requestedAt'],
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return Colors.green;
      case 'pending': return Colors.orange;
      case 'rejected': return Colors.red;
      case 'repaying': return Colors.blue;
      case 'cleared': return Colors.teal;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved': return Icons.check_circle;
      case 'pending': return Icons.hourglass_top;
      case 'rejected': return Icons.cancel;
      case 'repaying': return Icons.payments;
      case 'cleared': return Icons.done_all;
      default: return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_loans.isEmpty) {
      return Center(
        child: Text("No loan applications yet.", style: TextStyle(color: Colors.grey.shade600)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _loans.length,
      itemBuilder: (context, index) {
        final loan = _loans[index];
        String status = loan['status'];
        return Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("UGX ${loan['amount'].toStringAsFixed(0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    Chip(
                      avatar: Icon(_statusIcon(status), color: _statusColor(status), size: 16),
                      label: Text(status.toUpperCase(), style: TextStyle(color: _statusColor(status), fontWeight: FontWeight.bold, fontSize: 12)),
                      backgroundColor: _statusColor(status).withValues(alpha: 0.1),
                      side: BorderSide.none,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Credit Score: ${loan['creditScore']}", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                    Text("Interest: ${(loan['interestRate'] * 100).toStringAsFixed(0)}%", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 12),
                if (status == 'repaying' || status == 'approved') ...[
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.payments, size: 18),
                      label: const Text("Make Repayment", style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        // Calculate monthly installment from the stored repayment schedule
                        List<dynamic> schedule = loan['repaymentSchedule'] ?? [];
                        double monthly = 0;
                        if (schedule.isNotEmpty) {
                          monthly = (schedule[0]['amount'] as num?)?.toDouble() ?? 0;
                        }
                        if (monthly <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No repayment schedule found')),
                          );
                          return;
                        }
                        _repayLoan(loan['id'], monthly);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}