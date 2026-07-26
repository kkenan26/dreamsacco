import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../models/member.dart';
import '../../services/credit_score.dart';

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
      creditScoreService: MockCreditScoreService(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: StreamBuilder<List<Member>>(
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

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(member.userId),
                  subtitle: Text('Status: ${member.status}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          bool confirmed = await _confirmAction(
                            context,
                            'Remove Member?',
                            'This will remove ${member.userId} from the group.',
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
      ),
    );
  }
}