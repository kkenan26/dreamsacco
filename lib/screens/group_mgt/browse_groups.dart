import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../models/group.dart';
import '../../services/credit_score.dart';
import 'public_group_preview.dart';

class BrowseGroupsScreen extends StatelessWidget {
  const BrowseGroupsScreen({super.key});

  // TODO: replace with FirebaseAuth.instance.currentUser!.uid once auth is wired in
  static const String _currentUserId = 'test_user_456';
  static const String _currentUserName = 'Test User';

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Browse Public Groups')),
      body: StreamBuilder<List<Group>>(
        stream: groupService.getPublicGroups(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data ?? [];

          if (groups.isEmpty) {
            return const Center(child: Text('No public groups available.'));
          }

          return ListView.builder(
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text(group.description),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PublicGroupPreviewScreen(group: group),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}