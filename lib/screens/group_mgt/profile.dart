import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/group.dart';
import '../../services/adapter.dart';

class ProfileScreen extends StatelessWidget {
  final String? userId; // null means "view my own profile"

  const ProfileScreen({super.key, this.userId});

  @override
  Widget build(BuildContext context) {
    final GroupService groupService = GroupService(
      creditScoreService: RealCreditScoreAdapter(),
    );
    final String viewedUserId = userId ?? FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: groupService.getUserProfile(viewedUserId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = snapshot.data ?? {};
          final name = profile['name'] ?? 'Unknown User';
          final email = profile['email'] ?? FirebaseAuth.instance.currentUser!.email ?? '';
          final phone = profile['phone'] ?? 'Not provided';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF0D47A1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _profileRow(Icons.email, 'Email', email),
                        const Divider(),
                        _profileRow(Icons.phone, 'Phone', phone),
                        const Divider(),
                        _profileRow(Icons.badge, 'User ID', viewedUserId),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FutureBuilder<double>(
                  future: groupService.getCreditScoreForDisplay(viewedUserId),
                  builder: (context, scoreSnapshot) {
                    if (!scoreSnapshot.hasData) return const SizedBox.shrink();
                    double score = scoreSnapshot.data!;
                    String risk = score >= 70
                        ? 'Low Risk'
                        : score >= 40
                        ? 'Medium Risk'
                        : 'High Risk';
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.credit_score, color: Color(0xFF0D47A1)),
                        title: Text('Credit Score: ${score.toStringAsFixed(0)}'),
                        subtitle: Text(risk),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _profileRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}