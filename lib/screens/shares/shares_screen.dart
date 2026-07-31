import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SharesScreen extends StatefulWidget {
  const SharesScreen({super.key});

  @override
  State<SharesScreen> createState() => _SharesScreenState();
}

class _SharesScreenState extends State<SharesScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _isLoading = true;
  String? _groupId;
  String _groupName = '';
  double _sharePrice = 0;
  int _totalShares = 0;
  int _sharesTaken = 0;
  double _myShares = 0;
  List<Map<String, dynamic>> _transactions = [];

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _loadData();
  }

  Future<void> _loadData() async {
    QuerySnapshot memberGroups = await _db
        .collectionGroup('members')
        .where('userId', isEqualTo: _uid)
        .limit(1)
        .get();

    if (memberGroups.docs.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    _groupId = memberGroups.docs.first.reference.parent.parent!.id;
    DocumentSnapshot groupDoc = await _db.collection('groups').doc(_groupId).get();
    DocumentSnapshot memberDoc = await _db
        .collection('groups')
        .doc(_groupId)
        .collection('members')
        .doc(_uid)
        .get();

    if (!groupDoc.exists || !mounted) {
      setState(() => _isLoading = false);
      return;
    }

    Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>;
    Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>? ?? {};

    QuerySnapshot txSnapshot = await _db
        .collection('groups')
        .doc(_groupId)
        .collection('shareTransactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('purchasedAt', descending: true)
        .get();

    List<Map<String, dynamic>> txs = txSnapshot.docs.map((doc) {
      Map<String, dynamic> d = doc.data() as Map<String, dynamic>;
      Timestamp? ts = d['purchasedAt'] as Timestamp?;
      DateTime date = ts?.toDate() ?? DateTime.now();
      return {
        'date': '${date.month}/${date.year}',
        'units': (d['units'] as num?)?.toInt() ?? 0,
        'amount': (d['amount'] as num?)?.toDouble() ?? 0.0,
        'type': d['type'] ?? 'Purchase',
      };
    }).toList();

    if (mounted) {
      setState(() {
        _groupName = groupData['name'] ?? 'Your Group';
        _sharePrice = (groupData['contributionPerShare'] as num?)?.toDouble() ?? 0.0;
        _totalShares = (groupData['totalShares'] as num?)?.toInt() ?? 0;
        _sharesTaken = (groupData['sharesTaken'] as num?)?.toInt() ?? 0;
        _myShares = (memberData['shares'] as num?)?.toDouble() ?? 0.0;
        _transactions = txs;
        _isLoading = false;
      });
      _animController.forward(from: 0);
    }
  }

  double get totalShareValue => _myShares * _sharePrice;

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
    if (_groupId == null) return;
    final unitsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Buy Shares"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Share Price: ${_formatCurrency(_sharePrice)} per unit",
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
              onPressed: () async {
                final units = int.tryParse(unitsController.text.trim()) ?? 0;
                if (units <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid number of units")),
                  );
                  return;
                }

                int remaining = _totalShares - _sharesTaken;
                if (units > remaining) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Only $remaining shares remaining.")),
                  );
                  return;
                }

                double amount = units * _sharePrice;

                await _db.collection('groups').doc(_groupId).collection('shareTransactions').add({
                  'userId': _uid,
                  'units': units,
                  'amount': amount,
                  'type': 'Purchase',
                  'purchasedAt': FieldValue.serverTimestamp(),
                });

                await _db.collection('groups').doc(_groupId).collection('members').doc(_uid).update({
                  'shares': FieldValue.increment(units.toDouble()),
                });

                await _db.collection('groups').doc(_groupId).update({
                  'sharesTaken': FieldValue.increment(units),
                  'totalBalance': FieldValue.increment(amount),
                });

                Navigator.pop(context);
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Purchased $units share unit${units > 1 ? 's' : ''}")),
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
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          elevation: 0,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          title: const Text("My Shares", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("My Shares", style: TextStyle(fontWeight: FontWeight.w600)),
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
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
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
          Text(_groupName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final displayValue = totalShareValue * Curves.easeOutCubic.transform(_animController.value);
              return Text(
                _formatCurrency(displayValue),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
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
                    const Text("Units Owned", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      "${_myShares.toStringAsFixed(0)} units",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
                    const Text("Price per Unit", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(_sharePrice),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
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
    final meetsMinimum = _myShares > 0;
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
                  "Member ID: ${_uid.substring(0, 8).toUpperCase()}",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  meetsMinimum
                      ? "Shareholder in $_groupName"
                      : "Buy shares to become a shareholder",
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
    if (_transactions.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: Text("No share purchases yet", style: TextStyle(color: Colors.grey.shade600)),
        ),
      );
    }

    return Column(
      children: _transactions.map((tx) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: secondaryColor.withValues(alpha: 0.12),
                child: const Icon(Icons.pie_chart, color: secondaryColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${tx['type']} • ${tx['units']} units",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tx['date'],
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              Text(
                _formatCurrency(tx['amount']),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}