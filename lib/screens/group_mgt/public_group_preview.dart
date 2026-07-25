import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../models/group.dart';
import '../../services/credit_score.dart';

class PublicGroupPreviewScreen extends StatefulWidget {
  final Group group;

  const PublicGroupPreviewScreen({super.key, required this.group});

  @override
  State<PublicGroupPreviewScreen> createState() => _PublicGroupPreviewScreenState();
}

class _PublicGroupPreviewScreenState extends State<PublicGroupPreviewScreen> {
  bool _isSubmitting = false;

  // TODO: replace with FirebaseAuth.instance.currentUser!.uid once auth is wired in
  static const String _currentUserId = 'test_user_456';
  static const String _currentUserName = 'Test User';

  final GroupService _groupService = GroupService(
    creditScoreService: MockCreditScoreService(),
  );

  Future<void> _requestToJoin() async {
    setState(() => _isSubmitting = true);
    try {
      await _groupService.submitJoinRequest(
        groupId: widget.group.id,
        userId: _currentUserId,
        userName: _currentUserName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Join request sent!')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    final progress = group.goalAmount > 0
        ? (group.totalBalance / group.goalAmount).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: Text(group.name)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.description, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('Goal: ${group.goalDescription}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress),
            const SizedBox(height: 8),
            Text(
              'UGX ${group.totalBalance.toStringAsFixed(0)} / ${group.goalAmount.toStringAsFixed(0)}',
            ),
            const SizedBox(height: 16),
            Text(
              'Contribution Amount: UGX ${group.contribution.toStringAsFixed(0)} every ${group.contributionFrequencyValue} ${group.contributionFrequencyUnit}',
            ),
            const SizedBox(height: 24),
            _isSubmitting
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _requestToJoin,
                child: const Text('Request to Join'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}