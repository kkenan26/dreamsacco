import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/group_picker.dart'; // adjust path

class TransparencyScreen extends StatefulWidget {
  const TransparencyScreen({super.key});

  @override
  State<TransparencyScreen> createState() => _TransparencyScreenState();
}

class _TransparencyScreenState extends State<TransparencyScreen> {
  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

  String? _selectedGroupId;
  bool _isLoading = false;
  String _groupName = '';
  double _totalBalance = 0;
  double _goalAmount = 0;
  List<Map<String, dynamic>> _memberPayments = [];
  String _currentMonth = '';

  Future<void> _onGroupSelected(String? groupId) async {
    if (groupId == null || groupId == _selectedGroupId) return;
    setState(() {
      _selectedGroupId = groupId;
      _isLoading = true;
    });
    await _loadTransparencyData(groupId);
  }

  Future<void> _loadTransparencyData(String groupId) async {
    try {
      _currentMonth = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

      DocumentSnapshot groupDoc = await FirebaseFirestore.instance.collection('groups').doc(groupId).get();
      Map<String, dynamic> groupData = groupDoc.data() as Map<String, dynamic>? ?? {};

      QuerySnapshot membersSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .collection('members')
          .get();

      List<Map<String, dynamic>> payments = [];

      for (var memberDoc in membersSnapshot.docs) {
        Map<String, dynamic> memberData = memberDoc.data() as Map<String, dynamic>;
        String memberId = memberDoc.id;

        String memberName = 'Unknown';
        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(memberId).get();
        if (userDoc.exists) {
          memberName = (userDoc.data() as Map<String, dynamic>)['name'] ?? 'Unknown';
        }

        QuerySnapshot thisMonthContribution = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('contributions')
            .where('userId', isEqualTo: memberId)
            .where('month', isEqualTo: _currentMonth)
            .where('status', isEqualTo: 'paid')
            .limit(1)
            .get();

        payments.add({
          'name': memberName,
          'role': memberData['role'] ?? 'member',
          'paid': thisMonthContribution.docs.isNotEmpty,
        });
      }

      if (mounted) {
        setState(() {
          _groupName = groupData['name'] ?? 'Group';
          _totalBalance = (groupData['totalBalance'] ?? 0).toDouble();
          _goalAmount = (groupData['goalAmount'] ?? 0).toDouble();
          _memberPayments = payments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    int paidCount = _memberPayments.where((m) => m['paid'] == true).length;
    int totalCount = _memberPayments.length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text("Transparency Dashboard", style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GroupPicker(selectedGroupId: _selectedGroupId, onChanged: _onGroupSelected),
          const SizedBox(height: 20),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else if (_selectedGroupId != null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [primaryColor, secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_groupName, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(_formatCurrency(_totalBalance), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('of ${_formatCurrency(_goalAmount)} goal', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("This Month's Contributions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("$paidCount / $totalCount paid", style: const TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text("Members", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._memberPayments.map((m) {
              bool paid = m['paid'] == true;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: (paid ? Colors.green : Colors.red).withValues(alpha: 0.12),
                      child: Icon(paid ? Icons.check : Icons.close, color: paid ? Colors.green : Colors.red, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(m['role'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    Text(paid ? 'Paid' : 'Unpaid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: paid ? Colors.green : Colors.red)),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}