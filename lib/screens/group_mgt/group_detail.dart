import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../services/credit_score.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import 'join_requests.dart';
import 'member_mgt.dart';

class GroupDetailScreen extends StatelessWidget {
  final Group group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    final progress = group.goalAmount > 0
        ? (group.totalBalance / group.goalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JoinRequestsScreen(groupId: group.id),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.manage_accounts),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => MemberManagementScreen(groupId: group.id),
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Goal: ${group.goalDescription}'),
            Text(
              'Contributions every ${group.contributionFrequencyValue} ${group.contributionFrequencyUnit}',
              style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              'UGX ${group.totalBalance.toStringAsFixed(0)} / ${group.goalAmount.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 24),
            const Text(
              'Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<List<Member>>(
                stream: groupService.getGroupMembers(group.id),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
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
                      return ListTile(
                        title: Text(member.userId),
                        subtitle: Text('Role: ${member.role}'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}