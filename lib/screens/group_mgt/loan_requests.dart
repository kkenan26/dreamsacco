import 'package:flutter/material.dart';
import '../../services/group.dart';
import '../../services/adapter.dart';

class LoanRequestsScreen extends StatelessWidget {
  final String groupId;

  const LoanRequestsScreen({super.key, required this.groupId});

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
        title: const Text('Loan Requests', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: groupService.getPendingLoanRequests(groupId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];
          if (requests.isEmpty) {
            return Center(child: Text('No pending loan requests.', style: TextStyle(color: Colors.grey.shade600)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final loan = requests[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UGX ${(loan['amount'] ?? 0).toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Credit Score: ${loan['creditScoreAtRequest'] ?? 0}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    Text(
                      'Interest Rate: ${((loan['interestRate'] ?? 0.15) * 100).toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle, color: Colors.green),
                          onPressed: () async {
                            await groupService.approveLoanRequest(
                              groupId: groupId,
                              loanId: loan['id'],
                              requesterId: loan['requesterId'],
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () async {
                            await groupService.rejectLoanRequest(
                              groupId: groupId,
                              loanId: loan['id'],
                              requesterId: loan['requesterId'],
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}