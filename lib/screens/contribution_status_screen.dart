import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/contribution.dart';
import '../services/contribution_service.dart';
import '../widgets/streak_badge.dart';

/// Shows the "who has paid this month" list for a group — the core
/// visibility piece of your part. Admins/treasurers use this to see
/// payment status at a glance; members can see their own streak here too.
class ContributionStatusScreen extends StatefulWidget {
  final String groupId;

  const ContributionStatusScreen({super.key, required this.groupId});

  @override
  State<ContributionStatusScreen> createState() => _ContributionStatusScreenState();
}

class _ContributionStatusScreenState extends State<ContributionStatusScreen> {
  final ContributionService _service = ContributionService();
  late Future<List<MemberMonthStatus>> _statusFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = _service.getMonthlyStatus(widget.groupId);
  }

  void _refresh() {
    setState(() {
      _statusFuture = _service.getMonthlyStatus(widget.groupId);
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'late':
        return Colors.orange;
      case 'missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contributions — ${_service.currentMonthKey}'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<List<MemberMonthStatus>>(
        future: _statusFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final members = snapshot.data ?? [];
          final paidCount = members.where((m) => m.hasPaid).length;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  '$paidCount of ${members.length} members have paid',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _statusColor(m.status),
                        child: Icon(
                          m.hasPaid ? Icons.check : Icons.close,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      title: Text(m.userName),
                      subtitle: Text(m.status.toUpperCase()),
                      trailing: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(m.userId)
                            .snapshots(),
                        builder: (context, userSnap) {
                          if (!userSnap.hasData) return const SizedBox.shrink();
                          final streak =
                              (userSnap.data?.get('contributionStreak') ?? 0) as int;
                          return StreakBadge(streak: streak);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
