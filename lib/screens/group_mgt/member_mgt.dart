import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/group.dart';
import '../../models/member.dart';
import 'profile.dart';
import '../../services/adapter.dart';

Future<bool> _confirmAction(BuildContext context, String title, String message) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Confirm'),
        ),
      ],
    ),
  );
  return result ?? false;
}

class MemberManagementScreen extends StatelessWidget {
  final String groupId;

  const MemberManagementScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: RealCreditScoreAdapter(),
    );
    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0D47A1),
          foregroundColor: Colors.white,
          title: const Text('Manage Members', style: TextStyle(fontWeight: FontWeight.w600))),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('members')
            .doc(currentUserId)
            .get(),
        builder: (context, adminSnapshot) {
          bool isAdmin = false;
          if (adminSnapshot.hasData && adminSnapshot.data!.exists) {
            isAdmin = (adminSnapshot.data!.data() as Map<String, dynamic>)['role'] == 'admin';
          }

          return StreamBuilder<List<Member>>(
            stream: groupService.getGroupMembers(groupId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final members = snapshot.data ?? [];

              if (members.isEmpty) {
                return const Text('No members yet.');
              }

              return ListView.builder(
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];

                  return FutureBuilder<String>(
                    future: groupService.getUserName(member.userId),
                    builder: (context, nameSnapshot) {
                      final displayName = nameSnapshot.data ?? member.userId;

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text(displayName),
                          subtitle: Text(
                            member.shares > 0
                                ? 'Status: ${member.status} · Shares: ${member.shares.toStringAsFixed(1)}'
                                : 'Status: ${member.status}',
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ProfileScreen(userId: member.userId),
                              ),
                            );
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isAdmin)
                                DropdownButton<String>(
                                  value: member.role,
                                  items: const [
                                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                                    DropdownMenuItem(value: 'treasurer', child: Text('Treasurer')),
                                    DropdownMenuItem(value: 'member', child: Text('Member')),
                                  ],
                                  onChanged: (newRole) async {
                                    if (newRole == null) return;
                                    await groupService.updateMemberRole(
                                      groupId: groupId,
                                      userId: member.userId,
                                      newRole: newRole,
                                    );
                                  },
                                ),
                              if (isAdmin)
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () async {
                                    bool confirmed = await _confirmAction(
                                      context,
                                      'Remove Member?',
                                      'This will remove $displayName from the group.',
                                    );
                                    if (confirmed) {
                                      await groupService.removeMember(
                                        groupId: groupId,
                                        userId: member.userId,
                                      );
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}