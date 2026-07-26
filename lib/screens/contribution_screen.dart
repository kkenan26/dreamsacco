import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/momo_service.dart';

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final MomoService _momoService = MomoService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _groupId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    String uid = _auth.currentUser?.uid ?? '';

    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && mounted) {
      String phone = (userDoc['phone'] ?? '').toString().replaceAll('+256', '');
      _phoneController.text = phone;
    }

    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where(FieldPath.documentId, isEqualTo: uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isNotEmpty && mounted) {
      setState(() {
        _groupId = memberGroups.docs.first.reference.parent.parent!.id;
      });
    }
  }

  void _makeContribution() async {
    String amountText = _amountController.text.trim();
    String phone = _phoneController.text.trim();

    if (amountText.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_groupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be in a group to contribute')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'Sending payment request to your phone...';
    });

    Map<String, dynamic> result = await _momoService.requestToPay(
      payerPhone: phone,
      amount: amount,
      description: 'DreamSacco Contribution',
    );

    if (result['success'] == true) {
      String uid = _auth.currentUser?.uid ?? '';
      String month =
          '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

      await _db
          .collection('groups')
          .doc(_groupId)
          .collection('contributions')
          .add({
        'userId': uid,
        'amount': amount,
        'month': month,
        'paidAt': FieldValue.serverTimestamp(),
        'status': 'paid',
        'momoReference': result['referenceId'],
      });

      DocumentSnapshot userDoc =
      await _db.collection('users').doc(uid).get();
      int streak =
          (userDoc['contributionStreak'] as num?)?.toInt() ?? 0;
      int total =
          (userDoc['totalContributions'] as num?)?.toInt() ?? 0;

      await _db.collection('users').doc(uid).update({
        'contributionStreak': streak + 1,
        'totalContributions': total + 1,
      });

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contribution successful!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Payment failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F8FF),
      appBar: AppBar(
        title: const Text('Make Contribution'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF0D47A1)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You will receive a payment prompt on your MTN MoMo phone. Approve it with your PIN to complete the contribution.',
                      style:
                      TextStyle(color: Color(0xFF0D47A1), fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Amount (UGX)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 50000',
                filled: true,
                fillColor: Colors.white,
                prefixIcon:
                const Icon(Icons.attach_money, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('MTN MoMo Phone Number',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+256 ',
                hintText: '7XXXXXXXX',
                filled: true,
                fillColor: Colors.white,
                prefixIcon:
                const Icon(Icons.phone, color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                  const BorderSide(color: Color(0xFF0D47A1), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isProcessing) ...[
              const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF0D47A1)),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _statusMessage,
                  style: const TextStyle(
                      color: Color(0xFF0D47A1), fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _makeContribution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: const Text(
                    'Pay with MTN MoMo',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}