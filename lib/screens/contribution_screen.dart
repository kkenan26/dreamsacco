import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/momo_service.dart';
import '../widgets/group_picker.dart';

class ContributionScreen extends StatefulWidget {
  const ContributionScreen({super.key});

  @override
  State<ContributionScreen> createState() => _ContributionScreenState();
}

class _ContributionScreenState extends State<ContributionScreen> {
  static const Color primaryColor = Color(0xFF0D47A1);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final MomoService _momoService = MomoService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isProcessing = false;
  String _statusMessage = '';
  String? _selectedGroupId;
  List<Map<String, dynamic>> _recentContributions = [];
  bool _isThisMonthPaid = false;

  // FIX: Track partial payment state
  double _currentMonthPaidAmount = 0;
  double _requiredContributionAmount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserPhone();
  }

  void _loadUserPhone() async {
    String uid = _auth.currentUser?.uid ?? '';
    DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
    if (userDoc.exists && mounted) {
      String phone = (userDoc.data() as Map<String, dynamic>)['phone']?.toString().replaceAll('+256', '') ?? '';
      _phoneController.text = phone;
    }
  }

  Future<void> _onGroupSelected(String? groupId) async {
    if (groupId == null || groupId == _selectedGroupId) return;
    setState(() => _selectedGroupId = groupId);
    await _loadGroupContributions(groupId);
  }

  Future<void> _loadGroupContributions(String groupId) async {
    DocumentSnapshot groupDoc = await _db.collection('groups').doc(groupId).get();
    double contributionAmount = 0;
    if (groupDoc.exists) {
      contributionAmount = ((groupDoc.data() as Map<String, dynamic>)['contribution'] ?? 0).toDouble();
    }

    String uid = _auth.currentUser?.uid ?? '';
    QuerySnapshot contributions = await _db
        .collection('groups')
        .doc(groupId)
        .collection('contributions')
        .where('userId', isEqualTo: uid)
        .orderBy('paidAt', descending: true)
        .limit(10)
        .get();

    String currentMonth = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

    // FIX: Sum all payments for the current month to determine if fully paid
    double totalPaidThisMonth = 0;

    List<Map<String, dynamic>> loaded = contributions.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      if (data['month'] == currentMonth) {
        totalPaidThisMonth += (data['amount'] ?? 0).toDouble();
      }
      return {
        'month': data['month'] ?? '',
        'amount': (data['amount'] ?? 0).toDouble(),
        'status': data['status'] ?? 'paid',
      };
    }).toList();

    if (mounted) {
      setState(() {
        _recentContributions = loaded;
        _isThisMonthPaid = totalPaidThisMonth >= contributionAmount;
        _currentMonthPaidAmount = totalPaidThisMonth;
        _requiredContributionAmount = contributionAmount;
        if (contributionAmount > 0) {
          _amountController.text = contributionAmount.toStringAsFixed(0);
        }
      });
    }
  }

  void _makeContribution() async {
    String amountText = _amountController.text.trim();
    String phone = _phoneController.text.trim();

    if (_selectedGroupId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a group first')));
      return;
    }
    if (amountText.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill in all fields')));
      return;
    }

    double amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
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
      String month = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

      // FIX: Determine if payment is full or partial
      DocumentSnapshot groupDoc = await _db.collection('groups').doc(_selectedGroupId).get();
      double requiredAmount = 0;
      if (groupDoc.exists) {
        requiredAmount = ((groupDoc.data() as Map<String, dynamic>)['contribution'] ?? 0).toDouble();
      }
      String paymentStatus = (requiredAmount > 0 && amount < requiredAmount) ? 'partial' : 'paid';

      // 1. Record contribution
      await _db.collection('groups').doc(_selectedGroupId).collection('contributions').add({
        'userId': uid,
        'amount': amount,
        'month': month,
        'paidAt': FieldValue.serverTimestamp(),
        'status': paymentStatus,
        'momoReference': result['referenceId'],
      });

      // 2. UPDATE GROUP BALANCE
      await _db.collection('groups').doc(_selectedGroupId).update({
        'totalBalance': FieldValue.increment(amount),
      });

      // 3. UPDATE USER'S TOTAL SAVINGS
      await _db.collection('users').doc(uid).update({
        'totalSavings': FieldValue.increment(amount),
      });

      // 4. FIX STREAK LOGIC
      DocumentSnapshot userDoc = await _db.collection('users').doc(uid).get();
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      int currentStreak = (userData['contributionStreak'] as num?)?.toInt() ?? 0;
      Timestamp? lastTs = userData['lastContributionAt'] as Timestamp?;

      int newStreak = 1;
      if (lastTs != null) {
        DateTime last = lastTs.toDate();
        DateTime now = DateTime.now();
        DateTime lastMonth = DateTime(now.year, now.month - 1, 1);
        DateTime lastContribMonth = DateTime(last.year, last.month, 1);
        if (lastContribMonth.year == lastMonth.year && lastContribMonth.month == lastMonth.month) {
          newStreak = currentStreak + 1;
        }
      }

      await _db.collection('users').doc(uid).update({
        'contributionStreak': newStreak,
        'totalContributions': FieldValue.increment(1),
        'lastContributionAt': FieldValue.serverTimestamp(),
      });

      // 5. OPTIMISTIC UI
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
        if (paymentStatus == 'paid') _isThisMonthPaid = true;
        _currentMonthPaidAmount += amount;
        _recentContributions.insert(0, {
          'month': month,
          'amount': amount,
          'status': paymentStatus,
        });
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contribution successful!'), backgroundColor: Colors.green),
      );
    } else {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
        _statusMessage = '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Payment failed'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Contributions'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupPicker(selectedGroupId: _selectedGroupId, onChanged: _onGroupSelected),
          const SizedBox(height: 20),
          if (_selectedGroupId != null) ...[
            // FIX: Show partial payment status in the banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isThisMonthPaid
                    ? Colors.green.shade50
                    : (_currentMonthPaidAmount > 0 ? Colors.amber.shade50 : Colors.orange.shade50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isThisMonthPaid
                      ? Colors.green.shade200
                      : (_currentMonthPaidAmount > 0 ? Colors.amber.shade200 : Colors.orange.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isThisMonthPaid
                        ? Icons.check_circle
                        : (_currentMonthPaidAmount > 0 ? Icons.info_outline : Icons.warning_amber),
                    color: _isThisMonthPaid
                        ? Colors.green
                        : (_currentMonthPaidAmount > 0 ? Colors.amber.shade800 : Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isThisMonthPaid
                          ? "This month's contribution is paid."
                          : (_currentMonthPaidAmount > 0
                          ? "Partially paid: UGX ${_currentMonthPaidAmount.toStringAsFixed(0)} of UGX ${_requiredContributionAmount.toStringAsFixed(0)}"
                          : "This month's contribution is due."),
                      style: TextStyle(
                        color: _isThisMonthPaid
                            ? Colors.green.shade800
                            : (_currentMonthPaidAmount > 0 ? Colors.amber.shade900 : Colors.orange.shade800),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Amount (UGX)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 50000',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.attach_money, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('MTN MoMo Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                prefixText: '+256 ',
                hintText: '7XXXXXXXX',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.phone, color: primaryColor),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: primaryColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_isProcessing) ...[
              const Center(child: CircularProgressIndicator(color: primaryColor)),
              const SizedBox(height: 16),
              Center(child: Text(_statusMessage, style: const TextStyle(color: primaryColor, fontSize: 14), textAlign: TextAlign.center)),
            ] else
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _makeContribution,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: const Text('Pay with MTN MoMo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 28),
            const Text('Contribution History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_recentContributions.isEmpty)
              Text('No contributions yet.', style: TextStyle(color: Colors.grey.shade600))
            else
              ..._recentContributions.map((c) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    // FIX: Show different icon for partial payments
                    Icon(
                      c['status'] == 'paid'
                          ? Icons.check_circle
                          : (c['status'] == 'partial' ? Icons.timelapse : Icons.error_outline),
                      color: c['status'] == 'paid'
                          ? Colors.green
                          : (c['status'] == 'partial' ? Colors.orange : Colors.red),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['month'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          if (c['status'] == 'partial')
                            Text(
                              'Partial',
                              style: TextStyle(color: Colors.orange.shade700, fontSize: 11, fontWeight: FontWeight.w500),
                            ),
                        ],
                      ),
                    ),
                    Text('UGX ${(c['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              )),
          ],
        ],
      ),
    );
  }
}