import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../services/credit_score.dart';
import '../../models/group.dart';
import 'group_create.dart';
import 'group_detail.dart';
import 'browse_groups.dart';
import 'join_by_id.dart';
import 'notifications.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  static const String _currentUserId = 'test_admin_123';

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BrowseGroupsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.key),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const JoinByIdScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Group>>(
        stream: groupService.getGroupsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text('No groups yet. Create one!'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final progress = group.goalAmount > 0
                  ? (group.totalBalance / group.goalAmount).clamp(0.0, 1.0)
                  : 0.0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.description),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: progress),
                      const SizedBox(height: 4),
                      Text(
                        'UGX ${group.totalBalance.toStringAsFixed(0)} / ${group.goalAmount.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GroupDetailScreen(group: group)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}