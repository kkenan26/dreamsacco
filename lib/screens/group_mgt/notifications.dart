import 'package:flutter/material.dart';
import '../../services/group.dart';
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
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  // TODO: replace with FirebaseAuth.instance.currentUser!.uid once auth is wired in
  static const String _currentUserId = 'test_user_456';

  IconData _iconForType(String type) {
    switch (type) {
      case 'join_approved':
        return Icons.check_circle;
      case 'join_rejected':
        return Icons.cancel;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: MockCreditScoreService(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: groupService.getNotificationsForUser(_currentUserId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final notifications = snapshot.data ?? [];

          if (notifications.isEmpty) {
            return const Center(child: Text('No notifications yet.'));
          }

          return ListView.builder(
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final bool isRead = notif['read'] ?? false;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                color: isRead ? Colors.white : const Color(0xFFEAF4FF),
                child: ListTile(
                  leading: Icon(_iconForType(notif['type'] ?? '')),
                  title: Text(notif['message'] ?? ''),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isRead)
                        IconButton(
                          icon: const Icon(Icons.mark_email_read, size: 20),
                          onPressed: () {
                            groupService.markNotificationAsRead(notif['id']);
                          },
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () {
                          groupService.deleteNotification(notif['id']);
                        },
                      ),IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        onPressed: () async {
                          bool confirmed = await _confirmAction(
                            context,
                            'Delete Notification?',
                            'This cannot be undone.',
                          );
                          if (confirmed) {
                            groupService.deleteNotification(notif['id']);
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