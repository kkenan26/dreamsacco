// lib/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'contribution_screen.dart';
import 'credit_scoring_screen.dart';
import 'loan_screen.dart';
import 'goals/goal_screen.dart';
import 'milestones/milestone_screen.dart';
import 'risk/risk_alert_screen.dart';
import 'shares/shares_screen.dart';
import 'transparency/transparency_screen.dart';
import 'whatif/what_if_calculator_screen.dart';
import 'group_mgt/group_list.dart';
import 'welcome_screen.dart';
import 'group_mgt/notifications.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  bool hideBalance = false;

  String userName = "Loading...";
  String memberId = "";
  String savingsAmount = "UGX 0";
  String loanAmount = "UGX 0";
  String contributionStatus = "UNPAID";
  String savingsGoal = "0% Score";
  String riskAlert = "No Alerts";
  String milestones = "0 Month Streak";

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadDashboardData();
  }

  void _loadDashboardData() async {
    try {
      String uid = FirebaseAuth.instance.currentUser?.uid ?? '';

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists || !mounted) return;
      Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

      String groupId = '';
      String contribution = 'UNPAID';

      QuerySnapshot memberGroups = await FirebaseFirestore.instance
          .collectionGroup('members')
          .where('userId', isEqualTo: uid)
          .limit(1)
          .get();

      if (memberGroups.docs.isNotEmpty) {
        groupId = memberGroups.docs.first.reference.parent.parent!.id;

        String month =
            '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}';

        QuerySnapshot contributions = await FirebaseFirestore.instance
            .collection('groups')
            .doc(groupId)
            .collection('contributions')
            .where('userId', isEqualTo: uid)
            .where('month', isEqualTo: month)
            .where('status', isEqualTo: 'paid')
            .limit(1)
            .get();

        if (contributions.docs.isNotEmpty) {
          contribution = 'PAID';
        }
      }

      // ✅ FIX: Read totalSavings (money), not totalContributions (count)
      double totalSavings = (data['totalSavings'] as num?)?.toDouble() ?? 0.0;
      double loanLimitVal = (data['loanLimit'] as num?)?.toDouble() ?? 0.0;
      int creditScore = (data['creditScore'] as num?)?.toInt() ?? 50;
      int streak = (data['contributionStreak'] as num?)?.toInt() ?? 0;

      String fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

      if (!mounted) return;
      setState(() {
        userName = data['name'] ?? 'User';
        memberId = uid.substring(0, 6).toUpperCase();
        savingsAmount = "UGX ${fmt(totalSavings)}";
        loanAmount = "UGX ${fmt(loanLimitVal)}";
        contributionStatus = contribution;
        savingsGoal = "$creditScore% Score";
        riskAlert = streak > 2 ? "Good Standing" : "Build Your Streak";
        milestones = "$streak Month Streak";
      });
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    }
  }

  String getGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning 👋";
    if (hour < 17) return "Good Afternoon 👋";
    return "Good Evening 👋";
  }

  List<Map<String, dynamic>> get services => [
    {
      "title": "Credit Score",
      "subtitle": savingsGoal,
      "icon": Icons.star,
      "color": Colors.orange,
      "screen": const CreditScoreScreen(),
    },
    {
      "title": "Contributions",
      "subtitle": contributionStatus,
      "icon": Icons.payments,
      "color": Colors.green,
      "screen": const ContributionScreen(),
    },
    {
      "title": "Savings Goals",
      "subtitle": "View Goals",
      "icon": Icons.flag,
      "color": Colors.blue,
      "screen": const GoalScreen(),
    },
    {
      "title": "Milestones",
      "subtitle": milestones,
      "icon": Icons.emoji_events,
      "color": Colors.amber,
      "screen": const MilestoneScreen(),
    },
    {
      "title": "Transparency",
      "subtitle": "Group Ledger",
      "icon": Icons.bar_chart,
      "color": Colors.teal,
      "screen": const TransparencyScreen(),
    },
    {
      "title": "Shares",
      "subtitle": "View Shares",
      "icon": Icons.pie_chart,
      "color": Colors.indigo,
      "screen": const SharesScreen(),
    },
  ];

  Widget _quick(IconData icon, String label) {
    return InkWell(
      onTap: () => _handleQuickAction(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF0D47A1)),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String action) async {
    if (action == "Deposit") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ContributionScreen()));
    } else if (action == "Loan") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const LoanScreen()));
    } else if (action == "Groups") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const GroupListScreen()));
    } else if (action == "Loan Status") {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const LoanScreen()));
    } else if (action == "Sign Out") {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$action tapped')),
      );
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _authService.signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => const WelcomeScreen()),
                    (route) => false,
              );
            },
            child: const Text('Sign Out',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text("DreamSacco",
            style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsScreen())),
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: _showSignOutDialog,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              getGreeting(),
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              userName,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
            ),
            const SizedBox(height: 16),

            // Balance Card
            Container(
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color:
                      const Color(0xFF0D47A1).withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ]),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Account Summary",
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16)),
                          const SizedBox(height: 2),
                          Text("ID: $memberId",
                              style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: () => setState(
                                () => hideBalance = !hideBalance),
                        icon: Icon(hideBalance
                            ? Icons.visibility_off
                            : Icons.visibility),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Savings",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                                hideBalance
                                    ? "******"
                                    : savingsAmount,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))
                          ],
                        ),
                      ),
                      Container(
                          width: 1,
                          height: 35,
                          color: Colors.white30),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Loan Limit",
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                                hideBalance
                                    ? "******"
                                    : loanAmount,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18))
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    avatar: const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                    label: Text(
                      "Contributions: $contributionStatus",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions Section
            const Text(
              "Quick Actions",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _quick(Icons.add_card, "Deposit"),
                  _quick(Icons.request_page, "Loan"),
                  _quick(Icons.group, "Groups"),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Services Grid
            const Text("Services",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.15),
              itemBuilder: (c, i) {
                final s = services[i];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0.5,
                  child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                            s["screen"] as Widget)),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment:
                        MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                            (s["color"] as Color)
                                .withValues(alpha: .12),
                            child: Icon(s["icon"] as IconData,
                                color: s["color"] as Color),
                          ),
                          const SizedBox(height: 10),
                          Text(s["title"] as String,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(s["subtitle"] as String,
                              style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12))
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
