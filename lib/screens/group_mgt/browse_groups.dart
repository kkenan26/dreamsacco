import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../models/group.dart';
import '../../services/adapter.dart';
import 'public_group_preview.dart';
import 'group_list.dart';

class BrowseGroupsScreen extends StatelessWidget {
  const BrowseGroupsScreen({super.key});

  static const Color primaryColor = Color(0xFF0D47A1);

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: RealCreditScoreAdapter(),
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text('Browse Public Groups', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
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
            return Center(
              child: Text('No public groups available.', style: TextStyle(color: Colors.grey.shade600)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return GroupCard(
                group: group,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => PublicGroupPreviewScreen(group: group)),
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