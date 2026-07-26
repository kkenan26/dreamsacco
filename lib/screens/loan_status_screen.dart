//lib/screens/loan_status_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoanStatusScreen extends StatefulWidget {
  const LoanStatusScreen({super.key});

  @override
  State<LoanStatusScreen> createState() => _LoanStatusScreenState();
}

class _LoanStatusScreenState extends State<LoanStatusScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  void _loadLoans() async {
    String uid = _auth.currentUser?.uid ?? '';

    // Find user's group
    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    String groupId =
        memberGroups.docs.first.reference.parent.parent!.id;

    // Fetch all loans for this user ranked by credit score
    QuerySnapshot loans = await _db
        .collection('groups')
        .doc(groupId)
        .collection('loans')
        .where('requesterId', isEqualTo: uid)
        .orderBy('creditScoreAtRequest', descending: true)
        .get();

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

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      case 'repaying':
        return Colors.blue;
      case 'cleared':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'pending':
        return Icons.hourglass_top;
      case 'rejected':
        return Icons.cancel;
      case 'repaying':
        return Icons.payments;
      case 'cleared':
        return Icons.done_all;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Loan Application Status"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
          ? const Center(
          child: Text("No loan applications found.",
              style: TextStyle(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _loans.length,
        itemBuilder: (context, index) {
          final loan = _loans[index];
          String status = loan['status'];
          return Card(
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "UGX ${loan['amount'].toStringAsFixed(0)}",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D47A1)),
                      ),
                      Chip(
                        avatar: Icon(_statusIcon(status),
                            color: _statusColor(status), size: 16),
                        label: Text(status.toUpperCase(),
                            style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.bold,
                                fontSize: 12)),
                        backgroundColor:
                        _statusColor(status).withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          "Credit Score: ${loan['creditScore']}",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      Text(
                          "Interest: ${(loan['interestRate'] * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}