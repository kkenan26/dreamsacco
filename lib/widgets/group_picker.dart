import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GroupPicker extends StatelessWidget {
  final String? selectedGroupId;
  final ValueChanged<String?> onChanged;

  const GroupPicker({super.key, required this.selectedGroupId, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('memberIds', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(height: 56, child: Center(child: CircularProgressIndicator()));
        }

        final groups = snapshot.data!.docs;

        if (groups.isEmpty) {
          return const Text("You're not in any groups yet.");
        }

        // Auto-select the first group if nothing is selected yet
        if (selectedGroupId == null || !groups.any((g) => g.id == selectedGroupId)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onChanged(groups.first.id);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: groups.any((g) => g.id == selectedGroupId) ? selectedGroupId : null,
              isExpanded: true,
              hint: const Text('Select a group'),
              items: groups.map((doc) {
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
                return DropdownMenuItem(
                  value: doc.id,
                  child: Text(data['name'] ?? 'Unnamed Group'),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}