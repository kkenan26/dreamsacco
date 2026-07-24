// lib/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'credit_scoring_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool hideBalance = false;
  int currentIndex = 0;

  final String userName = "Kimberly Miracle";
  final String memberId = "SAC001";
  final String savingsAmount = "UGX 850,000";
  final String loanAmount = "UGX 300,000";
  final String contributionStatus = "PAID";
  final String savingsGoal = "68% Complete";
  final String riskAlert = "No Alerts";
  final String milestones = "2 Achieved";

  String getGreeting() {
    final int hour = DateTime.now().hour;
    if (hour < 12) return "Good Morning 👋";
    if (hour < 17) return "Good Afternoon 👋";
    return "Good Evening 👋";
  }

  List<Map<String, dynamic>> get services => [
        {
          "title": "Group Balance",
          "subtitle": "UGX 12.5M",
          "icon": Icons.account_balance_wallet,
          "color": Colors.blue
        },
        {
          "title": "Contributions",
          "subtitle": contributionStatus,
          "icon": Icons.payments,
          "color": Colors.green
        },
        {
          "title": "Savings Goals",
          "subtitle": savingsGoal,
          "icon": Icons.flag,
          "color": Colors.orange
        },
        {
          "title": "Calculator",
          "subtitle": "Estimate Loan",
          "icon": Icons.calculate,
          "color": Colors.purple
        },
        {
          "title": "Risk Alerts",
          "subtitle": riskAlert,
          "icon": Icons.warning_amber,
          "color": Colors.red
        },
        {
          "title": "Milestones",
          "subtitle": milestones,
          "icon": Icons.emoji_events,
          "color": Colors.amber
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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
          ],
        ),
      ),
    );
  }

  void _handleQuickAction(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$action tapped')),
    );
  }

  void _handleServiceTap(String title) {
    if (title== "Credit Score"|| title== "Savings Goals"){
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context)=> const CreditScoreScreen()),
      );
    }else{
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title tapped')),
      );
    }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: const Text("DreamSacco Dashboard", style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: () {}, 
            icon: const Icon(Icons.notifications_outlined),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16.0, left: 8.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, size: 18, color: Colors.white),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            Text(
              getGreeting(),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 2),
            Text(
              userName, 
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 16),
            
            // Balance Card Section
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
                    color: const Color(0xFF0D47A1).withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Account Summary", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 2),
                          Text("ID: $memberId", style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                      IconButton(
                        color: Colors.white,
                        onPressed: () => setState(() => hideBalance = !hideBalance),
                        icon: Icon(hideBalance ? Icons.visibility_off : Icons.visibility),
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
                            const Text("Savings", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(hideBalance ? "******" : savingsAmount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                          ],
                        ),
                      ),
                      Container(width: 1, height: 35, color: Colors.white30),
                      Expanded(
                        child: Column(
                          children: [
                            const Text("Loan Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(hideBalance ? "******" : loanAmount, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))
                          ],
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green, size: 18),
                    label: Text("Contributions: $contributionStatus", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0D47A1))),
                    backgroundColor: Colors.white,
                    side: BorderSide.none,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  )
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Quick Actions Section (Merged Layout)
            const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            Center(
              child: Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: [
                  _quick(Icons.add_card, "Deposit"),
                  _quick(Icons.money_off, "Withdraw"),
                  _quick(Icons.request_page, "Loan"),
                  _quick(Icons.pie_chart, "Shares"),
                  _quick(Icons.person, "Profile"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Services Grid Section
            const Text("Services", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: services.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.15),
              itemBuilder: (c, i) {
                final s = services[i];
                return Card(
                  color: Colors.white,
                  surfaceTintColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0.5,
                  child: InkWell(
                    onTap: () => _handleServiceTap(s["title"]),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center, 
                        children: [
                          CircleAvatar(
                            backgroundColor: (s["color"] as Color).withValues(alpha: .12),
                            child: Icon(s["icon"], color: s["color"]),
                          ),
                          const SizedBox(height: 10),
                          Text(s["title"], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text(s["subtitle"], style: TextStyle(color: Colors.grey.shade600, fontSize: 12))
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        selectedItemColor: const Color(0xFF0D47A1),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

