import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/group.dart';
import '../../models/group.dart';
import '../../services/adapter.dart';

class PublicGroupPreviewScreen extends StatefulWidget {
  final Group group;

  const PublicGroupPreviewScreen({super.key, required this.group});

  @override
  State<PublicGroupPreviewScreen> createState() => _PublicGroupPreviewScreenState();
}

class _PublicGroupPreviewScreenState extends State<PublicGroupPreviewScreen> {
  bool _isSubmitting = false;
  final _sharesController = TextEditingController();


  final GroupService _groupService = GroupService(
    creditScoreService: RealCreditScoreAdapter(),
  );

  @override
  void dispose() {
    _sharesController.dispose();
    super.dispose();
  }

  Future<void> _requestToJoin() async {
    double sharesRequested = 0.0;

    if (widget.group.isShareBased) {
      if (_sharesController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter a share percentage to request.')),
        );
        return;
      }
      double percent = double.tryParse(_sharesController.text.trim()) ?? 0;
      sharesRequested = (percent / 100) * widget.group.totalShares;

      int remainingShares = widget.group.totalShares - widget.group.sharesTaken;
      if (sharesRequested > remainingShares) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only $remainingShares shares remaining.')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String userName = await _groupService.getUserName(userId);

      await _groupService.submitJoinRequest(
        groupId: widget.group.id,
        userId: userId,
        userName: userName,
        sharesRequested: sharesRequested,
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
            if (group.isShareBased) ...[
              Text(
                'Shares available: ${group.totalShares - group.sharesTaken} / ${group.totalShares}',
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _sharesController,
                decoration: const InputDecoration(labelText: 'Percentage of shares to request (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
            ],
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