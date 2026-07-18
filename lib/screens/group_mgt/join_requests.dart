import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../models/join_request.dart';
import '../../services/credit_score.dart';
class JoinRequestsScreen extends StatelessWidget {
  final String groupId;

  const JoinRequestsScreen({super.key, required this.groupId});

  Color _riskColor(String riskFlag) {
    switch (riskFlag) {
      case 'low':
        return const Color(0xFF8FD6BD);
      case 'medium':
        return const Color(0xFFF6C177);
      case 'high':
        return const Color(0xFFE8A0A0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Requests'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Join Requests'),
              Tab(text: 'Leave Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Join Requests
            StreamBuilder<List<JoinRequest>>(
              stream: groupService.getPendingJoinRequests(groupId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(child: Text('No pending join requests.'));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(request.userName),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Credit Score: ${request.userCreditScore.toStringAsFixed(0)}'),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _riskColor(request.riskFlag),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                request.riskFlag.toUpperCase(),
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await groupService.approveJoinRequest(
                                  groupId: groupId,
                                  requestId: request.id,
                                  userId: request.userId,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await groupService.rejectJoinRequest(
                                  groupId: groupId,
                                  requestId: request.id,
                                  userId: request.userId,
                                  groupName: request.userName,
                                );
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

            // TAB 2: Leave Requests
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: groupService.getPendingLeaveRequests(groupId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? [];

                if (requests.isEmpty) {
                  return const Center(child: Text('No pending leave requests.'));
                }

                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        title: Text(request['userName'] ?? 'Unknown'),
                        subtitle: const Text('Requested to leave this group'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () async {
                                await groupService.approveLeaveRequest(
                                  groupId: groupId,
                                  requestId: request['id'],
                                  userId: request['userId'],
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () async {
                                await groupService.rejectLeaveRequest(
                                  groupId: groupId,
                                  requestId: request['id'],
                                  userId: request['userId'],
                                );
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
          ],
        ),
      ),
    );
  }
}