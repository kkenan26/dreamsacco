import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/credit_score_model.dart';
import '../services/credit_score_service.dart';

class CreditScoreScreen extends StatefulWidget {
  const CreditScoreScreen({super.key});

  @override
  State<CreditScoreScreen> createState() => _CreditScoreScreenState();
}

class _CreditScoreScreenState extends State<CreditScoreScreen> {
  final CreditScoreService _service = CreditScoreService();
  CreditScoreModel? _credit;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    QuerySnapshot groups = await FirebaseFirestore.instance
        .collection('groups')
        .where('memberIds', arrayContains: uid)
        .limit(1)
        .get();

    String groupId = '';
    if (groups.docs.isNotEmpty) {
      groupId = groups.docs.first.id;
    }

    CreditScoreModel score =
    await _service.fetchUserCreditScore(groupId.isEmpty ? 'none' : groupId);

    if (!mounted) return;
    setState(() {
      _credit = score;
      _loading = false;
    });
  }

  Color _scoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Credit Worthiness Engine"),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _credit == null
          ? const Center(child: Text("No credit data available"))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text("Your Credit Score",
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16)),
                  const SizedBox(height: 8),
                  Text("${_credit!.score}/100",
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(_credit!.rating,
                        style: TextStyle(
                            color: _scoreColor(
                                _credit!.score),
                            fontWeight:
                            FontWeight.bold)),
                    backgroundColor: Colors.white,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4)
                ],
              ),
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text("Loan Eligibility",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Maximum Loan:",
                          style: TextStyle(
                              color: Colors.grey)),
                      Text(
                          "UGX ${_credit!.loanLimit.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D47A1))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Interest Rate:",
                          style: TextStyle(
                              color: Colors.grey)),
                      Text(
                          "${(_credit!.interestRate * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4)
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _scoreColor(
                        _credit!.score)
                        .withValues(alpha: 0.12),
                    child: Icon(Icons.info_outline,
                        color:
                        _scoreColor(_credit!.score)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        const Text("Score Analysis",
                            style: TextStyle(
                                fontWeight:
                                FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_credit!.remark,
                            style: TextStyle(
                                color:
                                Colors.grey.shade600,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}