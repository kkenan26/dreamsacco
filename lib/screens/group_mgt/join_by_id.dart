import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/group.dart';
import '../../services/credit_score_service.dart';

class JoinByIdScreen extends StatefulWidget {
  const JoinByIdScreen({super.key});

  @override
  State<JoinByIdScreen> createState() => _JoinByIdScreenState();
}

class _JoinByIdScreenState extends State<JoinByIdScreen> {
  final _idController = TextEditingController();
  bool _isSubmitting = false;

  final String _currentUserId = FirebaseAuth.instance.currentUser!.uid;

  final GroupService _groupService = GroupService(
    creditScoreService: CreditScoreService(),
  );

  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }

  Future<void> _joinGroup() async {
    if (_idController.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await _groupService.joinGroupByGroupId(
        groupId: _idController.text.trim(),
        userId: _currentUserId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined the group!')),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Join Group by ID')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'Enter Group ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _isSubmitting
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _joinGroup,
              child: const Text('Join Group'),
            ),
          ],
        ),
      ),
    );
  }
}