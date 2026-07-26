import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../services/group.dart';
import '../../services/adapter.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import 'join_requests.dart';
import 'member_mgt.dart';
import 'loan_requests.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color secondaryColor = Color(0xFF1976D2);

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
    final GroupService groupService = GroupService(
      creditScoreService: RealCreditScoreAdapter(),
    );

    final progress = group.goalAmount > 0
        ? (group.totalBalance / group.goalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => JoinRequestsScreen(groupId: group.id)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => MemberManagementScreen(groupId: group.id)));
            },
          ),
          IconButton(
            icon: const Icon(Icons.request_page),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => LoanRequestsScreen(groupId: group.id)));
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryColor, secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: primaryColor.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
                const SizedBox(height: 16),
                Text('Goal: ${group.goalDescription}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatCurrency(group.totalBalance)} / ${_formatCurrency(group.goalAmount)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.payments_outlined, size: 18, color: secondaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'UGX ${group.contribution.toStringAsFixed(0)} every ${group.contributionFrequencyValue} ${group.contributionFrequencyUnit}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text('Group ID: ${group.id}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 16),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: group.id));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group ID copied!')));
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                String userId = FirebaseAuth.instance.currentUser!.uid;
                if (userId == group.adminId) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reassign the admin role before leaving.')),
                  );
                  return;
                }
                String userName = await groupService.getUserName(userId);
                await groupService.requestToLeaveGroup(groupId: group.id, userId: userId, userName: userName);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Leave request sent to admin.')));
                }
              },
              icon: const Icon(Icons.logout, size: 16, color: Colors.grey),
              label: Text('Request to Leave Group', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Members', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 12),
          StreamBuilder<List<Member>>(
            stream: groupService.getGroupMembers(group.id),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Text('Error: ${snapshot.error}');
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data ?? [];
              if (members.isEmpty) {
                return Text('No members yet.', style: TextStyle(color: Colors.grey.shade600));
              }

              return Column(
                children: members.map((member) {
                  return FutureBuilder<String>(
                    future: groupService.getUserName(member.userId),
                    builder: (context, nameSnapshot) {
                      final displayName = nameSnapshot.data ?? member.userId;
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
                              backgroundColor: secondaryColor.withValues(alpha: 0.12),
                              child: Text(
                                displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                                style: const TextStyle(color: secondaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  Text(
                                    member.shares > 0
                                        ? 'Role: ${member.role} · Shares: ${member.shares.toStringAsFixed(1)}'
                                        : 'Role: ${member.role}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}