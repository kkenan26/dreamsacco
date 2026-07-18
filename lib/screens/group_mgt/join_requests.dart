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
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: StreamBuilder<List<JoinRequest>>(
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
    );
  }
}